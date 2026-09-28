import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String _formatUrl(String raw) {
    var url = raw.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!kIsWeb && Platform.isAndroid) {
      if (url.contains('localhost')) {
        url = url.replaceAll('localhost', '10.0.2.2');
      } else if (url.contains('127.0.0.1')) {
        url = url.replaceAll('127.0.0.1', '10.0.2.2');
      }
    }
    return url;
  }

  // Default API and Socket backend endpoints from .env with fallback
  static String get defaultApiUrl {
    final envVal = dotenv.maybeGet('API_URL');
    if (envVal != null && envVal.isNotEmpty) {
      return _formatUrl(envVal);
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:9060';
    }
    return 'http://localhost:9060';
  }

  static String get defaultSocketUrl {
    final envVal = dotenv.maybeGet('SOCKET_URL');
    if (envVal != null && envVal.isNotEmpty) {
      return _formatUrl(envVal);
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:9060';
    }
    return 'http://localhost:9060';
  }

  static String _apiUrl = '';
  static String get apiUrl => _apiUrl.isNotEmpty ? _apiUrl : defaultApiUrl;
  static set apiUrl(String val) => _apiUrl = _formatUrl(val);

  static String _socketUrl = '';
  static String get socketUrl => _socketUrl.isNotEmpty ? _socketUrl : defaultSocketUrl;
  static set socketUrl(String val) => _socketUrl = _formatUrl(val);

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
