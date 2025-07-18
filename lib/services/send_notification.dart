// import 'dart:convert';
// import 'dart:developer';
//
// import 'package:foodie_customer/ui/GetAccessToken/getAccessTokan.dart';
// import 'package:http/http.dart' as http;
//
//
//
// String serverToken = '';
//
// void getToken() async {
//
//   GetServerToken Getservertoken = GetServerToken();
//   serverToken = await Getservertoken.getAccessToken();
//   print('serverToken : $serverToken');
// }
//
// class SendNotification {
//
//   static Future<void> sendOneNotification({
//     required String token,
//     required String title,
//     required String body,
//     required Map<String, dynamic> payload,
//   }) async {
//     GetServerToken Getservertoken = GetServerToken();
//     serverToken = await Getservertoken.getAccessToken();
//     print("serverToken${serverToken}");
//     final url =
//         'https://fcm.googleapis.com/v1/projects/grubb-ba0e4/messages:send';
//
//     // Unique message ID to avoid multiple notifications
//     final messageId = DateTime.now().millisecondsSinceEpoch.toString();
//
//     final notificationPayload = {
//       "message": {
//         "token": token,
//         "data": payload,
//         "notification": {
//           "title": title,
//           "body": body,
//         },
//         "android": {
//           "notification": {
//             "tag": "single_notification", // Tag to ensure only one notification
//             "sound": "tune.aiff", // Custom sound for Android
//           },
//         },
//         "apns": {
//           "headers": {
//             "apns-collapse-id": "single_notification", // Collapse ID for iOS
//           },
//           "payload": {
//             "aps": {
//               "thread-id": "single_notification",
//               "sound": "tune.aiff", // Custom sound for iOS
//             },
//           },
//         },
//       },
//     };
//
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: <String, String>{
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $serverToken',
//         },
//         body: jsonEncode(notificationPayload),
//       );
//
//       if (response.statusCode == 200) {
//         log('Notification sent successfully');
//       } else {
//         log('Failed to send notification. Status Code: ${response.statusCode}');
//         log('Response: ${response.body}');
//       }
//     } catch (e) {
//       log('Exception caught: $e');
//     }
//   }
//
//   static Future<void> sendChatNotification({
//     required String token,
//     required String title,
//     required String body,
//     required Map<String, dynamic> payload,
//   }) async {
//     GetServerToken Getservertoken = GetServerToken();
//     serverToken = await Getservertoken.getAccessToken();
//     final url =
//         'https://fcm.googleapis.com/v1/projects/parkpal-3de72/messages:send';
//
//     // Unique message ID to avoid multiple notifications
//     final messageId = DateTime.now().millisecondsSinceEpoch.toString();
//
//     final notificationPayload = {
//       "message": {
//         "token": token,
//         "data": payload,
//         "notification": {
//           "title": title,
//           "body": body,
//         },
//         "android": {
//           "notification": {
//             "tag": "single_notification", // Tag to ensure only one notification
//             // Custom sound for Android
//           },
//         },
//         "apns": {
//           "headers": {
//             "apns-collapse-id": "single_notification", // Collapse ID for iOS
//           },
//           "payload": {
//             "aps": {
//               "thread-id": "single_notification",
//               "sound": "default", // Custom sound for iOS
//             },
//           },
//         },
//       },
//     };
//
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: <String, String>{
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $serverToken',
//         },
//         body: jsonEncode(notificationPayload),
//       );
//
//       if (response.statusCode == 200) {
//         log('Notification sent successfully');
//       } else {
//         log('Failed to send notification. Status Code: ${response.statusCode}');
//         log('Response: ${response.body}');
//       }
//     } catch (e) {
//       log('Exception caught: $e');
//     }
//   }
// }
