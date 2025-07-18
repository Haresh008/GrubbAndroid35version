// **************      fablead code by Haresh Castom tune  *****************************

// import 'dart:convert';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:developer';
//
// Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   log("Background Message :: ${message.messageId}");
//   displayNotification(FlutterLocalNotificationsPlugin(), message);
// }
//
// class NotificationService {
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//
//   NotificationService() {
//     initInfo();
//   }
//
//   Future<void> initInfo() async {
//     await FirebaseMessaging.instance
//         .setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     NotificationSettings settings =
//         await FirebaseMessaging.instance.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );
//
//     if (settings.authorizationStatus == AuthorizationStatus.authorized ||
//         settings.authorizationStatus == AuthorizationStatus.provisional) {
//       const AndroidInitializationSettings initializationSettingsAndroid =
//           AndroidInitializationSettings('@mipmap/ic_launcher');
//       var iosInitializationSettings = const DarwinInitializationSettings();
//       final InitializationSettings initializationSettings =
//           InitializationSettings(
//               android: initializationSettingsAndroid,
//               iOS: iosInitializationSettings);
//
//       await flutterLocalNotificationsPlugin.initialize(
//         initializationSettings,
//         onDidReceiveNotificationResponse: (NotificationResponse response) {
//           log("Notification clicked with payload: ${response.payload}");
//         },
//       );
//       await setupInteractedMessage();
//     }
//   }
//
//   Future<void> setupInteractedMessage() async {
//     RemoteMessage? initialMessage =
//         await FirebaseMessaging.instance.getInitialMessage();
//     if (initialMessage != null) {
//       handleNotification(initialMessage);
//     }
//
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       log("onMessage: ${message.notification.toString()}");
//       handleNotification(message);
//     });
//
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       log("onMessageOpenedApp: ${message.notification.toString()}");
//       handleNotification(message);
//     });
//
//     log("Permission authorized");
//     await FirebaseMessaging.instance.subscribeToTopic("QuicklAI");
//   }
//
//   static Future<String> getToken() async {
//     String? token = await FirebaseMessaging.instance.getToken();
//     return token!;
//   }
//
//   Future<void> handleNotification(RemoteMessage message) async {
//     if (message.data.isNotEmpty) {
//       await displayNotification(flutterLocalNotificationsPlugin, message);
//     }
//   }
// }
//
// Future<void> displayNotification(
//     FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
//     RemoteMessage message) async {
//   log('Displaying notification: ${message.data['body']}');
//   try {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.reload();
//     final String? name = prefs.getString('userName');
//
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       '0',
//       'foodie-customer',
//       description: 'Show Grubb Notification',
//       importance: Importance.max,
//       sound: RawResourceAndroidNotificationSound(
//           'tune'), // Ensure this matches your sound file name
//     );
//
//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//
//     AndroidNotificationDetails androidNotificationDetails =
//         AndroidNotificationDetails(
//       channel.id,
//       channel.name,
//       channelDescription: channel.description,
//       importance: Importance.max,
//       priority: Priority.max,
//       ticker: 'ticker',
//       sound: RawResourceAndroidNotificationSound('tune'),
//     );
//
//     DarwinNotificationDetails darwinNotificationDetails =
//         const DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );
//
//     NotificationDetails notificationDetailsBoth = NotificationDetails(
//       android: androidNotificationDetails,
//       iOS: darwinNotificationDetails,
//     );
//
//     await flutterLocalNotificationsPlugin.show(
//       message.messageId.hashCode,
//       message.data['title'],
//       "Hii ${message.data['body']}",
//       notificationDetailsBoth,
//       payload: jsonEncode(message.data),
//     );
//   } on Exception catch (e) {
//     log(e.toString());
//   }
// }
// **************      fablead code by Haresh Castom tune  *****************************

//*******************  Client Code  ********************************
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("BackGround Message :: ${message.messageId}");
}

class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  initInfo() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    var request = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosInitializationSettings = const DarwinInitializationSettings();
      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: iosInitializationSettings,
          );
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (payload) {},
      );
      setupInteractedMessage();
    }
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      FirebaseMessaging.onBackgroundMessage(
        (message) => firebaseMessageBackgroundHandle(message),
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("::::::::::::onMessage:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
        display(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("::::::::::::onMessageOpenedApp:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
        display(message);
      }
    });
    log("::::::::::::Permission authorized:::::::::::::::::");
    await FirebaseMessaging.instance.subscribeToTopic("QuicklAI");
  }

  static getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    return token!;
  }

  void display(RemoteMessage message) async {
    log('Got a message whilst in the foreground!');
    log('Message data: ${message.notification!.body.toString()}');
    try {
      // final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final String? name = prefs.getString('userName');
      AndroidNotificationChannel channel = const AndroidNotificationChannel(
        '0',
        'foodie-customer',
        description: 'Show Grubb Notification',
        importance: Importance.max,
      );
      AndroidNotificationDetails notificationDetails =
          AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: 'your channel Description',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
          );
      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );
      NotificationDetails notificationDetailsBoth = NotificationDetails(
        android: notificationDetails,
        iOS: darwinNotificationDetails,
      );
      await FlutterLocalNotificationsPlugin().show(
        0,
        message.notification!.title,
        "${message.notification!.body}",
        notificationDetailsBoth,
        payload: jsonEncode(message.data),
      );
    } on Exception catch (e) {
      log(e.toString());
    }
  }
}
