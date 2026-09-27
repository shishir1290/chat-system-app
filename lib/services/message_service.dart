import 'dart:io';
import 'package:dio/dio.dart';
import '../models/message_model.dart';
import 'api_service.dart';

class MessageService {
  final ApiService _api = ApiService();

  Future<List<MessageModel>> getRoomMessages(String roomId, {int page = 1, int limit = 50}) async {
    final response = await _api.get(
      '/api/v1/chat/messages/rooms/$roomId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      final data = resData['data'];
      final List list = data is Map ? (data['data'] ?? data['messages'] ?? []) : (data is List ? data : []);
      return list.map((m) => MessageModel.fromJson(m as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<MessageModel> sendMessage(
    String roomId,
    String text, {
    String? replayMessageId,
    List<File>? files,
    bool? isAudioCall,
    bool? isVideoCall,
    bool? isCallActive,
  }) async {
    if (files != null && files.isNotEmpty) {
      final List<MultipartFile> attachments = [];
      for (final file in files) {
        final fileName = file.path.split('/').last.split('\\').last;
        attachments.add(await MultipartFile.fromFile(file.path, filename: fileName));
      }

      final formData = FormData.fromMap({
        'message': text,
        if (replayMessageId != null) 'replay_message_id': replayMessageId,
        if (isAudioCall == true) 'is_audio_call': 'true',
        if (isVideoCall == true) 'is_video_call': 'true',
        if (isCallActive != null) 'is_call_active': isCallActive.toString(),
        'attachments': attachments,
      });

      final response = await _api.post(
        '/api/v1/chat/messages/rooms/$roomId/messages',
        data: formData,
      );

      final resData = response.data;
      if (resData['status'] == true && resData['data'] != null) {
        return MessageModel.fromJson(resData['data']);
      }
      throw Exception(resData['message'] ?? 'Failed to send message');
    }

    final response = await _api.post(
      '/api/v1/chat/messages/rooms/$roomId/messages',
      data: {
        'message': text,
        if (replayMessageId != null) 'replay_message_id': replayMessageId,
        if (isAudioCall != null) 'is_audio_call': isAudioCall,
        if (isVideoCall != null) 'is_video_call': isVideoCall,
        if (isCallActive != null) 'is_call_active': isCallActive,
      },
    );

    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return MessageModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to send message');
  }

  Future<MessageModel> editMessage(String messageId, String newMessage, {bool? isCallActive}) async {
    final response = await _api.put(
      '/api/v1/chat/messages/messages/$messageId',
      data: {
        'message': newMessage,
        if (isCallActive != null) 'is_call_active': isCallActive,
      },
    );
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return MessageModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to edit message');
  }

  Future<void> markAsRead(String roomId, List<String> messageIds) async {
    await _api.post(
      '/api/v1/chat/messages/rooms/$roomId/read',
      data: {'message_ids': messageIds},
    );
  }

  Future<void> deleteMessage(String messageId) async {
    await _api.delete('/api/v1/chat/messages/messages/$messageId');
  }
}
