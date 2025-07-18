import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_share/flutter_share.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/model/referral_model.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:share_plus/share_plus.dart';

import '../../model/mail_setting.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
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
    // TODO: implement initState
    getReferralCode();
    super.initState();
    initializeFlutterFire();
  }

  ReferralModel? referralModel = ReferralModel();
  bool isLoading = true;

  getReferralCode() async {
    await FireStoreUtils.getReferralUserBy().then((value) {
      if (value != null) {
        setState(() {
          isLoading = false;
          referralModel = value;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFF662E),
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body:
          isLoading == true
              ? Center(child: CircularProgressIndicator())
              : referralModel == null
              ? Center(child: Text("Something want wrong"))
              : Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/background_image_referral.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/earn_icon.png',
                            width: 160,
                          ),
                          SizedBox(height: 40),
                          Text(
                            "Refer your friends and",
                            style: TextStyle(
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Earn".tr() +
                                " ${amountShow(amount: referralAmount.toString())} " +
                                "each".tr(),
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 10),
                          // Text(
                          //   referralModel!.referralCode.toString(),
                          //   style: TextStyle(fontSize: 20, color: Colors.black),
                          // ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Invite Friend & Family".tr(),
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.0,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "Invite friends and family to sign up using your referral code and you and your friend will get ${amountShow(amount: referralAmount.toString())}/- in your wallet which can be used on your future orders”"
                              .tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0XFF666666),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      GestureDetector(
                        onTap: () {
                          FlutterClipboard.copy(
                            referralModel!.referralCode.toString(),
                          ).then((value) {
                            SnackBar snackBar = SnackBar(
                              content: Text(
                                "Coupon code copied".tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
                          });
                        },
                        child: DottedBorder(
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(2),
                          padding: const EdgeInsets.all(15),
                          color: const Color(COUPON_DASH_COLOR),
                          strokeWidth: 2,
                          dashPattern: const [5],
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                            child: Container(
                              height: 25,
                              width: MediaQuery.of(context).size.width * 0.30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: const Color(COUPON_BG_COLOR),
                              ),
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                referralModel!.referralCode.toString(),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Color(COLOR_PRIMARY),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 40.0,
                          left: 40.0,
                          top: 60,
                        ),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF662E),
                              padding: EdgeInsets.only(top: 12, bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                side: BorderSide(color: Color(0xFFFF662E)),
                              ),
                            ),
                            onPressed: () async {
                              await showProgress(
                                context,
                                "Please wait".tr(),
                                false,
                              );
                              share();
                            },
                            child: Text(
                              'Refer Friend'.tr(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode(context)
                                        ? Colors.black
                                        : Colors.white,
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

  // Future<void> share() async {
  //   hideProgress();
  //   await FlutterShare.share(
  //     title: 'Grubb'.tr(),
  //     text:
  //         "Hey! Use my code ${referralModel!.referralCode.toString()} and get"
  //             .tr() +
  //         " ${amountShow(amount: referralAmount.toString())} " +
  //         "added to your Grubb wallet for your next order. ".tr(),
  //   );
  // }
  Future<void> share() async {
    hideProgress();

    final String referralCode = referralModel?.referralCode ?? '';
    final String referralAmountText = amountShow(amount: referralAmount.toString());

    final String shareText =
        "Hey! Use my code $referralCode and get".tr() +
            " $referralAmountText " +
            "added to your Grubb wallet for your next order.".tr();

    await Share.share(
      shareText,
      subject: 'Grubb'.tr(),
    );
  }

}
