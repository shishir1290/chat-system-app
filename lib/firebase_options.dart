// File generated for Firebase configuration
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAiq5KRQh0iKFusFMhElXlMHI2jp56eV-w',
    appId: '1:942566218345:web:dc22b17b5ed0ca645da0f8',
    messagingSenderId: '942566218345',
    projectId: 'nexora-d9d28',
    authDomain: 'nexora-d9d28.firebaseapp.com',
    storageBucket: 'nexora-d9d28.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAiq5KRQh0iKFusFMhElXlMHI2jp56eV-w',
    appId: '1:942566218345:android:dc22b17b5ed0ca645da0f8',
    messagingSenderId: '942566218345',
    projectId: 'nexora-d9d28',
    storageBucket: 'nexora-d9d28.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAiq5KRQh0iKFusFMhElXlMHI2jp56eV-w',
    appId: '1:942566218345:ios:dc22b17b5ed0ca645da0f8',
    messagingSenderId: '942566218345',
    projectId: 'nexora-d9d28',
    storageBucket: 'nexora-d9d28.firebasestorage.app',
    iosBundleId: 'com.nexora.chat.nexoraChat',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAiq5KRQh0iKFusFMhElXlMHI2jp56eV-w',
    appId: '1:942566218345:web:dc22b17b5ed0ca645da0f8',
    messagingSenderId: '942566218345',
    projectId: 'nexora-d9d28',
    authDomain: 'nexora-d9d28.firebaseapp.com',
    storageBucket: 'nexora-d9d28.firebasestorage.app',
  );
}
