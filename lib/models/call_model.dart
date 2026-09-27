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

  factory IncomingCallData.fromJson(Map<String, dynamic> json) {
    return IncomingCallData(
      callerId: json['caller_id']?.toString() ?? json['callerId']?.toString() ?? json['from_id']?.toString() ?? '',
      callerName: json['caller_name']?.toString() ?? json['callerName']?.toString() ?? 'Caller',
      callerAvatar: json['caller_avatar']?.toString() ?? json['callerAvatar']?.toString(),
      roomId: json['room_id']?.toString() ?? json['roomId']?.toString() ?? '',
      roomName: json['room_name']?.toString() ?? json['roomName']?.toString() ?? 'Chat Call',
      roomAvatar: json['room_avatar']?.toString() ?? json['roomAvatar']?.toString(),
      isGroup: json['is_group'] == true || json['isGroup'] == true,
      isVideo: json['is_video'] == true || json['isVideo'] == true,
      offer: json['offer'],
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
