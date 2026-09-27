import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../services/webrtc_service.dart';

class CallProvider extends ChangeNotifier {
  final WebRTCService _webrtcService = WebRTCService();
  final SocketService _socketService = SocketService();

  CallStatus _callStatus = CallStatus.idle;
  CallType _callType = CallType.video;
  IncomingCallData? _incomingCall;

  String? _activeRoomId;
  String? _targetUserId;
  String? _targetUserName;
  String? _targetUserAvatar;
  bool _isGroupCall = false;
  UserModel? _currentUser;

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
    notifyListeners();

    try {
      final isVideo = type == CallType.video;
      await _webrtcService.openUserMedia(isVideo);

      await _webrtcService.createPeerConnectionInstance(
        peerId: targetUserId,
        onIceCandidate: (candidate) {
          _socketService.emitIceCandidate({
            'target_user_id': targetUserId,
            'room_id': roomId,
            'candidate': candidate.toMap(),
          });
        },
        onAddStream: (stream) {
          notifyListeners();
        },
        onConnectionState: (state) {
          if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
            _callStatus = CallStatus.connected;
            notifyListeners();
          }
        },
      );

      final offer = await _webrtcService.createOffer(targetUserId);

      _socketService.emitCallUser({
        'room_id': roomId,
        'target_user_id': targetUserId,
        'is_video': isVideo,
        'offer': offer.toMap(),
        'caller_name': _currentUser?.name ?? 'User',
        'caller_avatar': _currentUser?.avatar ?? '',
        'room_name': targetName ?? 'Direct Call',
        'is_group': isGroup,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error starting call: $e');
      endCall();
    }
  }

  void _handleIncomingCall(dynamic data) {
    if (data == null || _callStatus != CallStatus.idle) return;
    try {
      if (data is Map<String, dynamic>) {
        _incomingCall = IncomingCallData.fromJson(data);
        _callStatus = CallStatus.incoming;
        _callType = _incomingCall!.isVideo ? CallType.video : CallType.audio;
        _activeRoomId = _incomingCall!.roomId;
        _targetUserId = _incomingCall!.callerId;
        _targetUserName = _incomingCall!.callerName;
        _targetUserAvatar = _incomingCall!.callerAvatar;
        _isGroupCall = _incomingCall!.isGroup;
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
    _callStatus = CallStatus.connected;
    notifyListeners();

    try {
      final isVideo = incoming.isVideo;
      await _webrtcService.openUserMedia(isVideo);

      final callerId = incoming.callerId;
      await _webrtcService.createPeerConnectionInstance(
        peerId: callerId,
        onIceCandidate: (candidate) {
          _socketService.emitIceCandidate({
            'target_user_id': callerId,
            'room_id': incoming.roomId,
            'candidate': candidate.toMap(),
          });
        },
        onAddStream: (stream) {
          notifyListeners();
        },
        onConnectionState: (state) {
          if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
            _callStatus = CallStatus.connected;
            notifyListeners();
          }
        },
      );

      final answer = await _webrtcService.createAnswer(callerId, incoming.offer);

      _socketService.emitAnswerCall({
        'caller_id': callerId,
        'target_user_id': callerId,
        'room_id': incoming.roomId,
        'answer': answer.toMap(),
        'callee_name': _currentUser?.name ?? 'User',
        'callee_avatar': _currentUser?.avatar ?? '',
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error answering call: $e');
      endCall();
    }
  }

  void rejectCall({String reason = 'Call declined'}) {
    if (_incomingCall != null) {
      _socketService.emitRejectCall({
        'caller_id': _incomingCall!.callerId,
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
      final fromId = data['from_id']?.toString() ?? data['caller_id']?.toString();
      final offer = data['offer'];
      if (fromId != null && offer != null && _callStatus == CallStatus.connected) {
        final answer = await _webrtcService.createAnswer(fromId, offer);
        _socketService.emitAnswerCall({
          'caller_id': fromId,
          'target_user_id': fromId,
          'room_id': _activeRoomId,
          'answer': answer.toMap(),
          'callee_name': _currentUser?.name ?? 'User',
        });
      }
    }
  }

  Future<void> _handleCallAnswered(dynamic data) async {
    if (data is Map) {
      final fromId = data['callee_id']?.toString() ?? data['from_id']?.toString() ?? _targetUserId;
      final answer = data['answer'];
      if (fromId != null && answer != null) {
        await _webrtcService.setRemoteAnswer(fromId, answer);
        _callStatus = CallStatus.connected;
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
      final fromId = data['from_id']?.toString() ?? _targetUserId;
      final candidate = data['candidate'];
      if (fromId != null && candidate != null) {
        await _webrtcService.addIceCandidate(fromId, candidate);
      }
    }
  }

  void _handleUserJoinedCall(dynamic data) {
    // For group calling
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
