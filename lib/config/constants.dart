import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Default API and Socket backend endpoints from .env with fallback
  static String get defaultApiUrl =>
      dotenv.maybeGet('API_URL') ??
      const String.fromEnvironment(
        'API_URL',
        defaultValue: 'https://195.35.6.141',
      );

  static String get defaultSocketUrl =>
      dotenv.maybeGet('SOCKET_URL') ??
      const String.fromEnvironment(
        'SOCKET_URL',
        defaultValue: 'https://195.35.6.141',
      );

  static String _apiUrl = '';
  static String get apiUrl => _apiUrl.isNotEmpty ? _apiUrl : defaultApiUrl;
  static set apiUrl(String val) => _apiUrl = val;

  static String _socketUrl = '';
  static String get socketUrl => _socketUrl.isNotEmpty ? _socketUrl : defaultSocketUrl;
  static set socketUrl(String val) => _socketUrl = val;

  static const String apiVersion = '/api/v1';

  static Map<String, dynamic> iceConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      // {'urls': 'stun:74.125.197.127:19302'},
      // {'urls': 'stun:142.250.180.127:19302'},
      // {'urls': 'stun:173.194.202.127:19302'},
      {'urls': 'stun:global.stun.twilio.com:3478'},
      {
        'urls': [
          'turn:195.35.6.141:3478?transport=udp',
          'turn:195.35.6.141:3478?transport=tcp',
        ],
        'username': 'webrtc',
        'credential': '1234',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  static String getFullMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (path.contains('/uploads/') && !path.contains('/api/v1/uploads/')) {
        return path.replaceFirst('/uploads/', '/api/v1/uploads/');
      }
      return path;
    }
    var cleanPath = path.startsWith('/') ? path : '/$path';
    if (cleanPath.startsWith('/uploads/')) {
      cleanPath = '/api/v1$cleanPath';
    }
    return '$apiUrl$cleanPath';
  }
}

class StorageKeys {
  static const String accessToken = 'chat_access_token';
  static const String refreshToken = 'chat_refresh_token';
  static const String userProfile = 'chat_user_profile';
  static const String serverUrl = 'chat_server_url';
}
