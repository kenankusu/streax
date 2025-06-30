import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Echte Web-Konfiguration von Firebase Console:
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDHqoPE7hPq13P3Vu4qmOCZpWMdHN1MmsU",
    authDomain: "streax-38c3c.firebaseapp.com",
    projectId: "streax-38c3c",
    storageBucket: "streax-38c3c.firebasestorage.app",
    messagingSenderId: "1418608495",
    appId: "1:1418608495:web:716bdfbb828128f769729a",
    measurementId: "G-XKQBPR04YF", // Optional für Analytics
  );

  // Android-Konfiguration (für später):
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "your-android-api-key-here",
    appId: "1:1418608495:android:your-android-app-id",
    messagingSenderId: "1418608495",
    projectId: "streax-38c3c",
    storageBucket: "streax-38c3c.firebasestorage.app",
  );

  // iOS-Konfiguration aus GoogleService-Info.plist:
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyDCW2asFJq83IQBVVKwF2UWrRizt_I7Kog",
    appId: "1:1418608495:ios:571635b22d68d6e969729a",
    messagingSenderId: "1418608495",
    projectId: "streax-38c3c",
    storageBucket: "streax-38c3c.firebasestorage.app",
    iosBundleId: "com.example.flutterApplication1",
  );
}
