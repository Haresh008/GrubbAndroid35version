import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/container/ContainerScreen.dart';
import 'package:foodie_customer/ui/login/LoginScreen.dart';
import 'package:foodie_customer/ui/signUp/SignUpScreen.dart';

import '../../model/mail_setting.dart';

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

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

class _AuthScreenState extends State<AuthScreen> {
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeFlutterFire();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 20.0,
                left: 20.0,
                top: 40,
                bottom: 20,
              ),
              child: TextButton(
                child:
                    Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(COLOR_PRIMARY),
                      ),
                    ).tr(),
                onPressed: () {
                  pushAndRemoveUntil(
                    context,
                    ContainerScreen(user: null),
                    false,
                  );
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.only(top: 5, bottom: 5),
                  ),
                  shape: MaterialStateProperty.all<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      side: BorderSide(color: Color(COLOR_PRIMARY)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  // color: Color(COLOR_PRIMARY),
                  fit: BoxFit.cover,
                  width: 150,
                  height: 150,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 32,
                  right: 16,
                  bottom: 8,
                ),
                child:
                    Text(
                      "Welcome to Grubb",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(COLOR_PRIMARY),
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ).tr(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                child:
                    Text(
                      "Orders from restaurants near you and track food in real-time",
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ).tr(),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 40.0,
                  left: 40.0,
                  top: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(COLOR_PRIMARY),
                      padding: EdgeInsets.only(top: 12, bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        side: BorderSide(color: Color(COLOR_PRIMARY)),
                      ),
                    ),
                    child:
                        Text(
                          "Log In",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).tr(),
                    onPressed: () {
                      push(context, LoginScreen());
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 40.0,
                  left: 40.0,
                  top: 20,
                  bottom: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: TextButton(
                    child:
                        Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(COLOR_PRIMARY),
                          ),
                        ).tr(),
                    onPressed: () {
                      push(context, SignUpScreen());
                    },
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                        EdgeInsets.only(top: 12, bottom: 12),
                      ),
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          side: BorderSide(color: Color(COLOR_PRIMARY)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
