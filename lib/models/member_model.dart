import 'user_model.dart';

class MemberModel {
  final String id;
  final String roomId;
  final String memberId;
  final bool isAdmin;
  final String name;
  final String? avatar;
  final String? email;
  final bool isOnline;
  final UserModel? user;

  MemberModel({
    required this.id,
    required this.roomId,
    required this.memberId,
    this.isAdmin = false,
    required this.name,
    this.avatar,
    this.email,
    this.isOnline = false,
    this.user,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    UserModel? parsedUser;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['user']);
    }

    return MemberModel(
      id: json['id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? json['roomId']?.toString() ?? '',
      memberId: json['member_id']?.toString() ?? json['memberId']?.toString() ?? json['id']?.toString() ?? '',
      isAdmin: json['is_admin'] == true || json['isAdmin'] == true,
      name: json['name']?.toString() ?? parsedUser?.name ?? 'Member',
      avatar: json['avatar']?.toString() ?? parsedUser?.avatar,
      email: json['email']?.toString() ?? parsedUser?.email,
      isOnline: json['is_online'] == true || json['isOnline'] == true || (parsedUser?.isOnline ?? false),
      user: parsedUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'member_id': memberId,
      'is_admin': isAdmin,
      'name': name,
      'avatar': avatar,
      'email': email,
      'is_online': isOnline,
      if (user != null) 'user': user!.toJson(),
    };
  }
}
