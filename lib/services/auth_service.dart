import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post(
      '/api/v1/users/login',
      data: {'email': email, 'password': password},
    );

    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      final data = resData['data'];
      final user = UserModel.fromJson(data['user'] ?? {});
      final token = data['access_token']?.toString() ?? '';
      if (token.isNotEmpty) {
        await _api.saveToken(token);
      }
      return {'user': user, 'token': token, 'refreshToken': data['refresh_token']};
    }
    throw Exception(resData['message'] ?? 'Login failed');
  }

  Future<UserModel> register(String name, String email, String password, {String? phone}) async {
    final response = await _api.post(
      '/api/v1/users/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return UserModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Registration failed');
  }

  Future<bool> verifyEmail(String token) async {
    final response = await _api.post(
      '/api/v1/users/verify-email',
      data: {'token': token},
    );
    return response.data['status'] == true;
  }

  Future<bool> resendVerification(String email) async {
    final response = await _api.post(
      '/api/v1/users/resend-verification',
      data: {'email': email},
    );
    return response.data['status'] == true;
  }

  Future<UserModel> getMe() async {
    final response = await _api.get('/api/v1/users/me');
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return UserModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to get profile');
  }

  Future<UserModel> updateProfile(String id, {String? name, String? email}) async {
    final response = await _api.put(
      '/api/v1/users/update/$id',
      data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      },
    );
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return UserModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to update profile');
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final response = await _api.post(
      '/api/v1/users/change-password',
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
    if (response.data['status'] != true) {
      throw Exception(response.data['message'] ?? 'Password change failed');
    }
  }

  Future<UserModel> uploadAvatar(File file) async {
    final fileName = file.path.split('/').last.split('\\').last;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _api.post(
      '/api/v1/users/avatar',
      data: formData,
    );

    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      return UserModel.fromJson(resData['data']);
    }
    throw Exception(resData['message'] ?? 'Failed to upload avatar');
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _api.get(
      '/api/v1/users/list',
      queryParameters: {'search': query, 'limit': 30},
    );
    final resData = response.data;
    if (resData['status'] == true && resData['data'] != null) {
      final data = resData['data'];
      final List items = data is Map ? (data['data'] ?? []) : (data is List ? data : []);
      return items.map((u) => UserModel.fromJson(u as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> blockUser(String targetUserId) async {
    await _api.post('/api/v1/users/block/$targetUserId');
  }

  Future<void> unblockUser(String targetUserId) async {
    await _api.post('/api/v1/users/unblock/$targetUserId');
  }
}
