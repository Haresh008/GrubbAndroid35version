import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/mail_setting.dart';
import 'language_model.dart';

// ignore: must_be_immutable
class LanguageChooseScreen extends StatefulWidget {
  bool isContainer = false;

  LanguageChooseScreen({Key? key, required this.isContainer}) : super(key: key);

  @override
  State<LanguageChooseScreen> createState() => _LanguageChooceScreenState();
}

class _LanguageChooceScreenState extends State<LanguageChooseScreen> {
  var languageList = <Data>[];
  String selectedLanguage = "en";

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
    loadData();
    super.initState();
    initializeFlutterFire();
  }

  void loadData() async {
    languageList.clear();
    await FireStoreUtils.firestore
        .collection(Setting)
        .doc("languages")
        .get()
        .then((value) {
          List list = value.data()!["list"];
          for (int i = 0; i < list.length; i++) {
            Map data = list[i];
            if (data["isActive"]) {
              Data langData = new Data();
              langData.language = data["title"];
              langData.languageCode = data["slug"];

              if (langData.languageCode == "en") {
                langData.icon = "assets/flags/ic_uk.png";
              } else if (langData.languageCode == "es") {
                langData.icon = "assets/flags/ic_spain.png";
              } else if (langData.languageCode == "ar") {
                langData.icon = "assets/flags/ic_uae.png";
              } else if (langData.languageCode == "Fr") {
                langData.icon = "assets/flags/ic_france.png";
              } else if (langData.languageCode == "pt") {
                langData.icon = "assets/flags/ic_portugal.png";
              }
              languageList.add(langData);
            }

            if (i == (languageList.length - 1)) {
              setState(() {});
            }
          }
        });
    // final response = await rootBundle.loadString("assets/translations/language.json");
    // final decodeData = jsonDecode(response);
    // var productData = decodeData["data"];
    // setState(() {
    //   languageList = List.from(productData).map<Data>((item) => Data.fromJson(item)).toList();
    // });
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.containsKey("languageCode")) {
      selectedLanguage = sp.getString("languageCode")!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:
            isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : Color(0xffFFFFFF),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              ListView.builder(
                itemCount: languageList.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedLanguage =
                            languageList[index].languageCode.toString();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        decoration:
                            languageList[index].languageCode == selectedLanguage
                                ? BoxDecoration(
                                  border: Border.all(
                                    color: Color(COLOR_PRIMARY),
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(
                                      5.0,
                                    ), //                 <--- border radius here
                                  ),
                                )
                                : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Image.asset(
                                languageList[index].icon.toString(),
                                height: 60,
                                width: 60,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                ),
                                child: Text(
                                  languageList[index].language.toString(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(COLOR_PRIMARY),
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: Color(COLOR_PRIMARY)),
              ),
            ),
            onPressed: () async {
              if (selectedLanguage == "en") {
                SharedPreferences sp = await SharedPreferences.getInstance();
                sp.setString("languageCode", selectedLanguage);
                context.setLocale(Locale(selectedLanguage));
              } else if (selectedLanguage == "ar") {
                SharedPreferences sp = await SharedPreferences.getInstance();
                sp.setString("languageCode", selectedLanguage);
                context.setLocale(Locale(selectedLanguage));
              } else {
                SharedPreferences sp = await SharedPreferences.getInstance();
                sp.setString("languageCode", "en");
                context.setLocale(Locale("en"));
              }

              if (widget.isContainer) {
                SnackBar snack = SnackBar(
                  content:
                      const Text(
                        'Language change successfully',
                        style: TextStyle(color: Colors.white),
                      ).tr(),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.black,
                );
                ScaffoldMessenger.of(context).showSnackBar(snack);
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(
              'Save'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode(context) ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
