import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/services/paystack_url_genrater.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../model/mail_setting.dart';

class PayStackScreen extends StatefulWidget {
  final String initialURl;
  final String reference;
  final String amount;
  final String secretKey;
  final String callBackUrl;

  const PayStackScreen({
    Key? key,
    required this.initialURl,
    required this.reference,
    required this.amount,
    required this.secretKey,
    required this.callBackUrl,
  }) : super(key: key);

  @override
  State<PayStackScreen> createState() => _PayStackScreenState();
}

class _PayStackScreenState extends State<PayStackScreen> {
  WebViewController controller = WebViewController();

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

  @override
  void initState() {
    initializeFlutterFire();
    initController();
    super.initState();
  }

  initController() {
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                // Update loading bar.
              },
              onPageStarted: (String url) {},
              onPageFinished: (String url) {},
              onWebResourceError: (WebResourceError error) {},
              onNavigationRequest: (NavigationRequest navigation) async {
                debugPrint("--->2" + navigation.url);
                debugPrint(
                  "--->2" +
                      "${widget.callBackUrl}?trxref=${widget.reference}&reference=${widget.reference}",
                );
                if (navigation.url ==
                        'https://foodieweb.siswebapp.com/success?trxref=${widget.reference}&reference=${widget.reference}' ||
                    navigation.url ==
                        '${widget.callBackUrl}?trxref=${widget.reference}&reference=${widget.reference}') {
                  final isDone = await PayStackURLGen.verifyTransaction(
                    secretKey: widget.secretKey,
                    reference: widget.reference,
                    amount: widget.amount,
                  );
                  Navigator.pop(context, isDone); //close webview
                }
                if ((navigation.url ==
                        '${widget.callBackUrl}?trxref=${widget.reference}&reference=${widget.reference}') ||
                    (navigation.url == "https://hello.pstk.xyz/callback") ||
                    (navigation.url == 'https://standard.paystack.co/close') ||
                    (navigation.url == 'https://talazo.app/login')) {
                  final isDone = await PayStackURLGen.verifyTransaction(
                    secretKey: widget.secretKey,
                    reference: widget.reference,
                    amount: widget.amount,
                  );
                  Navigator.pop(context, isDone);
                  //close webview
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.initialURl));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showMyDialog();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(COLOR_PRIMARY),
          title: Text("Payment".tr()),
          centerTitle: false,
          leading: GestureDetector(
            onTap: () {
              _showMyDialog();
            },
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: WebViewWidget(controller: controller),
      ),
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Payment').tr(),
          content: SingleChildScrollView(
            child: Text("Are you want to cancel Payment?"),
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ).tr(),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child:
                  const Text(
                    'Continue',
                    style: TextStyle(color: Colors.green),
                  ).tr(),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
