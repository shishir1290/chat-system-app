import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  UserModel? _user;
  String? _token;
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null && _token != null;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    try {
      final savedToken = await _apiService.loadSavedToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(StorageKeys.userProfile);
        if (userJson != null) {
          _user = UserModel.fromJson(jsonDecode(userJson));
        }
        // Fetch fresh profile in background
        try {
          final freshUser = await _authService.getMe();
          _user = freshUser;
          await prefs.setString(StorageKeys.userProfile, jsonEncode(freshUser.toJson()));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      _user = result['user'] as UserModel;
      _token = result['token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.userProfile, jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<UserModel?> register(String name, String email, String password, {String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = await _authService.register(name, email, password, phone: phone);
      _isLoading = false;
      notifyListeners();
      return newUser;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyEmail(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.verifyEmail(token);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerification(String email) async {
    try {
      return await _authService.resendVerification(email);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({String? name, String? email}) async {
    if (_user == null) return false;
    try {
      final updated = await _authService.updateProfile(_user!.id, name: name, email: email);
      _user = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.userProfile, jsonEncode(updated.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(File file) async {
    try {
      final updated = await _authService.uploadAvatar(file);
      _user = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.userProfile, jsonEncode(updated.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      await _authService.changePassword(oldPassword, newPassword);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = false;
    _user = null;
    _token = null;
    await _apiService.clearToken();
    notifyListeners();
  }
}
