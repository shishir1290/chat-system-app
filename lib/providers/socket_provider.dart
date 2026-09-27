import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';

class SocketProvider extends ChangeNotifier {
  final SocketService _socketService = SocketService();

  bool _isConnected = false;
  Set<String> _onlineUserIds = {};
  StreamSubscription? _onlineSub;
  StreamSubscription? _connSub;

  bool get isConnected => _isConnected;
  Set<String> get onlineUserIds => _onlineUserIds;
  SocketService get socketService => _socketService;

  SocketProvider() {
    _connSub = _socketService.connectionStateStream.listen((state) {
      _isConnected = state;
      notifyListeners();
    });

    _onlineSub = _socketService.onlineUsersStream.listen((users) {
      _onlineUserIds = Set.from(users);
      notifyListeners();
    });
  }

  void connect(String token, String myUserId) {
    _socketService.connect(token, myUserId: myUserId);
  }

  void disconnect() {
    _socketService.disconnect();
    _isConnected = false;
    _onlineUserIds.clear();
    notifyListeners();
  }

  bool isUserOnline(String userId) {
    return _onlineUserIds.contains(userId);
  }

  @override
  void dispose() {
    _onlineSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}
