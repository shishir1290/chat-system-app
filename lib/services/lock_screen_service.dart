import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LockScreenService {
  static const MethodChannel _channel = MethodChannel('com.nexora.chat/lockscreen');

  /// Enable full-screen overlay and screen turn-on exclusively for calls on locked devices
  static Future<void> enableCallLockScreenMode() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enableCallLockScreenMode');
    } catch (e) {
      debugPrint('[LockScreenService] Error enabling call lockscreen mode: $e');
    }
  }

  /// Disable lock screen display mode when call ends or is rejected
  static Future<void> disableCallLockScreenMode() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableCallLockScreenMode');
    } catch (e) {
      debugPrint('[LockScreenService] Error disabling call lockscreen mode: $e');
    }
  }

  /// Check if the phone keyguard is currently locked
  static Future<bool> isKeyguardLocked() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final bool? isLocked = await _channel.invokeMethod<bool>('isKeyguardLocked');
      return isLocked ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request system device unlock prompt (PIN / Pattern / Biometrics)
  static Future<bool> requestDismissKeyguard() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool? unlocked = await _channel.invokeMethod<bool>('requestDismissKeyguard');
      return unlocked ?? false;
    } catch (e) {
      return false;
    }
  }

  /// If the phone was locked when the call finished or was declined,
  /// immediately hide the app back to Android secure lockscreen to prevent unauthorized access
  static Future<void> exitLockScreenIfLocked() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('exitLockScreenIfLocked');
    } catch (e) {
      debugPrint('[LockScreenService] Error exiting lockscreen: $e');
    }
  }
}
