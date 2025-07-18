import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../model/mail_setting.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initializeFlutterFire() async {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      final FlutterExceptionHandler? originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails errorDetails) async {
        await FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
        originalOnError!(errorDetails);
        // Forward to original handler.
      };
      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("globalSettings")
          .get()
          .then((dineinresult) {
            if (dineinresult.exists &&
                dineinresult.data() != null &&
                dineinresult.data()!.containsKey("website_color")) {
              COLOR_PRIMARY = int.parse(
                dineinresult.data()!["website_color"].replaceFirst("#", "0xff"),
              );
            }
          });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("DineinForRestaurant")
          .get()
          .then((dineinresult) {
            if (dineinresult.exists) {
              isDineInEnable = dineinresult.data()!["isEnabledForCustomer"];
            }
          });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("emailSetting")
          .get()
          .then((value) {
            if (value.exists) {
              mailSettings = MailSettings.fromJson(value.data()!);
            }
          });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("home_page_theme")
          .get()
          .then((value) {
            if (value.exists) {
              homePageThem = value.data()!["theme"];
            }
          });
      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("Version")
          .get()
          .then((value) {
            print(value.data());
            setState(() {
              firebasecustomerapk = value.data()!['app_version'].toString();
              firebasecustomerIos = value.data()!['ios_version'].toString();
            });
          });
      print("firebasemerchantapkfirebasemerchantapk${firebasecustomerapk}");
      print("firebasemerchantapkfirebasemerchantapk${firebasecustomerIos}");
      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("Version")
          .get()
          .then((value) {
            debugPrint(value.data().toString());
            appVersion = value.data()!['app_version'].toString();
          });

      await FirebaseFirestore.instance
          .collection(Setting)
          .doc("googleMapKey")
          .get()
          .then((value) {
            print(value.data());
            GOOGLE_API_KEY = value.data()!['key'].toString();
          });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<String?> getImageUrl() async {
    try {
      // Firestore na instance mate reference lo
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Firestore ma collection ane document no path specify karo
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await firestore.collection('settings').doc('refCustomerScreen').get();

      if (docSnapshot.exists) {
        // Document ma thi imageURL fetch karo
        final data = docSnapshot.data();
        Timer(Duration(seconds: 10), () {
          // if (customerapk==firebasecustomerapk) {
          //   if (mounted) pushReplacement(context, OnBoarding());
          // } else {
          //   showUpdateDialog(context);
          // }
          if (Platform.isAndroid) {
            if (customerapk == firebasecustomerapk) {
              if (context.mounted) pushReplacement(context, OnBoarding());
            } else {
              showUpdateDialog(context);
            }
          } else if (Platform.isIOS) {
            if (castomerios == firebasecustomerIos) {
              if (context.mounted) pushReplacement(context, OnBoarding());
            } else {
              print("call ios call tha che ho");
              showUpdateDialog(context);
            }
          }
        });
        return data?['image'];
      } else {
        print('Document does not exist');
        return null;
      }
    } catch (e) {
      print('Error fetching image URL: $e');
      return null;
    }
  }

  void initState() {
    // TODO: implement initState
    super.initState();
    initializeFlutterFire();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String?>(
        future: getImageUrl(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null) {
            return Center(child: Text('No image URL found'));
          } else {
            return Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Image.network(snapshot.data!, fit: BoxFit.fitHeight),
            );
          }
        },
      ),
      // Container(
      //   width: MediaQuery.of(context).size.width,
      //   height: MediaQuery.of(context).size.height,
      //   child: Image.asset('assets/images/grubb_splash_two.png',
      //       fit: BoxFit.fitHeight),
      // ),
    );
  }

  void showUpdateDialog(BuildContext context) {
    print("a call thache ke kem");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New Update Available"),
          content: Text(
            "A new version of the app is available. Please update to continue.",
          ),
          actions: [
            // TextButton(
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //   },
            //   child: Text("Later"),
            // ),
            InkWell(
              onTap: () {
                pushReplacement(context, OnBoarding());
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("Not Now", style: TextStyle(color: Colors.white)),
              ),
            ),
            InkWell(
              onTap: () async {
                String url =
                    Platform.isAndroid
                        ? "https://play.google.com/store/apps/details?id=com.grubb.customer"
                        : "https://apps.apple.com/app/grubb-food-order-dine-in/id6503343291";

                Uri uri = Uri.parse(url);

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Could not open the store")),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Update Now",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     String url = Platform.isAndroid
            //         ? "https://play.google.com/store/apps/details?id=com.grubb.restaurant"
            //         : "https://apps.apple.com/app/grubb-merchant/id6596748584";
            //
            //     Uri uri = Uri.parse(url);
            //
            //     if (await canLaunchUrl(uri)) {
            //       await launchUrl(uri, mode: LaunchMode.externalApplication);
            //     } else {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(content: Text("Could not open the store")),
            //       );
            //     }
            //   },
            //   child: Text("Update Now"),
            // ),
          ],
        );
      },
    );
  }
}
