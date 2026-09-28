import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../main.dart';
import '../models/call_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/message_service.dart';
import '../services/socket_service.dart';
import '../services/webrtc_service.dart';
import '../ui/screens/call_screen.dart';

class CallProvider extends ChangeNotifier {
  final WebRTCService _webrtcService = WebRTCService();
  final SocketService _socketService = SocketService();
  final MessageService _messageService = MessageService();

  CallStatus _callStatus = CallStatus.idle;
  CallType _callType = CallType.video;
  IncomingCallData? _incomingCall;

  String? _activeRoomId;
  String? _targetUserId;
  String? _targetUserName;
  String? _targetUserAvatar;
  bool _isGroupCall = false;
  bool _isCaller = false;
  UserModel? _currentUser;

  MessageModel? _currentCallMessage;
  DateTime? _callConnectedTime;
  bool _wasCallConnected = false;

  // Track whether the answerer has set up its PC and is ready for offers
  bool _answerInProgress = false;
  // Pending offer received while answer was in progress
  dynamic _pendingOffer;
  String? _pendingOfferFromId;

  // Pending ICE candidates received before PC was created
  final List<Map<String, dynamic>> _pendingIceCandidates = [];

  StreamSubscription? _incomingSub;
  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _rejectSub;
  StreamSubscription? _iceSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _userJoinedSub;
  StreamSubscription? _userLeftSub;
  StreamSubscription? _transferredSub;
  StreamSubscription? _answeredElsewhereSub;

  CallStatus get callStatus => _callStatus;
  CallType get callType => _callType;
  IncomingCallData? get incomingCall => _incomingCall;
  String? get activeRoomId => _activeRoomId;
  String? get targetUserId => _targetUserId;
  String? get targetUserName => _targetUserName;
  String? get targetUserAvatar => _targetUserAvatar;
  bool get isGroupCall => _isGroupCall;
  bool get isCaller => _isCaller;

  RTCVideoRenderer get localRenderer => _webrtcService.localRenderer;
  Map<String, RTCVideoRenderer> get remoteRenderers => _webrtcService.remoteRenderers;
  bool get isAudioMuted => _webrtcService.isAudioMuted;
  bool get isVideoOff => _webrtcService.isVideoOff;

  Future<void> initialize(UserModel user) async {
    _currentUser = user;
    await _webrtcService.initializeRenderers();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _incomingSub?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _rejectSub?.cancel();
    _iceSub?.cancel();
    _endedSub?.cancel();
    _userJoinedSub?.cancel();
    _userLeftSub?.cancel();
    _transferredSub?.cancel();
    _answeredElsewhereSub?.cancel();

    _incomingSub = _socketService.incomingCallStream.listen(_handleIncomingCall);
    _offerSub = _socketService.callOfferStream.listen(_handleCallOffer);
    _answerSub = _socketService.callAnsweredStream.listen(_handleCallAnswered);
    _rejectSub = _socketService.callRejectedStream.listen(_handleCallRejected);
    _iceSub = _socketService.iceCandidateStream.listen(_handleIceCandidate);
    _endedSub = _socketService.callEndedStream.listen(_handleCallEnded);
    _userJoinedSub = _socketService.userJoinedCallStream.listen(_handleUserJoinedCall);
    _userLeftSub = _socketService.userLeftCallStream.listen(_handleUserLeftCall);
    _transferredSub = _socketService.callTransferredStream.listen(_handleCallTransferred);
    _answeredElsewhereSub = _socketService.callAnsweredElsewhereStream.listen(_handleCallAnsweredElsewhere);
  }

  String _resolvePeerId(Map map) {
    for (final key in [
      'callee_id',
      'calleeId',
      'from_id',
      'from_user_id',
      'from',
      'userId',
      'user_id',
      'target_user_id',
      'targetUserId',
      'caller_id',
      'callerId',
    ]) {
      final val = map[key]?.toString();
      if (val != null && val.isNotEmpty && val != _currentUser?.id) {
        return val;
      }
    }
    return _targetUserId ?? '';
  }

  /// Helper to create a peer connection with standard callbacks
  Future<RTCPeerConnection> _createPC(String peerId) async {
    return await _webrtcService.createPeerConnectionInstance(
      peerId: peerId,
      onIceCandidate: (candidate) {
        final candMap = candidate.toMap();
        final payload = {
          'target_user_id': peerId,
          'targetUserId': peerId,
          'caller_id': _currentUser?.id ?? '',
          'callerId': _currentUser?.id ?? '',
          'callee_id': peerId,
          'calleeId': peerId,
          'to': peerId,
          'to_user_id': peerId,
          'from_id': _currentUser?.id ?? '',
          'from_user_id': _currentUser?.id ?? '',
          'from': _currentUser?.id ?? '',
          'user_id': _currentUser?.id ?? '',
          'room_id': _activeRoomId,
          'roomId': _activeRoomId,
          'candidate': candMap,
          'signal': {'candidate': candMap},
          'signalData': {'candidate': candMap},
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'sdp': candidate.candidate,
        };

        if (_callStatus != CallStatus.idle) {
          _socketService.emitIceCandidate(payload);
        }
      },
      onAddStream: (stream) {
        debugPrint('📺 onAddStream fired for $peerId - stream has ${stream.getVideoTracks().length} video tracks');
        _callStatus = CallStatus.connected;
        _wasCallConnected = true;
        _callConnectedTime ??= DateTime.now();
        notifyListeners();
      },
      onConnectionState: (state) {
        debugPrint('🔌 PeerConnection state for $peerId: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _callStatus = CallStatus.connected;
          _wasCallConnected = true;
          _callConnectedTime ??= DateTime.now();
          notifyListeners();
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          debugPrint('⚠️ PeerConnection failed/disconnected for $peerId');
        }
      },
    );
  }

  /// Flush pending ICE candidates for a given peer
  Future<void> _flushPendingIceCandidates(String peerId) async {
    final pending = List<Map<String, dynamic>>.from(_pendingIceCandidates);
    _pendingIceCandidates.clear();
    for (final entry in pending) {
      final candidate = entry['candidate'];
      final entryPeerId = entry['peerId'] ?? peerId;
      debugPrint('🧊 Flushing pending ICE candidate for $entryPeerId');
      await _webrtcService.addIceCandidate(entryPeerId, candidate);
    }
  }

  Future<void> startCall({
    required String targetUserId,
    required String roomId,
    required CallType type,
    String? targetName,
    String? targetAvatar,
    bool isGroup = false,
  }) async {
    _callStatus = CallStatus.calling;
    _callType = type;
    _activeRoomId = roomId;
    _targetUserId = targetUserId;
    _targetUserName = targetName;
    _targetUserAvatar = targetAvatar;
    _isGroupCall = isGroup;
    _isCaller = true;
    _callConnectedTime = null;
    _wasCallConnected = false;
    _currentCallMessage = null;
    _pendingIceCandidates.clear();
    notifyListeners();

    final isVideo = type == CallType.video;

    // Send call started message into the chat room
    try {
      _currentCallMessage = await _messageService.sendMessage(
        roomId,
        isVideo ? 'Video call started' : 'Audio call started',
        isAudioCall: !isVideo,
        isVideoCall: isVideo,
        isCallActive: true,
      );
    } catch (e) {
      debugPrint('Error sending initial call message: $e');
    }

    try {
      await _webrtcService.initializeRenderers();
      await _webrtcService.openUserMedia(isVideo);

      await _createPC(targetUserId);

      final offer = await _webrtcService.createOffer(targetUserId);
      debugPrint('📤 Sending offer to $targetUserId');

      final offerMap = offer.toMap();
      _socketService.emitCallUser({
        'room_id': roomId,
        'roomId': roomId,
        'target_user_id': targetUserId,
        'targetUserId': targetUserId,
        'to': targetUserId,
        'to_user_id': targetUserId,
        'caller_id': _currentUser?.id ?? '',
        'callerId': _currentUser?.id ?? '',
        'from_id': _currentUser?.id ?? '',
        'from_user_id': _currentUser?.id ?? '',
        'from': _currentUser?.id ?? '',
        'user_id': _currentUser?.id ?? '',
        'is_video': isVideo,
        'isVideo': isVideo,
        'type': isVideo ? 'video' : 'audio',
        'offer': offerMap,
        'signal': offerMap,
        'signalData': offerMap,
        'sdp': offer.sdp,
        'caller_name': _currentUser?.name ?? 'User',
        'caller_avatar': _currentUser?.avatar ?? '',
        'room_name': targetName ?? 'Direct Call',
        'is_group': isGroup,
      });

      // Flush any ICE candidates that arrived before PC was ready
      await _flushPendingIceCandidates(targetUserId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error starting call: $e');
      endCall();
    }
  }

  void _handleIncomingCall(dynamic data) {
    if (data == null) return;
    // If we are already calling or connected, ignore incoming call to prevent loop
    if (_callStatus == CallStatus.calling || _callStatus == CallStatus.connected) {
      debugPrint('📞 Ignoring incoming_call because call is already in progress ($_callStatus)');
      return;
    }

    try {
      final map = data is Map ? Map<String, dynamic>.from(data) : null;
      if (map != null) {
        final fromId = map['caller_id']?.toString() ??
            map['callerId']?.toString() ??
            map['from_id']?.toString() ??
            map['from']?.toString();
        if (fromId == _currentUser?.id) return;

        _isCaller = false;
        _incomingCall = IncomingCallData.fromJson(map);
        _callStatus = CallStatus.incoming;
        _callType = _incomingCall!.isVideo ? CallType.video : CallType.audio;
        _activeRoomId = _incomingCall!.roomId;
        _targetUserId = _incomingCall!.callerId;
        _targetUserName = _incomingCall!.callerName;
        _targetUserAvatar = _incomingCall!.callerAvatar;
        _isGroupCall = _incomingCall!.isGroup;
        _pendingIceCandidates.clear();
        debugPrint('📞 Incoming call from ${_incomingCall!.callerName} (${_incomingCall!.callerId}), has offer: ${_incomingCall!.offer != null}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error parsing incoming call: $e');
    }
  }

  Future<void> handleIncomingCallFromPush(Map<String, dynamic> data, {bool autoAnswer = false}) async {
    try {
      if (_currentUser == null) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(StorageKeys.userProfile);
        final token = prefs.getString(StorageKeys.accessToken);
        if (userJson != null) {
          _currentUser = UserModel.fromJson(jsonDecode(userJson));
          await _webrtcService.initializeRenderers();
          _setupSocketListeners();
        }
        if (token != null && _currentUser != null && !_socketService.isConnected) {
          _socketService.connect(token, myUserId: _currentUser!.id);
        }
      }

      final callerId = data['caller_id']?.toString() ?? data['callerId']?.toString() ?? '';
      final callerName = data['caller_name']?.toString() ?? data['callerName']?.toString() ?? 'Caller';
      final callerAvatar = data['caller_avatar']?.toString() ?? data['callerAvatar']?.toString() ?? '';
      final roomId = data['room_id']?.toString() ?? data['roomId']?.toString() ?? '';
      final roomName = data['room_name']?.toString() ?? data['roomName']?.toString() ?? 'Call';
      final isVideo = data['is_video'] == 'true' || data['is_video'] == true || data['isVideo'] == true;
      final isGroup = data['is_group'] == 'true' || data['is_group'] == true || data['isGroup'] == true;

      if (callerId.isEmpty || callerId == _currentUser?.id) return;

      _incomingCall = IncomingCallData(
        callerId: callerId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        roomId: roomId,
        roomName: roomName,
        roomAvatar: callerAvatar,
        isGroup: isGroup,
        isVideo: isVideo,
      );
      _callStatus = CallStatus.incoming;
      _callType = isVideo ? CallType.video : CallType.audio;
      _activeRoomId = roomId;
      _targetUserId = callerId;
      _targetUserName = callerName;
      _targetUserAvatar = callerAvatar;
      _isGroupCall = isGroup;
      _isCaller = false;
      _pendingIceCandidates.clear();
      notifyListeners();

      if (autoAnswer) {
        await answerCall();
        appNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const CallScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error handling incoming call from push: $e');
    }
  }

  Future<void> answerCall() async {
    if (_incomingCall == null) return;
    final incoming = _incomingCall!;
    _incomingCall = null;

    if (_currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(StorageKeys.userProfile);
      final token = prefs.getString(StorageKeys.accessToken);
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      }
      if (token != null && _currentUser != null && !_socketService.isConnected) {
        _socketService.connect(token, myUserId: _currentUser!.id);
      }
    }

    // Don't set to connected yet — wait for actual WebRTC connection
    _callStatus = CallStatus.calling;
    _answerInProgress = true;
    _isCaller = false;
    _activeRoomId = incoming.roomId;
    _targetUserId = incoming.callerId;
    _targetUserName = incoming.callerName;
    _targetUserAvatar = incoming.callerAvatar;
    _isGroupCall = incoming.isGroup;
    _callType = incoming.isVideo ? CallType.video : CallType.audio;
    _pendingIceCandidates.clear();
    notifyListeners();

    try {
      await _webrtcService.initializeRenderers();
      final isVideo = incoming.isVideo;
      await _webrtcService.openUserMedia(isVideo);

      final callerId = incoming.callerId;
      await _createPC(callerId);

      debugPrint('📞 answerCall: callerId=$callerId, hasOffer=${incoming.offer != null}');

      // Determine the offer to use — either from the incoming call data or
      // from a pending offer that arrived while we were setting up
      dynamic offerToUse = incoming.offer ?? _pendingOffer;
      if (offerToUse == null && _pendingOfferFromId == callerId) {
        offerToUse = _pendingOffer;
      }
      _pendingOffer = null;
      _pendingOfferFromId = null;

      dynamic answerObj;
      if (offerToUse != null) {
        debugPrint('📝 Creating answer from offer');
        final answer = await _webrtcService.createAnswer(callerId, offerToUse);
        if (answer != null) {
          answerObj = answer.toMap();
          debugPrint('✅ Answer created successfully');
        } else {
          debugPrint('⚠️ createAnswer returned null');
        }
      } else {
        debugPrint('⚠️ No offer available, will wait for call_offer event');
      }

      final payload = {
        'caller_id': callerId,
        'callerId': callerId,
        'target_user_id': callerId,
        'targetUserId': callerId,
        'to': callerId,
        'to_user_id': callerId,
        'from_id': _currentUser?.id ?? '',
        'from_user_id': _currentUser?.id ?? '',
        'from': _currentUser?.id ?? '',
        'user_id': _currentUser?.id ?? '',
        'callee_id': _currentUser?.id ?? '',
        'room_id': incoming.roomId,
        'roomId': incoming.roomId,
        'callee_name': _currentUser?.name ?? 'User',
        'callee_avatar': _currentUser?.avatar ?? '',
        if (answerObj != null) ...{
          'answer': answerObj,
          'signal': answerObj,
          'signalData': answerObj,
          if (answerObj is Map) 'sdp': answerObj['sdp'],
          if (answerObj is Map) 'type': answerObj['type'],
        },
      };

      _socketService.emitAnswerCall(payload);
      _socketService.emitJoinCall({
        'room_id': incoming.roomId,
        'roomId': incoming.roomId,
        'target_user_id': callerId,
        'from_id': _currentUser?.id ?? '',
      });

      // Flush any ICE candidates that arrived while we were setting up
      await _flushPendingIceCandidates(callerId);

      _answerInProgress = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error answering call: $e');
      _answerInProgress = false;
    }
  }

  void rejectCall({String reason = 'Call declined'}) {
    if (_incomingCall != null) {
      _socketService.emitRejectCall({
        'caller_id': _incomingCall!.callerId,
        'target_user_id': _incomingCall!.callerId,
        'to': _incomingCall!.callerId,
        'from_id': _currentUser?.id ?? '',
        'room_id': _incomingCall!.roomId,
        'is_group': _incomingCall!.isGroup,
        'reason': reason,
      });
      _incomingCall = null;
    }
    _callStatus = CallStatus.idle;
    notifyListeners();
  }

  Future<void> _handleCallOffer(dynamic data) async {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final fromId = _resolvePeerId(map);
      final offer = map['offer'] ?? map['signal'] ?? map['signalData'] ?? map['sdp'];

      debugPrint('📨 _handleCallOffer: fromId=$fromId, hasOffer=${offer != null}, status=$_callStatus, answerInProgress=$_answerInProgress');

      if (fromId.isNotEmpty && offer != null) {
        // If we are still in incoming ringing state, store offer for answerCall()
        if (_callStatus == CallStatus.incoming && _incomingCall != null) {
          _incomingCall = IncomingCallData(
            callerId: _incomingCall!.callerId.isNotEmpty ? _incomingCall!.callerId : fromId,
            callerName: _incomingCall!.callerName,
            callerAvatar: _incomingCall!.callerAvatar,
            roomId: _incomingCall!.roomId,
            roomName: _incomingCall!.roomName,
            roomAvatar: _incomingCall!.roomAvatar,
            isGroup: _incomingCall!.isGroup,
            isVideo: _incomingCall!.isVideo,
            offer: offer,
          );
          debugPrint('📨 Stored offer in incomingCall data');
          return;
        }

        // If answerCall() is currently running, store the offer for it to pick up
        if (_answerInProgress) {
          debugPrint('📨 Storing pending offer (answerInProgress)');
          _pendingOffer = offer;
          _pendingOfferFromId = fromId;
          return;
        }

        // If we are already in a call (calling/connected status as callee),
        // create a peer connection and answer
        if (!_webrtcService.peerConnections.containsKey(fromId)) {
          await _createPC(fromId);
        }

        final answer = await _webrtcService.createAnswer(fromId, offer);
        final payload = {
          'caller_id': fromId,
          'callerId': fromId,
          'target_user_id': fromId,
          'targetUserId': fromId,
          'to': fromId,
          'to_user_id': fromId,
          'from_id': _currentUser?.id ?? '',
          'from_user_id': _currentUser?.id ?? '',
          'from': _currentUser?.id ?? '',
          'user_id': _currentUser?.id ?? '',
          'callee_id': _currentUser?.id ?? '',
          'room_id': _activeRoomId,
          'roomId': _activeRoomId,
          'callee_name': _currentUser?.name ?? 'User',
          'callee_avatar': _currentUser?.avatar ?? '',
          if (answer != null) ...{
            'answer': answer.toMap(),
            'signal': answer.toMap(),
            'signalData': answer.toMap(),
            'sdp': answer.sdp,
            'type': answer.type,
          },
        };

        _socketService.emitAnswerCall(payload);

        // Flush pending ICE candidates
        await _flushPendingIceCandidates(fromId);

        _callStatus = CallStatus.connected;
        _wasCallConnected = true;
        _callConnectedTime ??= DateTime.now();
        notifyListeners();
      }
    }
  }

  Future<void> _handleCallAnswered(dynamic data) async {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final fromId = _resolvePeerId(map);
      final answer = map['answer'] ?? map['signal'] ?? map['signalData'] ?? map['sdp'];

      debugPrint('📨 _handleCallAnswered: fromId=$fromId, hasAnswer=${answer != null}');

      if (fromId.isNotEmpty && answer != null) {
        // Ensure peer connection exists for this peer
        if (!_webrtcService.peerConnections.containsKey(fromId) && fromId != _currentUser?.id) {
          debugPrint('⚠️ No PC for $fromId when answer arrived, creating one...');
          await _createPC(fromId);
        }

        await _webrtcService.setRemoteAnswer(fromId, answer);
        debugPrint('✅ Remote answer set for $fromId');

        // Flush pending ICE candidates now that remote description is set
        await _flushPendingIceCandidates(fromId);

        _callStatus = CallStatus.connected;
        _wasCallConnected = true;
        _callConnectedTime ??= DateTime.now();
        notifyListeners();
      }
    }
  }

  void _handleCallRejected(dynamic data) {
    debugPrint('Call was rejected');
    final callMsgId = _currentCallMessage?.id;
    final isVideo = _callType == CallType.video;
    if (callMsgId != null) {
      final text = isVideo ? 'Declined Video Call' : 'Declined Audio Call';
      _messageService.editMessage(callMsgId, text, isCallActive: false).catchError((e) {
        debugPrint('Error editing call message on reject: $e');
        return MessageModel.fromJson({});
      });
    }
    endCall(silent: true);
  }

  Future<void> _handleIceCandidate(dynamic data) async {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final fromId = _resolvePeerId(map);
      final candidate = map['candidate'] ?? map['signal']?['candidate'] ?? map['signalData']?['candidate'] ?? map;

      if (fromId.isNotEmpty && candidate != null) {
        // If peer connection doesn't exist yet, buffer the candidate
        if (!_webrtcService.peerConnections.containsKey(fromId) && fromId != _currentUser?.id) {
          debugPrint('🧊 Buffering ICE candidate for $fromId (no PC yet)');
          _pendingIceCandidates.add({'peerId': fromId, 'candidate': candidate});
          return;
        }

        // Also buffer if we haven't set remote description yet
        // (peer connection exists but may not have remote description)
        try {
          await _webrtcService.addIceCandidate(fromId, candidate);
        } catch (e) {
          debugPrint('🧊 Buffering ICE candidate for $fromId (error adding: $e)');
          _pendingIceCandidates.add({'peerId': fromId, 'candidate': candidate});
        }
      }
    }
  }

  Future<void> _handleUserJoinedCall(dynamic data) async {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final uid = map['user_id']?.toString() ?? map['userId']?.toString();
      final switchedDevice = map['switched_device'] == true;
      if (uid != null && uid.isNotEmpty && uid != _currentUser?.id) {
        if (_callStatus == CallStatus.calling || _callStatus == CallStatus.connected) {
          _callStatus = CallStatus.connected;
          _wasCallConnected = true;
          _callConnectedTime ??= DateTime.now();

          // Only send offer if switched_device or if peer connection doesn't exist yet (e.g. group call)
          if (switchedDevice || (_isCaller && !_webrtcService.peerConnections.containsKey(uid))) {
            try {
              if (_webrtcService.peerConnections.containsKey(uid)) {
                await _webrtcService.closePeer(uid);
              }
              await _createPC(uid);
              final offer = await _webrtcService.createOffer(uid);
              final offerMap = offer.toMap();
              _socketService.emitCallOffer({
                'room_id': _activeRoomId,
                'target_user_id': uid,
                'caller_id': _currentUser?.id ?? '',
                'is_video': _callType == CallType.video,
                'offer': offerMap,
                'caller_name': _currentUser?.name ?? 'User',
                'caller_avatar': _currentUser?.avatar ?? '',
              });
            } catch (e) {
              debugPrint('Error re-negotiating offer on user join: $e');
            }
          }
        }
      }
    }
    notifyListeners();
  }

  void _handleCallTransferred(dynamic data) {
    debugPrint('📲 Call transferred to another device');
    endCall(silent: true);
  }

  void _handleCallAnsweredElsewhere(dynamic data) {
    if (_callStatus == CallStatus.incoming) {
      debugPrint('📲 Call answered on another device');
      _incomingCall = null;
      _callStatus = CallStatus.idle;
      notifyListeners();
    }
  }

  Future<void> switchCallDevice({
    required String roomId,
    required bool isVideo,
    String? targetUserId,
    String? targetUserName,
    String? targetUserAvatar,
    bool isGroup = false,
  }) async {
    _callStatus = CallStatus.calling;
    _callType = isVideo ? CallType.video : CallType.audio;
    _activeRoomId = roomId;
    _targetUserId = targetUserId;
    _targetUserName = targetUserName;
    _targetUserAvatar = targetUserAvatar;
    _isGroupCall = isGroup;
    _callConnectedTime = DateTime.now();
    _wasCallConnected = true;
    _pendingIceCandidates.clear();
    notifyListeners();

    try {
      await _webrtcService.initializeRenderers();
      await _webrtcService.openUserMedia(isVideo);

      _socketService.emitSwitchCallDevice({
        'room_id': roomId,
        'user_name': _currentUser?.name ?? 'User',
        'user_avatar': _currentUser?.avatar ?? '',
        'is_video': isVideo,
      });

      if (targetUserId != null && targetUserId.isNotEmpty) {
        await _createPC(targetUserId);
        final offer = await _webrtcService.createOffer(targetUserId);
        _socketService.emitCallUser({
          'room_id': roomId,
          'target_user_id': targetUserId,
          'caller_id': _currentUser?.id ?? '',
          'is_video': isVideo,
          'offer': offer.toMap(),
          'caller_name': _currentUser?.name ?? 'User',
          'caller_avatar': _currentUser?.avatar ?? '',
          'is_group': isGroup,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching call device: $e');
      endCall();
    }
  }

  void _handleUserLeftCall(dynamic data) {
    if (data is Map) {
      final uid = data['user_id']?.toString();
      if (uid != null) {
        _webrtcService.closePeer(uid);
        notifyListeners();
      }
    }
  }

  void _handleCallEnded(dynamic data) {
    endCall(silent: true);
  }

  void toggleAudio() {
    _webrtcService.toggleAudio();
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    await _webrtcService.toggleVideo();
    if (!_webrtcService.isVideoOff) {
      _callType = CallType.video;

      // Broadcast renegotiation offer to all active peers so remote sides receive video
      for (final peerId in _webrtcService.peerConnections.keys) {
        try {
          final offer = await _webrtcService.createOffer(peerId);
          _socketService.emitCallOffer({
            'room_id': _activeRoomId,
            'target_user_id': peerId,
            'from_id': _currentUser?.id ?? '',
            'caller_id': _currentUser?.id ?? '',
            'offer': offer.toMap(),
            'is_video': true,
            'caller_name': _currentUser?.name ?? 'User',
            'caller_avatar': _currentUser?.avatar ?? '',
            'is_group': _isGroupCall,
          });
          debugPrint('📡 Sent renegotiation offer for video to $peerId');
        } catch (e) {
          debugPrint('Error creating/sending renegotiation offer: $e');
        }
      }
    }
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _webrtcService.switchCamera();
    notifyListeners();
  }

  Future<void> endCall({bool silent = false}) async {
    final wasConnected = _wasCallConnected || _callConnectedTime != null;
    final callMsgId = _currentCallMessage?.id;
    final isVideo = _callType == CallType.video;

    if (callMsgId != null) {
      try {
        if (wasConnected && _callConnectedTime != null) {
          final durationSec = DateTime.now().difference(_callConnectedTime!).inSeconds;
          final mins = (durationSec ~/ 60).toString().padLeft(2, '0');
          final secs = (durationSec % 60).toString().padLeft(2, '0');
          final text = isVideo
              ? 'Video Call Is Ended\nDuration: $mins:$secs'
              : 'Audio Call Is Ended\nDuration: $mins:$secs';
          await _messageService.editMessage(callMsgId, text, isCallActive: false);
        } else {
          final text = isVideo ? 'Missed Video Call' : 'Missed Audio Call';
          await _messageService.editMessage(callMsgId, text, isCallActive: false);
        }
      } catch (e) {
        debugPrint('Error updating call message on end: $e');
      }
    }

    if (!silent && _activeRoomId != null) {
      _socketService.emitEndCall({
        'room_id': _activeRoomId,
        'target_user_id': _targetUserId,
        'is_group': _isGroupCall,
      });
    }

    await _webrtcService.cleanUp();
    _callStatus = CallStatus.idle;
    _incomingCall = null;
    _activeRoomId = null;
    _targetUserId = null;
    _targetUserName = null;
    _targetUserAvatar = null;
    _isGroupCall = false;
    _isCaller = false;
    _currentCallMessage = null;
    _callConnectedTime = null;
    _wasCallConnected = false;
    _answerInProgress = false;
    _pendingOffer = null;
    _pendingOfferFromId = null;
    _pendingIceCandidates.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _rejectSub?.cancel();
    _iceSub?.cancel();
    _endedSub?.cancel();
    _userJoinedSub?.cancel();
    _userLeftSub?.cancel();
    _transferredSub?.cancel();
    _answeredElsewhereSub?.cancel();
    _webrtcService.cleanUp();
    super.dispose();
  }
}
