import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/AddressModel.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/Address/Add_New-Addresss.dart';
import 'package:geolocator/geolocator.dart';
import 'package:place_picker/place_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/NewAddressModal.dart';
import '../../model/mail_setting.dart';

class CurrentAddressChangeScreen extends StatefulWidget {
  static final kInitialPosition = LatLng(-33.8567844, 151.213108);

  const CurrentAddressChangeScreen({Key? key}) : super(key: key);

  @override
  _CurrentAddressChangeScreenState createState() =>
      _CurrentAddressChangeScreenState();
}

class _CurrentAddressChangeScreenState
    extends State<CurrentAddressChangeScreen> {
  final _formKey = GlobalKey<FormState>();

  // String? line1, line2, zipCode, city;
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
  bool _isChecked = false;
  String _value = 'unchecked';
  List<NewAddressModal>? newAddressModal;

  Future<void> fetchAddresses() async {
    List<NewAddressModal> addresses = await FireStoreUtils().getAddresses(
      MyAppState.currentUser!.userID,
    );
    setState(() {
      newAddressModal = addresses;
    });
  }

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

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeFlutterFire();
    fetchAddresses();
  }

  @override
  void dispose() {
    street.dispose();
    landmark.dispose();
    city.dispose();
    // cutries.dispose();
    super.dispose();
  }

  Future<void> saveAddressState(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('address_state', value);
  }

  @override
  Widget build(BuildContext context) {
    print('user : ${MyAppState.currentUser?.userID}');
    print('userCountry : ${MyAppState.currentUser?.shippingAddress.country}');
    if (MyAppState.currentUser != null) {
      if (MyAppState.currentUser?.shippingAddress.country != '') {
        country = MyAppState.currentUser?.shippingAddress.country;
      }
      street.text = MyAppState.currentUser?.shippingAddress.line1 ?? '';
      landmark.text = MyAppState.currentUser?.shippingAddress.line2 ?? '';
      city.text = MyAppState.currentUser?.shippingAddress.city ?? '';
      zipcode.text = MyAppState.currentUser?.shippingAddress.postalCode ?? '';
      cutries.text = MyAppState.currentUser?.shippingAddress.country ?? '';
    }
    return Scaffold(
      appBar: AppBar(
        title:
            Text(
              'Change Address'.tr(),
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
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                MyAppState.currentUser == null
                    ? Container()
                    : newAddressModal?.length == 0
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
                  Container(
                    width: MediaQuery.of(context).size.width * .97,
                    child: Card(
                      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                      child: InkWell(
                        onTap: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.remove('postalCode');
                          await prefs.remove('line1');
                          await prefs.remove('line2');
                          await prefs.remove('country');
                          await prefs.remove('city');
                          await prefs.remove('latitude');
                          await prefs.remove(
                            'longitude',
                          ); // Clears all stored data

                          // Store address details in SharedPreferences
                          await prefs.setString(
                            'postalCode',
                            newAddressModal?[i].zipCode ?? '',
                          );
                          await prefs.setString(
                            'line1',
                            newAddressModal?[i].street ?? '',
                          );
                          await prefs.setString(
                            'line2',
                            newAddressModal?[i].landmark ?? '',
                          );
                          await prefs.setString(
                            'country',
                            newAddressModal?[i].country ?? '',
                          );
                          await prefs.setString(
                            'city',
                            newAddressModal?[i].city ?? '',
                          );

                          // Store latitude and longitude
                          await prefs.setDouble(
                            'latitude',
                            double.parse(newAddressModal?[i].latitude ?? ''),
                          );
                          await prefs.setDouble(
                            'longitude',
                            double.parse(newAddressModal?[i].longitude ?? ''),
                          );

                          // Log the saved postal code for debugging
                          print(
                            "SharedPreferences ${prefs.getString('postalCode')}",
                          );

                          // Update current user location
                          MyAppState.currentUser!.location = UserLocation(
                            latitude: prefs.getDouble('latitude') ?? 0.0,
                            longitude: prefs.getDouble('longitude') ?? 0.0,
                          );
                          print(
                            "shu lat log ave che chek karo ${prefs.getDouble('latitude')}",
                          );
                          print(
                            "shu lat log ave che chek karo ${prefs.getDouble('longitude')}",
                          );

                          // MyAppState.currentUser!.location = UserLocation(
                          //   latitude:
                          //       double.parse(newAddressModal?[i].latitude ?? ''),
                          //   longitude:
                          //       double.parse(newAddressModal?[i].longitude ?? ''),
                          // );
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

                          updateUserLocation(
                            MyAppState.currentUser?.userID ?? "",
                            double.parse(newAddressModal?[i].latitude ?? ''),
                            MyAppState.selectedPosotion.longitude,
                          );
                          print(
                            "newAddressModal?[i].latitude ?? ''${newAddressModal?[i].latitude ?? ''}",
                          );

                          // String passAddress =
                          //     (newAddressModal?[i].street).toString() +
                          //         ", " +
                          //         (newAddressModal?[i].landmark).toString() +
                          //         ", " +
                          //         (newAddressModal?[i].city).toString() +
                          //         ", " +
                          //         (newAddressModal?[i].zipCode).toString() +
                          //         ", " +
                          //         (newAddressModal?[i].country).toString();
                          String passAddress =
                              "${prefs.getString('line1')}, ${prefs.getString('line2')}, ${prefs.getString('city')}, ${prefs.getString('postalCode')}, ${prefs.getString('country')}";
                          Navigator.pop(context, passAddress);
                          setState(() async {
                            addrss = true;
                            await saveAddressState(addrss);
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8,
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
                                      : newAddressModal?[i].addressType ==
                                          'work'
                                      ? WORK_IMG
                                      : newAddressModal?[i].addressType ==
                                          'hotel'
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
                              SizedBox(width: 5),
                              PopupMenuButton(
                                iconColor: Color(COLOR_PRIMARY),
                                itemBuilder:
                                    (context) => <PopupMenuEntry>[
                                      PopupMenuItem(
                                        child: Text('Edit'),
                                        onTap: () async {
                                          await Navigator.of(context)
                                              .push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => AddNewAddressScreen(
                                                        collId:
                                                            newAddressModal?[i]
                                                                .id ??
                                                            '',
                                                        isEdit: true,
                                                        city:
                                                            newAddressModal?[i]
                                                                .city ??
                                                            '',
                                                        country:
                                                            newAddressModal?[i]
                                                                .country ??
                                                            '',
                                                        landmark:
                                                            newAddressModal?[i]
                                                                .landmark ??
                                                            '',
                                                        street:
                                                            newAddressModal?[i]
                                                                .street ??
                                                            '',
                                                        zip:
                                                            newAddressModal?[i]
                                                                .zipCode ??
                                                            '',
                                                        lat: double.parse(
                                                          newAddressModal?[i]
                                                                  .latitude ??
                                                              '',
                                                        ),
                                                        lng: double.parse(
                                                          newAddressModal?[i]
                                                                  .longitude ??
                                                              '',
                                                        ),
                                                        addType:
                                                            newAddressModal?[i]
                                                                        .addressType ==
                                                                    'home'
                                                                ? 0
                                                                : newAddressModal?[i]
                                                                        .addressType ==
                                                                    'work'
                                                                ? 1
                                                                : newAddressModal?[i]
                                                                        .addressType ==
                                                                    'hotel'
                                                                ? 2
                                                                : 3,
                                                      ),
                                                ),
                                              )
                                              .then(
                                                (value) => fetchAddresses(),
                                              );
                                        },
                                      ),
                                      PopupMenuDivider(),
                                      PopupMenuItem(
                                        child: Text('Delete'),
                                        onTap: () async {
                                          final snackBar = SnackBar(
                                            backgroundColor:
                                                isDarkMode(context)
                                                    ? Colors.white
                                                    : Color(DARK_BG_COLOR),
                                            content: Text(
                                              'Address Deleted Successfully',
                                              style: TextStyle(
                                                color:
                                                    isDarkMode(context)
                                                        ? Colors.black
                                                        : Colors.white,
                                              ),
                                            ),
                                          );

                                          await FirebaseFirestore.instance
                                              .collection(UserAddress)
                                              .doc(newAddressModal?[i].id)
                                              .delete()
                                              .then(
                                                (value) => print(
                                                  'Hum Khaini Khane Jaa rhe Hain !!',
                                                ),
                                              );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(snackBar);
                                          fetchAddresses();
                                        },
                                      ),
                                    ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                newAddressModal?.length == 0
                    ? Container()
                    : SizedBox(height: 10),
                MyAppState.currentUser == null
                    ? Container()
                    : InkWell(
                      onTap: () async {
                        await Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AddNewAddressScreen(isEdit: false),
                              ),
                            )
                            .then((value) => fetchAddresses());
                      },
                      child: Card(
                        elevation: 0.5,
                        color:
                            isDarkMode(context)
                                ? Color(DARK_BG_COLOR)
                                : Color(0XFFFFFFFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.only(left: 20, right: 20),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.add,
                                size: 18,
                                color: Color(COLOR_PRIMARY),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'add_address'.tr(),
                                style: TextStyle(
                                  color: Color(COLOR_PRIMARY),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                MyAppState.currentUser == null
                    ? () {
                      final snackBar = SnackBar(
                        backgroundColor:
                            !isDarkMode(context)
                                ? Colors.white
                                : Color(DARK_BG_COLOR),
                        content: Text(
                          'Please login to save your address',
                          style: TextStyle(
                            color:
                                !isDarkMode(context)
                                    ? Colors.red
                                    : Colors.white,
                          ),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                    : city1.text == "null"
                    ? () {
                      print("city.text${city1.text}");
                      final snackBar = SnackBar(
                        backgroundColor:
                            !isDarkMode(context)
                                ? Colors.white
                                : Color(DARK_BG_COLOR),
                        content: Text(
                          'Please Select City',
                          style: TextStyle(
                            color:
                                !isDarkMode(context)
                                    ? Colors.red
                                    : Colors.white,
                          ),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                    : () {
                      // showProgress(context, 'Saving Address...'.tr(), true);

                      validateForm();
                    },
            child: Text(
              'DONE'.tr(),
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
    print("a call tha che ho");
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      {
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
              updateUserLocation(
                MyAppState.currentUser!.userID ?? "",
                double.parse(
                  MyAppState.currentUser!.location.latitude.toString(),
                ),
                double.parse(
                  MyAppState.currentUser!.location.longitude.toString(),
                ),
              );
            } else {
              // showProgress(context, 'Saving Address...'.tr(), true);
              print('Ayya Else Ma');
              MyAppState.currentUser!.location = UserLocation(
                latitude: lat,
                longitude: long,
              );
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('postalCode');
              await prefs.remove('line1');
              await prefs.remove('line2');
              await prefs.remove('country');
              await prefs.remove('city');
              await prefs.remove('latitude');
              await prefs.remove('longitude'); // Clears all stored data

              // Store address details in SharedPreferences
              await prefs.setString('postalCode', zipcode.text);
              await prefs.setString('line1', street.text);
              await prefs.setString('line2', landmark.text);
              await prefs.setString('country', cutries.text);
              await prefs.setString('city', city.text);

              // Store latitude and longitude
              await prefs.setDouble(
                'latitude',
                double.parse(
                  MyAppState.currentUser!.location.latitude.toString(),
                ),
              );
              await prefs.setDouble(
                'longitude',
                double.parse(
                  MyAppState.currentUser!.location.longitude.toString(),
                ),
              );
              MyAppState.currentUser!.location = UserLocation(
                latitude: prefs.getDouble('latitude') ?? 0.0,
                longitude: prefs.getDouble('longitude') ?? 0.0,
              );
              print(
                "prefs.getDouble('latitude')${prefs.getDouble('latitude')}",
              );
              print(
                "prefs.getDouble('latitude')${prefs.getDouble('longitude')}",
              );
              updateUserLocation(
                MyAppState.currentUser!.userID ?? "",
                double.parse(
                  MyAppState.currentUser!.location.latitude.toString(),
                ),
                double.parse(
                  MyAppState.currentUser!.location.longitude.toString(),
                ),
              );
              AddressModel userAddress = AddressModel(
                name: MyAppState.currentUser!.fullName(),
                postalCode: zipcode.text,
                line1: street.text,
                line2: landmark.text,
                country: cutries.text,
                city: city.text,
                location: MyAppState.currentUser!.location,
                email: MyAppState.currentUser!.email,
              );
              MyAppState.currentUser!.shippingAddress = userAddress;
              await FireStoreUtils.updateCurrentUserAddress(userAddress);
              hideProgress();
              hideProgress();
              MyAppState.selectedPosotion = Position.fromMap({
                'latitude': lat,
                'longitude': long,
                'timestamp': 0.0,
              });
              // String passAddress = street.text.toString() +
              //     ", " +
              //     landmark.text.toString() +
              //     ", " +
              //     city.text.toString() +
              //     ", " +
              //     zipcode.text.toString() +
              //     ", " +
              //     cutries.text.toString();
              String passAddress =
                  "${prefs.getString('line1')}, ${prefs.getString('line2')}, ${prefs.getString('city')}, ${prefs.getString('postalCode')}, ${prefs.getString('country')}";
              setState(() {
                addrss = true;
                saveAddressState(addrss);
              });
              Navigator.pop(context, passAddress);
            }
          }
        }
      }
    } else {
      hideProgress();
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }
}

Future<void> updateUserLocation(
  String userId,
  double latitude,
  double longitude,
) async {
  try {
    // FirebaseFirestore નો રેફરન્સ મેળવો
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // latitude અને longitude અપડેટ કરો
    await docRef.update({
      'location': {'latitude': latitude, 'longitude': longitude},
    });

    print('Location updated successfully!');
  } catch (e) {
    print('Error updating location: $e');
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
