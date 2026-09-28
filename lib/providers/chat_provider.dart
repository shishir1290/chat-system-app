import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/room_model.dart';
import '../services/chat_service.dart';
import '../services/message_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final MessageService _messageService = MessageService();
  final SocketService _socketService = SocketService();

  List<ChatRoomModel> _rooms = [];
  ChatRoomModel? _activeRoom;
  final Map<String, List<MessageModel>> _roomMessages = {};
  final Map<String, Set<String>> _typingUsers = {};

  bool _isLoadingRooms = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _currentUserId;

  // Stream subscriptions
  StreamSubscription? _newMsgSub;
  StreamSubscription? _editMsgSub;
  StreamSubscription? _deleteMsgSub;
  StreamSubscription? _readMsgSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _roomUpdateSub;

  List<ChatRoomModel> get rooms => _rooms;
  ChatRoomModel? get activeRoom => _activeRoom;
  List<MessageModel> get activeMessages =>
      _activeRoom != null ? (_roomMessages[_activeRoom!.id] ?? []) : [];
  bool get isLoadingRooms => _isLoadingRooms;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;

  Set<String> getActiveTypingUsers() {
    if (_activeRoom == null) return {};
    final set = _typingUsers[_activeRoom!.id] ?? {};
    if (_currentUserId != null) {
      return set.where((id) => id != _currentUserId).toSet();
    }
    return set;
  }

  void initializeWithUser(String userId) {
    _currentUserId = userId;
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _newMsgSub?.cancel();
    _editMsgSub?.cancel();
    _deleteMsgSub?.cancel();
    _readMsgSub?.cancel();
    _typingSub?.cancel();
    _roomUpdateSub?.cancel();

    _newMsgSub = _socketService.newMessageStream.listen(_handleIncomingMessage);
    _editMsgSub = _socketService.messageEditedStream.listen(_handleEditedMessage);
    _deleteMsgSub = _socketService.messageDeletedStream.listen(_handleDeletedMessage);
    _readMsgSub = _socketService.messageReadStream.listen(_handleReadMessage);
    _typingSub = _socketService.typingStream.listen(_handleTypingEvent);
    _roomUpdateSub = _socketService.roomUpdatedStream.listen((_) => loadRooms(silent: true));
  }

  void _handleIncomingMessage(dynamic data) {
    if (data == null) return;
    try {
      final rawMap = data is Map ? (data['message'] ?? data['data'] ?? data) : null;
      if (rawMap is Map) {
        final msgMap = Map<String, dynamic>.from(rawMap);
        final message = MessageModel.fromJson(msgMap);
        final roomId = message.roomId.isNotEmpty ? message.roomId : (_activeRoom?.id ?? '');

        if (roomId.isNotEmpty) {
          // Insert into room messages if loaded
          if (!_roomMessages.containsKey(roomId)) {
            _roomMessages[roomId] = [];
          }

          final list = _roomMessages[roomId]!;
          final existingIdx = list.indexWhere((m) => m.id == message.id);
          if (existingIdx != -1) {
            list[existingIdx] = message;
          } else {
            list.add(message);
          }
        }

        // Update last message in room list
        final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
        if (roomIndex != -1) {
          final room = _rooms[roomIndex];
          int unread = room.unreadCount;
          if (_activeRoom?.id != roomId && message.senderId != _currentUserId) {
            unread += 1;
          }
          _rooms[roomIndex] = room.copyWith(
            lastMessage: message,
            unreadCount: unread,
            updatedAt: DateTime.now(),
          );
          // Re-sort rooms to put latest on top
          _sortRooms();
        } else {
          // If room not in list, fetch rooms
          loadRooms(silent: true);
        }

        // Auto mark as read if this is the active room and message is from someone else
        if (_activeRoom?.id == roomId && message.senderId != _currentUserId) {
          markRoomAsRead(roomId);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling incoming socket message: $e');
    }
  }

  void _handleEditedMessage(dynamic data) {
    if (data == null) return;
    try {
      final rawMap = data is Map ? (data['message'] ?? data['data'] ?? data) : null;
      if (rawMap is Map) {
        final msgMap = Map<String, dynamic>.from(rawMap);
        final message = MessageModel.fromJson(msgMap);
        final roomId = message.roomId.isNotEmpty ? message.roomId : (_activeRoom?.id ?? '');

        // Update in room messages if cached
        final targetRoomIds = [
          if (message.roomId.isNotEmpty) message.roomId,
          if (_activeRoom != null && _activeRoom!.id.isNotEmpty) _activeRoom!.id,
        ];

        bool updatedInList = false;
        for (final rId in targetRoomIds) {
          final list = _roomMessages[rId];
          if (list != null) {
            final idx = list.indexWhere((m) => m.id == message.id);
            if (idx != -1) {
              list[idx] = message;
              updatedInList = true;
            }
          }
        }

        // Update last message in room sidebar if matched
        final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
        if (roomIndex != -1) {
          final room = _rooms[roomIndex];
          if (room.lastMessage?.id == message.id) {
            _rooms[roomIndex] = room.copyWith(
              lastMessage: message,
              updatedAt: DateTime.now(),
            );
          }
        }

        if (updatedInList || roomIndex != -1) {
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error handling edited message: $e');
    }
  }

  void _handleDeletedMessage(dynamic data) {
    if (data == null) return;
    try {
      final roomId = data['room_id']?.toString() ?? data['roomId']?.toString();
      final msgId = data['message_id']?.toString() ?? data['messageId']?.toString() ?? data['id']?.toString();

      if (roomId != null && msgId != null) {
        final list = _roomMessages[roomId];
        if (list != null) {
          list.removeWhere((m) => m.id == msgId);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error handling deleted message: $e');
    }
  }

  void _handleReadMessage(dynamic data) {
    if (data == null) return;
    try {
      final roomId = data['room_id']?.toString() ?? data['roomId']?.toString();
      final readerId = data['reader_id']?.toString() ?? data['readerId']?.toString();
      final rawMsgIds = data['message_ids'] ?? data['messageIds'];
      final List<String> msgIds = [];
      if (rawMsgIds is List) {
        for (final id in rawMsgIds) {
          if (id != null) msgIds.add(id.toString());
        }
      }

      if (roomId != null && roomId.isNotEmpty) {
        // 1. Update cached messages in room
        final list = _roomMessages[roomId];
        if (list != null) {
          for (int i = 0; i < list.length; i++) {
            if (msgIds.isEmpty || msgIds.contains(list[i].id)) {
              list[i] = list[i].copyWith(isRead: true);
            }
          }
        }

        // 2. Update room in sidebar
        final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
        if (roomIndex != -1) {
          final room = _rooms[roomIndex];
          var updatedLastMsg = room.lastMessage;
          if (updatedLastMsg != null && (msgIds.isEmpty || msgIds.contains(updatedLastMsg.id))) {
            updatedLastMsg = updatedLastMsg.copyWith(isRead: true);
          }
          final newUnread = (readerId != null && readerId == _currentUserId) ? 0 : room.unreadCount;
          _rooms[roomIndex] = room.copyWith(
            lastMessage: updatedLastMsg,
            unreadCount: newUnread,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling read receipts: $e');
    }
  }

  void _handleTypingEvent(dynamic data) {
    if (data == null) return;
    try {
      final roomId = data['room_id']?.toString() ?? data['roomId']?.toString();
      final userId = data['user_id']?.toString() ?? data['userId']?.toString();
      final isTyping = data['is_typing'] == true || data['isTyping'] == true;

      if (roomId != null && userId != null && userId != _currentUserId) {
        if (!_typingUsers.containsKey(roomId)) {
          _typingUsers[roomId] = {};
        }
        if (isTyping) {
          _typingUsers[roomId]!.add(userId);
        } else {
          _typingUsers[roomId]!.remove(userId);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling typing event: $e');
    }
  }

  Future<void> loadRooms({bool silent = false}) async {
    if (!silent) {
      _isLoadingRooms = true;
      notifyListeners();
    }

    try {
      final fetched = await _chatService.getRooms();
      _rooms = fetched;
      _sortRooms();
    } catch (e) {
      debugPrint('Error loading rooms: $e');
    } finally {
      if (!silent) {
        _isLoadingRooms = false;
        notifyListeners();
      }
    }
  }

  void _sortRooms() {
    _rooms.sort((a, b) {
      final aDate = a.lastMessage?.createdAt ?? a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.lastMessage?.createdAt ?? b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

  Future<void> selectRoom(ChatRoomModel? room) async {
    if (_activeRoom != null) {
      _socketService.leaveRoom(_activeRoom!.id);
    }

    _activeRoom = room;
    notifyListeners();

    if (room != null) {
      _socketService.joinRoom(room.id);
      await loadRoomMessages(room.id);
      await markRoomAsRead(room.id);
    }
  }

  Future<void> loadRoomMessages(String roomId, {bool refresh = false}) async {
    if (_roomMessages.containsKey(roomId) && !refresh && _roomMessages[roomId]!.isNotEmpty) {
      return;
    }

    _isLoadingMessages = true;
    notifyListeners();

    try {
      final messages = await _messageService.getRoomMessages(roomId, limit: 100);
      // Backend might return oldest first or newest first; sort by createdAt ascending for chat thread
      messages.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

      _roomMessages[roomId] = messages;
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> markRoomAsRead(String roomId) async {
    try {
      _socketService.emitMarkRead(roomId);
      await _messageService.markAsRead(roomId, []);
      final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
      if (roomIndex != -1) {
        _rooms[roomIndex] = _rooms[roomIndex].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> sendMessage({
    required String text,
    String? replyMessageId,
    List<File>? files,
  }) async {
    if (_activeRoom == null) return false;
    if (text.trim().isEmpty && (files == null || files.isEmpty)) return false;

    _isSending = true;
    notifyListeners();

    try {
      final newMsg = await _messageService.sendMessage(
        _activeRoom!.id,
        text.trim(),
        replayMessageId: replyMessageId,
        files: files,
      );

      final list = _roomMessages[_activeRoom!.id] ?? [];
      if (!list.any((m) => m.id == newMsg.id)) {
        list.add(newMsg);
        _roomMessages[_activeRoom!.id] = list;
      }

      // Update room in sidebar
      final roomIndex = _rooms.indexWhere((r) => r.id == _activeRoom!.id);
      if (roomIndex != -1) {
        _rooms[roomIndex] = _rooms[roomIndex].copyWith(
          lastMessage: newMsg,
          updatedAt: DateTime.now(),
        );
        _sortRooms();
      }

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> editMessage(String messageId, String newText) async {
    try {
      final edited = await _messageService.editMessage(messageId, newText);
      if (_activeRoom != null) {
        final list = _roomMessages[_activeRoom!.id];
        if (list != null) {
          final idx = list.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            list[idx] = edited;
            notifyListeners();
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error editing message: $e');
      return false;
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId);
      if (_activeRoom != null) {
        final list = _roomMessages[_activeRoom!.id];
        if (list != null) {
          list.removeWhere((m) => m.id == messageId);
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  Future<bool> reactToMessage(String messageId, String emoji) async {
    try {
      if (_activeRoom != null) {
        _socketService.emitReactMessage(messageId, _activeRoom!.id, emoji);
      }
      final updated = await _messageService.reactToMessage(messageId, emoji);
      if (_activeRoom != null) {
        final list = _roomMessages[_activeRoom!.id];
        if (list != null) {
          final idx = list.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            list[idx] = updated;
            notifyListeners();
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error reacting to message: $e');
      return false;
    }
  }

  void sendTyping(bool isTyping) {
    if (_activeRoom != null) {
      _socketService.sendTyping(_activeRoom!.id, isTyping);
    }
  }

  Future<ChatRoomModel?> createPeerChat(String recipientId) async {
    try {
      final room = await _chatService.createOrGetPeerRoom(recipientId);
      final idx = _rooms.indexWhere((r) => r.id == room.id);
      if (idx == -1) {
        _rooms.insert(0, room);
      } else {
        _rooms[idx] = room;
      }
      notifyListeners();
      return room;
    } catch (e) {
      debugPrint('Error creating peer room: $e');
      return null;
    }
  }

  Future<ChatRoomModel?> createGroupChat(String name, List<String> memberIds) async {
    try {
      final room = await _chatService.createGroupRoom(name, memberIds);
      _rooms.insert(0, room);
      notifyListeners();
      return room;
    } catch (e) {
      debugPrint('Error creating group room: $e');
      return null;
    }
  }

  Future<bool> addMembersToGroup(String roomId, List<String> memberIds) async {
    try {
      final updated = await _chatService.addMembers(roomId, memberIds);
      final idx = _rooms.indexWhere((r) => r.id == roomId);
      if (idx != -1) {
        _rooms[idx] = updated;
      }
      if (_activeRoom?.id == roomId) {
        _activeRoom = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding members: $e');
      return false;
    }
  }

  Future<bool> removeMemberFromGroup(String roomId, String memberId) async {
    try {
      await _chatService.removeMember(roomId, memberId);
      await loadRooms(silent: true);
      if (_activeRoom?.id == roomId) {
        final updated = await _chatService.getRoomById(roomId);
        _activeRoom = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing member: $e');
      return false;
    }
  }

  Future<bool> updateGroupInfo(String roomId, {String? name, File? avatarFile}) async {
    try {
      if (avatarFile != null) {
        await _chatService.uploadGroupAvatar(roomId, avatarFile);
      }
      if (name != null) {
        await _chatService.updateGroupRoom(roomId, name: name);
      }
      final fresh = await _chatService.getRoomById(roomId);
      final idx = _rooms.indexWhere((r) => r.id == roomId);
      if (idx != -1) _rooms[idx] = fresh;
      if (_activeRoom?.id == roomId) _activeRoom = fresh;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating group info: $e');
      return false;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _chatService.deleteRoom(roomId);
      _rooms.removeWhere((r) => r.id == roomId);
      if (_activeRoom?.id == roomId) {
        _activeRoom = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting room: $e');
    }
  }

  @override
  void dispose() {
    _newMsgSub?.cancel();
    _editMsgSub?.cancel();
    _deleteMsgSub?.cancel();
    _readMsgSub?.cancel();
    _typingSub?.cancel();
    _roomUpdateSub?.cancel();
    super.dispose();
  }
}
