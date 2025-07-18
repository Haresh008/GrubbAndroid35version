import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/model/PhoneCallModal.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../model/mail_setting.dart';

class ContactUsScreen extends StatefulWidget {
  @override
  _ContactUsScreenState createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  String address = "", phone = "", email = "";

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

  final _formKey = GlobalKey<FormState>();
  PhoneCallModal? phonecallmodal;
  String? phoneNumber;
  TextEditingController _phoneController = TextEditingController();

  void getUserPhoneNumber() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      // Firestore thi data fetch karo
      DocumentSnapshot document =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (document.exists) {
        Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;
        if (data != null && data['role'] == 'customer') {
          phoneNumber = data['phoneNumber'];
          print('User Phone Number: $phoneNumber');
          _phoneController.text = phoneNumber.toString();
        } else {
          print('Role is not customer or data is missing');
        }
      } else {
        print('User document does not exist');
      }
    } else {
      print('No user logged in');
    }
  }

  void launchPhoneDialer() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: "+9176020 91988");
    if (await canLaunch(phoneUri.toString())) {
      await launch(phoneUri.toString());
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire();
    getUserPhoneNumber();
    print("phoneNumber${phoneNumber}");
    FireStoreUtils().getContactUs().then((value) {
      setState(() {
        address = value['Address'];
        phone = value['Phone'];
        email = value['Email'];
      });
    });
    print("phone${phone}");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              Material(
                elevation: 2,
                color: isDarkMode(context) ? Colors.black12 : Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                      onTap: () {
                        // _showAlertDialog(context);
                        launchPhoneDialer();
                      },
                      title:
                          Text(
                            'Talk to us!',
                            style: TextStyle(
                              color:
                                  isDarkMode(context)
                                      ? Colors.white
                                      : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ).tr(),
                      // subtitle: Text('+91 6297811058'),
                      trailing: Icon(
                        CupertinoIcons.chevron_forward,
                        color:
                            isDarkMode(context)
                                ? Colors.white54
                                : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  whatsapp() async {
    var contact = "+916297811058";
    var androidUrl =
        "whatsapp://send?phone=+916297811058&text=Hi, I need some help";
    var iosUrl =
        "https://wa.me/+916297811058?text=${Uri.parse('Hi, I need some help')}";

    try {
      if (Platform.isIOS) {
        await launchUrl(Uri.parse(iosUrl));
      } else {
        await launchUrl(Uri.parse(androidUrl));
      }
    } on Exception {}
  }

  // void _showAlertDialog(BuildContext context) {
  //   // Set up the buttons
  //
  //   // Set up the AlertDialog
  //   AlertDialog alert = AlertDialog(
  //     title: Text(
  //       "Grubb AI",
  //       style: TextStyle(
  //           color: isDarkMode(context) ? Colors.white : Colors.black,
  //           fontSize: 15,
  //           fontWeight: FontWeight.bold),
  //     ),
  //     content: Container(
  //       // height: 150,
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Row(
  //             children: [
  //               SizedBox(
  //                 width: 231,
  //                 child: Text(
  //                   "Hello Grubb AI Will Be Launched Soon Stay Tuned",
  //                   style: TextStyle(
  //                       color:
  //                           isDarkMode(context) ? Colors.white : Colors.black,
  //                       fontSize: 15,
  //                       fontWeight: FontWeight.bold),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           SizedBox(
  //             height: 15,
  //           ),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Color(COLOR_PRIMARY),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(10.0),
  //                     side: BorderSide(
  //                       color: Color(COLOR_PRIMARY),
  //                     ),
  //                   ),
  //                 ),
  //                 child: Text(
  //                   'Okay'.tr(),
  //                   style: const TextStyle(
  //                       fontWeight: FontWeight.w600,
  //                       fontSize: 16,
  //                       color: Colors.white),
  //                 ).tr(),
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                 },
  //               ),
  //             ],
  //           ),
  //           SizedBox(
  //             height: 5,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  //
  //   // Show the dialog
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return alert;
  //     },
  //   );
  // }

  void _showAlertDialog(BuildContext context) {
    // Set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop(); // Close the dialog
      },
    );
    Widget continueButton = TextButton(
      child: Text("Continue"),
      onPressed: () {
        Navigator.of(context).pop(); // Close the dialog
        // Add your action for Continue button here
      },
    );

    // Set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        "Hi there, this is Daisy!",
        style: TextStyle(
          color: isDarkMode(context) ? Colors.white : Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Container(
        // height: 150,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 231,
                  child: Text(
                    "Please confirm your phone number and tap on call me",
                    style: TextStyle(
                      color: isDarkMode(context) ? Colors.white : Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Container(
                  height: 35,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color:
                          isDarkMode(context) ? Colors.white : Colors.black26,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone,
                        color:
                            isDarkMode(context) ? Colors.white : Colors.black,
                        size: 18,
                      ),
                      SizedBox(width: 5),
                      Text(
                        phoneNumber.toString(),
                        style: TextStyle(
                          color:
                              isDarkMode(context) ? Colors.white : Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(COLOR_PRIMARY),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(color: Color(COLOR_PRIMARY)),
                    ),
                  ),
                  child:
                      Text(
                        'Request A Call Back'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ).tr(),
                  onPressed: () {
                    loginapp();
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "*Daisy will call you from an international number.",
                  style: TextStyle(
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  loginapp() async {
    print("adfdsafd");
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> data = {
        "phone_number": phoneNumber.toString(),
        "pathway_id": "bec420c9-bf29-4e1c-b51b-abfbe575ed5e",
        "voice": "e1289219-0ea2-4f22-a994-c542c2a48a0f",
      };
      // Convert 'billing' to a string

      print(data);
      final apiUrl = "https://api.bland.ai/v1/calls";

      // Construct the request headers
      final headers = {
        'Content-Type': 'application/json',
        'authorization':
            'sk-pen1pmbtosss26tp0hhdjlz2h00ecpzohqtybkosr9km9cr5ks3y2u45myje43nl69',
      };
      // Construct the request body
      final requestBody = json.encode({
        'phone_number': data['phone_number'],
        'pathway_id': data['pathway_id'],
        'voice': data['voice'],
      });

      // Make the API call using http.post
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: requestBody,
      );

      // Handle the response
      phonecallmodal = PhoneCallModal.fromJson(json.decode(response.body));
      if (response.statusCode == 200) {
        print("Abcskgjsgf");
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Daisy will call you from an international number."),
          ),
        );
        print('******************************');
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((phonecallmodal?.message).toString())),
        );
      }
    } else {
      // handle password mismatch
    }
  }
}
