class AppConfig {
  // Default API and Socket backend endpoints from environment with fallback
  static const String defaultApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.81.100.38:9080',
  );
  static const String defaultSocketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.81.100.38:9080',
  );

  static String apiUrl = defaultApiUrl;
  static String socketUrl = defaultSocketUrl;

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
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$apiUrl$cleanPath';
  }
}

class StorageKeys {
  static const String accessToken = 'chat_access_token';
  static const String refreshToken = 'chat_refresh_token';
  static const String userProfile = 'chat_user_profile';
  static const String serverUrl = 'chat_server_url';
}
