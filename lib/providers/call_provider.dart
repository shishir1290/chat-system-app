import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/message_service.dart';
import '../services/socket_service.dart';
import '../services/webrtc_service.dart';

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

  CallStatus get callStatus => _callStatus;
  CallType get callType => _callType;
  IncomingCallData? get incomingCall => _incomingCall;
  String? get activeRoomId => _activeRoomId;
  String? get targetUserId => _targetUserId;
  String? get targetUserName => _targetUserName;
  String? get targetUserAvatar => _targetUserAvatar;
  bool get isGroupCall => _isGroupCall;

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

    _incomingSub = _socketService.incomingCallStream.listen(_handleIncomingCall);
    _offerSub = _socketService.callOfferStream.listen(_handleCallOffer);
    _answerSub = _socketService.callAnsweredStream.listen(_handleCallAnswered);
    _rejectSub = _socketService.callRejectedStream.listen(_handleCallRejected);
    _iceSub = _socketService.iceCandidateStream.listen(_handleIceCandidate);
    _endedSub = _socketService.callEndedStream.listen(_handleCallEnded);
    _userJoinedSub = _socketService.userJoinedCallStream.listen(_handleUserJoinedCall);
    _userLeftSub = _socketService.userLeftCallStream.listen(_handleUserLeftCall);
  }

  /// Helper to create a peer connection with standard callbacks
  Future<RTCPeerConnection> _createPC(String peerId) async {
    return await _webrtcService.createPeerConnectionInstance(
      peerId: peerId,
      onIceCandidate: (candidate) {
        final candMap = candidate.toMap();
        _socketService.emitIceCandidate({
          'target_user_id': peerId,
          'targetUserId': peerId,
          'caller_id': peerId,
          'to': peerId,
          'to_user_id': peerId,
          'from_id': _currentUser?.id ?? '',
          'from_user_id': _currentUser?.id ?? '',
          'from': _currentUser?.id ?? '',
          'user_id': _currentUser?.id ?? '',
          'room_id': _activeRoomId,
          'roomId': _activeRoomId,
          'candidate': candMap,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'sdp': candidate.candidate,
        });
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
        'offer': offer.toMap(),
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
    // Ignore our own outgoing call events echoed back
    if (_callStatus == CallStatus.calling || _callStatus == CallStatus.connected) {
      // Check if this is from ourselves
      if (data is Map) {
        final fromId = data['caller_id']?.toString() ??
            data['callerId']?.toString() ??
            data['from_id']?.toString() ??
            data['from']?.toString();
        if (fromId == _currentUser?.id) return;
      }
    }

    try {
      final map = data is Map ? Map<String, dynamic>.from(data) : null;
      if (map != null) {
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

  Future<void> answerCall() async {
    if (_incomingCall == null) return;
    final incoming = _incomingCall!;
    _incomingCall = null;

    // Don't set to connected yet — wait for actual WebRTC connection
    _callStatus = CallStatus.calling;
    _answerInProgress = true;
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
      final fromId = map['from_id']?.toString() ??
          map['from_user_id']?.toString() ??
          map['caller_id']?.toString() ??
          map['callerId']?.toString() ??
          map['userId']?.toString() ??
          map['from']?.toString() ??
          _targetUserId;
      final offer = map['offer'] ?? map['signal'] ?? map['signalData'] ?? map['sdp'];

      debugPrint('📨 _handleCallOffer: fromId=$fromId, hasOffer=${offer != null}, status=$_callStatus, answerInProgress=$_answerInProgress');

      if (fromId != null && offer != null) {
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
      final fromId = map['callee_id']?.toString() ??
          map['from_id']?.toString() ??
          map['from_user_id']?.toString() ??
          map['caller_id']?.toString() ??
          map['callerId']?.toString() ??
          map['userId']?.toString() ??
          map['from']?.toString() ??
          _targetUserId;
      final answer = map['answer'] ?? map['signal'] ?? map['signalData'] ?? map['sdp'];

      debugPrint('📨 _handleCallAnswered: fromId=$fromId, hasAnswer=${answer != null}');

      if (fromId != null && answer != null) {
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
    endCall();
  }

  Future<void> _handleIceCandidate(dynamic data) async {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final fromId = map['from_id']?.toString() ??
          map['from_user_id']?.toString() ??
          map['caller_id']?.toString() ??
          map['callerId']?.toString() ??
          map['userId']?.toString() ??
          map['from']?.toString() ??
          _targetUserId;
      final candidate = map['candidate'] ?? map;

      if (fromId != null && candidate != null) {
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

  void _handleUserJoinedCall(dynamic data) {
    notifyListeners();
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

  void toggleVideo() {
    _webrtcService.toggleVideo();
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
    _webrtcService.cleanUp();
    super.dispose();
  }
}
