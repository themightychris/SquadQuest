// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyA87qGDgjT9CSoW2skUs-af-qsF5oU0-X0',
    appId: '1:902139539375:web:8ffb7afcec26c91c77c95a',
    messagingSenderId: '902139539375',
    projectId: 'squadquest-d8665',
    authDomain: 'squadquest-d8665.firebaseapp.com',
    storageBucket: 'squadquest-d8665.appspot.com',
    measurementId: 'G-HCYKP80G02',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBq0veID9cftBAgLXRyrv33ufPHAN8QJXY',
    appId: '1:902139539375:android:df52a255864ed20577c95a',
    messagingSenderId: '902139539375',
    projectId: 'squadquest-d8665',
    storageBucket: 'squadquest-d8665.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDe93NeptzroIGiH51YSfO2XL2Pl-WSYJY',
    appId: '1:902139539375:ios:1b306c90cd05f5f877c95a',
    messagingSenderId: '902139539375',
    projectId: 'squadquest-d8665',
    storageBucket: 'squadquest-d8665.appspot.com',
    iosBundleId: 'app.squadquest',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDe93NeptzroIGiH51YSfO2XL2Pl-WSYJY',
    appId: '1:902139539375:ios:1b306c90cd05f5f877c95a',
    messagingSenderId: '902139539375',
    projectId: 'squadquest-d8665',
    storageBucket: 'squadquest-d8665.appspot.com',
    iosBundleId: 'app.squadquest',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA87qGDgjT9CSoW2skUs-af-qsF5oU0-X0',
    appId: '1:902139539375:web:f9acccf0e89abc4177c95a',
    messagingSenderId: '902139539375',
    projectId: 'squadquest-d8665',
    authDomain: 'squadquest-d8665.firebaseapp.com',
    storageBucket: 'squadquest-d8665.appspot.com',
    measurementId: 'G-4SMR1LJEHB',
  );

}