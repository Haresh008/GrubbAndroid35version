import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;

import '../../model/mail_setting.dart';

enum AuthProviders { PASSWORD, PHONE, FACEBOOK, APPLE }

class ReAuthUserScreen extends StatefulWidget {
  final AuthProviders provider;
  final String? email;
  final String? phoneNumber;
  final bool deleteUser;

  ReAuthUserScreen({
    Key? key,
    required this.provider,
    this.email,
    this.phoneNumber,
    required this.deleteUser,
  }) : super(key: key);

  @override
  _ReAuthUserScreenState createState() => _ReAuthUserScreenState();
}

class _ReAuthUserScreenState extends State<ReAuthUserScreen> {
  TextEditingController _passwordController = TextEditingController();
  late Widget body = CircularProgressIndicator.adaptive(
    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
  );
  String? _verificationID;

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
    super.initState();
    initializeFlutterFire();
    Future.delayed(Duration.zero, () {
      buildBody();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Text(
                  "Please Re-Authenticate in order to perform this action."
                      .tr(),
                  textAlign: TextAlign.center,
                ),
              ),
              body,
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: 'Password'.tr()),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(COLOR_PRIMARY),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onPressed: () async => passwordButtonPressed(),
            child: Text(
              'Verify'.tr(),
              style: TextStyle(
                color: isDarkMode(context) ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildFacebookButton() {
    return ElevatedButton.icon(
      label: Expanded(
        child: Text(
          'Facebook Verify'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Image.asset(
          'assets/images/facebook_logo.png',
          color: Colors.white,
          height: 30,
          width: 30,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(FACEBOOK_BUTTON_COLOR),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Color(FACEBOOK_BUTTON_COLOR)),
        ),
      ),
      onPressed: () async => facebookButtonPressed(),
    );
  }

  Widget buildAppleButton() {
    return FutureBuilder<bool>(
      future: apple.TheAppleSignIn.isAvailable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
          );
        }
        if (!snapshot.hasData || (snapshot.data != true)) {
          return Center(
            child: Text("Apple sign in is not available on this device.".tr()),
          );
        } else {
          return apple.AppleSignInButton(
            cornerRadius: 12.0,
            type: apple.ButtonType.continueButton,
            style:
                isDarkMode(context)
                    ? apple.ButtonStyle.white
                    : apple.ButtonStyle.black,
            onPressed: () => appleButtonPressed(),
          );
        }
      },
    );
  }

  Widget buildPhoneField() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: PinCodeTextField(
            length: 6,
            appContext: context,
            keyboardType: TextInputType.phone,
            backgroundColor: Colors.transparent,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(5),
              fieldHeight: 40,
              fieldWidth: 40,
              activeColor: Color(COLOR_PRIMARY),
              activeFillColor:
                  isDarkMode(context)
                      ? Colors.grey.shade700
                      : Colors.grey.shade100,
              selectedFillColor: Colors.transparent,
              selectedColor: Color(COLOR_PRIMARY),
              inactiveColor: Colors.grey.shade600,
              inactiveFillColor: Colors.transparent,
            ),
            enableActiveFill: true,
            onCompleted: (v) {
              _submitCode(v);
            },
            onChanged: (value) {
              print(value);
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  passwordButtonPressed() async {
    if (_passwordController.text.isEmpty) {
      showAlertDialog(
        context,
        'Empty Password'.tr(),
        'Password is required to update email'.tr(),
        true,
      );
    } else {
      await showProgress(context, "Verifying".tr(), false);
      try {
        auth.UserCredential? result = await FireStoreUtils.reAuthUser(
          widget.provider,
          email: MyAppState.currentUser!.email,
          password: _passwordController.text,
        );
        if (result == null) {
          await hideProgress();
          showAlertDialog(
            context,
            "Couldn't verify".tr(),
            "Please double check the password and try again.".tr(),
            true,
          );
        } else {
          if (result.user != null) {
            if (widget.email != null)
              await result.user!.updateEmail(widget.email!);
            await hideProgress();
            Navigator.pop(context, true);
          } else {
            await hideProgress();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Couldn't verify, Please try again.".tr(),
                  style: TextStyle(fontSize: 17),
                ),
              ),
            );
          }
        }
      } catch (e, s) {
        print('_ReAuthUserScreenState.passwordButtonPressed $e $s');
        await hideProgress();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Couldn't verify, Please try again.".tr(),
              style: TextStyle(fontSize: 17),
            ),
          ),
        );
      }
    }
  }

  facebookButtonPressed() async {
    try {
      await showProgress(context, "Verifying".tr(), false);
      AccessToken? token;
      FacebookAuth facebookAuth = FacebookAuth.instance;
      if (await facebookAuth.accessToken == null) {
        LoginResult result = await facebookAuth.login();
        if (result.status == LoginStatus.success) {
          token = await facebookAuth.accessToken;
        }
      } else {
        token = await facebookAuth.accessToken;
      }
      if (token != null)
        await FireStoreUtils.reAuthUser(widget.provider, accessToken: token);
      await hideProgress();
      Navigator.pop(context, true);
    } catch (e, s) {
      await hideProgress();
      print('facebookButtonPressed $e $s');
      showAlertDialog(
        context,
        'error'.tr(),
        "Couldn't verify with facebook.".tr(),
        true,
      );
    }
  }

  appleButtonPressed() async {
    try {
      await showProgress(context, "Verifying".tr(), false);
      final appleCredential = await apple.TheAppleSignIn.performRequests([
        apple.AppleIdRequest(
          requestedScopes: [apple.Scope.email, apple.Scope.fullName],
        ),
      ]);
      if (appleCredential.error != null) {
        showAlertDialog(
          context,
          'error'.tr(),
          "Couldn't verify with apple.".tr(),
          true,
        );
      }
      if (appleCredential.status == apple.AuthorizationStatus.authorized) {
        await FireStoreUtils.reAuthUser(
          widget.provider,
          appleCredential: appleCredential,
        );
      }
      await hideProgress();
      Navigator.pop(context, true);
    } catch (e, s) {
      await hideProgress();
      print('appleButtonPressed $e $s');
      showAlertDialog(
        context,
        'error'.tr(),
        "Couldn't verify with apple.".tr(),
        true,
      );
    }
  }

  _submitPhoneNumber() async {
    await showProgress(context, "Sending code...".tr(), true);
    await FireStoreUtils.firebaseSubmitPhoneNumber(
      widget.phoneNumber!,
      (String verificationId) {
        if (mounted) {
          hideProgress();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Code verification timeout, request new code.".tr(),
              ),
            ),
          );
        }
      },
      (String? verificationId, int? forceResendingToken) async {
        print('_ReAuthUserScreenState._submitPhoneNumber $verificationId');
        if (mounted) {
          print('_ReAuthUserScreenState.mounted');
          await hideProgress();
          _verificationID = verificationId;
        }
      },
      (auth.FirebaseAuthException error) async {
        if (mounted) {
          await hideProgress();
          print('${error.message} ${error.stackTrace}');
          String message = "An error has occurred, please try again.".tr();
          switch (error.code) {
            case 'invalid-verification-code':
              message = "Invalid code or has been expired.".tr();
              break;
            case 'user-disabled':
              message = "This user has been disabled.".tr();
              break;
            default:
              message = "An error has occurred, please try again.".tr();
              break;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          Navigator.pop(context);
        }
      },
      (auth.PhoneAuthCredential credential) async {
        print('_ReAuthUserScreenState._submitPhoneNumber');
      },
    );
  }

  void _submitCode(String code) async {
    await showProgress(context, 'Verifying'.tr(), false);
    try {
      if (_verificationID != null) {
        if (widget.deleteUser) {
          await FireStoreUtils.reAuthUser(
            widget.provider,
            verificationId: _verificationID!,
            smsCode: code,
          );
        } else {
          auth.PhoneAuthCredential credential = auth
              .PhoneAuthProvider.credential(
            smsCode: code,
            verificationId: _verificationID!,
          );
          await auth.FirebaseAuth.instance.currentUser!.updatePhoneNumber(
            credential,
          );
        }
        await hideProgress();
        Navigator.pop(context, true);
      } else {
        await hideProgress();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't get verification ID".tr()),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } on auth.FirebaseAuthException catch (exception) {
      print('_ReAuthUserScreenState._submitCode ${exception.toString()}');
      await hideProgress();
      Navigator.pop(context);

      String message = "An error has occurred, please try again.".tr();
      switch (exception.code) {
        case 'invalid-verification-code':
          message = "Invalid code or has been expired.".tr();
          break;
        case 'user-disabled':
          message = "This user has been disabled.".tr();
          break;
        default:
          message = "An error has occurred, please try again.".tr();
          break;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e, s) {
      print('_PhoneNumberInputScreenState._submitCode $e $s');
      await hideProgress();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error has occurred, please try again.".tr()),
        ),
      );
    }
  }

  void buildBody() async {
    switch (widget.provider) {
      case AuthProviders.PASSWORD:
        body = buildPasswordField();
        break;
      case AuthProviders.PHONE:
        await _submitPhoneNumber();
        body = buildPhoneField();
        break;
      case AuthProviders.FACEBOOK:
        body = buildFacebookButton();
        break;
      case AuthProviders.APPLE:
        body = buildAppleButton();
        break;
    }
    setState(() {});
  }
}
