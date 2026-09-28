class FileAttachment {
  final String? id;
  final String fileUrl;
  final String fileName;
  final int? fileSize;
  final String? fileType;

  FileAttachment({
    this.id,
    required this.fileUrl,
    required this.fileName,
    this.fileSize,
    this.fileType,
  });

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      id: json['id']?.toString(),
      fileUrl: json['file_url']?.toString() ?? json['fileUrl']?.toString() ?? json['url']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? json['fileName']?.toString() ?? json['name']?.toString() ?? 'Attachment',
      fileSize: json['file_size'] is int ? json['file_size'] : int.tryParse(json['file_size']?.toString() ?? '0'),
      fileType: json['file_type']?.toString() ?? json['fileType']?.toString() ?? json['mime_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': fileType,
    };
  }
}

class SenderInfo {
  final String id;
  final String name;
  final String? email;
  final String? avatar;

  SenderInfo({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
  });

  factory SenderInfo.fromJson(Map<String, dynamic> json) {
    return SenderInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown User',
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}

class MessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String message;
  final bool isRead;
  final bool isDeleted;
  final bool isEdited;
  final bool isImage;
  final bool isAudio;
  final bool isVideo;
  final bool isAudioCall;
  final bool isVideoCall;
  final bool isCallActive;
  final String? replayMessageId;
  final MessageModel? replayMessage;
  final List<FileAttachment> files;
  final SenderInfo? sender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.message,
    this.isRead = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.isImage = false,
    this.isAudio = false,
    this.isVideo = false,
    this.isAudioCall = false,
    this.isVideoCall = false,
    this.isCallActive = false,
    this.replayMessageId,
    this.replayMessage,
    this.files = const [],
    this.sender,
    this.createdAt,
    this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    List<FileAttachment> parsedFiles = [];
    if (json['files'] != null && json['files'] is List) {
      parsedFiles = (json['files'] as List)
          .map((f) => f is Map
              ? FileAttachment.fromJson(Map<String, dynamic>.from(f))
              : null)
          .whereType<FileAttachment>()
          .toList();
    }

    SenderInfo? parsedSender;
    if (json['sender'] != null && json['sender'] is Map) {
      parsedSender = SenderInfo.fromJson(Map<String, dynamic>.from(json['sender'] as Map));
    }

    MessageModel? parsedReplay;
    if (json['replay_message'] != null && json['replay_message'] is Map) {
      parsedReplay = MessageModel.fromJson(Map<String, dynamic>.from(json['replay_message'] as Map));
    }

    return MessageModel(
      id: json['id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? json['roomId']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true || json['isRead'] == true,
      isDeleted: json['is_deleted'] == true || json['isDeleted'] == true,
      isEdited: json['is_edited'] == true || json['isEdited'] == true,
      isImage: json['is_image'] == true || json['isImage'] == true,
      isAudio: json['is_audio'] == true || json['isAudio'] == true,
      isVideo: json['is_video'] == true || json['isVideo'] == true,
      isAudioCall: json['is_audio_call'] == true || json['isAudioCall'] == true,
      isVideoCall: json['is_video_call'] == true || json['isVideoCall'] == true,
      isCallActive: json['is_call_active'] == true || json['isCallActive'] == true,
      replayMessageId: json['replay_message_id']?.toString() ?? json['replayMessageId']?.toString(),
      replayMessage: parsedReplay,
      files: parsedFiles,
      sender: parsedSender,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'message': message,
      'is_read': isRead,
      'is_deleted': isDeleted,
      'is_edited': isEdited,
      'is_image': isImage,
      'is_audio': isAudio,
      'isVideo': isVideo,
      'is_audio_call': isAudioCall,
      'is_video_call': isVideoCall,
      'is_call_active': isCallActive,
      'replay_message_id': replayMessageId,
      'files': files.map((f) => f.toJson()).toList(),
      if (sender != null) 'sender': sender!.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? message,
    bool? isRead,
    bool? isDeleted,
    bool? isEdited,
    bool? isImage,
    bool? isAudio,
    bool? isVideo,
    bool? isAudioCall,
    bool? isVideoCall,
    bool? isCallActive,
    String? replayMessageId,
    MessageModel? replayMessage,
    List<FileAttachment>? files,
    SenderInfo? sender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      isImage: isImage ?? this.isImage,
      isAudio: isAudio ?? this.isAudio,
      isVideo: isVideo ?? this.isVideo,
      isAudioCall: isAudioCall ?? this.isAudioCall,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      isCallActive: isCallActive ?? this.isCallActive,
      replayMessageId: replayMessageId ?? this.replayMessageId,
      replayMessage: replayMessage ?? this.replayMessage,
      files: files ?? this.files,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
