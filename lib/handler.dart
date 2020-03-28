import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotifications {
  FirebaseMessaging _firebaseMessaging;

  Future<String> setUpFirebase() async {
    String userToken = "";
    _firebaseMessaging = FirebaseMessaging();
    firebaseCloudMessagingListeners();
    //_firebaseMessaging.getToken().then((token) {
      //userToken = token;
    //});
    userToken = await _firebaseMessaging.getToken();
    return userToken;
  }

  void firebaseCloudMessagingListeners() {
    if (Platform.isIOS) iOSPermissions();

    _firebaseMessaging.getToken().then((token) {
      print(token);
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
      },
    );
  }

  void iOSPermissions() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }
}
