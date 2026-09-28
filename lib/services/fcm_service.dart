import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'api_service.dart';

// Top-level background tap handler for local notification action buttons
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('[FLN Background] Tap action: ${notificationResponse.actionId}, payload: ${notificationResponse.payload}');
}

// Helper to show rich call notification with Answer and Decline action buttons
Future<void> _showCallNotification(Map<String, dynamic> data, FlutterLocalNotificationsPlugin fln) async {
  final callerName = data['caller_name']?.toString() ?? 'Someone';
  final isVideo = data['is_video'] == 'true' || data['is_video'] == true;
  final callType = isVideo ? 'Incoming Video Call' : 'Incoming Voice Call';

  final androidDetails = AndroidNotificationDetails(
    'nexora_calls_channel',
    'Nexora Calls',
    channelDescription: 'High-priority full-screen incoming call notifications',
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.call,
    visibility: NotificationVisibility.public,
    ongoing: true,
    autoCancel: false,
    enableVibration: true,
    playSound: true,
    colorized: true,
    color: const Color.fromARGB(255, 37, 211, 102),
    subText: 'Incoming Call',
    timeoutAfter: 45000,
    audioAttributesUsage: AudioAttributesUsage.voiceCommunication,
    actions: const <AndroidNotificationAction>[
      AndroidNotificationAction(
        'decline_call',
        'Decline',
        showsUserInterface: false,
        cancelNotification: true,
        contextual: false,
      ),
      AndroidNotificationAction(
        'answer_call',
        'Answer',
        showsUserInterface: true,
        cancelNotification: true,
        contextual: false,
      ),
    ],
  );

  final details = NotificationDetails(android: androidDetails);
  await fln.show(
    8888, // Call notification ID
    callerName,
    callType,
    details,
    payload: jsonEncode(data),
  );
}

// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[FCM Background] Firebase init error: $e');
  }

  debugPrint('[FCM Background] Message received: ${message.data}');
  final data = message.data;
  final type = data['type'];

  final fln = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  const initSettings = InitializationSettings(android: androidInit);
  await fln.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint('[FLN Background Init] Notification tap: ${response.actionId}');
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  if (type == 'CALL_INCOMING') {
    await _showCallNotification(data, fln);
  } else if (type == 'CALL_CANCELLED') {
    await fln.cancel(8888);
  } else if (type == 'NEW_MESSAGE') {
    final senderName = data['sender_name'] ?? 'Nexora';
    final body = data['body'] ?? 'New message';

    const androidDetails = AndroidNotificationDetails(
      'nexora_messages_channel',
      'Nexora Messages',
      channelDescription: 'New chat message notifications',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);
    final msgId = (data['message_id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF;
    await fln.show(msgId, senderName, body, details, payload: jsonEncode(data));
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  void Function(Map<String, dynamic> data, String? actionId)? onNotificationAction;
  String? _pendingLaunchPayload;
  String? _pendingLaunchActionId;

  Future<void> initialize() async {
    try {
      // 1. Request permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // 2. Setup Notification Channels for Android
      await _setupNotificationChannels();

      // 3. Initialize Local Notifications
      const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Check if app was launched from a local notification
      final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        _pendingLaunchPayload = launchDetails.notificationResponse?.payload;
        _pendingLaunchActionId = launchDetails.notificationResponse?.actionId;
        debugPrint('[FCM] App launched via notification response: $_pendingLaunchPayload, actionId: $_pendingLaunchActionId');
      }

      // Check if app was launched from a terminated FCM message
      final initialMsg = await _messaging.getInitialMessage();
      if (initialMsg != null && initialMsg.data.isNotEmpty) {
        _pendingLaunchPayload = jsonEncode(initialMsg.data);
        debugPrint('[FCM] App launched via initial FCM message: ${initialMsg.data}');
      }

      // Background to foreground FCM tap listener
      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        debugPrint('[FCM] onMessageOpenedApp data: ${msg.data}');
        if (msg.data.isNotEmpty) {
          _handleActionPayload(msg.data, null);
        }
      });

      // 4. Background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 5. Get & Register FCM Token
      _fcmToken = await _messaging.getToken();
      debugPrint('[FCM] Device Token: $_fcmToken');
      if (_fcmToken != null) {
        await registerTokenWithBackend(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        registerTokenWithBackend(newToken);
      });

      // 6. Foreground message listener
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    } catch (e) {
      debugPrint('[FCM] Init error: $e');
    }
  }

  Future<void> _setupNotificationChannels() async {
    if (!kIsWeb && Platform.isAndroid) {
      const callChannel = AndroidNotificationChannel(
        'nexora_calls_channel',
        'Nexora Calls',
        description: 'High-priority full-screen incoming call notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const messageChannel = AndroidNotificationChannel(
        'nexora_messages_channel',
        'Nexora Messages',
        description: 'New chat message notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(callChannel);
        await androidPlugin.createNotificationChannel(messageChannel);
        await androidPlugin.requestNotificationsPermission();
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM Foreground] Data: ${message.data}');
    final data = message.data;
    final type = data['type'];

    if (type == 'CALL_CANCELLED') {
      _localNotifications.cancel(8888);
      return;
    }

    // When inside the app (foreground), live calls and messages are rendered in-app
    // by WebSockets (IncomingCallDialog and ChatScreen). We suppress system notification popups.
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Notification tapped: ${response.payload}, actionId: ${response.actionId}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleActionPayload(data, response.actionId);
      } catch (e) {
        debugPrint('[FCM] Error decoding payload: $e');
      }
    }
  }

  void _handleActionPayload(Map<String, dynamic> data, String? actionId) {
    final type = data['type'];
    if (type == 'CALL_INCOMING') {
      _localNotifications.cancel(8888);
    }

    if (onNotificationAction != null) {
      onNotificationAction!(data, actionId);
    } else {
      _pendingLaunchPayload = jsonEncode(data);
      _pendingLaunchActionId = actionId;
    }
  }

  void processPendingNotification(void Function(Map<String, dynamic> data, String? actionId) handler) {
    onNotificationAction = handler;
    if (_pendingLaunchPayload != null) {
      try {
        final data = jsonDecode(_pendingLaunchPayload!) as Map<String, dynamic>;
        final actionId = _pendingLaunchActionId;
        _pendingLaunchPayload = null;
        _pendingLaunchActionId = null;
        handler(data, actionId);
      } catch (e) {
        debugPrint('[FCM] Error processing pending launch notification: $e');
      }
    }
  }

  Future<void> registerTokenWithBackend(String token) async {
    try {
      final apiService = ApiService();
      var authToken = apiService.token;
      if (authToken == null || authToken.isEmpty) {
        authToken = await apiService.loadSavedToken();
      }
      if (authToken == null || authToken.isEmpty) {
        debugPrint('[FCM] Skipping registration: User not logged in yet.');
        return;
      }
      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      await apiService.post(
        '/api/v1/users/fcm-token',
        data: {
          'token': token,
          'platform': platform,
        },
      );
      debugPrint('[FCM] Registered token with backend successfully.');
    } catch (e) {
      debugPrint('[FCM] Failed to register token with backend: $e');
    }
  }

  Future<void> deleteTokenFromBackend() async {
    try {
      if (_fcmToken != null) {
        final apiService = ApiService();
        await apiService.delete(
          '/api/v1/users/fcm-token',
          data: {'token': _fcmToken},
        );
      }
    } catch (e) {
      debugPrint('[FCM] Failed to delete token on logout: $e');
    }
  }
}
