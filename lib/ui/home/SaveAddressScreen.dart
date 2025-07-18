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
import 'package:foodie_customer/ui/container/ContainerScreen.dart';
import 'package:foodie_customer/ui/home/HomeScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:place_picker/place_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/NewAddressModal.dart';
import '../../model/mail_setting.dart';

class SaveAddressScreen extends StatefulWidget {
  static final kInitialPosition = LatLng(-33.8567844, 151.213108);

  const SaveAddressScreen({Key? key}) : super(key: key);

  @override
  _SaveAddressScreenState createState() => _SaveAddressScreenState();
}

class _SaveAddressScreenState extends State<SaveAddressScreen> {
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
      // appBar: AppBar(
      //   title: Text(
      //     'Change Address'.tr(),
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
                SizedBox(height: 10),
                for (int i = 0; i < (newAddressModal?.length ?? 0); i++) ...[
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.remove('postalCode');
                        await prefs.remove('line1');
                        await prefs.remove('line2');
                        await prefs.remove('country');
                        await prefs.remove('city');
                        await prefs.remove('latitude');
                        await prefs.remove('longitude');
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
                        print(
                          "SharedPreferences${prefs.getString('postalCode')}",
                        );
                        // Store location
                        MyAppState.currentUser!.location = UserLocation(
                          latitude: prefs.getDouble('latitude') ?? 0.0,
                          longitude: prefs.getDouble('longitude') ?? 0.0,
                        );

                        String passAddress =
                            "${newAddressModal?[i].street}, ${newAddressModal?[i].landmark}, ${newAddressModal?[i].city}, ${newAddressModal?[i].zipCode}, ${newAddressModal?[i].country},${newAddressModal?[i].latitude},${newAddressModal?[i].longitude}";
                        print("passAddress${passAddress}");
                        print("passAddress: $passAddress");

                        // Save the passAddress to SharedPreferences
                        savePassAddress(passAddress);
                        print("savePassAddress123456: $savePassAddress");
                        MyAppState.street = newAddressModal?[i].street ?? '';
                        MyAppState.landmark =
                            newAddressModal?[i].landmark ?? '';
                        MyAppState.city = newAddressModal?[i].city ?? '';
                        MyAppState.zipCode = newAddressModal?[i].zipCode ?? '';
                        MyAppState.country = newAddressModal?[i].country ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ContainerScreen(
                                  user: MyAppState.currentUser,
                                  appBarTitle: 'Home'.tr(),
                                  currentWidget: HomeScreen(
                                    user: MyAppState.currentUser,
                                    address: passAddress,
                                  ),
                                ),
                            // HomeScreen(address: passAddress,user:MyAppState.currentUser,),
                          ),
                        );
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //       builder: (context) => ContainerScreen(
                        //             user: MyAppState.currentUser,
                        //             appBarTitle: 'Home'.tr(),
                        //             currentWidget: HomeScreen(
                        //               user: MyAppState.currentUser,
                        //               address: passAddress,
                        //             ),
                        //           )
                        //       // HomeScreen(address: passAddress,user:MyAppState.currentUser,),
                        //       ),
                        // );
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
                                            .then((value) => fetchAddresses());
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
                ],
                newAddressModal?.length == 0
                    ? Container()
                    : SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    await Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder:
                                (context) => AddNewAddressScreen(isEdit: false),
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
            onPressed: () {
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
            } else {
              // showProgress(context, 'Saving Address...'.tr(), true);
              print('Ayya Else Ma');
              MyAppState.currentUser!.location = UserLocation(
                latitude: lat,
                longitude: long,
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
              String passAddress =
                  street.text.toString() +
                  ", " +
                  landmark.text.toString() +
                  ", " +
                  city.text.toString() +
                  ", " +
                  zipcode.text.toString() +
                  ", " +
                  cutries.text.toString();
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

Future<void> savePassAddress(String passAddress) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('passAddress', passAddress);
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) {
      return '';
    }
    return this[0].toUpperCase() + this.substring(1).toLowerCase();
  }
}
