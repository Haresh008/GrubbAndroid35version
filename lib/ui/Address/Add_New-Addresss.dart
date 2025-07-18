import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/NewAddressModal.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:place_picker/place_picker.dart';

import '../../model/mail_setting.dart';

class AddNewAddressScreen extends StatefulWidget {
  // static final kInitialPosition = LatLng(-33.8567844, 151.213108);
  final String? street, landmark, zip, city, country, collId;
  final bool? isEdit;
  final int? addType;
  final double? lat, lng;

  const AddNewAddressScreen({
    this.street,
    this.landmark,
    this.zip,
    this.city,
    this.country,
    this.addType,
    this.collId,
    this.lat,
    this.lng,
    required this.isEdit,
    Key? key,
  }) : super(key: key);

  @override
  _AddNewAddressScreenState createState() => _AddNewAddressScreenState();
}

class addressdata {
  String? image;
  int? id;
  String? name;

  addressdata(this.image, this.name, this.id);
}

String collectionid = '';

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // String? line1, line2, zipCode, city;
  String? country;
  int? selIdex;
  var street = TextEditingController();
  var street1 = TextEditingController();
  var landmark = TextEditingController();
  var landmark1 = TextEditingController();
  var zipcode = TextEditingController();
  var zipcode1 = TextEditingController();
  var city = TextEditingController();
  var city1 = TextEditingController();
  var cutries = TextEditingController();
  var cutries1 = TextEditingController();
  var lat;
  var long;
  bool _isChecked = false;
  String _value = 'unchecked';

  void _handleCheckboxChange(bool? newValue) {
    setState(() {
      _isChecked = newValue!;
      _value = _isChecked ? 'home' : 'unchecked';
      print("_handleCheckboxChange${_value}");
    });
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

  List<addressdata> addresstype = [
    addressdata(HOME_IMG, 'Home', 0),
    addressdata(WORK_IMG, 'Work', 1),
    // addressdata(HOTEL_IMG, 'Hotel', 2),
    addressdata(OTHER_IMG, 'Other', 3),
  ];
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeFlutterFire();
    setState(() {
      if (widget.isEdit == true) {
        street.text = widget.street ?? '';
        cutries.text = widget.country ?? '';
        city.text = widget.city ?? '';
        landmark.text = widget.landmark ?? '';
        zipcode.text = widget.zip ?? '';
        selIdex = widget.addType ?? 0;
      }
    });
  }

  @override
  void dispose() {
    street.dispose();
    landmark.dispose();
    city.dispose();
    // cutries.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('user : ${MyAppState.currentUser?.userID}');
    print('userCountry : ${MyAppState.currentUser?.shippingAddress.country}');
    if (MyAppState.currentUser != null) {
      if (MyAppState.currentUser?.shippingAddress.country != '') {
        country = MyAppState.currentUser?.shippingAddress.country;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title:
            Text(
              widget.isEdit == true ? 'edit_address'.tr() : 'add_address'.tr(),
              style: TextStyle(
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            ).tr(),
      ),
      body: Container(
        color: isDarkMode(context) ? null : Color(0XFFF1F4F7),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10),
                Card(
                  elevation: 0.5,
                  color:
                      isDarkMode(context)
                          ? Color(DARK_BG_COLOR)
                          : Color(0XFFFFFFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.only(left: 20, right: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 10, top: 5, bottom: 2),
                        child: Text(
                          'address_type'.tr() + ' :',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        height: 50,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          scrollDirection: Axis.horizontal,
                          itemCount: addresstype.length,
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selIdex = index;
                                });
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color:
                                        selIdex == index
                                            ? Color(COLOR_PRIMARY)
                                            : Color(0Xff696A75),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        addresstype[index].image ?? '',
                                        height: 20,
                                        width: 20,
                                        color:
                                            selIdex == index
                                                ? Color(COLOR_PRIMARY)
                                                : Color(0Xff696A75),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        addresstype[index].name ?? '',
                                        style: TextStyle(
                                          color:
                                              selIdex == index
                                                  ? Color(COLOR_PRIMARY)
                                                  : Color(0Xff696A75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Card(
                  elevation: 0.5,
                  color:
                      isDarkMode(context)
                          ? Color(DARK_BG_COLOR)
                          : Color(0XFFFFFFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.only(left: 20, right: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.only(
                          start: 20,
                          end: 20,
                          bottom: 10,
                        ),
                        child: TextFormField(
                          // controller: street,
                          controller: street1.text.isEmpty ? street : street1,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          validator: validateEmptyField,
                          // onSaved: (text) => line1 = text,
                          onSaved: (text) => street.text = text!,
                          style: TextStyle(fontSize: 18.0),
                          keyboardType: TextInputType.streetAddress,
                          cursorColor: Color(COLOR_PRIMARY),
                          // initialValue:
                          //     MyAppState.currentUser!.shippingAddress.line1,
                          decoration: InputDecoration(
                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                            labelText: 'Street 1'.tr(),
                            labelStyle: TextStyle(
                              color: Color(0Xff696A75),
                              fontSize: 17,
                            ),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(COLOR_PRIMARY),
                              ),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                              // borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'Street 2'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),
                      Container(
                        padding: const EdgeInsetsDirectional.only(
                          start: 20,
                          end: 20,
                          bottom: 10,
                        ),
                        child: TextFormField(
                          // controller: _controller,
                          controller:
                              landmark1.text.isEmpty ? landmark : landmark1,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          validator: validateEmptyField,
                          onSaved: (text) => landmark.text = text!,
                          style: TextStyle(fontSize: 18.0),
                          keyboardType: TextInputType.streetAddress,
                          cursorColor: Color(COLOR_PRIMARY),
                          // initialValue:
                          //     MyAppState.currentUser!.shippingAddress.line2,
                          decoration: InputDecoration(
                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                            labelText: 'Landmark'.tr(),
                            labelStyle: TextStyle(
                              color: Color(0Xff696A75),
                              fontSize: 17,
                            ),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(COLOR_PRIMARY),
                              ),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                              // borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'Zip Code'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),
                      Container(
                        padding: const EdgeInsetsDirectional.only(
                          start: 20,
                          end: 20,
                          bottom: 10,
                        ),
                        child: TextFormField(
                          controller:
                              zipcode1.text.isEmpty ? zipcode : zipcode1,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          validator: validateEmptyField,
                          onSaved: (text) => zipcode.text = text!,
                          style: TextStyle(fontSize: 18.0),
                          keyboardType: TextInputType.phone,
                          cursorColor: Color(COLOR_PRIMARY),
                          // initialValue: MyAppState
                          //     .currentUser!.shippingAddress.postalCode,
                          decoration: InputDecoration(
                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                            labelText: 'Zip Code'.tr(),
                            labelStyle: TextStyle(
                              color: Color(0Xff696A75),
                              fontSize: 17,
                            ),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(COLOR_PRIMARY),
                              ),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                              // borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'City'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),
                      Container(
                        padding: const EdgeInsetsDirectional.only(
                          start: 20,
                          end: 20,
                          bottom: 10,
                        ),
                        child: TextFormField(
                          controller: city1.text.isEmpty ? city : city1,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          validator: validateEmptyField,
                          onSaved: (text) => city.text = text!,
                          style: TextStyle(fontSize: 18.0),
                          keyboardType: TextInputType.streetAddress,
                          cursorColor: Color(COLOR_PRIMARY),
                          // initialValue:
                          //     MyAppState.currentUser!.shippingAddress.city,
                          decoration: InputDecoration(
                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                            labelText: 'City'.tr(),
                            labelStyle: TextStyle(
                              color: Color(0Xff696A75),
                              fontSize: 17,
                            ),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(COLOR_PRIMARY),
                              ),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                              // borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsetsDirectional.only(
                          start: 20,
                          end: 20,
                          bottom: 10,
                        ),
                        child: TextFormField(
                          controller:
                              cutries1.text.isEmpty ? cutries : cutries1,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          validator: validateEmptyField,
                          onSaved: (text) => cutries.text = text!,
                          style: TextStyle(fontSize: 18.0),
                          keyboardType: TextInputType.streetAddress,
                          cursorColor: Color(COLOR_PRIMARY),
                          // initialValue:
                          //     MyAppState.currentUser!.shippingAddress.city,
                          decoration: InputDecoration(
                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                            labelText: 'Country'.tr(),
                            labelStyle: TextStyle(
                              color: Color(0Xff696A75),
                              fontSize: 17,
                            ),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(COLOR_PRIMARY),
                              ),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                              // borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Card(
                          child: ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ImageIcon(
                                //   AssetImage('assets/images/current_location1.png'),
                                //   size: 23,
                                //   color: Color(COLOR_PRIMARY),
                                // ),
                                Icon(
                                  Icons.location_searching_rounded,
                                  color: Color(COLOR_PRIMARY),
                                ),
                              ],
                            ),
                            title: Text(
                              widget.isEdit == true
                                  ? "Edit Location".tr()
                                  : "Current Location".tr(),
                              style: TextStyle(color: Color(COLOR_PRIMARY)),
                            ),
                            subtitle: Text(
                              "Using GPS".tr(),
                              style: TextStyle(color: Color(COLOR_PRIMARY)),
                            ),
                            onTap: () async {
                              LocationResult result = await Navigator.of(
                                context,
                              ).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          widget.isEdit == true
                                              ? PlacePicker(
                                                GOOGLE_API_KEY,
                                                displayLocation: LatLng(
                                                  widget.lat ?? 0.0,
                                                  widget.lng ?? 0.0,
                                                ),
                                              )
                                              : PlacePicker(GOOGLE_API_KEY),
                                ),
                              );

                              street1.text = result.name.toString();
                              landmark1.text =
                                  result.subLocalityLevel1!.name == null
                                      ? result.subLocalityLevel2!.name
                                          .toString()
                                      : result.subLocalityLevel1!.name
                                          .toString();
                              city1.text = result.city!.name.toString();
                              cutries1.text = result.country!.name.toString();
                              zipcode1.text = result.postalCode.toString();
                              lat = result.latLng!.latitude;
                              long = result.latLng!.longitude;
                              setState(() {});
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 10),
                    ],
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(15),
              backgroundColor: Color(COLOR_PRIMARY),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed:
                selIdex == null
                    ? () {
                      final snackBar = SnackBar(
                        backgroundColor:
                            !isDarkMode(context)
                                ? Colors.white
                                : Color(DARK_BG_COLOR),
                        content: Text(
                          'Please Select Address Type to Continue',
                          style: TextStyle(
                            color:
                                !isDarkMode(context)
                                    ? Colors.black
                                    : Colors.white,
                          ),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                    : () {
                      // showProgress(context, 'Saving Address...'.tr(), true);

                      validateForm();

                      // String passAddress = street.text.toString() +
                      //     ", " +
                      //     landmark.text.toString() +
                      //     ", " +
                      //     city.text.toString() +
                      //     ", " +
                      //     zipcode.text.toString() +
                      //     ", " +
                      //     cutries.text.toString();
                    },
            child: Text(
              widget.isEdit == true ? 'edit'.tr() : 'ADD'.tr(),
              style: TextStyle(
                color: isDarkMode(context) ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  validateForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      if (MyAppState.currentUser != null) {
        if (MyAppState.currentUser!.shippingAddress.location.latitude == 0 &&
            MyAppState.currentUser!.shippingAddress.location.longitude == 0) {
          if (lat == 0 && long == 0) {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (_) {
                return AlertDialog(
                  content: Text(
                    "Please select current address using GPS location. Move pin to exact location"
                        .tr(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        hideProgress();
                        Navigator.pop(context, true);
                      }, // passing true
                      child: Text('OK'.tr()),
                    ),
                  ],
                );
              },
            ).then((exit) {
              if (exit == null) return;

              if (exit) {
                // user pressed Yes button
              } else {
                // user pressed No button
              }
            });
          }
        } else {
          if (lat == null || long == null || (lat == 0 && long == 0)) {
            lat = MyAppState.currentUser!.shippingAddress.location.latitude;
            long = MyAppState.currentUser!.shippingAddress.location.longitude;
            print('latitude : $lat');
            print('longitude : $long');
          }
        }

        // showProgress(context, 'Saving Address...'.tr(), true);

        MyAppState.currentUser!.location = UserLocation(
          latitude: lat,
          longitude: long,
        );
        if (widget.isEdit == true) {
          NewAddressModal userAddress = NewAddressModal(
            id: widget.collId ?? '',
            addressType:
                selIdex == 0
                    ? 'home'
                    : selIdex == 1
                    ? 'work'
                    : selIdex == 2
                    ? 'hotel'
                    : 'other',
            city: city.text,
            country: cutries.text,
            landmark: landmark.text,
            latitude: lat.toString(),
            longitude: long.toString(),
            street: street.text,
            userId: MyAppState.currentUser!.userID,
            zipCode: zipcode.text,
          );
          FirebaseFirestore.instance
              .collection(
                UserAddress,
              ) // Replace 'UserAddress' with your actual collection name
              .doc(
                widget.collId,
              ) // Replace collectionid with the document ID you want to update
              .update({
                'address_type': userAddress.addressType,
                'city': userAddress.city,
                'country': userAddress.country,
                'landmark': userAddress.landmark,
                'latitude': userAddress.latitude,
                'longitude': userAddress.longitude,
                'street': userAddress.street,
                'user_id': userAddress.userId,
                'zip_code': userAddress.zipCode,
              })
              .then((value) {
                final snackBar = SnackBar(
                  backgroundColor:
                      !isDarkMode(context)
                          ? Colors.white
                          : Color(DARK_BG_COLOR),
                  content: Text(
                    'Address Updated Successfully',
                    style: TextStyle(
                      color: !isDarkMode(context) ? Colors.black : Colors.white,
                    ),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                print("Address Updated");
                hideProgress();
              })
              .catchError((error) {
                print("Failed to update address: $error");
                hideProgress();
              });
        } else {
          setState(() {
            collectionid = RandomIdGenerator.generateRandomId();
            print('Dekh raha he Binod Yeh Id : ${collectionid}');
          });
          NewAddressModal userAddress = NewAddressModal(
            id: collectionid,
            addressType:
                selIdex == 0
                    ? 'home'
                    : selIdex == 1
                    ? 'work'
                    : 'other',
            city: city.text,
            country: cutries.text,
            landmark: landmark.text,
            latitude: lat.toString(),
            longitude: long.toString(),
            street: street.text,
            userId: MyAppState.currentUser!.userID,
            zipCode: zipcode.text,
          );
          // Insert the address data into Firestore
          FirebaseFirestore.instance
              .collection(UserAddress)
              .doc(collectionid)
              .set({
                'id': collectionid,
                'address_type': userAddress.addressType,
                'city': userAddress.city,
                'country': userAddress.country,
                'landmark': userAddress.landmark,
                'latitude': userAddress.latitude,
                'longitude': userAddress.longitude,
                'street': userAddress.street,
                'user_id': userAddress.userId,
                'zip_code': userAddress.zipCode,
              })
              .then((value) {
                final snackBar = SnackBar(
                  backgroundColor:
                      isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
                  content: Text(
                    'Address Added Successfully',
                    style: TextStyle(
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                    ),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                print("Address Added");
                hideProgress();
              })
              .catchError((error) {
                print("Failed to add address: $error");
                hideProgress();
              });
        }
      }
      MyAppState.selectedPosotion = Position.fromMap({
        'latitude': lat,
        'longitude': long,
        'timestamp': 0.0,
      });
    } else {
      hideProgress();
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
    Navigator.pop(context);
  }
}

class RandomIdGenerator {
  static String generateRandomId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const length = 10; // Adjust the length of the random ID as needed

    Random random = Random();
    String id = '';

    for (int i = 0; i < length; i++) {
      id += chars[random.nextInt(chars.length)];
    }
    return id;
  }
}
