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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBcZhYN8jBSBQCrkXuxi_dOfcVK5y-Rc4w',
    appId: '1:776182699118:web:4de636ce351916f709427f',
    messagingSenderId: '776182699118',
    projectId: 'ecosignal-a10ae',
    authDomain: 'ecosignal-a10ae.firebaseapp.com',
    storageBucket: 'ecosignal-a10ae.firebasestorage.app',
    measurementId: 'G-7Q0FXBGSBN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDjCMp3BtpBwIM3pxnvp507k-1DED0cSnw',
    appId: '1:776182699118:android:d8845bab7028eccc09427f',
    messagingSenderId: '776182699118',
    projectId: 'ecosignal-a10ae',
    storageBucket: 'ecosignal-a10ae.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA6cPuEyaStt0z-gEjduzFdW3OYUetYzkU',
    appId: '1:776182699118:ios:497e0861e22563ac09427f',
    messagingSenderId: '776182699118',
    projectId: 'ecosignal-a10ae',
    storageBucket: 'ecosignal-a10ae.firebasestorage.app',
    androidClientId:
        '776182699118-06o7ct8vjtinv8sop7nmn8kqqcvv8vl4.apps.googleusercontent.com',
    iosClientId:
        '776182699118-hn5lsnpjt5s2t552a1v7evglnboqugc9.apps.googleusercontent.com',
    iosBundleId: 'com.ecosignal.md',
  );
}
