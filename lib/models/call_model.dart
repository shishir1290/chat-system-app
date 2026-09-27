import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallStatus {
  idle,
  calling,
  incoming,
  connected,
  ended,
}

enum CallType {
  audio,
  video,
}

class IncomingCallData {
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String roomId;
  final String roomName;
  final String? roomAvatar;
  final bool isGroup;
  final bool isVideo;
  final dynamic offer;

  IncomingCallData({
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.roomId,
    required this.roomName,
    this.roomAvatar,
    this.isGroup = false,
    this.isVideo = true,
    this.offer,
  });

  factory IncomingCallData.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map)
        ? Map<String, dynamic>.from(rawJson['data'])
        : (rawJson['payload'] is Map)
            ? Map<String, dynamic>.from(rawJson['payload'])
            : rawJson;

    final isVid = json['is_video'] == true ||
        json['isVideo'] == true ||
        rawJson['is_video'] == true ||
        rawJson['isVideo'] == true ||
        json['call_type'] == 'video' ||
        json['type'] == 'video' ||
        (json['offer'] != null && json['type'] != 'audio' && json['call_type'] != 'audio');

    dynamic offer = json['offer'] ?? json['signal'] ?? json['signalData'] ?? json['sdp'] ?? rawJson['offer'] ?? rawJson['signal'];
    if (offer is String && offer.trim().startsWith('{')) {
      try {
        offer = jsonDecode(offer);
      } catch (_) {}
    }

    return IncomingCallData(
      callerId: json['caller_id']?.toString() ??
          json['callerId']?.toString() ??
          json['from_id']?.toString() ??
          json['from_user_id']?.toString() ??
          json['fromId']?.toString() ??
          json['from']?.toString() ??
          json['sender_id']?.toString() ??
          json['senderId']?.toString() ??
          json['userId']?.toString() ??
          json['user_id']?.toString() ??
          json['id']?.toString() ??
          rawJson['caller_id']?.toString() ??
          rawJson['from_id']?.toString() ??
          rawJson['from']?.toString() ??
          rawJson['sender_id']?.toString() ??
          rawJson['user_id']?.toString() ??
          '',
      callerName: json['caller_name']?.toString() ??
          json['callerName']?.toString() ??
          json['from_user_name']?.toString() ??
          json['name']?.toString() ??
          json['userName']?.toString() ??
          rawJson['caller_name']?.toString() ??
          'Incoming Call',
      callerAvatar: json['caller_avatar']?.toString() ??
          json['callerAvatar']?.toString() ??
          json['avatar']?.toString() ??
          rawJson['caller_avatar']?.toString(),
      roomId: json['room_id']?.toString() ??
          json['roomId']?.toString() ??
          json['room']?.toString() ??
          rawJson['room_id']?.toString() ??
          rawJson['roomId']?.toString() ??
          '',
      roomName: json['room_name']?.toString() ??
          json['roomName']?.toString() ??
          rawJson['room_name']?.toString() ??
          'Chat Call',
      roomAvatar: json['room_avatar']?.toString() ??
          json['roomAvatar']?.toString() ??
          rawJson['room_avatar']?.toString(),
      isGroup: json['is_group'] == true || json['isGroup'] == true || rawJson['is_group'] == true,
      isVideo: isVid,
      offer: offer,
    );
  }
}

class CallParticipant {
  final String userId;
  final String name;
  final String? avatar;
  final MediaStream? stream;
  final RTCVideoRenderer renderer;
  bool isAudioMuted;
  bool isVideoOff;

  CallParticipant({
    required this.userId,
    required this.name,
    this.avatar,
    this.stream,
    required this.renderer,
    this.isAudioMuted = false,
    this.isVideoOff = false,
  });
}
