import 'dart:io';
import 'package:dio/dio.dart';
import '../models/room_model.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  Future<List<ChatRoomModel>> getRooms() async {
    final response = await _api.get('/api/v1/chat/rooms/list');
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      final List list = resData['data'] is List ? resData['data'] : [];
      return list.map((r) => ChatRoomModel.fromJson(r as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ChatRoomModel> createOrGetPeerRoom(String recipientId) async {
    final response = await _api.post(
      '/api/v1/chat/rooms/peer',
      data: {'recipient_id': recipientId},
    );
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return ChatRoomModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to open direct chat');
  }

  Future<ChatRoomModel> createGroupRoom(String name, List<String> memberIds) async {
    final response = await _api.post(
      '/api/v1/chat/rooms/group',
      data: {
        'name': name,
        'member_ids': memberIds,
      },
    );
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return ChatRoomModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to create group');
  }

  Future<ChatRoomModel> getRoomById(String roomId) async {
    final response = await _api.get('/api/v1/chat/rooms/single/$roomId');
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return ChatRoomModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to load room');
  }

  Future<ChatRoomModel> addMembers(String roomId, List<String> memberIds) async {
    final response = await _api.post(
      '/api/v1/chat/rooms/add-members/$roomId',
      data: {'member_ids': memberIds},
    );
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return ChatRoomModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to add members');
  }

  Future<void> removeMember(String roomId, String memberId) async {
    await _api.delete('/api/v1/chat/rooms/remove-member/$roomId/$memberId');
  }

  Future<ChatRoomModel> uploadGroupAvatar(String roomId, File file) async {
    final fileName = file.path.split('/').last.split('\\').last;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _api.post(
      '/api/v1/chat/rooms/avatar/$roomId',
      data: formData,
    );
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return ChatRoomModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to upload group avatar');
  }

  Future<ChatRoomModel> updateGroupRoom(String roomId, {String? name, String? avatar}) async {
    final response = await _api.put(
      '/api/v1/chat/rooms/update/$roomId',
      data: {
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
      },
    );
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return ChatRoomModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to update group');
  }

  Future<void> deleteRoom(String roomId) async {
    await _api.delete('/api/v1/chat/rooms/delete/$roomId');
  }

  Future<ChatRoomModel> setMemberAdmin(String roomId, String memberId, bool isAdmin) async {
    final response = await _api.post(
      '/api/v1/chat/rooms/admin/$roomId',
      data: {
        'member_id': memberId,
        'is_admin': isAdmin,
      },
    );
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return ChatRoomModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to update admin role');
  }
}
