import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration.
///
/// Replace these values by running:
/// `dart pub global activate flutterfire_cli && flutterfire configure`
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
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemo-Web-Key-Replace-Me',
    appId: '1:000000000000:web:driver-schedule-demo',
    messagingSenderId: '000000000000',
    projectId: 'driver-schedule-demo',
    authDomain: 'driver-schedule-demo.firebaseapp.com',
    storageBucket: 'driver-schedule-demo.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemo-Android-Key-Replace-Me',
    appId: '1:000000000000:android:driver-schedule-demo',
    messagingSenderId: '000000000000',
    projectId: 'driver-schedule-demo',
    storageBucket: 'driver-schedule-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemo-iOS-Key-Replace-Me',
    appId: '1:000000000000:ios:driver-schedule-demo',
    messagingSenderId: '000000000000',
    projectId: 'driver-schedule-demo',
    storageBucket: 'driver-schedule-demo.appspot.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDemo-macOS-Key-Replace-Me',
    appId: '1:000000000000:macos:driver-schedule-demo',
    messagingSenderId: '000000000000',
    projectId: 'driver-schedule-demo',
    storageBucket: 'driver-schedule-demo.appspot.com',
    iosBundleId: 'com.example.flutterApplication1',
  );
}
