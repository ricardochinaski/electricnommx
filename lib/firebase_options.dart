import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for macos - '
          'run FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for linux - '
          'run FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMR6RYUrxCyXsDqxVtMeeMOPuLk8_fHO8',
    appId: '1:276605821197:web:9bf886207b59949f659044',
    messagingSenderId: '276605821197',
    projectId: 'pliegos-ric-chile',
    authDomain: 'pliegos-ric-chile.firebaseapp.com',
    storageBucket: 'pliegos-ric-chile.firebasestorage.app',
    measurementId: 'G-CZW9L7QMWX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbCZvmm_OE46Q9llmiecRiUIpu_TZPcFw',
    appId: '1:276605821197:android:78dd025e92b4cd3c659044',
    messagingSenderId: '276605821197',
    projectId: 'pliegos-ric-chile',
    storageBucket: 'pliegos-ric-chile.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCwGQS8no-wV2-ww3ufUOJxW8eZdloMpfE',
    appId: '1:276605821197:ios:fd6b03839d372220659044',
    messagingSenderId: '276605821197',
    projectId: 'pliegos-ric-chile',
    storageBucket: 'pliegos-ric-chile.firebasestorage.app',
    iosBundleId: 'com.aselec.pliegosric',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDMR6RYUrxCyXsDqxVtMeeMOPuLk8_fHO8',
    appId: '1:276605821197:web:1d1690c921e440d2659044',
    messagingSenderId: '276605821197',
    projectId: 'pliegos-ric-chile',
    authDomain: 'pliegos-ric-chile.firebaseapp.com',
    storageBucket: 'pliegos-ric-chile.firebasestorage.app',
    measurementId: 'G-BXSM9KFG13',
  );
}
