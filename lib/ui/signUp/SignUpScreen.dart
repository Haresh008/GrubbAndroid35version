import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart' as easyLocal;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/container/ContainerScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../model/mail_setting.dart';

File? _image;

class SignUpScreen extends StatefulWidget {
  @override
  State createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  TextEditingController _passwordController = TextEditingController();
  GlobalKey<FormState> _key = GlobalKey();
  String? firstName,
      lastName,
      email,
      mobile,
      password,
      confirmPassword,
      referralCode;
  AutovalidateMode _validate = AutovalidateMode.disabled;

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
    super.initState();
    initializeFlutterFire();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      retrieveLostData();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDarkMode(context) ? Colors.white : Colors.black,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
          child: Form(key: _key, autovalidateMode: _validate, child: formUI()),
        ),
      ),
    );
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse? response = await _imagePicker.retrieveLostData();
    if (response == null) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _image = File(response.file!.path);
      });
    }
  }

  _onCameraClick() {
    final action = CupertinoActionSheet(
      message:
          Text('Add profile picture', style: TextStyle(fontSize: 15.0)).tr(),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text('Choose from gallery').tr(),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image = await _imagePicker.pickImage(
              source: ImageSource.gallery,
            );
            if (image != null)
              setState(() {
                _image = File(image.path);
              });
          },
        ),
        CupertinoActionSheetAction(
          child: Text('Take a picture').tr(),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image = await _imagePicker.pickImage(
              source: ImageSource.camera,
            );
            if (image != null)
              setState(() {
                _image = File(image.path);
              });
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('cancel').tr(),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  Widget formUI() {
    return Column(
      children: <Widget>[
        Align(
          alignment:
              Directionality.of(context) == TextDirection.ltr
                  ? Alignment.topLeft
                  : Alignment.topRight,
          child:
              Text(
                'Create new account',
                style: TextStyle(
                  color: Color(COLOR_PRIMARY),
                  fontWeight: FontWeight.bold,
                  fontSize: 25.0,
                ),
              ).tr(),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            top: 32,
            right: 8,
            bottom: 8,
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              CircleAvatar(
                radius: 65,
                backgroundColor: Colors.grey.shade400,
                child: ClipOval(
                  child: SizedBox(
                    width: 170,
                    height: 170,
                    child:
                        _image == null
                            ? Image.asset(
                              'assets/images/placeholder.jpg',
                              fit: BoxFit.cover,
                            )
                            : Image.file(_image!, fit: BoxFit.cover),
                  ),
                ),
              ),
              Positioned(
                left: 80,
                right: 0,
                child: FloatingActionButton(
                  backgroundColor: Color(COLOR_ACCENT),
                  child: Icon(
                    CupertinoIcons.camera,
                    color: isDarkMode(context) ? Colors.black : Colors.white,
                  ),
                  mini: true,
                  onPressed: _onCameraClick,
                ),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: Theme(
              data: ThemeData(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: Colors.grey,
                ),
              ),
              child: TextFormField(
                cursorColor: Color(COLOR_PRIMARY),
                textAlignVertical: TextAlignVertical.center,
                validator: validateName,
                onSaved: (String? val) {
                  firstName = val;
                },
                textInputAction: TextInputAction.next,
                style: TextStyle(
                  fontSize: 18.0,
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  fillColor: Colors.white,
                  hintText: easyLocal.tr('First Name'),
                  hintStyle: TextStyle(
                    fontSize: 18.0,
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: Color(COLOR_PRIMARY),
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: Theme(
              data: ThemeData(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: Colors.grey,
                ),
              ),
              child: TextFormField(
                validator: validateName,
                textAlignVertical: TextAlignVertical.center,
                cursorColor: Color(COLOR_PRIMARY),
                onSaved: (String? val) {
                  lastName = val;
                },
                textInputAction: TextInputAction.next,
                style: TextStyle(
                  fontSize: 18.0,
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  fillColor: Colors.white,
                  hintText: 'Last Name'.tr(),
                  hintStyle: TextStyle(
                    fontSize: 18.0,
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: Color(COLOR_PRIMARY),
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: Theme(
              data: ThemeData(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: Colors.grey,
                ),
              ),
              child: TextFormField(
                keyboardType: TextInputType.emailAddress,
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.next,
                cursorColor: Color(COLOR_PRIMARY),
                validator: validateEmail,
                onSaved: (String? val) {
                  email = val;
                },
                style: TextStyle(
                  fontSize: 18.0,
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  fillColor: Colors.white,
                  hintText: 'Email Address'.tr(),
                  hintStyle: TextStyle(
                    fontSize: 18.0,
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: Color(COLOR_PRIMARY),
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
              ),
            ),
          ),
        ),

        /// user mobile text field, this is hidden in case of sign up with
        /// phone number
        // Padding(
        //   padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
        //   child: Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 16),
        //     decoration: BoxDecoration(
        //         borderRadius: BorderRadius.circular(25),
        //         shape: BoxShape.rectangle,
        //         border: Border.all(color: Colors.grey.shade200)),
        //     child: InternationalPhoneNumberInput(
        //
        //       onInputChanged: (PhoneNumber number) =>
        //           mobile = number.phoneNumber,
        //       ignoreBlank: true,
        //       autoValidateMode: AutovalidateMode.onUserInteraction,
        //       inputDecoration: InputDecoration(
        //         hintText: 'Phone Number'.tr(),
        //         border: const OutlineInputBorder(
        //           borderSide: BorderSide.none,
        //         ),
        //         isDense: true,
        //         errorBorder: const OutlineInputBorder(
        //           borderSide: BorderSide.none,
        //         ),
        //       ),
        //       inputBorder: const OutlineInputBorder(
        //         borderSide: BorderSide.none,
        //       ),
        //       initialValue: PhoneNumber(isoCode: 'IN'),
        //       selectorConfig: const SelectorConfig(
        //           selectorType: PhoneInputSelectorType.DIALOG),
        //     ),
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              shape: BoxShape.rectangle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: InternationalPhoneNumberInput(
              onInputChanged:
                  (PhoneNumber number) => mobile = number.phoneNumber,
              ignoreBlank: true,
              autoValidateMode: AutovalidateMode.onUserInteraction,
              validator: validateMobile,
              inputDecoration: InputDecoration(
                hintText: 'Phone Number'.tr(),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                isDense: true,
                errorBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
              inputBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              initialValue: PhoneNumber(isoCode: 'IN'),
              selectorConfig: const SelectorConfig(
                selectorType: PhoneInputSelectorType.DIALOG,
              ),
            ),
          ),
        ),

        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: Theme(
              data: ThemeData(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: Colors.grey,
                ),
              ),
              child: TextFormField(
                obscureText: true,
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.next,
                controller: _passwordController,
                validator: validatePassword,
                onSaved: (String? val) {
                  password = val;
                },
                style: TextStyle(
                  fontSize: 18.0,
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                ),
                cursorColor: Color(COLOR_PRIMARY),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  fillColor: Colors.white,
                  hintText: 'Password'.tr(),
                  hintStyle: TextStyle(
                    fontSize: 18.0,
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: Color(COLOR_PRIMARY),
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: Theme(
              data: ThemeData(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: Colors.grey,
                ),
              ),
              child: TextFormField(
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _signUp(),
                obscureText: true,
                validator:
                    (val) =>
                        validateConfirmPassword(_passwordController.text, val),
                onSaved: (String? val) {
                  confirmPassword = val;
                },
                style: TextStyle(
                  fontSize: 18.0,
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                ),
                cursorColor: Color(COLOR_PRIMARY),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  fillColor: Colors.white,
                  hintText: 'Confirm Password'.tr(),
                  hintStyle: TextStyle(
                    fontSize: 18.0,
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: Color(COLOR_PRIMARY),
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
              ),
            ),
          ),
        ),

        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: Theme(
              data: ThemeData(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: Colors.grey,
                ),
              ),
              child: TextFormField(
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.next,
                onSaved: (String? val) {
                  referralCode = val;
                },
                style: TextStyle(
                  fontSize: 18.0,
                  color: isDarkMode(context) ? Colors.white : Colors.black,
                ),
                cursorColor: Color(COLOR_PRIMARY),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  fillColor: Colors.white,
                  hintText: 'Referral Code (Optional)'.tr(),
                  hintStyle: TextStyle(
                    fontSize: 18.0,
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: Color(COLOR_PRIMARY),
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.only(top: 12, bottom: 12),
                backgroundColor: Color(COLOR_PRIMARY),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  side: BorderSide(color: Color(COLOR_PRIMARY)),
                ),
              ),
              child: Text(
                'Sign Up'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                ),
              ),
              onPressed: () => _signUp(),
            ),
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.all(25.0),
        //   child: Center(
        //     child: Text(
        //       'or',
        //       style: TextStyle(
        //           color: isDarkMode(context) ? Colors.white : Colors.black),
        //     ).tr(),
        //   ),
        // ),
        // InkWell(
        //   onTap: () {
        //     push(context, PhoneNumberInputScreen(login: false));
        //   },
        //   child: Padding(
        //     padding: EdgeInsets.only(top: 10, right: 30, left: 30),
        //     child: Container(
        //         alignment: Alignment.bottomCenter,
        //         padding: EdgeInsets.all(10),
        //         decoration: BoxDecoration(
        //             borderRadius: BorderRadius.circular(25),
        //             border: Border.all(color: Color(COLOR_PRIMARY), width: 1)),
        //         child: Row(
        //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //             children: [
        //               Icon(
        //                 Icons.phone,
        //                 color: Color(COLOR_PRIMARY),
        //               ),
        //               Text(
        //                 "Sign Up With Phone Number".tr(),
        //                 style: TextStyle(
        //                     color: Color(COLOR_PRIMARY),
        //                     fontWeight: FontWeight.bold,
        //                     letterSpacing: 1),
        //               ),
        //             ])),
        //   ),
        // )
      ],
    );
  }

  /// dispose text controllers to avoid memory leaks
  @override
  void dispose() {
    _passwordController.dispose();
    _image = null;
    super.dispose();
  }

  /// if the fields are validated and location is enabled we create a new user
  /// and navigate to [ContainerScreen] else we show error
  _signUp() async {
    if (_key.currentState?.validate() ?? false) {
      _key.currentState!.save();
      bool userExists = await FireStoreUtils.checkIfUserExists(
        mobile!,
        'customer',
      );
      print("userExists : $userExists");
      if (userExists) {
        await hideProgress();
        showAlertDialog(
          context,
          "failed".tr(),
          "Phone Number is Already Used Please Use Another".tr(),
          true,
        );
        return;
      }
      if (referralCode.toString().isNotEmpty) {
        FireStoreUtils.checkReferralCodeValidOrNot(
          referralCode.toString(),
        ).then((value) async {
          if (value == true) {
            await _signUpWithEmailAndPassword();
          } else {
            final snack = SnackBar(
              content: Text(
                'Referral Code is Invalid'.tr(),
                style: TextStyle(color: Colors.white),
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.black,
            );
            ScaffoldMessenger.of(context).showSnackBar(snack);
          }
        });
      } else {
        await _signUpWithEmailAndPassword();
      }
    } else {
      setState(() {
        _validate = AutovalidateMode.onUserInteraction;
      });
    }
  }

  _signUpWithEmailAndPassword() async {
    await showProgress(
      context,
      "Creating new account, Please wait...".tr(),
      false,
    );
    dynamic result = await FireStoreUtils.firebaseSignUpWithEmailAndPassword(
      email!.trim(),
      password!.trim(),
      _image,
      firstName!,
      lastName!,
      mobile ?? "0",
      context,
      referralCode.toString(),
    );
    print("referralCode${referralCode}");
    await hideProgress();
    if (result != null && result is User) {
      MyAppState.currentUser = result;
      pushAndRemoveUntil(context, ContainerScreen(user: result), false);
    } else if (result != null && result is String) {
      print("zzczxczcczxc${result}");
      showAlertDialog(context, 'failed'.tr(), result, true);
    } else {
      showAlertDialog(context, 'failed'.tr(), "Couldn't sign up".tr(), true);
    }
  }
}
