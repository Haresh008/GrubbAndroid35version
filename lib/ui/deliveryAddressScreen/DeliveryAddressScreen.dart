import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/AddressModel.dart';
import 'package:foodie_customer/model/DeliveryChargeModel.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/payment/PaymentScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:place_picker/place_picker.dart';

import '../../model/NewAddressModal.dart';
import '../../model/TaxModel.dart';
import '../../model/mail_setting.dart';

class DeliveryAddressScreen extends StatefulWidget {
  static final kInitialPosition = LatLng(-33.8567844, 151.213108);

  final double total;
  final double toatvendoramount;
  final num wallamountvendor;
  final num autoapplydiscount;
  final double? discount;

  final String? couponCode;
  final String? chargepacking;
  final String? razorpayaccount;
  final String? vendoraccountnumber;
  final String? groceryitem;
  final String? couponId, notes;
  final String? couponId1;
  final List<CartProduct> products;
  final List<String>? extraAddons;
  final String? extraSize;
  final String? tipValue;
  final String? deliveryCharge;
  final bool? takeAway;
  final bool? codWallet;
  final bool? auto_apply;
  final bool? cityaveche;
  final bool? isMyTime;
  final List<TaxModel>? taxModel;
  final Map<String, dynamic>? specialDiscountMap;
  final Timestamp? scheduleTime;

  const DeliveryAddressScreen({
    Key? key,
    required this.total,
    required this.toatvendoramount,
    required this.groceryitem,
    required this.wallamountvendor,
    required this.codWallet,
    required this.auto_apply,
    required this.cityaveche,
    required this.isMyTime,
    required this.autoapplydiscount,
    this.discount,
    this.razorpayaccount,
    this.vendoraccountnumber,
    this.couponCode,
    this.couponId,
    this.chargepacking,
    required this.products,
    required this.couponId1,
    this.extraAddons,
    this.extraSize,
    this.tipValue,
    this.takeAway,
    this.specialDiscountMap,
    this.deliveryCharge,
    this.taxModel,
    this.scheduleTime,
    this.notes,
  }) : super(key: key);

  @override
  _DeliveryAddressScreenState createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  String? country;
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
  bool continue1 = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  List<NewAddressModal>? newAddressModal;

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

  Future<void> fetchAddresses() async {
    List<NewAddressModal> addresses = await FireStoreUtils().getAddresses(
      MyAppState.currentUser!.userID,
    );
    setState(() {
      newAddressModal = addresses;
    });
  }

  num? kmlkmm;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeFlutterFire();
    fetchAddresses();
    deliveryCharges = widget.deliveryCharge.toString();
    log("radiusValueradiusValueradiusValue${radiusValue}");

    print("vendor vallent smount ave che ${widget.wallamountvendor}");
    print("denishdeliveryCharges${deliveryCharges}");
    print("chargedelivery:-${widget.chargepacking}");
    print("couponIdasfasdff1:-${widget.couponId1}");
  }

  @override
  void dispose() {
    street.dispose();
    landmark.dispose();
    city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MyAppState.currentUser!.shippingAddress.country != '') {
      country = MyAppState.currentUser!.shippingAddress.country;
    }
    street.text = MyAppState.currentUser!.shippingAddress.line1;
    landmark.text = MyAppState.currentUser!.shippingAddress.line2;
    city.text = MyAppState.currentUser!.shippingAddress.city;
    zipcode.text = MyAppState.currentUser!.shippingAddress.postalCode;
    cutries.text = MyAppState.currentUser!.shippingAddress.country;
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(
      //     'Delivery Address'.tr(),
      //     style: TextStyle(
      //         color: isDarkMode(context) ? Colors.white : Colors.black),
      //   ).tr(),
      // ),
      body: Container(
        color: isDarkMode(context) ? null : Color(0XFFF1F4F7),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        print("haresh delivery chartges${deliveryCharges}");
                        print(
                          "ramala mer tame zabala fado${widget.deliveryCharge}",
                        );

                        Navigator.pop(
                          context,
                          deliveryCharges == 0.00 ||
                                  deliveryCharges == "0" ||
                                  deliveryCharges == '0.00' ||
                                  deliveryCharges == 0
                              ? widget.deliveryCharge
                              : deliveryCharges,
                        );
                      },
                      icon: Icon(Icons.arrow_back),
                      color: Color(COLOR_PRIMARY),
                      iconSize: 35,
                    ),
                    Text(
                      'Delivery Address'.tr(),
                      style: TextStyle(
                        color:
                            isDarkMode(context) ? Colors.white : Colors.black,
                      ),
                    ).tr(),
                    IconButton(onPressed: () {}, icon: Icon(null)),
                  ],
                ),
                SizedBox(height: 40),
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

                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'Country'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),

                      // ListTile(
                      //     contentPadding: const EdgeInsetsDirectional.only(
                      //         start: 5, end: 10),
                      //     subtitle: Padding(
                      //         padding: EdgeInsets.only(left: 16, right: 10),
                      //         child: Divider(
                      //           color: Color(0XFFB1BCCA),
                      //           thickness: 1.5,
                      //         )),
                      //     title: ButtonTheme(
                      //         alignedDropdown: true,
                      //         child: DropdownButtonHideUnderline(
                      //             child: DropdownButton<String>(
                      //           icon: Icon(Icons.keyboard_arrow_down_outlined),
                      //           hint: country == null
                      //               ? Text('Country'.tr())
                      //               : Text(
                      //                   country!,
                      //                   style: TextStyle(
                      //                       color: Color(COLOR_PRIMARY)),
                      //                 ),
                      //           items: <String>[
                      //             'USA',
                      //             'UK',
                      //             'India',
                      //             'France',
                      //             'Russia',
                      //             'Japan',
                      //             'UAE',
                      //             'Qatar',
                      //             'Netherland',
                      //             'Canada'
                      //           ].map((String value) {
                      //             return DropdownMenuItem<String>(
                      //               value: value,
                      //               child: Text(value),
                      //             );
                      //           }).toList(),
                      //           isExpanded: true,
                      //           iconSize: 30.0,
                      //           onChanged: (value) {
                      //             setState(() {
                      //               country = value;
                      //             });
                      //           },
                      //         )))
                      // ),
                      // leading: Container(
                      //   width: 60,
                      //   child: Text(
                      //     'Country'.tr(),
                      //     style: TextStyle(fontWeight: FontWeight.bold),
                      //   ),
                      // ),
                      // title: TextFormField(
                      //   textAlignVertical: TextAlignVertical.center,
                      //   textInputAction: TextInputAction.done,
                      //   validator: validateEmptyField,
                      //   onFieldSubmitted: (_) => validateForm(),
                      //   maxLength: 2,
                      //   onSaved: (text) => country = text,
                      //   style: TextStyle(fontSize: 18.0),
                      //   keyboardType: TextInputType.streetAddress,
                      //   cursorColor: Color(COLOR_PRIMARY),
                      //   initialValue: MyAppState.currentUser!.shippingAddress.country,
                      //   decoration: InputDecoration(
                      //     contentPadding: EdgeInsets.symmetric(horizontal: 24),
                      //     hintText: 'UK'.tr(),
                      //     hintStyle: TextStyle(color: Colors.grey.shade400),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(8.0),
                      //       borderSide:
                      //           BorderSide(color: Color(COLOR_PRIMARY), width: 2.0),
                      //     ),
                      //     errorBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Theme.of(context).errorColor),
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //     focusedErrorBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Theme.of(context).errorColor),
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //     enabledBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Colors.grey.shade300),
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //   ),
                      // ),
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
                              "Current Location".tr(),
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
                                      (context) => PlacePicker(GOOGLE_API_KEY),
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
                              log("live location ave che result par ${lat}");
                              log("live location ave che result par ${long}");
                              MyAppState
                                  .currentUser!
                                  .shippingAddress
                                  .location
                                  .latitude = result.latLng!.latitude;
                              MyAppState
                                  .currentUser!
                                  .shippingAddress
                                  .location
                                  .longitude = result.latLng!.longitude;
                              getDeliveyData();
                              setState(() {});
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      continue1 == true
                          ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Sorry, our services are currently not available in your location. We only provide services within a ${radiusValue}-kilometer radius. Please try another location closer to our service area"
                                  .tr(),
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                color: Colors.red,
                              ),
                            ),
                          )
                          : Visibility(
                            child: Text(
                              "Your new delivery charge will be".tr() +
                                  " ${amountShow(amount: deliveryCharges.toString())}",
                              style: TextStyle(fontFamily: "Poppinsm"),
                            ),
                            visible: isLocationChange,
                          ),
                      SizedBox(height: 20),

                      continue1 == true
                          ? Container()
                          : Visibility(
                            child: Text(
                              "Your new total amount will be".tr() +
                                  " ${amountShow(amount: totalamount.toString())}",
                              style: TextStyle(fontFamily: "Poppinsm"),
                            ),
                            visible: isLocationChange,
                          ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                newAddressModal?.length == 0
                    ? Container()
                    : Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                            'saved_address'.tr() + ' :',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                for (int i = 0; i < (newAddressModal?.length ?? 0); i++) ...[
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: InkWell(
                      onTap: () async {
                        MyAppState.currentUser!.location = UserLocation(
                          latitude: double.parse(
                            newAddressModal?[i].latitude ?? '',
                          ),
                          longitude: double.parse(
                            newAddressModal?[i].longitude ?? '',
                          ),
                        );

                        AddressModel userAddress = AddressModel(
                          name: MyAppState.currentUser!.fullName(),
                          postalCode: newAddressModal?[i].zipCode ?? '',
                          line1: newAddressModal?[i].street ?? '',
                          line2: newAddressModal?[i].landmark ?? '',
                          country: newAddressModal?[i].country ?? '',
                          city: newAddressModal?[i].city ?? '',
                          location: MyAppState.currentUser!.location,
                          email: MyAppState.currentUser!.email,
                        );
                        print(
                          "locationlocation${MyAppState.currentUser!.location.latitude}",
                        );
                        print(
                          "locationlocation${newAddressModal?[i].latitude ?? ''}",
                        );
                        MyAppState.currentUser!.shippingAddress = userAddress;
                        await FireStoreUtils.updateCurrentUserAddress(
                          userAddress,
                        );
                        hideProgress();

                        MyAppState.selectedPosotion = Position.fromMap({
                          'latitude': double.parse(
                            newAddressModal?[i].latitude ?? '',
                          ),
                          'longitude': double.parse(
                            newAddressModal?[i].longitude ?? '',
                          ),
                          'timestamp': 0.0,
                        });

                        String passAddress =
                            "${newAddressModal?[i].street}, ${newAddressModal?[i].landmark}, ${newAddressModal?[i].city}, ${newAddressModal?[i].zipCode}, ${newAddressModal?[i].country},${newAddressModal?[i].latitude},${newAddressModal?[i].longitude}";
                        print("passAddress${passAddress}");
                        street1.text = newAddressModal?[i].street ?? '';
                        landmark1.text = newAddressModal?[i].landmark ?? '';
                        city1.text = newAddressModal?[i].city ?? '';
                        cutries1.text = newAddressModal?[i].country ?? '';
                        zipcode1.text = newAddressModal?[i].zipCode ?? '';
                        lat = double.parse(newAddressModal?[i].latitude ?? '');
                        long = double.parse(
                          newAddressModal?[i].longitude ?? '',
                        );

                        MyAppState
                            .currentUser!
                            .shippingAddress
                            .location
                            .latitude = double.parse(
                          newAddressModal?[i].latitude ?? '',
                        );
                        MyAppState
                            .currentUser!
                            .shippingAddress
                            .location
                            .longitude = double.parse(
                          newAddressModal?[i].longitude ?? '',
                        );
                        getDeliveyData();
                        setState(() {});
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 3.5,
                          vertical: 5,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Image.asset(
                                newAddressModal?[i].addressType == 'home'
                                    ? HOME_IMG
                                    : newAddressModal?[i].addressType == 'work'
                                    ? WORK_IMG
                                    : newAddressModal?[i].addressType == 'hotel'
                                    ? HOTEL_IMG
                                    : OTHER_IMG,
                                height: 30,
                                width: 30,
                                color: Color(COLOR_PRIMARY),
                              ),
                            ),
                            SizedBox(width: 12),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.63,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (newAddressModal?[i].addressType ?? '')
                                        .capitalize(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${newAddressModal?[i].street ?? ''}, ${newAddressModal?[i].landmark ?? ''}, ${newAddressModal?[i].zipCode ?? ''}, ${newAddressModal?[i].city ?? ''}, ${newAddressModal?[i].country ?? ''}',
                                  ),
                                ],
                              ),
                            ),
                            // SizedBox(
                            //   width: 5,
                            // ),
                            // PopupMenuButton(
                            //   iconColor: Color(COLOR_PRIMARY),
                            //   itemBuilder: (context) => <PopupMenuEntry>[
                            //     PopupMenuItem(
                            //       child: Text('Edit'),
                            //       onTap: () async {
                            //         await Navigator.of(context)
                            //             .push(MaterialPageRoute(
                            //           builder: (context) =>
                            //               AddNewAddressScreen(
                            //                 collId:
                            //                 newAddressModal?[i].id ?? '',
                            //                 isEdit: true,
                            //                 city:
                            //                 newAddressModal?[i].city ?? '',
                            //                 country:
                            //                 newAddressModal?[i].country ??
                            //                     '',
                            //                 landmark:
                            //                 newAddressModal?[i].landmark ??
                            //                     '',
                            //                 street:
                            //                 newAddressModal?[i].street ??
                            //                     '',
                            //                 zip: newAddressModal?[i].zipCode ??
                            //                     '',
                            //                 lat: double.parse(
                            //                     newAddressModal?[i].latitude ??
                            //                         ''),
                            //                 lng: double.parse(
                            //                     newAddressModal?[i].longitude ??
                            //                         ''),
                            //                 addType: newAddressModal?[i]
                            //                     .addressType ==
                            //                     'home'
                            //                     ? 0
                            //                     : newAddressModal?[i]
                            //                     .addressType ==
                            //                     'work'
                            //                     ? 1
                            //                     : newAddressModal?[i]
                            //                     .addressType ==
                            //                     'hotel'
                            //                     ? 2
                            //                     : 3,
                            //               ),
                            //         ))
                            //             .then(
                            //               (value) => fetchAddresses(),
                            //         );
                            //       },
                            //     ),
                            //     PopupMenuDivider(),
                            //     PopupMenuItem(
                            //       child: Text('Delete'),
                            //       onTap: () async {
                            //         final snackBar = SnackBar(
                            //           backgroundColor: isDarkMode(context)
                            //               ? Colors.white
                            //               : Color(DARK_BG_COLOR),
                            //           content: Text(
                            //             'Address Deleted Successfully',
                            //             style: TextStyle(
                            //                 color: isDarkMode(context)
                            //                     ? Colors.black
                            //                     : Colors.white),
                            //           ),
                            //         );
                            //
                            //         await FirebaseFirestore.instance
                            //             .collection(UserAddress)
                            //             .doc(newAddressModal?[i].id)
                            //             .delete()
                            //             .then((value) => print(
                            //             'Hum Khaini Khane Jaa rhe Hain !!'));
                            //         ScaffoldMessenger.of(context)
                            //             .showSnackBar(snackBar);
                            //         fetchAddresses();
                            //       },
                            //     ),
                            //   ],
                            // )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          continue1 == true
              ? Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 25,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    backgroundColor: Color(COLOR_PRIMARY),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ("Sorry, our services are currently not available in your location. We only provide services within a ${radiusValue}-kilometer radius. Please try another location closer to our service area"),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'CONTINUE'.tr(),
                    style: TextStyle(
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 25,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    backgroundColor: Color(COLOR_PRIMARY),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    validateForm();
                    hideProgress();
                  },
                  child: Text(
                    'CONTINUE'.tr(),
                    style: TextStyle(
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
    );
  }

  VendorModel? vendorModel;
  var deliveryCharges = "0.0";
  bool isLocationChange = false;
  double? totalamount;
  double deliveryChargesDouble = 0.0;
  double deliveryChargesnum = 0.0;

  getDeliveyData() async {
    DeliveryChargeModel? deliveryChargeModel;
    print("delivery called");
    if (!widget.takeAway!) {
      print("caen id ${widget.products.first.vendorID} ");
      await FireStoreUtils()
          .getVendorByVendorID(widget.products.first.vendorID)
          .then((value) {
            vendorModel = value;
          });
      num km = num.parse(
        getKm(
          Position.fromMap({'latitude': lat, 'longitude': long}),
          Position.fromMap({
            'latitude': vendorModel!.latitude,
            'longitude': vendorModel!.longitude,
          }),
        ),
      );
      log("vendorModel!.latitude${vendorModel!.latitude}");
      log("vendorModel!.latitude${vendorModel!.longitude}");
      log("vendorModel!.latitude${lat}");
      log("vendorModel!.latitude${long}");
      log("kmkmkmkmkmkmkmkmkm${km}");
      log("kmkmkmkmkmkmkmkmkm${radiusValue}");
      print("kmkmkmkmkmkmkmkmkm${km}");

      print("123456789${deliveryChargeModel?.deliveryChargesPerKm ?? ""}");
      deliveryCharges = (49 + km * 8).toDouble().toString();
      print("deliveryChargesdeliveryCharges${deliveryCharges}");
      deliveryChargesDouble = double.parse(deliveryCharges);
      print('Juno Charge ${widget.deliveryCharge}');
      deliveryChargesnum =
          widget.deliveryCharge == '49.0'
              ? 0
              : double.parse(widget.deliveryCharge.toString());
      print('deliveryChargesnum ${deliveryChargesnum}');
      print('Hanuman Dada Total ${widget.total}'); // Convert string to double
      totalamount = deliveryChargesDouble + widget.total - deliveryChargesnum;
      print(
        "deliveryChargesDoubledeliveryChargesDouble${deliveryChargesDouble}",
      );
      print("Hello Hanuman Dada ${totalamount}");
      await FireStoreUtils().getDeliveryCharges().then((value) {
        if (value != null) {
          DeliveryChargeModel deliveryChargeModel = value;
          print("123456${deliveryCharges}");
          if (!deliveryChargeModel.vendorCanModify) {
            print("789456${deliveryCharges}");
            if (km > 1) {
              print("1010101010${deliveryCharges}");
              deliveryCharges =
                  (deliveryChargeModel.minimumDeliveryCharges +
                          km * deliveryChargeModel.deliveryChargesPerKm)
                      .toDouble()
                      .toString();
              log("newaddresschnagedeliveryCharges${deliveryCharges}");
              print("newaddresschnagedeliveryCharges${deliveryCharges}");
              log("kmkmkmkmkmkmkmkm${km}");
              deliveryChargesDouble = double.parse(deliveryCharges);

              if (radiusValue < km) {
                log("a call if call tha che ho");
                setState(() {
                  continue1 = true;
                });
              } else {
                log("else ma ave che bhai");
                setState(() {
                  continue1 = false;
                });
              }

              print(
                "deliveryChargesDoubledeliveryChargesDouble${deliveryChargesDouble}",
              );
              print(
                'Hanuman Dada Total 123456 ${widget.total}',
              ); // Convert string to double
              totalamount =
                  deliveryChargesDouble +
                  widget.total -
                  num.parse(widget.deliveryCharge.toString());
              print(
                "double.parse(deliveryCharges)${double.parse(deliveryCharges)}",
              );
              print(" widget.total${widget.total}");
              print(
                "num.parse(widget.deliveryCharge.toString())${num.parse(widget.deliveryCharge.toString())}",
              );
              print(
                "deliveryChargeModel.minimumDeliveryChargesWithinKm${deliveryChargeModel.minimumDeliveryChargesWithinKm}",
              );
              print("Hello Hanuman Dada ${totalamount}");
              if (widget.deliveryCharge != deliveryCharges) {
                isLocationChange = true;
              }
              setState(() {});
            } else {
              print("123456${deliveryCharges}");
              deliveryCharges =
                  deliveryChargeModel.minimumDeliveryCharges
                      .toDouble()
                      .toString();
              totalamount =
                  deliveryChargesDouble +
                  widget.total -
                  num.parse(deliveryCharges);
              setState(() {
                continue1 = false;
              });
              if (widget.deliveryCharge != deliveryCharges) {
                isLocationChange = true;
              }
              setState(() {});
            }
          } else {
            if (vendorModel != null && vendorModel!.deliveryCharge != null) {
              if (km > 1) {
                deliveryCharges =
                    (vendorModel!.deliveryCharge!.minimumDeliveryCharges +
                            km *
                                vendorModel!
                                    .deliveryCharge!
                                    .deliveryChargesPerKm)
                        .toDouble()
                        .toString();
                if (widget.deliveryCharge != deliveryCharges) {
                  isLocationChange = true;
                }
                setState(() {});
              } else {
                deliveryCharges =
                    vendorModel!.deliveryCharge!.minimumDeliveryCharges
                        .toDouble()
                        .toString();
                if (widget.deliveryCharge != deliveryCharges) {
                  isLocationChange = true;
                }
                setState(() {});
              }
              print(
                "delivery charges ${widget.deliveryCharge!}  dd $deliveryCharges",
              );
            } else {
              if (km > 1) {
                deliveryCharges =
                    (deliveryChargeModel.deliveryChargesPerKm +
                            km * deliveryChargeModel.deliveryChargesPerKm)
                        .toDouble()
                        .toString();
                if (widget.deliveryCharge != deliveryCharges) {
                  isLocationChange = true;
                }
                setState(() {});
              } else {
                deliveryCharges =
                    deliveryChargeModel.minimumDeliveryCharges
                        .toDouble()
                        .toString();
                if (widget.deliveryCharge != deliveryCharges) {
                  isLocationChange = true;
                }
                setState(() {});
              }
            }
          }
        }
      });
    }
  }

  validateForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      // if (country == null) {
      //   showDialog(
      //     context: context,
      //     builder: (BuildContext context) => ShowDialogToDismiss(
      //       title: 'Error'.tr(),
      //       content: 'Please Select Country'.tr(),
      //       buttonText: 'CLOSE'.tr(),
      //     ),
      //   );
      // } else
      {
        // showProgress(context, 'Saving Address...'.tr(), false);
        hideProgress();

        MyAppState.currentUser!.location = UserLocation(
          latitude:
              lat == null
                  ? MyAppState.currentUser!.shippingAddress.location.latitude ==
                          0.01
                      ? showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            content: Text(
                              "Please select current address using GPS location. Move pin to exact location"
                                  .tr(),
                            ),
                            actions: [
                              // FlatButton(
                              //   onPressed: () => Navigator.pop(
                              //       context, false), // passing false
                              //   child: Text('No'),
                              // ),
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
                      })
                      : MyAppState
                          .currentUser!
                          .shippingAddress
                          .location
                          .latitude
                  : lat,
          longitude:
              long == null
                  ? MyAppState
                              .currentUser!
                              .shippingAddress
                              .location
                              .longitude ==
                          0.01
                      ? showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            content: Text(
                              "Please select current address using GPS location. Move pin to exact location"
                                  .tr(),
                            ),
                            actions: [
                              // FlatButton(
                              //   onPressed: () => Navigator.pop(
                              //       context, false), // passing false
                              //   child: Text('No'),
                              // ),
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
                      })
                      : MyAppState
                          .currentUser!
                          .shippingAddress
                          .location
                          .longitude
                  : long,
          // locationData!.longitude,
        );

        AddressModel userAddress = AddressModel(
          name: MyAppState.currentUser!.fullName(),
          postalCode: zipcode.text.toString(),
          line1: street.text.toString(),
          line2: landmark.text.toString(),
          country: cutries.text.toString(),
          city: city.text.toString(),
          location: MyAppState.currentUser!.location,
          email: MyAppState.currentUser!.email.toString(),
        );
        MyAppState.currentUser!.shippingAddress = userAddress;
        await FireStoreUtils.updateCurrentUserAddress(userAddress);
        hideProgress();
        debugPrint('==>-  $isLocationChange');
        debugPrint(widget.total.toString());
        debugPrint(
          isLocationChange ? deliveryCharges.toString() : widget.deliveryCharge,
        );
        debugPrint(widget.couponCode!);
        hideProgress();
        debugPrint("widget.couponId!${widget.couponId!}");
        debugPrint("widget.couponId!${widget.codWallet!}");
        push(
          context,
          PaymentScreen(
            cityaveche: widget.cityaveche,
            isMyTime: widget.isMyTime,
            autoapplydiscount: widget.autoapplydiscount,
            auto_apply: widget.auto_apply,
            codWallet: widget.codWallet,
            wallamountvendor: widget.wallamountvendor,
            razorpayaccount: widget.razorpayaccount,
            vendoraccountnumber: widget.vendoraccountnumber,
            toatvendoramount: widget.toatvendoramount,
            total:
                isLocationChange
                    ? (double.parse(totalamount.toString()))
                    : widget.total,
            discount: widget.discount!,
            couponCode: widget.couponCode!,
            groceryitem: widget.groceryitem.toString(),
            couponId: widget.couponId!,
            couponId1: widget.couponId1,
            chargepacking: widget.chargepacking,
            products: widget.products,
            extraAddons: widget.extraAddons,
            tipValue: widget.tipValue,
            takeAway: widget.takeAway,
            deliveryCharge:
                isLocationChange
                    ? deliveryCharges.toString()
                    : widget.deliveryCharge,
            notes: widget.notes,
            specialDiscountMap: widget.specialDiscountMap,
            taxModel: widget.taxModel,
            scheduleTime: widget.scheduleTime,
          ),
        );
        print("ayala tu beshi ja ayala tu beshi ja ${widget.auto_apply}");
        hideProgress();
        print("couponId1: widget.couponId1,${widget.couponId1}");
      }
    } else {
      hideProgress();
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
    hideProgress();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) {
      return '';
    }
    return this[0].toUpperCase() + this.substring(1).toLowerCase();
  }
}
