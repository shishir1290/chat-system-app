import 'member_model.dart';
import 'message_model.dart';

class ChatRoomModel {
  final String id;
  final String name;
  final String? avatar;
  final bool isGroup;
  final String createdById;
  final int unreadCount;
  final List<MemberModel> members;
  final MessageModel? lastMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatRoomModel({
    required this.id,
    required this.name,
    this.avatar,
    this.isGroup = false,
    required this.createdById,
    this.unreadCount = 0,
    this.members = const [],
    this.lastMessage,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    List<MemberModel> parsedMembers = [];
    if (json['members'] != null && json['members'] is List) {
      parsedMembers = (json['members'] as List)
          .map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    MessageModel? parsedLastMsg;
    if (json['last_message'] != null && json['last_message'] is Map<String, dynamic>) {
      parsedLastMsg = MessageModel.fromJson(json['last_message']);
    } else if (json['lastMessage'] != null && json['lastMessage'] is Map<String, dynamic>) {
      parsedLastMsg = MessageModel.fromJson(json['lastMessage']);
    }

    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Conversation',
      avatar: json['avatar']?.toString(),
      isGroup: json['is_group'] == true || json['isGroup'] == true,
      createdById: json['created_by_id']?.toString() ?? json['createdById']?.toString() ?? '',
      unreadCount: json['unread_count'] is int
          ? json['unread_count']
          : int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      members: parsedMembers,
      lastMessage: parsedLastMsg,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'is_group': isGroup,
      'created_by_id': createdById,
      'unread_count': unreadCount,
      'members': members.map((m) => m.toJson()).toList(),
      if (lastMessage != null) 'last_message': lastMessage!.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ChatRoomModel copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isGroup,
    String? createdById,
    int? unreadCount,
    List<MemberModel>? members,
    MessageModel? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isGroup: isGroup ?? this.isGroup,
      createdById: createdById ?? this.createdById,
      unreadCount: unreadCount ?? this.unreadCount,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get display details for 1-to-1 rooms based on current user ID
  String getDisplayName(String currentUserId) {
    if (isGroup) return name;
    final otherMember = members.firstWhere(
      (m) => m.memberId != currentUserId,
      orElse: () => members.isNotEmpty ? members.first : MemberModel(id: '', roomId: id, memberId: '', name: name),
    );
    return otherMember.name.isNotEmpty ? otherMember.name : name;
  }

  String? getDisplayAvatar(String currentUserId) {
    if (isGroup) return avatar;
    final otherMember = members.firstWhere(
      (m) => m.memberId != currentUserId,
      orElse: () => members.isNotEmpty ? members.first : MemberModel(id: '', roomId: id, memberId: '', name: name),
    );
    return otherMember.avatar ?? avatar;
  }

  bool isOtherUserOnline(String currentUserId, Set<String> onlineUserIds) {
    if (isGroup) return false;
    final otherMember = members.firstWhere(
      (m) => m.memberId != currentUserId,
      orElse: () => MemberModel(id: '', roomId: id, memberId: '', name: name),
    );
    return onlineUserIds.contains(otherMember.memberId) || otherMember.isOnline;
  }
}
