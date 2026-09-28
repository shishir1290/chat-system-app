import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants.dart';

typedef SocketEventCallback = void Function(dynamic data);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  final Set<String> _onlineUserIds = {};
  final StreamController<Set<String>> _onlineUsersController = StreamController<Set<String>>.broadcast();
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();

  // Chat stream controllers
  final StreamController<dynamic> _newMessageController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _messageEditedController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _messageDeletedController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _messageReadController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _typingController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _roomUpdatedController = StreamController<dynamic>.broadcast();

  // Call stream controllers
  final StreamController<dynamic> _incomingCallController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _callOfferController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _callAnsweredController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _callRejectedController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _iceCandidateController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _userJoinedCallController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _userLeftCallController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _groupCallStatusController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _callEndedController = StreamController<dynamic>.broadcast();

  bool get isConnected => _isConnected;
  Set<String> get onlineUserIds => Set.unmodifiable(_onlineUserIds);

  Stream<Set<String>> get onlineUsersStream => _onlineUsersController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  Stream<dynamic> get newMessageStream => _newMessageController.stream;
  Stream<dynamic> get messageEditedStream => _messageEditedController.stream;
  Stream<dynamic> get messageDeletedStream => _messageDeletedController.stream;
  Stream<dynamic> get messageReadStream => _messageReadController.stream;
  Stream<dynamic> get typingStream => _typingController.stream;
  Stream<dynamic> get roomUpdatedStream => _roomUpdatedController.stream;

  Stream<dynamic> get incomingCallStream => _incomingCallController.stream;
  Stream<dynamic> get callOfferStream => _callOfferController.stream;
  Stream<dynamic> get callAnsweredStream => _callAnsweredController.stream;
  Stream<dynamic> get callRejectedStream => _callRejectedController.stream;
  Stream<dynamic> get iceCandidateStream => _iceCandidateController.stream;
  Stream<dynamic> get userJoinedCallStream => _userJoinedCallController.stream;
  Stream<dynamic> get userLeftCallStream => _userLeftCallController.stream;
  Stream<dynamic> get groupCallStatusStream => _groupCallStatusController.stream;
  Stream<dynamic> get callEndedStream => _callEndedController.stream;

  void connect(String token, {String? myUserId}) {
    if (_socket != null && _socket!.connected) return;

    final targetUrl = AppConfig.socketUrl;
    _socket = IO.io(
      targetUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setTimeout(10000)
          .setAuth({'token': token, 'auth_token': token, 'access_token': token})
          .setQuery({'token': token, 'auth_token': token, 'access_token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionStateController.add(true);
      if (myUserId != null && myUserId.isNotEmpty) {
        _onlineUserIds.add(myUserId);
        _onlineUsersController.add(_onlineUserIds);
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
      _connectionStateController.add(false);
    });

    // Presence Listeners
    _socket!.on('online_users', (data) => _handleOnlineUsers(data));
    _socket!.on('server_user_connected', (data) => _handleOnlineUsers(data));
    _socket!.on('user_online', (data) => _handleUserOnline(data));
    _socket!.on('user_offline', (data) => _handleUserOffline(data));

    // Chat Listeners
    _socket!.on('new_message', (data) => _newMessageController.add(data));
    _socket!.on('new_message_notification', (data) => _newMessageController.add(data));
    _socket!.on('message_edited', (data) => _messageEditedController.add(data));
    _socket!.on('message_deleted', (data) => _messageDeletedController.add(data));
    _socket!.on('message_read', (data) => _messageReadController.add(data));
    _socket!.on('typing', (data) => _typingController.add(data));
    _socket!.on('room_created', (data) => _roomUpdatedController.add(data));
    _socket!.on('room_updated', (data) => _roomUpdatedController.add(data));
    _socket!.on('member_joined', (data) => _roomUpdatedController.add(data));
    _socket!.on('member_left', (data) => _roomUpdatedController.add(data));
    _socket!.on('room_deleted', (data) => _roomUpdatedController.add(data));

    // Call Listeners
    _socket!.on('incoming_call', (data) => _incomingCallController.add(data));
    _socket!.on('call_incoming', (data) => _incomingCallController.add(data));
    _socket!.on('call_user', (data) => _incomingCallController.add(data));
    _socket!.on('call:incoming', (data) => _incomingCallController.add(data));
    _socket!.on('call_offer', (data) => _callOfferController.add(data));
    _socket!.on('call:offer', (data) => _callOfferController.add(data));
    _socket!.on('offer', (data) => _callOfferController.add(data));
    _socket!.on('call_answered', (data) => _callAnsweredController.add(data));
    _socket!.on('call:answered', (data) => _callAnsweredController.add(data));
    _socket!.on('call_answer', (data) => _callAnsweredController.add(data));
    _socket!.on('answer_call', (data) => _callAnsweredController.add(data));
    _socket!.on('call_accepted', (data) => _callAnsweredController.add(data));
    _socket!.on('call_rejected', (data) => _callRejectedController.add(data));
    _socket!.on('call:rejected', (data) => _callRejectedController.add(data));
    _socket!.on('ice_candidate', (data) => _iceCandidateController.add(data));
    _socket!.on('call:ice_candidate', (data) => _iceCandidateController.add(data));
    _socket!.on('ice-candidate', (data) => _iceCandidateController.add(data));
    _socket!.on('candidate', (data) => _iceCandidateController.add(data));
    _socket!.on('user_joined_call', (data) => _userJoinedCallController.add(data));
    _socket!.on('user_left_call', (data) => _userLeftCallController.add(data));
    _socket!.on('group_call_status', (data) => _groupCallStatusController.add(data));
    _socket!.on('call_ended', (data) => _callEndedController.add(data));
    _socket!.on('call:ended', (data) => _callEndedController.add(data));
  }

  void _handleOnlineUsers(dynamic data) {
    if (data is List) {
      for (final id in data) {
        if (id != null) _onlineUserIds.add(id.toString());
      }
    } else if (data is Map && data['online_users'] is List) {
      for (final id in (data['online_users'] as List)) {
        if (id != null) _onlineUserIds.add(id.toString());
      }
    }
    _onlineUsersController.add(_onlineUserIds);
  }

  void _handleUserOnline(dynamic data) {
    String? uid;
    if (data is String) {
      uid = data;
    } else if (data is Map) {
      uid = data['user_id']?.toString() ?? data['userId']?.toString() ?? data['id']?.toString();
    }
    if (uid != null && uid.isNotEmpty) {
      _onlineUserIds.add(uid);
      _onlineUsersController.add(_onlineUserIds);
    }
  }

  void _handleUserOffline(dynamic data) {
    String? uid;
    if (data is String) {
      uid = data;
    } else if (data is Map) {
      uid = data['user_id']?.toString() ?? data['userId']?.toString() ?? data['id']?.toString();
    }
    if (uid != null && uid.isNotEmpty) {
      _onlineUserIds.remove(uid);
      _onlineUsersController.add(_onlineUserIds);
    }
  }

  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'room_id': roomId});
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leave_room', {'room_id': roomId});
  }

  void sendTyping(String roomId, bool isTyping) {
    _socket?.emit('typing', {'room_id': roomId, 'is_typing': isTyping});
  }

  void emitCallUser(Map<String, dynamic> payload) {
    _socket?.emit('call_user', payload);
    _socket?.emit('call:incoming', payload);
    _socket?.emit('incoming_call', payload);
    _socket?.emit('call_offer', payload);
    _socket?.emit('call:offer', payload);
    _socket?.emit('offer', payload);
  }

  void emitAnswerCall(Map<String, dynamic> payload) {
    _socket?.emit('answer_call', payload);
    _socket?.emit('call_answered', payload);
    _socket?.emit('call:answered', payload);
    _socket?.emit('call_answer', payload);
    _socket?.emit('accept_call', payload);
    _socket?.emit('call_accepted', payload);
  }

  void emitRejectCall(Map<String, dynamic> payload) {
    _socket?.emit('reject_call', payload);
    _socket?.emit('call_rejected', payload);
    _socket?.emit('call:rejected', payload);
  }

  void emitEndCall(Map<String, dynamic> payload) {
    _socket?.emit('end_call', payload);
    _socket?.emit('call_ended', payload);
    _socket?.emit('call:ended', payload);
  }

  void emitIceCandidate(Map<String, dynamic> payload) {
    _socket?.emit('ice_candidate', payload);
    _socket?.emit('call:ice_candidate', payload);
    _socket?.emit('ice-candidate', payload);
    _socket?.emit('candidate', payload);
    _socket?.emit('call:candidate', payload);
  }

  void emitJoinCall(Map<String, dynamic> payload) {
    _socket?.emit('join_call', payload);
    _socket?.emit('call:join', payload);
  }

  void emitLeaveCall(String roomId) {
    _socket?.emit('leave_call', {'room_id': roomId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _onlineUserIds.clear();
    _connectionStateController.add(false);
  }
}
