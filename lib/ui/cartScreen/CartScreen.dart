import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/DeliveryChargeModel.dart';
import 'package:foodie_customer/model/ProductModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/model/offer_model.dart';
import 'package:foodie_customer/model/variant_info.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/deliveryAddressScreen/DeliveryAddressScreen.dart';
import 'package:foodie_customer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/TaxModel.dart';
import '../../model/mail_setting.dart';
import '../payment/PaymentScreen.dart';

class CartScreen extends StatefulWidget {
  final bool fromContainer;
  bool? isopen;
  final String? packingCharge;

  CartScreen({
    Key? key,
    this.fromContainer = false,
    this.packingCharge,
    this.isopen,
  }) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<CartProduct>> cartFuture;
  late List<CartProduct> cartProducts = [];

  //coupan
  var nameCoupon = "Apply";
  final TextEditingController couponTextField = TextEditingController();
  var editableCoupon = true;
  String? deliveryChargesToShow;
  double subTotal = 0.0;
  double subTotal1 = 0.0;
  double bevafapdama = 0.0;
  double razorpayvendoramounttrafar = 0.0;
  double toatvendoramount = 0.0;

  String formatTime12Hour(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate(); // Timestamp ને DateTime માં ફેરવો
    return DateFormat(
      "hh:mm a",
    ).format(dateTime); // 12-કલાકના AM/PM ફોર્મેટમાં ફેરવો
  }

  double specialDiscount = 0.0;
  double specialDiscountAmount = 0.0;
  String specialType = "";
  String coponid123 = "";
  bool isSchedule = false;
  bool isLiveandScheduled = false;

  TextEditingController noteController = TextEditingController(text: '');
  late CartDatabase cartDatabase;
  double grandtotal = 00.0;
  double discountAmount = 00.0;
  num? charge;
  int? quantitycharge;
  var per = 0.0;
  late Future<List<OfferModel>> coupon;
  TextEditingController txt = TextEditingController(text: '');
  FireStoreUtils _fireStoreUtils = FireStoreUtils();
  String vendorID = "";
  late List<AddAddonsDemo> lstExtras = [];
  late List<String> commaSepratedAddOns = [];
  late List<String> commaSepratedAddSize = [];
  String? commaSepratedAddOnsString = "";
  String? commaSepratedAddSizeString = "";
  String? adminCommissionValue = "", addminCommissionType = "";
  bool? isEnableAdminCommission = false;
  var deliveryCharges = "0.0";
  VendorModel? vendorModel;
  String? selctedOrderTypeValue = "Delivery";
  bool isDeliverFound = false;
  var tipValue = 0.0;
  bool isTipSelected = false,
      isTipSelected1 = false,
      isTipSelected2 = false,
      isTipSelected3 = false;
  TextEditingController _textFieldController = TextEditingController();
  String? Dynamicminutes;
  late Map<String, dynamic>? adminCommission;

  Timestamp? scheduleTime;
  Timestamp? scheduleTime1;
  String? deleverychargeshare;

  Future<String?> fetchScheduleOrderMinutes() async {
    try {
      // Reference to Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get the document from the collection
      DocumentSnapshot docSnapshot =
          await firestore
              .collection('settings')
              .doc('orderCancellationMinutes')
              .get();

      // Check if the document exists
      if (docSnapshot.exists) {
        // Access the 'scheduleOrderMinutes' field as a string
        var data = docSnapshot.data() as Map<String, dynamic>;
        return data['scheduleOrderMinutes']?.toString();
      } else {
        print("Document does not exist!");
        return null;
      }
    } catch (e) {
      print("Error fetching scheduleOrderMinutes: $e");
      return null;
    }
  }

  void getScheduleOrderMinutes() async {
    Dynamicminutes = await fetchScheduleOrderMinutes();
    if (Dynamicminutes != null) {
      print("Schedule Order Minutes as String: $Dynamicminutes");
    } else {
      print("Failed to fetch scheduleOrderMinutes.");
    }
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

  String? commissionType;
  double? fixCommission;
  bool isEnabled = false;
  bool isload = true;

  Future<void> fetchAdminCommission() async {
    try {
      // Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Document reference for "AdminCommission"
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await firestore.collection('settings').doc('AdminCommission').get();

      if (docSnapshot.exists) {
        // Get data from the document
        Map<String, dynamic>? data = docSnapshot.data();

        if (data != null) {
          // Extract specific fields
          commissionType = data['commissionType'] ?? 'N/A';
          fixCommission = data['fix_commission']?.toDouble() ?? 0.0;
          isEnabled = data['isEnabled'] ?? false;

          // Print the values
          print('Commission Type: $commissionType');
          print('Fix Commission: $fixCommission');
          print('Is Enabled: $isEnabled');
        }
      } else {
        print('Document does not exist!');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    coupon = _fireStoreUtils.getAllCoupons();
    fetchAdminCommission();
    getFoodType();
    initializeFlutterFire();
    print(
      "location ave che${MyAppState.currentUser?.location?.latitude ?? ""}",
    );
    print(
      "location ave che${MyAppState.currentUser?.location?.longitude ?? ""}",
    );
    print("lstExtras${lstExtras}");
    print("couponIdasfasdff1:-${deliveryCharges}");
    print("===============>>>>>>>>>>>>>>>>>:-${vendorModel?.title ?? ""}");
    print(
      "vendorModeldhhghghfghfghfgh:-${vendorModel?.razorpayBankAcname ?? ""}",
    );
  }

  getFoodType() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    setState(() {
      selctedOrderTypeValue =
          sp.getString("foodType") == "" || sp.getString("foodType") == null
              ? "Delivery"
              : sp.getString("foodType");
    });
  }

  String? vendorbankholdername;
  num? wallamountvendor;
  String? rzorpaybankaccountnumber;
  String? ScheduledHrs;
  String? vendoridvendorid;

  bool? codWallet;

  // haresh bhai code
  // Future<void> getDeliveyData() async {
  //   isDeliverFound = true;
  //   await _fireStoreUtils
  //       .getVendorByVendorID(cartProducts.first.vendorID)
  //       .then((value) {
  //     vendorModel = value;
  //
  //
  //     setState(() {
  //       vendoridvendorid=cartProducts.first.vendorID;
  //       vendorbankholdername = vendorModel?.razorpayBankAcname ?? "";
  //       rzorpaybankaccountnumber = vendorModel?.razorpayBankAcno ?? "";
  //       isSchedule = vendorModel!.isScheduled;
  //       isLiveandScheduled = vendorModel!.isLiveandScheduled;
  //       wallamountvendor = vendorModel!.walletAmount;
  //       // wallamountvendor = vendorModel!.walletAmount;
  //       codWallet = vendorModel?.codWallet;
  //       print("vendoridvendoridvendoridvendoridvendoridvendorid${vendoridvendorid}");
  //       print("codWalletcodWalletcodWallet${codWallet}");
  //       print("wallamountvendor wallamountvendor${wallamountvendor}");
  //       print("vendorbank holder name${vendorbankholdername}");
  //       print("vendor modal razorpay data${rzorpaybankaccountnumber}");
  //       print("Vendor Schedule:-${isSchedule}");
  //       print("Vendor Scheduled Hrs:-${ScheduledHrs}");
  //       fetchWorkingHours();
  //     });
  //     // print("vendor modal razorpay data${vendorModel?.razorpayBankAcname ?? ""}");
  //   });
  //
  //   if (selctedOrderTypeValue == "Delivery") {
  //
  //     num km = num.parse(getKm(
  //
  //         // MyAppState.selectedPosotion,
  //         Position.fromMap({'latitude':addrss?MyAppState.currentUser!.shippingAddress.location.latitude==0.01?MyAppState.selectedPosotion.latitude:MyAppState.currentUser!.shippingAddress.location.latitude:MyAppState.selectedPosotion.latitude, 'longitude': addrss? MyAppState.currentUser!.shippingAddress.location.longitude==0.01?MyAppState.selectedPosotion.longitude:MyAppState.currentUser!.shippingAddress.location.longitude:MyAppState.selectedPosotion.longitude}),
  //         Position.fromMap({
  //           'latitude': vendorModel!.latitude,
  //           'longitude': vendorModel!.longitude
  //         })));
  //     print("hkkm${km}");
  //     _fireStoreUtils.getDeliveryCharges().then((value) {
  //       if (value != null) {
  //         DeliveryChargeModel deliveryChargeModel = value;
  //
  //         if (!deliveryChargeModel.vendorCanModify) {
  //           if (km > 1) {
  //             deliveryCharges = (deliveryChargeModel.minimumDeliveryCharges +
  //                     km * deliveryChargeModel.deliveryChargesPerKm)
  //                 .toDouble()
  //                 .toString();
  //             print("zxczxczxczxczxcckm${km}");
  //             print("deliveryCharges${deliveryCharges}");
  //             print("freeDeliveryWallet${vendorModel!.freeDeliveryWallet}");
  //             print("freeDelivery${vendorModel!.freeDelivery}");
  //             setState(() {});
  //           } else {
  //             // deliveryCharges = deliveryChargeModel.minimumDeliveryCharges
  //             //     .toDouble()
  //             //     .toString();
  //             print("bhai katala km cho tu ${km}");
  //             deliveryCharges = km <=
  //                     num.parse(
  //                         deliveryChargeModel.deliveryChargesPerKm.toString())
  //                 ? deliveryChargeModel.minimumDeliveryChargesWithinKm
  //                     .toDouble()
  //                     .toString()
  //                 : (deliveryChargeModel.minimumDeliveryCharges +
  //                         km * deliveryChargeModel.deliveryChargesPerKm)
  //                     .toDouble()
  //                     .toString();
  //
  //             print("deliveryCharges123456${deliveryCharges}");
  //             setState(() {});
  //           }
  //         } else {
  //           if (vendorModel != null && vendorModel!.deliveryCharge != null) {
  //             if (km > 1) {
  //               deliveryCharges = (vendorModel!
  //                           .deliveryCharge!.minimumDeliveryCharges +
  //                       km * vendorModel!.deliveryCharge!.deliveryChargesPerKm)
  //                   .toDouble()
  //                   .toString();
  //               print("jaylo guruji${deliveryCharges}");
  //               setState(() {});
  //             } else {
  //               deliveryCharges = vendorModel!
  //                   .deliveryCharge!.minimumDeliveryCharges
  //                   .toDouble()
  //                   .toString();
  //               setState(() {});
  //             }
  //           } else {
  //             if (km > 1) {
  //               deliveryCharges = (deliveryChargeModel.minimumDeliveryCharges +
  //                       km * deliveryChargeModel.deliveryChargesPerKm)
  //                   .toDouble()
  //                   .toString();
  //               print("ramla mer${deliveryCharges}");
  //               setState(() {});
  //             } else {
  //               deliveryCharges = deliveryChargeModel.minimumDeliveryCharges
  //                   .toDouble()
  //                   .toString();
  //               print("hariyomer${deliveryCharges}");
  //               setState(() {});
  //             }
  //           }
  //         }
  //       }
  //     });
  //   }
  //
  // }

  Future<void> getDeliveyData() async {
    isDeliverFound = true;

    await _fireStoreUtils.getVendorByVendorID(cartProducts.first.vendorID).then(
      (value) {
        vendorModel = value;

        setState(() {
          vendoridvendorid = cartProducts.first.vendorID;
          vendorbankholdername = vendorModel?.razorpayBankAcname ?? "";
          rzorpaybankaccountnumber = vendorModel?.razorpayBankAcno ?? "";
          isSchedule = vendorModel!.isScheduled;
          isLiveandScheduled = vendorModel!.isLiveandScheduled;
          wallamountvendor = vendorModel!.walletAmount;
          codWallet = vendorModel?.codWallet;

          print("vendor ID: $vendoridvendorid");
          print("codWallet: $codWallet");
          print("walletAmount: $wallamountvendor");
          print("Bank holder name: $vendorbankholdername");
          print("Razorpay account number: $rzorpaybankaccountnumber");
          print("Vendor Schedule: $isSchedule");
          print("Scheduled Hours: $ScheduledHrs");

          fetchWorkingHours();
        });
      },
    );

    if (selctedOrderTypeValue == "Delivery") {
      num km = num.parse(
        getKm(
          Position.fromMap({
            // 'latitude': addrss
            //     ? (MyAppState.currentUser!.shippingAddress.location.latitude ==
            //             0.01
            //         ? MyAppState.selectedPosotion.latitude
            //         : MyAppState.currentUser!.shippingAddress.location.latitude)
            //     : MyAppState.selectedPosotion.latitude,
            // 'longitude': addrss
            //     ? (MyAppState.currentUser!.shippingAddress.location.longitude ==
            //             0.01
            //         ? MyAppState.selectedPosotion.longitude
            //         : MyAppState.currentUser!.shippingAddress.location.longitude)
            //     : MyAppState.selectedPosotion.longitude
            'latitude':
                MyAppState.currentUser == null ||
                        MyAppState.currentUser?.userID == null ||
                        MyAppState.currentUser?.userID == ""
                    ? MyAppState.selectedPosotion.latitude
                    : MyAppState.currentUser?.location.latitude == 0.01
                    ? MyAppState.selectedPosotion.latitude
                    : double.parse(
                      (MyAppState.currentUser?.location.latitude).toString(),
                    ),
            'longitude':
                MyAppState.currentUser == null ||
                        MyAppState.currentUser?.userID == null ||
                        MyAppState.currentUser?.userID == ""
                    ? MyAppState.selectedPosotion.longitude
                    : MyAppState.currentUser?.location.longitude == 0.01
                    ? MyAppState.selectedPosotion.longitude
                    : double.parse(
                      (MyAppState.currentUser?.location.longitude).toString(),
                    ),
          }),
          Position.fromMap({
            'latitude': vendorModel!.latitude,
            'longitude': vendorModel!.longitude,
          }),
        ),
      );

      print("Distance in KM: $km");

      _fireStoreUtils.getDeliveryCharges().then((value) {
        if (value != null) {
          DeliveryChargeModel deliveryChargeModel = value;

          // Step 1: calculate actual deliveryCharges (will be used for backend)
          if (!deliveryChargeModel.vendorCanModify) {
            if (km > 1) {
              deliveryCharges =
                  (deliveryChargeModel.minimumDeliveryCharges +
                          km * deliveryChargeModel.deliveryChargesPerKm)
                      .toDouble()
                      .toString();
              print("khushi shu ave che ${deliveryCharges}");
            } else {
              deliveryCharges =
                  km <= deliveryChargeModel.deliveryChargesPerKm.toDouble()
                      ? deliveryChargeModel.minimumDeliveryChargesWithinKm
                          .toDouble()
                          .toString()
                      : (deliveryChargeModel.minimumDeliveryCharges +
                              km * deliveryChargeModel.deliveryChargesPerKm)
                          .toDouble()
                          .toString();
              print("dipti shu ave che ${deliveryCharges}");
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
                print("hiren shu ave che ${deliveryCharges}");
              } else {
                deliveryCharges =
                    vendorModel!.deliveryCharge!.minimumDeliveryCharges
                        .toDouble()
                        .toString();
                print("jay shu ave che ${deliveryCharges}");
              }
            } else {
              if (km > 1) {
                deliveryCharges =
                    (deliveryChargeModel.minimumDeliveryCharges +
                            km * deliveryChargeModel.deliveryChargesPerKm)
                        .toDouble()
                        .toString();
                print("haresh shu ave che ${deliveryCharges}");
              } else {
                deliveryCharges =
                    deliveryChargeModel.minimumDeliveryCharges
                        .toDouble()
                        .toString();
                print("ram shu ave che ${deliveryCharges}");
              }
            }
          }

          // Step 2: Calculate display version of charges for UI
          deliveryChargesToShow = deliveryCharges;

          if (vendorModel!.freeDelivery == true && deliveryCharges != null) {
            num deliveryChargeNum = num.tryParse(deliveryCharges!) ?? 0;
            num walletAmount = vendorModel!.freeDeliveryWallet ?? 0;

            if (walletAmount >= deliveryChargeNum) {
              deliveryChargesToShow = "0";
            } else {
              if (num.parse((vendorModel!.freeDeliveryWallet).toString()) <
                  num.parse(
                    (vendorModel!.deliveryCharge?.minimumDeliveryCharges)
                        .toString(),
                  )) {
                updateFreeDelivery1(
                  false,
                  vendorModel!.freeDeliveryWallet,
                  vendorModel?.id,
                );
                deliveryChargesToShow = deliveryCharges;
              }
            }
            print(
              "Free Delivery Wallet applied. Display Charges:a $deliveryChargesToShow",
            );
          }
          setState(() {});
        }
      });
    }
  }

  Future<void> updateFreeDelivery1(
    bool freeDelivery,
    freeDeliveryWallet,
    verdorid,
  ) {
    return FirebaseFirestore.instance
        .collection('vendors')
        .doc(verdorid)
        .update({
          'freeDeliveryWallet': freeDeliveryWallet,
          'freeDelivery': freeDelivery,
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    cartDatabase = Provider.of<CartDatabase>(context, listen: true);
    cartFuture = cartDatabase.allCartProducts;

    _fireStoreUtils.getAdminCommission().then((value) {
      if (value != null) {
        setState(() {
          adminCommission = value;
          adminCommissionValue = adminCommission!["adminCommission"].toString();
          addminCommissionType =
              adminCommission!["addminCommissionType"].toString();
          isEnableAdminCommission = adminCommission!["isAdminCommission"];
        });
      }
    });
    getPrefData();
    //setPrefData();
  }

  Future<void> checkIfVendorIsOpen(var vendorId) async {
    // Current time in "HH:mm" format
    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    final currentDay = DateFormat(
      'EEEE',
    ).format(DateTime.now()); // Get current day

    try {
      // Fetch vendor document from Firestore
      final vendorDoc =
          await FirebaseFirestore.instance
              .collection('vendors')
              .doc(vendorId)
              .get();

      if (vendorDoc.exists) {
        final workingHours = vendorDoc.data()?['workingHours'] ?? [];

        // Check for matching day in workingHours
        for (var dayData in workingHours) {
          if (dayData['day'] == currentDay) {
            final timeSlots = dayData['timeslot'] as List<dynamic>;

            // Check if the current time falls within any timeslot
            for (var slot in timeSlots) {
              final fromTime = slot['from'];
              final toTime = slot['to'];

              if (_isTimeWithinRange(currentTime, fromTime, toTime)) {

                log('Vendor is open');
                log('Vendor is open${currentTime}');
                log('Vendor is open${fromTime}');
                log('Vendor is open${toTime}');
                setState(() {
                  widget.isopen = true;
                });
                return;
              }
            }
          }
        }
      }
    setState(() {
      widget.isopen = false;
    });
      // If no matching time slot is found
      log('Vendor is closed');
    } catch (e) {
      log('Error: $e');
    }
  }

  String? catproducatmart;

  // bool _isTimeWithinRange(String currentTime, String fromTime, String toTime) {
  //   final current = _convertTimeToMinutes(currentTime);
  //   final from = _convertTimeToMinutes(fromTime);
  //   final to = _convertTimeToMinutes(toTime);
  //
  //   return current >= from && current <= to;
  // }
  bool _isTimeWithinRange(String currentTime, String fromTime, String toTime) {
    final current = _convertTimeToMinutes(currentTime);
    final from = _convertTimeToMinutes(fromTime);
    final to = _convertTimeToMinutes(toTime);

    return current >= from && current < to;
  }
  // Helper function to convert "HH:mm" to total minutes
  int _convertTimeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  @override
  Widget build(BuildContext context) {
    cartDatabase = Provider.of<CartDatabase>(context, listen: true);
    return Scaffold(
      extendBody: true,
      backgroundColor:
          isDarkMode(context)
              ? const Color(DARK_COLOR)
              : const Color(0xffFFFFFF),
      body: StreamBuilder<List<CartProduct>>(
        stream: cartDatabase.watchProducts,
        initialData: const [],
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
              ),
            );
          }
          if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
            return SizedBox(
              width: MediaQuery.of(context).size.width * 1,
              child: Center(child: showEmptyState('Empty Cart'.tr(), context)),
            );
          } else {
            cartProducts = snapshot.data!;
            getDatafromVendor();
            if (!isDeliverFound) {
              getDeliveyData();
            }
            return Column(
              children: [
                Expanded(
                  child:
                      isload
                          ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepOrange,
                            ),
                          )
                          : SingleChildScrollView(
                            child: Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: cartProducts.length,
                                  itemBuilder: (context, index) {
                                    vendorID = cartProducts[index].vendorID;
                                    // checkIfVendorIsOpen(vendorID);
                                    // fetchWorkingHours(vendorID);
                                    print("vendor id ave che ${vendorID}");
                                    return Container(
                                      margin: const EdgeInsets.only(
                                        left: 13,
                                        top: 13,
                                        right: 13,
                                        bottom: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              isDarkMode(context)
                                                  ? const Color(
                                                    DarkContainerBorderColor,
                                                  )
                                                  : Colors.grey.shade100,
                                          width: 1,
                                        ),
                                        color:
                                            isDarkMode(context)
                                                ? const Color(
                                                  DarkContainerColor,
                                                )
                                                : Colors.white,
                                        boxShadow: [
                                          isDarkMode(context)
                                              ? const BoxShadow()
                                              : BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.5,
                                                ),
                                                blurRadius: 5,
                                              ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          isload
                                              ? CircularProgressIndicator(
                                                color: Colors.deepOrange,
                                              )
                                              : buildCartRow(
                                                cartProducts[index],
                                                lstExtras,
                                              ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                buildTotalRow(
                                  snapshot.data!,
                                  lstExtras,
                                  vendorID,
                                ),
                              ],
                            ),
                          ),
                ),
                isload
                    ? Container()
                    : widget.isopen == false
                    ? GestureDetector(
                      onTap:
                          scheduleTime1 == null
                              ? () {
                                final snackBar = SnackBar(
                                  backgroundColor:
                                      !isDarkMode(context)
                                          ? Colors.white
                                          : Color(DARK_BG_COLOR),
                                  content: Text(
                                    'Please Select Schedule Order Time',
                                    style: TextStyle(
                                      color:
                                          !isDarkMode(context)
                                              ? Colors.black
                                              : Colors.white,
                                    ),
                                  ),
                                );
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(snackBar);
                              }
                              : () {
                                txt.clear();

                                Map<String, dynamic> specialDiscountMap = {
                                  'special_discount': specialDiscountAmount,
                                  'special_discount_label': specialDiscount,
                                  'specialType': specialType,
                                };

                                if (selctedOrderTypeValue == "Delivery") {
                                  Navigator.of(context)
                                      .push(
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => DeliveryAddressScreen(
                                                autoapplydiscount: num.parse(
                                                  discountadmindiscount
                                                      .toString(),
                                                ),
                                                auto_apply: auto_apply,
                                                cityaveche: cityaveche,
                                                isMyTime: isMyTime,
                                                codWallet: codWallet,
                                                wallamountvendor: num.parse(
                                                  wallamountvendor.toString(),
                                                ),
                                                toatvendoramount:
                                                    toatvendoramount,
                                                groceryitem:
                                                    cartProducts[0].item
                                                        .toString(),
                                                chargepacking:
                                                    charge == "" ||
                                                            charge == null
                                                        ? "0.0"
                                                        : charge.toString(),
                                                razorpayaccount:
                                                    rzorpaybankaccountnumber,
                                                vendoraccountnumber:
                                                    vendorbankholdername,
                                                total: grandtotal,
                                                couponId1: coponid123,
                                                products: cartProducts,
                                                discount: discountAmount,
                                                couponCode:
                                                    couponModel != null
                                                        ? couponModel!.offerCode
                                                        : "",
                                                notes: noteController.text,
                                                couponId:
                                                    couponModel != null
                                                        ? couponModel?.offerId
                                                        : "",
                                                extraAddons:
                                                    commaSepratedAddOns,
                                                tipValue: tipValue.toString(),
                                                takeAway:
                                                    selctedOrderTypeValue ==
                                                            "Delivery"
                                                        ? false
                                                        : true,
                                                deliveryCharge: deliveryCharges,
                                                taxModel: taxList,
                                                specialDiscountMap:
                                                    specialDiscountMap,
                                                scheduleTime: scheduleTime1,
                                              ),
                                          transitionsBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            const begin = Offset(1.0, 0.0);
                                            const end = Offset.zero;
                                            const curve = Curves.ease;

                                            final tween = Tween(
                                              begin: begin,
                                              end: end,
                                            );
                                            final curvedAnimation =
                                                CurvedAnimation(
                                                  parent: animation,
                                                  curve: curve,
                                                );
                                            print(
                                              "jayala tu beshi ja ${deliveryCharges}",
                                            );
                                            print(
                                              "scheduleTime1scheduleTime1scheduleTime1${scheduleTime1}",
                                            );
                                            return SlideTransition(
                                              position: tween.animate(
                                                curvedAnimation,
                                              ),
                                              child: child,
                                            );
                                          },
                                        ),
                                      )
                                      .then((value) {
                                        print("value${value}");
                                        if (value != null && mounted) {
                                          setState(() {
                                            deliveryCharges = value;
                                          });
                                        }
                                        print(
                                          "cartscreendeliveryCharges${deliveryCharges}",
                                        );
                                      });

                                  print(
                                    "couponModel?.offerId${couponModel?.offerId}",
                                  );
                                  print("coponid123${coponid123}");
                                } else {
                                  push(
                                    context,
                                    PaymentScreen(
                                      cityaveche: cityaveche,
                                      isMyTime: isMyTime,
                                      autoapplydiscount: num.parse(
                                        discountadmindiscount.toString(),
                                      ),
                                      auto_apply: auto_apply,
                                      codWallet: codWallet,
                                      wallamountvendor: num.parse(
                                        wallamountvendor.toString(),
                                      ),
                                      toatvendoramount: toatvendoramount,
                                      razorpayaccount: rzorpaybankaccountnumber,
                                      vendoraccountnumber: vendorbankholdername,
                                      total: grandtotal,
                                      discount: discountAmount,
                                      groceryitem:
                                          cartProducts[0].item.toString(),
                                      couponCode:
                                          couponModel != null
                                              ? couponModel!.offerCode
                                              : "",
                                      couponId:
                                          couponModel != null
                                              ? couponModel!.offerId
                                              : "",
                                      couponId1: coponid123,
                                      notes: noteController.text,
                                      products: cartProducts,
                                      extraAddons: commaSepratedAddOns,
                                      tipValue: "0",
                                      takeAway: true,
                                      deliveryCharge: "0",
                                      taxModel: taxList,
                                      specialDiscountMap: specialDiscountMap,
                                      scheduleTime: scheduleTime1,
                                    ),
                                  );
                                  print(
                                    "scheduleTime1scheduleTime1scheduleTime1${scheduleTime1}",
                                  );
                                  print(
                                    "couponModel?.offerId${couponModel?.offerId}",
                                  );
                                  print("coponid123${coponid123}");
                                  // placeOrder();
                                  print(
                                    "couponModel?.offerId${couponModel?.offerId}",
                                  );
                                }
                              },
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 1,
                        height: MediaQuery.of(context).size.height * 0.080,
                        child: Container(
                          color: Color(COLOR_PRIMARY),
                          padding: const EdgeInsets.only(
                            left: 15,
                            right: 10,
                            bottom: 8,
                            top: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Total : ".tr(),
                                    style: const TextStyle(
                                      fontFamily: "Poppinsl",
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                  Text(
                                    amountShow(amount: grandtotal.toString()),
                                    style: const TextStyle(
                                      fontFamily: "Poppinsm",
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "PROCEED TO CHECKOUT".tr(),
                                style: const TextStyle(
                                  fontFamily: "Poppinsm",
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : GestureDetector(
                      onTap:
                          isSchedule && scheduleTime == null
                              ? () {
                                final snackBar = SnackBar(
                                  backgroundColor:
                                      !isDarkMode(context)
                                          ? Colors.white
                                          : Color(DARK_BG_COLOR),
                                  content: Text(
                                    'Please Select Schedule Order Time',
                                    style: TextStyle(
                                      color:
                                          !isDarkMode(context)
                                              ? Colors.black
                                              : Colors.white,
                                    ),
                                  ),
                                );
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(snackBar);
                              }
                              : () {
                                txt.clear();

                                Map<String, dynamic> specialDiscountMap = {
                                  'special_discount': specialDiscountAmount,
                                  'special_discount_label': specialDiscount,
                                  'specialType': specialType,
                                };

                                if (selctedOrderTypeValue == "Delivery") {
                                  // push(
                                  //   context,
                                  //   DeliveryAddressScreen(
                                  //     chargepacking: charge == "" || charge == null
                                  //         ? "0.0"
                                  //         : charge.toString(),
                                  //     total: grandtotal,
                                  //     couponId1: coponid123,
                                  //     products: cartProducts,
                                  //     discount: discountAmount,
                                  //     couponCode:
                                  //         couponModel != null ? couponModel!.offerCode : "",
                                  //     notes: noteController.text,
                                  //     couponId:
                                  //         couponModel != null ? couponModel?.offerId : "",
                                  //     extraAddons: commaSepratedAddOns,
                                  //     tipValue: tipValue.toString(),
                                  //     takeAway: selctedOrderTypeValue == "Delivery"
                                  //         ? false
                                  //         : true,
                                  //     deliveryCharge: deliveryCharges,
                                  //     taxModel: taxList,
                                  //     specialDiscountMap: specialDiscountMap,
                                  //     scheduleTime: scheduleTime,
                                  //   ),

                                  Navigator.of(context)
                                      .push(
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => DeliveryAddressScreen(
                                                autoapplydiscount: num.parse(
                                                  discountadmindiscount
                                                      .toString(),
                                                ),
                                                auto_apply: auto_apply,
                                                codWallet: codWallet,
                                                cityaveche: cityaveche,
                                                isMyTime: isMyTime,
                                                wallamountvendor: num.parse(
                                                  wallamountvendor.toString(),
                                                ),
                                                toatvendoramount:
                                                    toatvendoramount,
                                                groceryitem:
                                                    cartProducts[0].item
                                                        .toString(),
                                                chargepacking:
                                                    charge == "" ||
                                                            charge == null
                                                        ? "0.0"
                                                        : charge.toString(),
                                                razorpayaccount:
                                                    rzorpaybankaccountnumber,
                                                vendoraccountnumber:
                                                    vendorbankholdername,
                                                total: grandtotal,
                                                couponId1: coponid123,
                                                products: cartProducts,
                                                discount: discountAmount,
                                                couponCode:
                                                    couponModel != null
                                                        ? couponModel!.offerCode
                                                        : "",
                                                notes: noteController.text,
                                                couponId:
                                                    couponModel != null
                                                        ? couponModel?.offerId
                                                        : "",
                                                extraAddons:
                                                    commaSepratedAddOns,
                                                tipValue: tipValue.toString(),
                                                takeAway:
                                                    selctedOrderTypeValue ==
                                                            "Delivery"
                                                        ? false
                                                        : true,
                                                deliveryCharge: deliveryCharges,
                                                taxModel: taxList,
                                                specialDiscountMap:
                                                    specialDiscountMap,
                                                scheduleTime: scheduleTime1,
                                              ),
                                          transitionsBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            const begin = Offset(1.0, 0.0);
                                            const end = Offset.zero;
                                            const curve = Curves.ease;

                                            final tween = Tween(
                                              begin: begin,
                                              end: end,
                                            );
                                            final curvedAnimation =
                                                CurvedAnimation(
                                                  parent: animation,
                                                  curve: curve,
                                                );
                                            print(
                                              "jayala tu beshi ja ${deliveryCharges}",
                                            );
                                            print(
                                              "jayala tu beshi ja ${auto_apply}",
                                            );
                                            print(
                                              "scheduleTime1scheduleTime1scheduleTime1${scheduleTime1}",
                                            );
                                            return SlideTransition(
                                              position: tween.animate(
                                                curvedAnimation,
                                              ),
                                              child: child,
                                            );
                                          },
                                        ),
                                      )
                                      .then((value) {
                                        print("value${value}");
                                        if (value != null && mounted) {
                                          setState(() {
                                            deliveryCharges = value;
                                          });
                                        }
                                        print(
                                          "cartscreendeliveryCharges${deliveryCharges}",
                                        );
                                      });

                                  print(
                                    "couponModel?.offerId${couponModel?.offerId}",
                                  );
                                  print("coponid123${coponid123}");
                                } else {
                                  push(
                                    context,
                                    PaymentScreen(
                                      autoapplydiscount: num.parse(
                                        discountadmindiscount.toString(),
                                      ),
                                      auto_apply: auto_apply,
                                      cityaveche: cityaveche,
                                      isMyTime: isMyTime,
                                      codWallet: codWallet,
                                      wallamountvendor: num.parse(
                                        wallamountvendor.toString(),
                                      ),
                                      toatvendoramount: toatvendoramount,
                                      razorpayaccount: rzorpaybankaccountnumber,
                                      vendoraccountnumber: vendorbankholdername,
                                      total: grandtotal,
                                      discount: discountAmount,
                                      groceryitem:
                                          cartProducts[0].item.toString(),
                                      couponCode:
                                          couponModel != null
                                              ? couponModel!.offerCode
                                              : "",
                                      couponId:
                                          couponModel != null
                                              ? couponModel!.offerId
                                              : "",
                                      couponId1: coponid123,
                                      notes: noteController.text,
                                      products: cartProducts,
                                      extraAddons: commaSepratedAddOns,
                                      tipValue: "0",
                                      takeAway: true,
                                      deliveryCharge: "0",
                                      taxModel: taxList,
                                      specialDiscountMap: specialDiscountMap,
                                      scheduleTime: scheduleTime1,
                                    ),
                                  );
                                  print(
                                    "scheduleTime1scheduleTime1scheduleTime1${scheduleTime1}",
                                  );
                                  print(
                                    "couponModel?.offerId${couponModel?.offerId}",
                                  );
                                  print("coponid123${coponid123}");
                                  // placeOrder();
                                  print(
                                    "couponModel?.offerId${couponModel?.offerId}",
                                  );
                                }
                              },
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 1,
                        height: MediaQuery.of(context).size.height * 0.080,
                        child: Container(
                          color: Color(COLOR_PRIMARY),
                          padding: const EdgeInsets.only(
                            left: 15,
                            right: 10,
                            bottom: 8,
                            top: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Total : ".tr(),
                                    style: const TextStyle(
                                      fontFamily: "Poppinsl",
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                  Text(
                                    amountShow(amount: grandtotal.toString()),
                                    style: const TextStyle(
                                      fontFamily: "Poppinsm",
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "PROCEED TO CHECKOUT".tr(),
                                style: const TextStyle(
                                  fontFamily: "Poppinsm",
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            );
          }
        },
      ),
    );
  }

  getDatafromVendor() async {
    await _fireStoreUtils.getVendorByVendorID(cartProducts.first.vendorID).then(
      (value) {
        vendorModel = value;
        isSchedule = vendorModel!.isScheduled;
        isLiveandScheduled = vendorModel!.isLiveandScheduled;
      },
    );
  }

  Future<List<String>> getresturantcities() async {
    print('athata che');

    // Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Settings document fetch karo
    DocumentSnapshot documentSnapshot =
        await firestore
            .collection('coupons')
            .doc('${auto_apply_coupon_id}')
            .get();
    if (documentSnapshot.exists) {
      List<String> cities = List<String>.from(documentSnapshot.get('cities'));
      setState(() {
        Timestamp expiresAt = documentSnapshot['expiresAt'];
        Timestamp startsAt = documentSnapshot['startsAt'];
        isEnabled1 = documentSnapshot['isEnabled'];
        DateTime now = DateTime.now();
        // Convert to DateTime
        DateTime expiresAtDateTime = expiresAt.toDate();
        DateTime startsAtDateTime = startsAt.toDate();
        print('Expires At (DateTime): $expiresAtDateTime');
        print('Expires At (DateTime): $startsAtDateTime');
        print('Expires At (DateTime): $isEnabled');
        isMyTime =
            now.isAfter(startsAtDateTime) && now.isBefore(expiresAtDateTime);
      });

      print("Is My Time: $isMyTime");
      print("Is My Time: $cityaveche");
      print("Is My Time: $auto_apply");
      print("citiescitiedfdsfsdfsfsfsdfdsffs${cities}");

      return cities;
    } else {
      // Default empty list return karo jya data na male
      return [];
    }
  }

  String? city1;
  bool? cityaveche;
  bool? isMyTime;
  bool? isEnabled1;

  Future<void> getCityrestaurantcity() async {
    try {
      // Latitude ane longitude thi location details melvo
      List<Placemark> placemarks = await placemarkFromCoordinates(
        MyAppState.currentUser?.userID == null ||
                MyAppState.currentUser?.userID == ""
            ? MyAppState.selectedPosotion.latitude
            : MyAppState.currentUser?.location.latitude == null ||
                MyAppState.currentUser?.location.latitude == 0.01
            ? MyAppState.selectedPosotion.latitude
            : double.parse(
              (MyAppState.currentUser?.location.latitude).toString(),
            ),
        MyAppState.currentUser?.userID == null ||
                MyAppState.currentUser?.userID == ""
            ? MyAppState.selectedPosotion.longitude
            : MyAppState.currentUser?.location.longitude == null ||
                MyAppState.currentUser?.location.longitude == 0.01
            ? MyAppState.selectedPosotion.longitude
            : double.parse(
              (MyAppState.currentUser?.location.longitude).toString(),
            ),
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          city1 = place.locality ?? 'City not found';
        });

        print('vendorcity ave che: $city1');
        List<String> cities = await getresturantcities();
        if (cities.contains(city1)) {
          // cityaveche = true;
          setState(() {
            cityaveche = true;
            isload = false;
          });

          print("call nay thay");
          print(
            "cityavechecityavechecityavechecityavechecall nay thay${cityaveche}",
          );
          print(
            'restaurant valu ave che  "$city1" is available in the Firestore cities.',
          );
        } else {
          setState(() {
            cityaveche = false;
            isload = false;
          });
          print(
            "cityavechecityavechecityavechecityavechecall nay thay${cityaveche}",
          );
          print(
            'restaurant valu ave che "$city1" is not available in the Firestore cities.',
          );
        }
      } else {
        print('No location found for the given coordinates.');

        print("======????????????????????????????????${cityaveche}");
        setState(() {
          cityaveche = false;
          isload = false;
        });
      }
    } catch (e) {
      print('Error: $e');

      setState(() {
        cityaveche = false;
        isload = false;
      });
    }
  }

  buildCartRow(CartProduct cartProduct, List<AddAddonsDemo> addons) {
    List addOnVal = [];
    catproducatmart:
    cartProduct?.item;
    var quen = cartProduct.quantity;
    double priceTotalValue = 0.0;
    // priceTotalValue   = double.parse(cartProduct.price);
    double addOnValDoule = 0;
    for (int i = 0; i < lstExtras.length; i++) {
      AddAddonsDemo addAddonsDemo = lstExtras[i];
      if (addAddonsDemo.categoryID == cartProduct.id) {
        addOnValDoule = addOnValDoule + double.parse(addAddonsDemo.price!);
      }
    }

    ProductModel? productModel;
    FireStoreUtils().getProductByID(cartProduct.id.split('~').first).then((
      value,
    ) {
      productModel = value;
    });

    VariantInfo? variantInfo;
    if (cartProduct.variant_info != null) {
      variantInfo = VariantInfo.fromJson(
        jsonDecode(cartProduct.variant_info.toString()),
      );
    }
    if (cartProduct.extras == null) {
      addOnVal.clear();
    } else {
      if (cartProduct.extras is String) {
        if (cartProduct.extras == '[]') {
          addOnVal.clear();
        } else {
          String extraDecode = cartProduct.extras
              .toString()
              .replaceAll("[", "")
              .replaceAll("]", "")
              .replaceAll("\"", "");
          if (extraDecode.contains(",")) {
            addOnVal = extraDecode.split(",");
          } else {
            if (extraDecode.trim().isNotEmpty) {
              addOnVal = [extraDecode];
            }
          }
        }
      }

      if (cartProduct.extras is List) {
        addOnVal = List.from(cartProduct.extras);
      }
    }

    if (cartProduct.extras_price != null &&
        cartProduct.extras_price != "" &&
        double.parse(cartProduct.extras_price!) != 0.0) {
      if (auto_apply == true && cityaveche == true && isMyTime == true) {
        pricenew =
            double.parse(cartProduct.extras_price!) *
            num.parse(discountadmindiscount.toString()) /
            100;
        double originalPrice = double.parse(cartProduct.extras_price!);
        // print("originalPriceoriginalPrice${originalPrice}");
        originalPrice =
            double.parse(cartProduct.extras_price!) -
            num.parse(pricenew.toString());
        priceTotalValue +=
            double.parse(originalPrice.toString()) * cartProduct.quantity;
      } else {
        priceTotalValue +=
            double.parse(cartProduct.extras_price!) * cartProduct.quantity;
      }
    }
    print("first a call thay che pachi a call ${auto_apply}");
    print("first a call thay che pachi a call ${cityaveche}");
    print("first a call thay che pachi a call ${isMyTime}");
    if (auto_apply == true && cityaveche == true && isMyTime == true) {
      print("caart screen shu ave che ${discountadmindiscount}");
      print("caart screen shu ave che shun ave che  ${cartProduct.price}");
      pricenew =
          double.parse(cartProduct.price) *
          num.parse(discountadmindiscount.toString()) /
          100;
      double originalPrice = double.parse(cartProduct.extras_price!);
      print("caart screen shu ave che ${originalPrice}");
      // print("originalPriceoriginalPrice${originalPrice}");
      originalPrice =
          double.parse(cartProduct.price) - num.parse(pricenew.toString());
      print(
        "caart screen shu ave che minum thay shu ave che  ${originalPrice}",
      );
      priceTotalValue +=
          double.parse(originalPrice.toString()) * cartProduct.quantity;
      print("priceTotalValuepriceTotalValue${priceTotalValue}");
    } else {
      print("first a call thay che");
      priceTotalValue += double.parse(cartProduct.price) * cartProduct.quantity;
    }

    // VariantInfo variantInfo= cartProduct.variant_info;
    return InkWell(
      onTap: () {
        _fireStoreUtils.getVendorByVendorID(cartProduct.vendorID).then((value) {
          push(context, NewVendorProductsScreen(vendorModel: value));
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    height: 80,
                    width: 80,
                    imageUrl: getImageVAlidUrl(cartProduct.photo),
                    imageBuilder:
                        (context, imageProvider) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(
                            AppGlobal.placeHolderImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartProduct.item == "grocery"
                            ? cartProduct.name +
                                ' (${cartProduct.groceryWeight} ${cartProduct.groceryUnit})'
                            : cartProduct.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: "Poppinsm",
                        ),
                      ),

                      // Text(
                      //   cartProduct.packingcharges,
                      //   style: const TextStyle(
                      //       fontSize: 18, fontFamily: "Poppinsm"),
                      // ),
                      isload
                          ? CircularProgressIndicator(color: Colors.deepOrange)
                          : Text(
                            amountShow(amount: priceTotalValue.toString()),
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: "Poppinsm",
                              color: Color(COLOR_PRIMARY),
                            ),
                          ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (quen != 0) {
                          quen--;
                          _apply();
                          removetocard(cartProduct, quen);
                        }
                      },
                      child: Image(
                        image: const AssetImage("assets/images/minus.png"),
                        color: Color(COLOR_PRIMARY),
                        height: 30,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${cartProduct.quantity}'.tr(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        if (productModel!.itemAttributes != null) {
                          if (productModel!.itemAttributes!.variants!
                              .where(
                                (element) =>
                                    element.variantSku ==
                                    variantInfo!.variantSku,
                              )
                              .isNotEmpty) {
                            if (int.parse(
                                      productModel!.itemAttributes!.variants!
                                          .where(
                                            (element) =>
                                                element.variantSku ==
                                                variantInfo!.variantSku,
                                          )
                                          .first
                                          .variantQuantity
                                          .toString(),
                                    ) >
                                    quen ||
                                int.parse(
                                      productModel!.itemAttributes!.variants!
                                          .where(
                                            (element) =>
                                                element.variantSku ==
                                                variantInfo!.variantSku,
                                          )
                                          .first
                                          .variantQuantity
                                          .toString(),
                                    ) ==
                                    -1) {
                              quen++;
                              _apply();
                              addtocard(cartProduct, quen);
                            } else {
                              cartProduct.item == "grocery"
                                  ? ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Item out of stock".tr()),
                                    ),
                                  )
                                  : ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("food out of stock".tr()),
                                    ),
                                  );
                            }
                          } else {
                            if (productModel!.quantity > quen ||
                                productModel!.quantity == -1) {
                              quen++;
                              addtocard(cartProduct, quen);
                            } else {
                              cartProduct.item == "grocery"
                                  ? ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Item out of stock".tr()),
                                    ),
                                  )
                                  : ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("food out of stock".tr()),
                                    ),
                                  );
                            }
                          }
                        } else {
                          if (productModel!.quantity > quen ||
                              productModel!.quantity == -1) {
                            quen++;
                            addtocard(cartProduct, quen);
                          } else {
                            cartProduct.item == "grocery"
                                ? ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Item out of stock".tr()),
                                  ),
                                )
                                : ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("food out of stock".tr()),
                                  ),
                                );
                          }
                        }
                      },
                      child: Image(
                        image: const AssetImage("assets/images/plus.png"),
                        color: Color(COLOR_PRIMARY),
                        height: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            variantInfo == null || variantInfo.variantOptions!.isEmpty
                ? Container()
                : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 10,
                  ),
                  child: Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children:
                        List.generate(variantInfo.variantOptions!.length, (i) {
                          return _buildChip(
                            "${variantInfo!.variantOptions!.keys.elementAt(i)} : ${variantInfo.variantOptions![variantInfo.variantOptions!.keys.elementAt(i)]}",
                            i,
                          );
                        }).toList(),
                  ),
                ),
            SizedBox(
              height: addOnVal.isEmpty ? 0 : 30,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ListView.builder(
                  itemCount: addOnVal.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Text(
                      "${addOnVal[index].toString().replaceAll("\"", "")} ${(index == addOnVal.length - 1) ? "" : ","}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    );
                  },
                ),
              ),
            ),
            // cartProduct.variant_info != null?ListView.builder(
            //   itemCount: variantInfo.variantOptions!.length,
            //   shrinkWrap: true,
            //   itemBuilder: (context, index) {
            //     String key = cartProduct.variant_info.variantOptions!.keys.elementAt(index);
            //     return Padding(
            //       padding: const EdgeInsets.symmetric(vertical: 2),
            //       child: Row(
            //         children: [
            //           Text("$key : "),
            //           Text("${cartProduct.variant_info.variantOptions![key]}"),
            //         ],
            //       ),
            //     );
            //   },
            // ):Container(),
          ],
        ),
      ),
    );
  }

  bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
    final currentDate = DateTime.now();
    return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  }

  Widget buildTotalRow(
    List<CartProduct> data,
    List<AddAddonsDemo> lstExtras,
    String vendorID,
  ) {
    var _font = 16.00;
    subTotal = 0.00;
    grandtotal = 0;
    num totalPackingCharge = 0;
    for (int a = 0; a < data.length; a++) {
      CartProduct e = data[a];
      double addOnValDoule = 0;
      for (int i = 0; i < lstExtras.length; i++) {
        print(" lstExtras.length${lstExtras.length}");
        AddAddonsDemo addAddonsDemo = lstExtras[i];
        print(" lstExtras.length${addAddonsDemo}");
        if (addAddonsDemo.categoryID == e.id) {
          addOnValDoule = addOnValDoule + double.parse(addAddonsDemo.price!);
        }
      }
      if (e.extras_price != null &&
          e.extras_price != "" &&
          double.parse(e.extras_price!) != 0.0) {
        subTotal += double.parse(e.extras_price!) * e.quantity;
        subTotal1 += double.parse(e.extras_price!) * e.quantity;
      }
      if (auto_apply == true && cityaveche == true && isMyTime == true) {
        print("caart screen shu ave che ${discountadmindiscount}");
        print("caart screen shu ave che shun ave che  ${e.price}");
        bevafapdama =
            double.parse(e.price) *
            num.parse(discountadmindiscount.toString()) /
            100;
        double originalPrice = double.parse(e.price);
        print("caart screen shu ave che ${originalPrice}");
        // print("originalPriceoriginalPrice${originalPrice}");
        originalPrice =
            double.parse(e.price) - num.parse(bevafapdama.toString());
        subTotal += double.parse(originalPrice.toString()) * e.quantity;
        subTotal1 += double.parse(e.price) * e.quantity;
        print(
          "caart screen shu ave che minum thay shu ave che  ${originalPrice}",
        );
      } else {
        subTotal += double.parse(e.price) * e.quantity;
        subTotal1 += double.parse(e.price) * e.quantity;
      }
      totalPackingCharge += num.parse(e.packingcharges ?? '0');
      charge = totalPackingCharge;
      print("chargecharge${charge}");
      quantitycharge = e.quantity;
      razorpayvendoramounttrafar = subTotal1;
      // + num.parse(charge.toString());
      print("razorpayvendoramounttrafar${razorpayvendoramounttrafar}");
      // double sprintamount = commissionType == "Percent"
      //     ? razorpayvendoramounttrafar *
      //         double.parse(fixCommission.toString()) /
      //         100
      //     : razorpayvendoramounttrafar + double.parse(fixCommission.toString());
      double sprintamount =
          commissionType == "Percent"
              ? razorpayvendoramounttrafar *
                  (fixCommission != null
                      ? double.parse(fixCommission.toString())
                      : 0) /
                  100
              : razorpayvendoramounttrafar +
                  (fixCommission != null
                      ? double.parse(fixCommission.toString())
                      : 0);
      toatvendoramount =
          razorpayvendoramounttrafar -
          sprintamount +
          num.parse(charge.toString());
      print(
        "toatvendoramounttoatvendoramounttoatvendoramount${toatvendoramount}",
      );
      print("toatvendoramounttoatvendoramounttoatvendoramount${sprintamount}");
    }
    // var charge=widget.packingCharge.toString();
    // grandtotal = subTotal + double.parse(deliveryCharges) + tipValue + charge;

    try {
      charge = charge;
    } catch (e) {
      charge = 0.0;
      // Or handle the error in a way that makes sense for your application
    }
    grandtotal =
        subTotal +
        double.parse(deliveryCharges) +
        tipValue +
        double.parse(charge.toString());
    // haresh bhai code
    //discountAmount = calculateDiscount(amount: subTotal.toString(), offerModel: couponModel);
    // grandtotal = grandtotal - discountAmount;

    //  ram code

    grandtotal = grandtotal - discountAmount;

    if (vendorModel?.freeDelivery == true &&
        vendorModel?.deliveryCharge != null) {
      grandtotal = grandtotal - double.parse(deliveryCharges);
    }

    if (vendorModel != null) {
      if (vendorModel!.specialDiscountEnable) {
        final now = new DateTime.now();
        var day = DateFormat('EEEE', 'en_US').format(now);
        var date = DateFormat('dd-MM-yyyy').format(now);
        vendorModel!.specialDiscount.forEach((element) {
          if (day == element.day.toString()) {
            if (element.timeslot!.isNotEmpty) {
              element.timeslot!.forEach((element) {
                if (element.discountType == "delivery") {
                  var start = DateFormat(
                    "dd-MM-yyyy HH:mm",
                  ).parse(date + " " + element.from.toString());
                  var end = DateFormat(
                    "dd-MM-yyyy HH:mm",
                  ).parse(date + " " + element.to.toString());
                  if (isCurrentDateInRange(start, end)) {
                    specialDiscount = double.parse(element.discount.toString());
                    specialType = element.type.toString();
                    if (element.type == "percentage") {
                      specialDiscountAmount = subTotal * specialDiscount / 100;
                    } else {
                      specialDiscountAmount = specialDiscount;
                    }
                    grandtotal = grandtotal - specialDiscountAmount;
                  }
                }
              });
            }
          }
        });
      } else {
        specialDiscount = double.parse("0");
        specialType = "amount";
      }
    }
    String taxAmount = " 0.0";
    if (taxList != null) {
      for (var element in taxList!) {
        taxAmount =
            (double.parse(taxAmount) +
                    calculateTax(
                      amount:
                          (subTotal - discountAmount - specialDiscountAmount)
                              .toString(),
                      taxModel: element,
                    ))
                .toString();
      }
    }
    grandtotal += double.parse(taxAmount);
    print("parkpalme@parkpal.co.inparkpalme@parkpal.co.in${auto_apply}");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        auto_apply == true && cityaveche == true && isMyTime == true
            ? Container()
            : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              margin: const EdgeInsets.only(
                left: 13,
                top: 13,
                right: 13,
                bottom: 13,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      isDarkMode(context)
                          ? const Color(DarkContainerBorderColor)
                          : Colors.grey.shade100,
                  width: 1,
                ),
                color:
                    isDarkMode(context)
                        ? const Color(DarkContainerColor)
                        : Colors.white,
                boxShadow: [
                  isDarkMode(context)
                      ? const BoxShadow()
                      : BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 5,
                      ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 222, // Set the width of the first element
                    height: 100, // Set the height of the first element
                    child: Center(
                      child: RoundedInputBox(couponTextField, editableCoupon),
                    ),
                  ),
                  nameCoupon == "Apply"
                      ? Container(
                        width: 70,
                        // Set the width of the second element
                        height: 65,
                        margin: EdgeInsets.all(10.0),
                        // Set the height of the second element
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            // Set the border radius
                            color: Colors.blue, // Background color
                          ),
                          child: GestureDetector(
                            child: Center(
                              child: Text(
                                nameCoupon,
                                style: TextStyle(
                                  color: Colors.white, // Text color
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            onTap:
                            // couponTextField.text == '' ||
                            //         couponTextField.text.isEmpty
                            //     ? () {
                            //         final snackBar = SnackBar(
                            //           backgroundColor: isDarkMode(context)
                            //               ? Colors.white
                            //               : Color(DARK_BG_COLOR),
                            //           content: Text(
                            //             'Please Enter Coupon Code',
                            //             style: TextStyle(
                            //                 color: isDarkMode(context)
                            //                     ? Colors.black
                            //                     : Colors.white),
                            //           ),
                            //         );
                            //         ScaffoldMessenger.of(context)
                            //             .showSnackBar(snackBar);
                            //       }
                            //     :
                            () async {
                              await _apply();
                              setState(() {});
                            },
                          ),
                        ),
                      )
                      : Container(
                        width: 70,
                        // Set the width of the second element
                        height: 65,
                        margin: EdgeInsets.all(10.0),
                        // Set the height of the second element
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            // Set the border radius
                            color: Colors.grey, // Background color
                          ),
                          child: GestureDetector(
                            child: Center(
                              child: Text(
                                nameCoupon,
                                style: TextStyle(
                                  color: Colors.black, // Text color
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            onTap: () async {
                              await _apply();
                              // setState(() {});
                            },
                          ),
                        ),
                      ),
                ],
              ),
            ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isDarkMode(context)
                      ? const Color(DarkContainerBorderColor)
                      : Colors.grey.shade100,
              width: 1,
            ),
            color:
                isDarkMode(context)
                    ? const Color(DarkContainerColor)
                    : Colors.white,
            boxShadow: [
              isDarkMode(context)
                  ? const BoxShadow()
                  : BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                  ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Instructions".tr(),
                    style: const TextStyle(fontFamily: "Poppinsm"),
                  ),
                  Text(
                    "Write instructions for restaurant".tr(),
                    style: const TextStyle(fontFamily: "Poppinsr"),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    isDismissible: true,
                    context: context,
                    backgroundColor: Colors.transparent,
                    enableDrag: true,
                    builder: (BuildContext context) => noteSheet(),
                  );
                },
                child: const Image(
                  image: AssetImage("assets/images/add.png"),
                  width: 40,
                ),
              ),
            ],
          ),
        ),
        if (isSchedule || isLiveandScheduled)
          widget.isopen == false
              ? Container()
              : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isDarkMode(context)
                            ? const Color(DarkContainerBorderColor)
                            : Colors.grey.shade100,
                    width: 1,
                  ),
                  color:
                      isDarkMode(context)
                          ? const Color(DarkContainerColor)
                          : Colors.white,
                  boxShadow: [
                    isDarkMode(context)
                        ? const BoxShadow()
                        : BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 5,
                        ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Schedule Order Time".tr(),
                          style: const TextStyle(fontFamily: "Poppinsm"),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 140,
                      child:
                      // GestureDetector(
                      //   onTap: () {
                      //     showDateTimeBottomSheet(context,
                      //         (DateTime dateAndTime) {
                      //       setState(() {
                      //         // scheduleTime = Timestamp.fromDate(dateAndTime.add(Duration(hours: 12)));
                      //         scheduleTime = Timestamp.fromDate(dateAndTime);
                      //       });
                      //     });
                      //   },
                      //   child: Text(
                      //     scheduleTime == null
                      //         ? "Select Time".tr()
                      //         : DateFormat("EEE dd MMMM , hh:mm aa")
                      //             .format(scheduleTime!.toDate().toLocal()),
                      //     textAlign: TextAlign.end,
                      //     style: TextStyle(
                      //         fontFamily: "Poppinsm",
                      //         color: Color(COLOR_PRIMARY)),
                      //   ),
                      // ),
                      GestureDetector(
                        onTap: () {
                          fetchWorkingHours()
                              .then((workingHours) {
                                showDateTimeBottomSheet12(
                                  context,
                                  (DateTime dateAndTime) {
                                    setState(() {
                                      // scheduleTime1 = Timestamp.fromDate(dateAndTime.add(Duration(hours: 12)));
                                      scheduleTime1 = Timestamp.fromDate(
                                        dateAndTime,
                                      );
                                    });
                                  },
                                  workingHours, // Pass working hours as the third argument
                                );
                              })
                              .catchError((e) {
                                // Handle errors when fetching working hours
                                print("Error fetching working hours: $e");
                              });
                          // showDateTimeBottomSheet12(context,
                          //     (DateTime dateAndTime) {
                          //   setState(() {
                          //     scheduleTime1 = Timestamp.fromDate(dateAndTime);
                          //   });
                          // });
                        },
                        child: Text(
                          scheduleTime1 == null
                              ? "Select Time".tr()
                              : DateFormat(
                                "EEE dd MMMM , hh:mm aa",
                              ).format(scheduleTime1!.toDate().toLocal()),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontFamily: "Poppinsm",
                            color: Color(COLOR_PRIMARY),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        if (widget.isopen == false)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isDarkMode(context)
                        ? const Color(DarkContainerBorderColor)
                        : Colors.grey.shade100,
                width: 1,
              ),
              color:
                  isDarkMode(context)
                      ? const Color(DarkContainerColor)
                      : Colors.white,
              boxShadow: [
                isDarkMode(context)
                    ? const BoxShadow()
                    : BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 5,
                    ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Schedule Order Time".tr(),
                      style: const TextStyle(fontFamily: "Poppinsm"),
                    ),
                  ],
                ),
                SizedBox(
                  width: 140,
                  child: GestureDetector(
                    onTap: () {
                      fetchWorkingHours()
                          .then((workingHours) {
                            showDateTimeBottomSheet12(
                              context,
                              (DateTime dateAndTime) {
                                setState(() {
                                  // scheduleTime1 = Timestamp.fromDate(dateAndTime.add(Duration(hours: 12)));
                                  scheduleTime1 = Timestamp.fromDate(
                                    dateAndTime,
                                  );
                                });
                              },
                              workingHours, // Pass working hours as the third argument
                            );
                          })
                          .catchError((e) {
                            // Handle errors when fetching working hours
                            print("Error fetching working hours: $e");
                          });
                      // showDateTimeBottomSheet12(context,
                      //     (DateTime dateAndTime) {
                      //   setState(() {
                      //     scheduleTime1 = Timestamp.fromDate(dateAndTime);
                      //   });
                      // });
                    },
                    child: Text(
                      scheduleTime1 == null
                          ? "Select Time".tr()
                          : DateFormat(
                            "EEE dd MMMM , hh:mm aa",
                          ).format(scheduleTime1!.toDate().toLocal()),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: "Poppinsm",
                        color: Color(COLOR_PRIMARY),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.only(
            left: 13,
            top: 10,
            right: 13,
            bottom: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isDarkMode(context)
                      ? const Color(DarkContainerBorderColor)
                      : Colors.grey.shade100,
              width: 1,
            ),
            color:
                isDarkMode(context)
                    ? const Color(DarkContainerColor)
                    : Colors.white,
            boxShadow: [
              isDarkMode(context)
                  ? const BoxShadow()
                  : BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                  ),
            ],
          ),
          child: Column(
            children: [
              // Container(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //       children: [
              //         Text(
              //           "Delivery Option: ".tr(),
              //           style:
              //               TextStyle(fontFamily: "Poppinsm", fontSize: _font),
              //         ),
              //         // Text(
              //         //   selctedOrderTypeValue == "Delivery"
              //         //       ? "Delivery (${amountShow(amount: deliveryCharges.toString())})"
              //         //       : selctedOrderTypeValue! + " (Free)",
              //         //   style: TextStyle(
              //         //       fontFamily: "Poppinsm",
              //         //       color: isDarkMode(context)
              //         //           ? const Color(0xffFFFFFF)
              //         //           : const Color(0xff333333),
              //         //       fontSize: selctedOrderTypeValue == "Delivery"
              //         //           ? _font
              //         //           : 14),
              //         // ),
              //       ],
              //     )),
              // const Divider(
              //   color: Color(0xffE2E8F0),
              //   height: 0.1,
              // ),
              SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Subtotal".tr(),
                      style: TextStyle(fontFamily: "Poppinsm", fontSize: _font),
                    ),
                    Text(
                      amountShow(amount: subTotal.toString()),
                      style: TextStyle(
                        fontFamily: "Poppinsm",
                        color:
                            isDarkMode(context)
                                ? const Color(0xffFFFFFF)
                                : const Color(0xff333333),
                        fontSize: _font,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Packing Charge".tr(),
                      style: TextStyle(fontFamily: "Poppinsm", fontSize: _font),
                    ),
                    Text(
                      amountShow(amount: charge.toString()),
                      style: TextStyle(
                        fontFamily: "Poppinsm",
                        color:
                            isDarkMode(context)
                                ? const Color(0xffFFFFFF)
                                : const Color(0xff333333),
                        fontSize: _font,
                      ),
                    ),
                  ],
                ),
              ),
              auto_apply == true && cityaveche == true && isMyTime == true
                  ? Container()
                  : const Divider(thickness: 1),
              auto_apply == true && cityaveche == true && isMyTime == true
                  ? Container()
                  : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Discount".tr(),
                          style: TextStyle(
                            fontFamily: "Poppinsm",
                            fontSize: _font,
                          ),
                        ),
                        Text(
                          "(-${discountAmount == null ? amountShow(amount: "0.0") : amountShow(amount: discountAmount.toString())})",
                          style: TextStyle(
                            fontFamily: "Poppinsm",
                            color: Colors.red,
                            fontSize: _font,
                          ),
                        ),
                      ],
                    ),
                  ),
              const Divider(thickness: 1),
              Visibility(
                visible:
                    vendorModel != null
                        ? vendorModel!.specialDiscountEnable
                        : false,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Special Discount".tr() +
                                "($specialDiscount ${specialType == "amount" ? currencyModel!.symbol : "%"})",
                            style: TextStyle(
                              fontFamily: "Poppinsm",
                              fontSize: _font,
                            ),
                          ),
                          Text(
                            "(-${amountShow(amount: specialDiscountAmount.toString())})",
                            style: TextStyle(
                              fontFamily: "Poppinsm",
                              color: Colors.red,
                              fontSize: _font,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1),
                  ],
                ),
              ),

              selctedOrderTypeValue == "Delivery"
                  ? (widget.fromContainer &&
                          !isDeliverFound &&
                          MyAppState.selectedPosotion.latitude == 0.0 &&
                          MyAppState.selectedPosotion.longitude == 0)
                      ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        child: Text(
                          "Delivery Charge Will Applied Next Step.".tr(),
                          style: TextStyle(
                            fontFamily: "Poppinsm",
                            fontSize: _font,
                          ),
                        ),
                      )
                      : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Delivery Charges".tr(),
                                  style: TextStyle(
                                    fontFamily: "Poppinsm",
                                    fontSize: _font,
                                  ),
                                ),
                                Text(
                                  deliveryChargesToShow == "0"
                                      ? "Free Delivery"
                                      : amountShow(
                                        amount: deliveryCharges.toString(),
                                      ),
                                  style: TextStyle(
                                    fontFamily: "Poppinsm",
                                    color:
                                        isDarkMode(context)
                                            ? const Color(0xffFFFFFF)
                                            : const Color(0xff333333),
                                    fontSize: _font,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(thickness: 1),
                          ],
                        ),
                      )
                  : Container(),

              ListView.builder(
                itemCount: taxList!.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  TaxModel taxModel = taxList![index];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${taxModel.title.toString()} ",
                                // "(${taxModel.type == "fix" ? amountShow(amount: taxModel.tax) : "${taxModel.tax}%"})",
                                style: TextStyle(
                                  fontFamily: "Poppinsm",
                                  fontSize: _font,
                                ),
                              ),
                            ),
                            Text(
                              amountShow(
                                amount:
                                    calculateTax(
                                      amount:
                                          (double.parse(subTotal.toString()) -
                                                  discountAmount -
                                                  specialDiscountAmount)
                                              .toString(),
                                      taxModel: taxModel,
                                    ).toString(),
                              ),
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                color:
                                    isDarkMode(context)
                                        ? const Color(0xffFFFFFF)
                                        : const Color(0xff333333),
                                fontSize: _font,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(thickness: 1),
                    ],
                  );
                },
              ),

              // taxModel != null
              //     ? Container(
              //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              //         child: Row(
              //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //           children: [
              //             Text(
              //               ((taxModel!.label!.isNotEmpty) ? taxModel!.label.toString() : "Tax".tr()) + " ${(taxModel!.type == "fix") ? "" : "(${taxModel!.tax} %)"}",
              //               style: TextStyle(fontFamily: "Poppinsm", fontSize: _font),
              //             ),
              //             Text(
              //               amountShow(amount: getTaxValue(taxModel, subTotal - discountVal - specialDiscountAmount).toString()),
              //               style: TextStyle(fontFamily: "Poppinsm", color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: _font),
              //             ),
              //           ],
              //         ))
              //     : Container(),
              Visibility(
                visible: ((tipValue) > 0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tip amount".tr(),
                            style: TextStyle(
                              fontFamily: "Poppinsm",
                              color:
                                  isDarkMode(context)
                                      ? const Color(0xffFFFFFF)
                                      : const Color(0xff333333),
                              fontSize: _font,
                            ),
                          ),
                          Text(
                            '${amountShow(amount: tipValue.toString())}',
                            style: TextStyle(
                              fontFamily: "Poppinsm",
                              color:
                                  isDarkMode(context)
                                      ? const Color(0xffFFFFFF)
                                      : const Color(0xff333333),
                              fontSize: _font,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order Total".tr(),
                      style: TextStyle(
                        fontFamily: "Poppinsm",
                        color:
                            isDarkMode(context)
                                ? const Color(0xffFFFFFF)
                                : const Color(0xff333333),
                        fontSize: _font,
                      ),
                    ),
                    Text(
                      amountShow(amount: grandtotal.toString()),
                      style: TextStyle(
                        fontFamily: "Poppinsm",
                        color:
                            isDarkMode(context)
                                ? const Color(0xffFFFFFF)
                                : const Color(0xff333333),
                        fontSize: _font,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        selctedOrderTypeValue == "Delivery"
            ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tip your delivery partner".tr(),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: "Poppinsm",
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode(context)
                              ? const Color(0xffFFFFFF)
                              : const Color(0xff333333),
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "100% of the tip will go to your delivery partner".tr(),
                    style: const TextStyle(
                      fontFamily: "Poppinsm",
                      color: Color(0xff9091A4),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isTipSelected) {
                              isTipSelected = false;
                              tipValue = 0;
                            } else {
                              tipValue = 10;
                              isTipSelected = true;
                            }

                            isTipSelected1 = false;
                            isTipSelected2 = false;
                            isTipSelected3 = false;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                          decoration: BoxDecoration(
                            color:
                                tipValue == 10 && isTipSelected
                                    ? Color(COLOR_PRIMARY)
                                    : isDarkMode(context)
                                    ? const Color(DARK_COLOR)
                                    : const Color(0xffFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xff9091A4),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              amountShow(amount: "10"),
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                color:
                                    isDarkMode(context)
                                        ? const Color(0xffFFFFFF)
                                        : const Color(0xff333333),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isTipSelected1) {
                              isTipSelected1 = false;
                              tipValue = 0;
                            } else {
                              tipValue = 20;
                              isTipSelected1 = true;
                            }
                            isTipSelected = false;
                            isTipSelected2 = false;
                            isTipSelected3 = false;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                          decoration: BoxDecoration(
                            color:
                                tipValue == 20 && isTipSelected1
                                    ? Color(COLOR_PRIMARY)
                                    : isDarkMode(context)
                                    ? const Color(DARK_COLOR)
                                    : const Color(0xffFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xff9091A4),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              amountShow(amount: "20"),
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                color:
                                    isDarkMode(context)
                                        ? const Color(0xffFFFFFF)
                                        : const Color(0xff333333),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isTipSelected2) {
                              isTipSelected2 = false;
                              tipValue = 0;
                            } else {
                              tipValue = 30;
                              isTipSelected2 = true;
                            }

                            isTipSelected = false;
                            isTipSelected1 = false;

                            isTipSelected3 = false;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                          decoration: BoxDecoration(
                            color:
                                tipValue == 30 && isTipSelected2
                                    ? Color(COLOR_PRIMARY)
                                    : isDarkMode(context)
                                    ? const Color(DARK_COLOR)
                                    : const Color(0xffFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xff9091A4),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              amountShow(amount: "30"),
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                color:
                                    isDarkMode(context)
                                        ? const Color(0xffFFFFFF)
                                        : const Color(0xff333333),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (isTipSelected3) {
                              setState(() {
                                if (isTipSelected3) {
                                  isTipSelected3 = false;
                                  tipValue = 0;
                                }
                                isTipSelected = false;
                                isTipSelected1 = false;
                                isTipSelected2 = false;
                                // grandtotal += tipValue;
                              });
                            } else {
                              _displayDialog(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                            decoration: BoxDecoration(
                              color:
                                  isTipSelected3
                                      ? Color(COLOR_PRIMARY)
                                      : isDarkMode(context)
                                      ? const Color(DARK_COLOR)
                                      : const Color(0xffFFFFFF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xff9091A4),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Other".tr(),
                                style: TextStyle(
                                  fontFamily: "Poppinsm",
                                  color:
                                      isDarkMode(context)
                                          ? const Color(0xffFFFFFF)
                                          : const Color(0xff333333),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // SizedBox(height: 10,),
                  // Row(
                  //   children: [
                  //     GestureDetector(
                  //       onTap: () {
                  //         if (isTipSelected3) {
                  //           setState(() {
                  //             if (isTipSelected3) {
                  //               isTipSelected3 = false;
                  //               tipValue = 0;
                  //             }
                  //             isTipSelected = false;
                  //             isTipSelected1 = false;
                  //             isTipSelected2 = false;
                  //             // grandtotal += tipValue;
                  //           });
                  //         } else {
                  //           _displayDialog(context);
                  //         }
                  //       },
                  //       child: Container(
                  //         padding:
                  //         const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  //         decoration: BoxDecoration(
                  //           color: isTipSelected3
                  //               ? Color(COLOR_PRIMARY)
                  //               : isDarkMode(context)
                  //               ? const Color(DARK_COLOR)
                  //               : const Color(0xffFFFFFF),
                  //           borderRadius: BorderRadius.circular(8),
                  //           border: Border.all(
                  //               color: const Color(0xff9091A4), width: 1),
                  //         ),
                  //         child: Center(
                  //             child: Text(
                  //               "Other".tr(),
                  //               style: TextStyle(
                  //                   fontFamily: "Poppinsm",
                  //                   color: isDarkMode(context)
                  //                       ? const Color(0xffFFFFFF)
                  //                       : const Color(0xff333333),
                  //                   fontSize: 14),
                  //             )),
                  //       ),
                  //     ),
                  //   ],
                  // )
                ],
              ),
            )
            : Container(),
      ],
    );
  }

  // showSheet(CartProduct cartProduct) async {
  //   bool? shouldUpdate = await showModalBottomSheet(
  //     isDismissible: true,
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => CartOptionsSheet(
  //       cartProduct: cartProduct,
  //     ),
  //   );
  //   if (shouldUpdate != null) {
  //     cartFuture = cartDatabase.allCartProducts;
  //     setState(() {});
  //   }
  // }

  addtocard(CartProduct cartProduct, qun) async {
    await cartDatabase.updateProduct(
      CartProduct(
        id: cartProduct.id,
        name: cartProduct.name,
        photo: cartProduct.photo,
        packingcharges: cartProduct.packingcharges,
        price: cartProduct.price,
        vendorID: cartProduct.vendorID,
        quantity: qun,
        category_id: cartProduct.category_id,
        discountPrice: cartProduct.discountPrice?.toString() ?? "0.0",
      ),
    );
  }

  removetocard(CartProduct cartProduct, qun) async {
    if (qun >= 1) {
      await cartDatabase.updateProduct(
        CartProduct(
          id: cartProduct.id,
          category_id: cartProduct.category_id,
          name: cartProduct.name,
          photo: cartProduct.photo,
          packingcharges: cartProduct.packingcharges,
          price: cartProduct.price,
          vendorID: cartProduct.vendorID,
          quantity: qun,
          discountPrice: cartProduct.discountPrice,
        ),
      );
    } else {
      cartDatabase.removeProduct(cartProduct.id);
    }
  }

  OfferModel? couponModel;

  sheet() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height / 4.3,
        left: 25,
        right: 25,
      ),
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(style: BorderStyle.none),
      ),
      child: FutureBuilder<List<OfferModel>>(
        future: coupon,
        initialData: const [],
        builder: (context, snapshot) {
          snapshot = snapshot;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
              ),
            );
          }

          // coupon = snapshot.data as Future<List<CouponModel>> ;
          return Column(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 0.3),
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),

                  // radius: 20,
                  child: const Center(
                    child: Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isDarkMode(context)
                              ? const Color(DarkContainerBorderColor)
                              : Colors.grey.shade100,
                      width: 1,
                    ),
                    color:
                        isDarkMode(context)
                            ? const Color(DarkContainerColor)
                            : Colors.white,
                    boxShadow: [
                      isDarkMode(context)
                          ? const BoxShadow()
                          : BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 5,
                          ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(top: 30),
                          child: const Image(
                            image: AssetImage(
                              'assets/images/redeem_coupon.png',
                            ),
                            width: 100,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            'Redeem Your Coupons'.tr(),
                            style: const TextStyle(
                              fontFamily: 'Poppinssb',
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(top: 10),
                          child:
                              Text(
                                "Voucher or Coupon code".tr(),
                                style: const TextStyle(
                                  fontFamily: 'Poppinsr',
                                  color: Color(0XFF9091A4),
                                  letterSpacing: 0.5,
                                  height: 2,
                                ),
                              ).tr(),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 20,
                          ),
                          // height: 120,
                          child: DottedBorder(
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(12),
                            dashPattern: const [4, 2],
                            color: const Color(0XFFB7B7B7),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                              child: Container(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 20,
                                  bottom: 20,
                                ),
                                // height: 120,
                                alignment: Alignment.center,
                                child: TextFormField(
                                  textAlign: TextAlign.center,
                                  controller: txt,

                                  // textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Write Coupon Code".tr(),
                                    //  hintTextDirection: TextDecoration.lineThrough
                                    // contentPadding: EdgeInsets.only(left: 80,right: 30),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 30, bottom: 30),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 100,
                                vertical: 15,
                              ),
                              backgroundColor: Color(COLOR_PRIMARY),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                for (
                                  int a = 0;
                                  a < snapshot.data!.length;
                                  a++
                                ) {
                                  OfferModel coupon = snapshot.data![a];

                                  if (vendorID == coupon.restaurantId ||
                                      coupon.restaurantId == "") {
                                    if (txt.text.toString() ==
                                        coupon.offerCode!.toString()) {
                                      print(coupon.toJson());
                                      setState(() {
                                        couponModel = coupon;
                                      });

                                      // if (couponModel.discountTypeOffer == 'Percentage' || couponModel.discountTypeOffer == 'Percent') {
                                      //   percentage = double.parse(couponModel.discountOffer!);
                                      //   couponId = couponModel.offerId!;
                                      //   break;
                                      // } else {
                                      //   type = double.parse(couponModel.discountOffer!);
                                      //   couponId = couponModel.offerId!;
                                      // }
                                    }
                                  }
                                }
                              });

                              Navigator.pop(context);
                            },
                            child: Text(
                              "REDEEM NOW".tr(),
                              style: TextStyle(
                                color:
                                    isDarkMode(context)
                                        ? Colors.black
                                        : Colors.white,
                                fontFamily: 'Poppinsm',
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //buildcouponItem(snapshot)
              //  listData(snapshot)
            ],
          );
        },
      ),
    );
  }

  _displayDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Tip your driver partner'.tr()),
          content: TextField(
            controller: _textFieldController,
            textInputAction: TextInputAction.go,
            keyboardType: TextInputType.numberWithOptions(),
            decoration: InputDecoration(hintText: "Enter your tip".tr()),
          ),
          actions: <Widget>[
            new ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(COLOR_PRIMARY),
                textStyle: TextStyle(fontWeight: FontWeight.normal),
              ),
              child: new Text('Cancel'.tr()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(COLOR_PRIMARY),
                textStyle: TextStyle(fontWeight: FontWeight.normal),
              ),
              child: new Text('Submit'.tr()),
              onPressed: () {
                setState(() {
                  var value = _textFieldController.text.toString();
                  if (value.isEmpty) {
                    isTipSelected3 = false;
                    tipValue = 0;
                  } else {
                    isTipSelected3 = true;
                    tipValue = double.parse(value);
                  }
                  isTipSelected = false;
                  isTipSelected1 = false;
                  isTipSelected2 = false;

                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> getPrefData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('musics_key')) {
      final String musicsString = prefs.getString('musics_key')!;
      if (musicsString.isNotEmpty) {
        lstExtras = AddAddonsDemo.decode(musicsString);
        lstExtras.forEach((element) {
          commaSepratedAddOns.add(element.name!);
        });
        commaSepratedAddOnsString = commaSepratedAddOns.join(", ");
        commaSepratedAddSizeString = commaSepratedAddSize.join(", ");
      }
    }
  }

  Future<void> setPrefData() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString("musics_key", "");
    sp.setString("addsize", "");
  }

  Widget tipWidgetMethod({String? amount}) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 5),
        padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
        decoration: BoxDecoration(
          color:
              tipValue == 10 && isTipSelected
                  ? Color(COLOR_PRIMARY)
                  : tipValue == 20 && isTipSelected1
                  ? Color(COLOR_PRIMARY)
                  : tipValue == 30 && isTipSelected2
                  ? Color(COLOR_PRIMARY)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xff9091A4), width: 1),
        ),
        child: Center(
          child: Text(
            amountShow(amount: amount),
            style: TextStyle(
              fontFamily: "Poppinssm",
              color:
                  isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff333333),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  noteSheet() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height / 4.3,
        left: 25,
        right: 25,
      ),
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(style: BorderStyle.none),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 0.3),
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),

              // radius: 20,
              child: Center(
                child: Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
          SizedBox(height: 25),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isDarkMode(context)
                          ? const Color(DarkContainerBorderColor)
                          : Colors.grey.shade100,
                  width: 1,
                ),
                color:
                    isDarkMode(context)
                        ? const Color(DarkContainerColor)
                        : Colors.white,
                boxShadow: [
                  isDarkMode(context)
                      ? const BoxShadow()
                      : BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 5,
                      ),
                ],
              ),
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        'Remarks'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppinssb',
                          color:
                              isDarkMode(context)
                                  ? Color(0XFFD5D5D5)
                                  : Color(0XFF2A2A2A),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 10),
                      child:
                          Text(
                            'Write remarks for restaurant',
                            style: TextStyle(
                              fontFamily: 'Poppinsr',
                              color:
                                  isDarkMode(context)
                                      ? Colors.white70
                                      : Color(0XFF9091A4),
                              letterSpacing: 0.5,
                              height: 2,
                            ),
                          ).tr(),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                      // height: 120,
                      child: DottedBorder(
                        // borderType: BorderType.RRect,
                        // radius: Radius.circular(12),
                        // dashPattern: [4, 2],
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          child: Container(
                            padding: EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 20,
                              bottom: 20,
                            ),
                            alignment: Alignment.center,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              controller: noteController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Write Remarks'.tr(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 30),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 15,
                          ),
                          backgroundColor: Color(COLOR_PRIMARY),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'SUBMIT'.tr(),
                          style: TextStyle(
                            color:
                                isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black,
                            fontFamily: 'Poppinsm',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showDateTimeBottomSheet(
    BuildContext context,
    Function(DateTime) onDateTimeSelected,
  ) {
    getScheduleOrderMinutes();
    DateTime now = DateTime.now();
    DateTime minimumAllowedTime = now.add(
      Duration(minutes: (int.parse(Dynamicminutes ?? '') + 5)),
    ); // Add 30 minutes
    DateTime selectedDate = minimumAllowedTime;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Date & Time',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: CupertinoDatePicker(
                      initialDateTime: selectedDate,
                      minimumDate: minimumAllowedTime,
                      mode: CupertinoDatePickerMode.dateAndTime,
                      onDateTimeChanged: (DateTime newDate) {
                        setState(() => selectedDate = newDate);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      alignment: Alignment.center,
                    ),
                    onPressed: () {
                      onDateTimeSelected(selectedDate);
                      print("selectedDateselectedDate${selectedDate}");
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Confirm',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Future<List<Map<String, dynamic>>> fetchWorkingHours(String vendorId) async {
  //   DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
  //       .collection('vendors')
  //       .doc(vendorId)
  //       .get();
  //
  //   if (vendorDoc.exists) {
  //     var workingHours = vendorDoc['workingHours'] as List<dynamic>? ?? [];
  //     print("workingHoursworkingHoursworkingHours${workingHours}");
  //     return workingHours.map((e) => e as Map<String, dynamic>).toList();
  //   } else {
  //     throw Exception("Vendor not found");
  //   }
  // }
  // void showDateTimeBottomSheet12(
  //     BuildContext context,
  //     Function(DateTime) onDateTimeSelected,
  //     List<Map<String, dynamic>> workingHours,
  //     ) {
  //   DateTime now = DateTime.now();
  //   DateTime selectedDate = now.add(const Duration(days: 1)); // Start from tomorrow
  //
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           String selectedDay = [
  //             "Sunday",
  //             "Monday",
  //             "Tuesday",
  //             "Wednesday",
  //             "Thursday",
  //             "Friday",
  //             "Saturday"
  //           ][selectedDate.weekday % 7];
  //
  //           List<Map<String, String>> availableTimeSlots =
  //           getTimeSlotsForDay(workingHours, selectedDay);
  //
  //           return Container(
  //             padding: const EdgeInsets.all(16),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const Text(
  //                   'Select Date & Time',
  //                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 SizedBox(
  //                   height: 200,
  //                   child: CupertinoDatePicker(
  //                     initialDateTime: selectedDate,
  //                     minimumDate: now.add(const Duration(days: 1)),
  //                     mode: CupertinoDatePickerMode.dateAndTime,
  //                     onDateTimeChanged: (DateTime newDate) {
  //                       setState(() {
  //                         selectedDate = newDate;
  //                         selectedDay = [
  //                           "Sunday",
  //                           "Monday",
  //                           "Tuesday",
  //                           "Wednesday",
  //                           "Thursday",
  //                           "Friday",
  //                           "Saturday"
  //                         ][newDate.weekday % 7];
  //                         availableTimeSlots =
  //                             getTimeSlotsForDay(workingHours, selectedDay);
  //                       });
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 availableTimeSlots.isEmpty
  //                     ? const Text('No available slots for this day.')
  //                     : Expanded(
  //                   child: ListView.builder(
  //                     shrinkWrap: true,
  //                     itemCount: availableTimeSlots.length,
  //                     itemBuilder: (context, index) {
  //                       final slot = availableTimeSlots[index];
  //                       return Card(
  //                         child: ListTile(
  //                           title: Text(
  //                             "From: ${slot['from']} To: ${slot['to']}",
  //                             style: const TextStyle(fontSize: 16),
  //                           ),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 ElevatedButton(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: const Color(0xFF007AFF),
  //                   ),
  //                   onPressed: () {
  //                     onDateTimeSelected(selectedDate);
  //                     Navigator.of(context).pop();
  //                   },
  //                   child: const Text(
  //                     'Confirm',
  //                     style: TextStyle(color: Colors.white),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  String? auto_apply_coupon_id;
  num discountadmindiscount = 0;
  num? pricenew;
  bool? auto_apply;

  /// code already working
  //   Future<List<Map<String, dynamic>>> fetchWorkingHours(String vendorId) async {
  //     print("fetchworking valu call thaya che");
  //     DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
  //         .collection('vendors')
  //         .doc(vendorId)
  //         .get();
  //
  //     if (vendorDoc.exists) {
  //       var workingHours = vendorDoc['workingHours'] as List<dynamic>? ?? [];
  //       auto_apply_coupon_id=vendorDoc['auto_apply_coupon_id'].toString();
  //       auto_apply = vendorDoc['auto_apply'];
  //
  //       // discountadmindiscount = vendorDoc['auto_apply_discount'];
  //        discountadmindiscount =num.parse(vendorDoc['auto_apply_discount'].toString());
  //
  //
  //       print("workingHours: $workingHours");
  //       print("workingHours gdfgdfg: $auto_apply_coupon_id");
  //       print("workingHoursgdfgdfgdfgdfgdfg:  $auto_apply");
  //       print("workingHoursgdfgdfgdfgdfgdfg:  $discountadmindiscount");
  //       auto_apply==true? getCityrestaurantcity():print("aoto apply  false ave che");
  //       // Convert to a list of maps
  //       return workingHours.map((e) => e as Map<String, dynamic>).toList();
  //     } else {
  //       throw Exception("Vendor not found");
  //     }
  //   }

  Future<List<Map<String, dynamic>>> fetchWorkingHours() async {
    print("fetchworking valu call thaya che${vendoridvendorid}");

    DocumentSnapshot vendorDoc =
        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendoridvendorid)
            .get();
    checkIfVendorIsOpen(vendoridvendorid);
    if (vendorDoc.exists) {
      var vendorData = vendorDoc.data() as Map<String, dynamic>? ?? {};

      var workingHours = vendorData['workingHours'] as List<dynamic>? ?? [];
      setState(() {
        auto_apply_coupon_id =
            vendorData.containsKey('auto_apply_coupon_id')
                ? vendorData['auto_apply_coupon_id'].toString()
                : "";

        auto_apply =
            vendorData.containsKey('auto_apply')
                ? vendorData['auto_apply']
                : false;

        discountadmindiscount =
            vendorData.containsKey('auto_apply_discount')
                ? num.tryParse(vendorData['auto_apply_discount'].toString()) ??
                    0
                : 0;

        print("workingHours: $workingHours");
        print("auto_apply_coupon_id: $auto_apply_coupon_id");
        print("auto_apply: $auto_apply");
        print("discountadmindiscount: $discountadmindiscount");
      });

      if (auto_apply == true) {
        getCityrestaurantcity();
      } else {
        setState(() {
          isload = false;
        });
        print("auto apply false che");
      }
      // auto_apply == true ?  : ;

      // Convert to a list of maps
      return workingHours.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception("Vendor not found");
    }
  }

  // void showDateTimeBottomSheet12(
  //     BuildContext context,
  //     Function(DateTime) onDateTimeSelected,
  //     List<Map<String, dynamic>> workingHours,
  //     ) {
  //   DateTime now = DateTime.now();
  //   DateTime selectedDate = now.add(const Duration(days: 1)); // Start from tomorrow
  //
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           String selectedDay = [
  //             "Sunday",
  //             "Monday",
  //             "Tuesday",
  //             "Wednesday",
  //             "Thursday",
  //             "Friday",
  //             "Saturday"
  //           ][selectedDate.weekday % 7];
  //
  //           // Get available time slots for the selected day
  //           List<Map<String, String>> availableTimeSlots =
  //           getTimeSlotsForDay(workingHours, selectedDay);
  //
  //           return Container(
  //             padding: const EdgeInsets.all(16),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const Text(
  //                   'Select Date & Time',
  //                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 SizedBox(
  //                   height: 200,
  //                   child: CupertinoDatePicker(
  //                     initialDateTime: selectedDate,
  //                     minimumDate: now.add(const Duration(days: 1)),
  //                     mode: CupertinoDatePickerMode.dateAndTime,
  //                     onDateTimeChanged: (DateTime newDate) {
  //                       setState(() {
  //                         selectedDate = newDate;
  //                         selectedDay = [
  //                           "Sunday",
  //                           "Monday",
  //                           "Tuesday",
  //                           "Wednesday",
  //                           "Thursday",
  //                           "Friday",
  //                           "Saturday"
  //                         ][newDate.weekday % 7];
  //                         availableTimeSlots =
  //                             getTimeSlotsForDay(workingHours, selectedDay);
  //                       });
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 availableTimeSlots.isEmpty
  //                     ? catproducatmart=="grocery"?Text('Mart closed for this time.'):Text('Restaurant closed for this time.')
  //                     : Expanded(
  //                   child: ListView.builder(
  //                     shrinkWrap: true,
  //                     itemCount: availableTimeSlots.length,
  //                     itemBuilder: (context, index) {
  //                       final slot = availableTimeSlots[index];
  //                       return Card(
  //                         child: ListTile(
  //                           title: Text(
  //                             "From: ${slot['from']} To: ${slot['to']}",
  //                             style: const TextStyle(fontSize: 16),
  //                           ),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 availableTimeSlots.isEmpty?Container():ElevatedButton(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: const Color(0xFF007AFF),
  //                   ),
  //                   onPressed: () {
  //                     onDateTimeSelected(selectedDate);
  //                     Navigator.of(context).pop();
  //                   },
  //                   child: const Text(
  //                     'Confirm',
  //                     style: TextStyle(color: Colors.white),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  ///code work kare che
  // void showDateTimeBottomSheet12(
  //     BuildContext context,
  //     Function(DateTime) onDateTimeSelected,
  //     List<Map<String, dynamic>> workingHours,
  //     ) {
  //   DateTime now = DateTime.now();
  //   DateTime selectedDate = now; // Start from tomorrow
  //
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           String selectedDay = [
  //             "Sunday",
  //             "Monday",
  //             "Tuesday",
  //             "Wednesday",
  //             "Thursday",
  //             "Friday",
  //             "Saturday"
  //           ][selectedDate.weekday % 7];
  //
  //           // Get available time slots for the selected day
  //           List<Map<String, String>> availableTimeSlots =
  //           getTimeSlotsForDay(workingHours, selectedDay);
  //
  //           // Function to check if selected time is within working hours
  //           bool isSelectedTimeValid(DateTime selectedDateTime) {
  //             for (var slot in availableTimeSlots) {
  //               var fromTime = _parseTime(slot['from']!);
  //               var toTime = _parseTime(slot['to']!);
  //
  //               DateTime slotStart = DateTime(
  //                 selectedDateTime.year,
  //                 selectedDateTime.month,
  //                 selectedDateTime.day,
  //                 fromTime['hour']!,
  //                 fromTime['minute']!,
  //               );
  //
  //               DateTime slotEnd = DateTime(
  //                 selectedDateTime.year,
  //                 selectedDateTime.month,
  //                 selectedDateTime.day,
  //                 toTime['hour']!,
  //                 toTime['minute']!,
  //               );
  //
  //               if (selectedDateTime.isAfter(slotStart) && selectedDateTime.isBefore(slotEnd)) {
  //                 return true;
  //               }
  //             }
  //             return false;
  //           }
  //
  //
  //           return Container(
  //             padding: const EdgeInsets.all(16),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const Text(
  //                   'Select Date & Time',
  //                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 SizedBox(
  //                   height: 200,
  //                   child: CupertinoDatePicker(
  //                     initialDateTime: selectedDate,
  //                     minimumDate: now.add(const Duration(days: 1)),
  //                     mode: CupertinoDatePickerMode.dateAndTime,
  //                     onDateTimeChanged: (DateTime newDate) {
  //                       setState(() {
  //                         selectedDate = newDate;
  //                         selectedDay = [
  //                           "Sunday",
  //                           "Monday",
  //                           "Tuesday",
  //                           "Wednesday",
  //                           "Thursday",
  //                           "Friday",
  //                           "Saturday"
  //                         ][newDate.weekday % 7];
  //                         availableTimeSlots =
  //                             getTimeSlotsForDay(workingHours, selectedDay);
  //                       });
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 availableTimeSlots.isEmpty
  //                     ? catproducatmart == "grocery"
  //                     ? Text('Mart closed for this time.')
  //                     : Text('Restaurant closed for this time.')
  //                     : Expanded(
  //                   child: ListView.builder(
  //                     shrinkWrap: true,
  //                     itemCount: availableTimeSlots.length,
  //                     itemBuilder: (context, index) {
  //                       final slot = availableTimeSlots[index];
  //                       return Card(
  //                         child: ListTile(
  //                           title: Text(
  //                             "From: ${slot['from']} To: ${slot['to']}",
  //                             style: const TextStyle(fontSize: 16),
  //                           ),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 availableTimeSlots.isEmpty
  //                     ? Container()
  //                     : ElevatedButton(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: const Color(0xFF007AFF),
  //                   ),
  //                   onPressed: () {
  //                     // Check if the selected time is within working hours
  //                     if (isSelectedTimeValid(selectedDate)) {
  //                       onDateTimeSelected(selectedDate);
  //                       Navigator.of(context).pop();
  //                     } else {
  //                       Navigator.of(context).pop();
  //                       // Show error message
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         SnackBar(content: Text('Selected time is outside working hours.')),
  //                       );
  //                     }
  //                   },
  //                   child: const Text(
  //                     'Confirm',
  //                     style: TextStyle(color: Colors.white),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
  /// new code che
  //   void showDateTimeBottomSheet12(
  //       BuildContext context,
  //       Function(DateTime) onDateTimeSelected,
  //       List<Map<String, dynamic>> workingHours,
  //       // Added parameter to check Mart or Restaurant
  //       ) {
  //     DateTime now = DateTime.now();
  //     DateTime minimumDate = now.add(const Duration(days: 1));
  //     DateTime selectedDate = minimumDate; // Ensure it starts from tomorrow
  //
  //     showModalBottomSheet(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return StatefulBuilder(
  //           builder: (BuildContext context, StateSetter setState) {
  //             String selectedDay = [
  //               "Sunday",
  //               "Monday",
  //               "Tuesday",
  //               "Wednesday",
  //               "Thursday",
  //               "Friday",
  //               "Saturday"
  //             ][selectedDate.weekday % 7];
  //
  //             // Get available time slots for the selected day
  //             List<Map<String, String>> availableTimeSlots =
  //             getTimeSlotsForDay(workingHours, selectedDay);
  //
  //             // Function to check if selected time is within working hours
  //             bool isSelectedTimeValid(DateTime selectedDateTime) {
  //               for (var slot in availableTimeSlots) {
  //                 var fromTime = _parseTime(slot['from']!);
  //                 var toTime = _parseTime(slot['to']!);
  //
  //                 DateTime slotStart = DateTime(
  //                   selectedDateTime.year,
  //                   selectedDateTime.month,
  //                   selectedDateTime.day,
  //                   fromTime['hour']!,
  //                   fromTime['minute']!,
  //                 );
  //
  //                 DateTime slotEnd = DateTime(
  //                   selectedDateTime.year,
  //                   selectedDateTime.month,
  //                   selectedDateTime.day,
  //                   toTime['hour']!,
  //                   toTime['minute']!,
  //                 );
  //
  //                 if (selectedDateTime.isAfter(slotStart) &&
  //                     selectedDateTime.isBefore(slotEnd)) {
  //                   return true;
  //                 }
  //               }
  //               return false;
  //             }
  //
  //             return Container(
  //               padding: const EdgeInsets.all(16),
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   const Text(
  //                     'Select Date & Time',
  //                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  //                   ),
  //                   const SizedBox(height: 20),
  //                   SizedBox(
  //                     height: 200,
  //                     child: CupertinoDatePicker(
  //                       initialDateTime: selectedDate,
  //                       minimumDate: minimumDate,
  //                       mode: CupertinoDatePickerMode.dateAndTime,
  //                       onDateTimeChanged: (DateTime newDate) {
  //                         setState(() {
  //                           selectedDate = newDate.isBefore(minimumDate)
  //                               ? minimumDate
  //                               : newDate;
  //                           selectedDay = [
  //                             "Sunday",
  //                             "Monday",
  //                             "Tuesday",
  //                             "Wednesday",
  //                             "Thursday",
  //                             "Friday",
  //                             "Saturday"
  //                           ][selectedDate.weekday % 7];
  //                           availableTimeSlots =
  //                               getTimeSlotsForDay(workingHours, selectedDay);
  //                         });
  //                       },
  //                     ),
  //                   ),
  //                   const SizedBox(height: 20),
  //                   availableTimeSlots.isEmpty
  //                       ? Text(catproducatmart == "grocery"
  //                       ? 'Mart closed for this time.'
  //                       : 'Restaurant closed for this time.')
  //                       : Expanded(
  //                     child: ListView.builder(
  //                       shrinkWrap: true,
  //                       itemCount: availableTimeSlots.length,
  //                       itemBuilder: (context, index) {
  //                         final slot = availableTimeSlots[index];
  //                         return Card(
  //                           child: ListTile(
  //                             title: Text(
  //                               "From: ${slot['from']} To: ${slot['to']}",
  //                               style: const TextStyle(fontSize: 16),
  //                             ),
  //                           ),
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                   const SizedBox(height: 20),
  //                   availableTimeSlots.isEmpty
  //                       ? Container()
  //                       : ElevatedButton(
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: const Color(0xFF007AFF),
  //                     ),
  //                     onPressed: () {
  //                       // Check if the selected time is within working hours
  //                       if (isSelectedTimeValid(selectedDate)) {
  //                         onDateTimeSelected(selectedDate);
  //                         Navigator.of(context).pop();
  //                       } else {
  //                         Navigator.of(context).pop();
  //                         // Show error message
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           SnackBar(
  //                               content: Text(
  //                                   'Selected time is outside working hours.')),
  //                         );
  //                       }
  //                     },
  //                     child: const Text(
  //                       'Confirm',
  //                       style: TextStyle(color: Colors.white),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           },
  //         );
  //       },
  //     );
  //   }
  //
  //   Map<String, int> _parseTime(String time) {
  //     List<String> timeParts = time.split(':');
  //     int hour = int.parse(timeParts[0]);
  //     int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
  //
  //     return {'hour': hour, 'minute': minute};
  //   }
  //
  List<Map<String, String>> getTimeSlotsForDay(
    List<Map<String, dynamic>> workingHours,
    String selectedDay,
  ) {
    var daySlots =
        workingHours.where((slot) => slot['day'] == selectedDay).toList();

    List<Map<String, String>> availableSlots =
        daySlots.expand((daySlot) {
          List<Map<String, String>> slots = [];
          for (var timeSlot in daySlot['timeslot'] as List<dynamic>) {
            slots.add({
              'from': timeSlot['from'], // Ensure this is in 24-hour format
              'to': timeSlot['to'], // Ensure this is in 24-hour format
            });
          }
          return slots;
        }).toList();

    print("availableSlots: $availableSlots");
    return availableSlots;
  }

  void showDateTimeBottomSheet12(
    BuildContext context,
    Function(DateTime) onDateTimeSelected,
    List<Map<String, dynamic>> workingHours,
    // Added parameter to check Mart or Restaurant
  ) {
    DateTime now = DateTime.now();
    DateTime minimumDate = now; // Allow today also
    DateTime selectedDate = minimumDate; // Ensure it starts from today

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            String selectedDay =
                [
                  "Sunday",
                  "Monday",
                  "Tuesday",
                  "Wednesday",
                  "Thursday",
                  "Friday",
                  "Saturday",
                ][selectedDate.weekday % 7];

            // Get available time slots for the selected day
            List<Map<String, String>> availableTimeSlots = getTimeSlotsForDay(
              workingHours,
              selectedDay,
            );

            // Function to check if selected time is within working hours
            bool isSelectedTimeValid(DateTime selectedDateTime) {
              for (var slot in availableTimeSlots) {
                var fromTime = _parseTime(slot['from']!);
                var toTime = _parseTime(slot['to']!);

                DateTime slotStart = DateTime(
                  selectedDateTime.year,
                  selectedDateTime.month,
                  selectedDateTime.day,
                  fromTime['hour']!,
                  fromTime['minute']!,
                );

                DateTime slotEnd = DateTime(
                  selectedDateTime.year,
                  selectedDateTime.month,
                  selectedDateTime.day,
                  toTime['hour']!,
                  toTime['minute']!,
                );

                if (selectedDateTime.isAfter(slotStart) &&
                    selectedDateTime.isBefore(slotEnd)) {
                  return true;
                }
              }
              return false;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Date & Time',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: CupertinoDatePicker(
                      initialDateTime: selectedDate,
                      minimumDate: minimumDate,
                      mode: CupertinoDatePickerMode.dateAndTime,
                      onDateTimeChanged: (DateTime newDate) {
                        setState(() {
                          selectedDate =
                              newDate.isBefore(minimumDate)
                                  ? minimumDate
                                  : newDate;
                          selectedDay =
                              [
                                "Sunday",
                                "Monday",
                                "Tuesday",
                                "Wednesday",
                                "Thursday",
                                "Friday",
                                "Saturday",
                              ][selectedDate.weekday % 7];
                          availableTimeSlots = getTimeSlotsForDay(
                            workingHours,
                            selectedDay,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  availableTimeSlots.isEmpty
                      ? Text(
                        catproducatmart == "grocery"
                            ? 'Mart closed for this time.'
                            : 'Restaurant closed for this time.',
                      )
                      : Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableTimeSlots.length,
                          itemBuilder: (context, index) {
                            final slot = availableTimeSlots[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  "From: ${formatTime(slot['from'].toString())} To: ${formatTime(slot['to'].toString())}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  const SizedBox(height: 20),
                  availableTimeSlots.isEmpty
                      ? Container()
                      : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                        ),
                        onPressed: () {
                          // Check if the selected time is within working hours
                          if (isSelectedTimeValid(selectedDate)) {
                            onDateTimeSelected(selectedDate);
                            print(
                              "selectedDatedsfdsfsd${formatTime1(selectedDate.toString())}",
                            );

                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pop();
                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Selected time is outside working hours.',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Confirm',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String formatTime(String time) {
    DateTime dateTime = DateTime.parse(
      "2024-01-01 $time",
    ); // ફક્ત સમય માટે ડેટા ઉમેરવો જરૂરી છે
    return DateFormat.jm().format(dateTime); // 12-કલાકનું ફોર્મેટ (AM/PM)
  }

  String formatTime1(String time) {
    DateTime dateTime = DateTime.parse(
      "$time",
    ); // ફક્ત સમય માટે ડેટા ઉમેરવો જરૂરી છે
    return DateFormat.jm().format(dateTime); // 12-કલાકનું ફોર્મેટ (AM/PM)
  }

  // Function to parse time string into hours and minutes
  Map<String, int> _parseTime(String time) {
    List<String> parts = time.split(':');
    return {'hour': int.parse(parts[0]), 'minute': int.parse(parts[1])};
  }

  // Dummy function for fetching available time slots

  /// a code haresh karelo che
  // void showDateTimeBottomSheet1(
  //     BuildContext context, Function(DateTime) onDateTimeSelected) {
  //   getScheduleOrderMinutes();
  //   DateTime now = DateTime.now();
  //   int dynamicMinutes = int.tryParse(Dynamicminutes ?? '') ?? 0; // Default to 0 if null or invalid
  //
  //   // Set minimum allowed date to tomorrow
  //   DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
  //   DateTime minimumAllowedTime = tomorrow.add(Duration(minutes: dynamicMinutes)); // Add any dynamic minutes
  //
  //   DateTime selectedDate = minimumAllowedTime;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return Container(
  //             padding: const EdgeInsets.all(16),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const Text(
  //                   'Select Date & Time',
  //                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 SizedBox(
  //                   height: 200,
  //                   child: CupertinoDatePicker(
  //                     initialDateTime: selectedDate,
  //                     minimumDate: minimumAllowedTime,
  //                     mode: CupertinoDatePickerMode.dateAndTime,
  //                     onDateTimeChanged: (DateTime newDate) {
  //                       setState(() => selectedDate = newDate);
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 ElevatedButton(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: const Color(0xFF007AFF),
  //                     alignment: Alignment.center,
  //                   ),
  //                   onPressed: () {
  //                     onDateTimeSelected(selectedDate);
  //                     Navigator.of(context).pop();
  //                   },
  //                   child: const Text(
  //                     'Confirm',
  //                     style: TextStyle(color: Colors.white),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  /// chat gpt code

  // _apply() async {
  //   if (nameCoupon == "Applied") {
  //     discountAmount = 0.0;
  //     editableCoupon = true;
  //     nameCoupon = "Apply";
  //     couponTextField.text = "";
  //     return;
  //   } else {
  //     var discount = 0.0;
  //     int? maxdiscount = 0;
  //     int? minamount = 0;
  //     var type = "";
  //     var data = await _fireStoreUtils.getAllCoupons();
  //     if (data.length > 0) {
  //       data.forEach((dataItem) =>
  //       {
  //         if (dataItem.offerCode == couponTextField.text)
  //           {
  //             discount = double.parse(dataItem.discount!),
  //             maxdiscount = int.parse(dataItem.maxdiscount!),
  //             type = dataItem.discountType!,
  //             minamount = int.parse(dataItem.minamount!),
  //             coponid123=dataItem.offerId.toString()
  //           }
  //       });
  //     }
  //
  //     if (type == "Percent") {
  //       discountAmount = (subTotal * discount) / 100;
  //     } else {
  //       discountAmount = discount;
  //     }
  //     if (subTotal < minamount!) {
  //       discountAmount = 0.0;
  //       editableCoupon = true;
  //       showAlertDialog(context, minamount!);
  //     } else if (discountAmount > maxdiscount!) {
  //       discountAmount = maxdiscount!.toDouble();
  //       editableCoupon = false;
  //       nameCoupon = "Applied";
  //     } else {
  //       editableCoupon = false;
  //       nameCoupon = "Applied";
  //     }
  //   }
  // }
  // _apply() async {
  //   if (nameCoupon == "Applied") {
  //     discountAmount = 0.0;
  //     editableCoupon = true;
  //     nameCoupon = "Apply";
  //     couponTextField.text = "";
  //     return;
  //   } else {
  //     var discount = 0.0;
  //     int? maxdiscount = 0;
  //     int? minamount = 0;
  //     var type = "";
  //
  //     var data = await _fireStoreUtils.getAllCoupons();
  //     if (data.length > 0) {
  //       data.forEach((dataItem) {
  //         if (dataItem.offerCode == couponTextField.text) {
  //           discount = double.parse(dataItem.discount!);
  //           maxdiscount = int.parse(dataItem.maxdiscount!);
  //           type = dataItem.discountType!;
  //           minamount = int.parse(dataItem.minamount!);
  //           coponid123 = dataItem.offerId.toString();
  //         }
  //       });
  //     }
  //
  //     // Ensure coponid123 is not empty before checking coupon usage
  //     if (coponid123.isNotEmpty) {
  //       String userId = MyAppState.currentUser?.userID ??
  //           ""; // replace with the actual user ID
  //       bool hasExceededLimit =
  //           await hasUserExceededCouponUseLimit(userId, coponid123);
  //
  //       if (hasExceededLimit) {
  //         final snackBar = SnackBar(
  //           backgroundColor:
  //               isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
  //           content: Text(
  //             'coupon_limit'.tr(),
  //             style: TextStyle(
  //                 color: isDarkMode(context) ? Colors.black : Colors.white),
  //           ),
  //         );
  //         return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //       }
  //     }
  //
  //     if (type == "Percent") {
  //       discountAmount = (subTotal * discount) / 100;
  //     } else {
  //       discountAmount = discount;
  //     }
  //
  //     if (subTotal < minamount!) {
  //       discountAmount = 0.0;
  //       editableCoupon = true;
  //     } else if (discountAmount > maxdiscount!) {
  //       discountAmount = maxdiscount!.toDouble();
  //       editableCoupon = false;
  //       nameCoupon = "Applied";
  //     } else {
  //       editableCoupon = false;
  //       nameCoupon = "Applied";
  //     }
  //   }
  // }
  //
  // Future<bool> hasUserExceededCouponUseLimit(
  //     String userId, String couponId) async {
  //   // Reference to the coupons collection
  //   CollectionReference couponsCollection =
  //       FirebaseFirestore.instance.collection('coupons');
  //
  //   // Reference to the coupon_used collection
  //   CollectionReference couponUsedCollection =
  //       FirebaseFirestore.instance.collection('coupon_used');
  //
  //   // Get the coupon document from the coupons collection
  //   DocumentSnapshot couponDoc = await couponsCollection.doc(couponId).get();
  //
  //   if (!couponDoc.exists) {
  //     throw Exception('Coupon not found');
  //   }
  //
  //   // Get the coupon_use_count from the coupon document
  //   int couponUseCount;
  //   try {
  //     couponUseCount = couponDoc['coupon_use_count'] is int
  //         ? couponDoc['coupon_use_count']
  //         : int.parse(couponDoc['coupon_use_count']);
  //     print("couponUseCount${couponUseCount}");
  //   } catch (e) {
  //     print("Invalid coupon_use_count value");
  //     throw Exception('Invalid coupon_use_count value');
  //   }
  //
  //   // Query the coupon_used collection to count how many times the user has used the coupon
  //   QuerySnapshot userCouponUsage = await couponUsedCollection
  //       .where('coupon_id', isEqualTo: couponId)
  //       .where('user_id', isEqualTo: userId)
  //       .get();
  //
  //   int userUsageCount = userCouponUsage.size;
  //   print("userId${userId}");
  //   print("couponId${couponId}");
  //   print("userUsageCount${userUsageCount}");
  //
  //   // Check if the user has used the coupon more times than allowed
  //   return userUsageCount >= couponUseCount;
  // }

  //upar code working
  /// a code working che 17-02-2025
  //   _apply() async {
  //     if (nameCoupon == "Applied") {
  //       discountAmount = 0.0;
  //       editableCoupon = true;
  //       nameCoupon = "Apply";
  //       couponTextField.text = "";
  //       return;
  //     } else {
  //       var discount = 0.0;
  //       int? maxdiscount = 0;
  //       int? minamount = 0;
  //       var type = "";
  //
  //       var data = await _fireStoreUtils.getAllCoupons();
  //       if (data.length > 0) {
  //         data.forEach((dataItem) {
  //           if (dataItem.offerCode == couponTextField.text) {
  //             discount = double.parse(dataItem.discount!);
  //             maxdiscount = int.parse(dataItem.maxdiscount!);
  //             type = dataItem.discountType!;
  //             minamount = int.parse(dataItem.minamount!);
  //             coponid123 = dataItem.offerId.toString();
  //           }
  //         });
  //       }
  //
  //       // Ensure coponid123 is not empty before checking coupon usage
  //       if (coponid123.isNotEmpty) {
  //         String userId = MyAppState.currentUser?.userID ?? "";
  //
  //         bool hasExceededLimit =
  //             await hasUserExceededCouponUseLimit(userId, coponid123);
  // print("hasExceededLimithasExceededLimit${hasExceededLimit}");
  //         if (hasExceededLimit) {
  //           final snackBar = SnackBar(
  //             backgroundColor:
  //                 isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
  //             content: Text(
  //               'coupon_limit'.tr(),
  //               style: TextStyle(
  //                   color: isDarkMode(context) ? Colors.black : Colors.white),
  //             ),
  //           );
  //           return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //         }
  //       }
  //
  //       if (type == "Percent") {
  //         discountAmount = (subTotal * discount) / 100;
  //       } else {
  //         discountAmount = discount;
  //       }
  //
  //       if (subTotal < minamount!) {
  //         discountAmount = 0.0;
  //         editableCoupon = true;
  //       } else if (discountAmount > maxdiscount!) {
  //         discountAmount = maxdiscount!.toDouble();
  //         editableCoupon = false;
  //         nameCoupon = "Applied";
  //       } else {
  //         editableCoupon = false;
  //         nameCoupon = "Applied";
  //       }
  //     }
  //   }
  /// a code working che
  _apply() async {
    if (nameCoupon == "Applied") {
      discountAmount = 0.0;
      editableCoupon = true;
      nameCoupon = "Apply";
      couponTextField.text = "";
      return;
    } else {
      var discount = 0.0;
      int? maxdiscount = 0;
      int? minamount = 0;
      var type = "";
      bool isExpired = false;
      bool isValidCoupon = false;

      var data = await _fireStoreUtils.getAllCoupons();
      if (data.isNotEmpty) {
        for (var dataItem in data) {
          if (dataItem.offerCode == couponTextField.text) {
            Timestamp expireTime = dataItem.expireOfferDate!;
            if (expireTime.toDate().isBefore(DateTime.now())) {
              isExpired = true;
              break;
            }

            discount = double.parse(dataItem.discount!.toString());
            maxdiscount = int.parse(dataItem.maxdiscount!);
            type = dataItem.discountType!;
            minamount = int.parse(dataItem.minamount!);
            coponid123 = dataItem.offerId.toString();
            isValidCoupon = true;
          }
        }
      }

      // **Check if Coupon is Expired First**
      if (isExpired) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
                isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
            content: Text(
              'Coupon is expired!',
              style: TextStyle(
                color: isDarkMode(context) ? Colors.black : Colors.white,
              ),
            ),
          ),
        );
        return;
      }

      // **Ensure coupon is valid before applying any logic**
      // if (!isValidCoupon) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       backgroundColor: isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
      //       content: Text(
      //         'Invalid coupon code!',
      //         style: TextStyle(
      //             color: isDarkMode(context) ? Colors.black : Colors.white),
      //       ),
      //     ),
      //   );
      //   return;
      // }

      if (coponid123.isNotEmpty) {
        String userId = MyAppState.currentUser?.userID ?? "";

        bool hasExceededLimit = await hasUserExceededCouponUseLimit(
          userId,
          coponid123,
        );
        if (hasExceededLimit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor:
                  isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
              content: Text(
                'You have exceeded the coupon usage limit!',
                style: TextStyle(
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                ),
              ),
            ),
          );
          return;
        }
      }

      // **Only apply discount if coupon is valid**
      if (type == "Percent") {
        discountAmount = (subTotal * discount) / 100;
      } else {
        discountAmount = discount;
      }

      if (subTotal < minamount!) {
        discountAmount = 0.0;
        editableCoupon = true;
      } else if (discountAmount > maxdiscount!) {
        discountAmount = maxdiscount!.toDouble();
        editableCoupon = false;
        nameCoupon = "Applied";
      } else {
        editableCoupon = false;
        nameCoupon = "Applied";
      }
    }
  }

  Future<bool> hasUserExceededCouponUseLimit(
    String userId,
    String couponId,
  ) async {
    // Reference to the coupons collection
    CollectionReference couponsCollection = FirebaseFirestore.instance
        .collection('coupons');

    // Reference to the coupon_used collection
    CollectionReference couponUsedCollection = FirebaseFirestore.instance
        .collection('coupon_used');

    // Get the coupon document from the coupons collection
    DocumentSnapshot couponDoc = await couponsCollection.doc(couponId).get();

    if (!couponDoc.exists) {
      throw Exception('Coupon not found');
    }

    // Get the coupon_use_count from the coupon document
    dynamic couponUseCount = couponDoc['coupon_use_count'];

    // If coupon_use_count is null or an empty string, it means unlimited usage
    if (couponUseCount == null || couponUseCount.toString().isEmpty) {
      return false;
    }

    int couponUseCountInt;
    try {
      couponUseCountInt =
          couponUseCount is int ? couponUseCount : int.parse(couponUseCount);
      print("couponUseCountInt${couponUseCountInt}");
    } catch (e) {
      print("Invalid coupon_use_count value");
      throw Exception('Invalid coupon_use_count value');
    }

    // Query the coupon_used collection to count how many times the user has used the coupon
    QuerySnapshot userCouponUsage =
        await couponUsedCollection
            .where('coupon_id', isEqualTo: couponId)
            .where('user_id', isEqualTo: userId)
            .get();

    int userUsageCount = userCouponUsage.size;
    print("userId${userId}");
    print("couponId${couponId}");
    print("userUsageCount${userUsageCount}");

    // Check if the user has used the coupon more times than allowed
    return userUsageCount >= couponUseCountInt;
  }
}

Widget _buildChip(String label, int attributesOptionIndex) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xffEEEDED),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(label, style: const TextStyle(color: Colors.black)),
    ),
  );
}

showAlertDialog(BuildContext context, int minamount) {
  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Coupon not available!"),
    content: Text(
      "This coupon can be applied only on orders above $minamount ₹",
    ),
    actions: [okButton],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

class RoundedInputBox extends StatelessWidget {
  late TextEditingController couponTextField;
  late bool editableCoupon;

  RoundedInputBox(TextEditingController couponTextField, bool editableCoupon) {
    this.couponTextField = couponTextField;
    this.editableCoupon = editableCoupon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color:
          isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
      child: TextField(
        controller: couponTextField,
        enabled: editableCoupon,
        decoration: InputDecoration(
          // labelText: 'Please Enter Coupon Code',
          hintText: 'Enter Coupon Code',
          hintStyle: TextStyle(
            color: isDarkMode(context) ? Colors.white : Colors.black,
          ),
          filled: true,

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      ),
    );
  }
}

class ButtonExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Button Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // Add your button's action here
              },
              child: Text('Text Button'),
            ),
          ],
        ),
      ),
    );
  }
}

/// old code
// import 'dart:convert';
// import 'dart:math';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dotted_border/dotted_border.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:foodie_customer/AppGlobal.dart';
// import 'package:foodie_customer/constants.dart';
// import 'package:foodie_customer/main.dart';
// import 'package:foodie_customer/model/DeliveryChargeModel.dart';
// import 'package:foodie_customer/model/ProductModel.dart';
// import 'package:foodie_customer/model/VendorModel.dart';
// import 'package:foodie_customer/model/offer_model.dart';
// import 'package:foodie_customer/model/variant_info.dart';
// import 'package:foodie_customer/services/FirebaseHelper.dart';
// import 'package:foodie_customer/services/helper.dart';
// import 'package:foodie_customer/services/localDatabase.dart';
// import 'package:foodie_customer/ui/deliveryAddressScreen/DeliveryAddressScreen.dart';
// import 'package:foodie_customer/ui/productDetailsScreen/ProductDetailsScreen.dart';
// import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../model/TaxModel.dart';
// import '../../model/mail_setting.dart';
// import '../payment/PaymentScreen.dart';
//
// class CartScreen extends StatefulWidget {
//   final bool fromContainer;
//    bool? isopen;
//   final String? packingCharge;
//   CartScreen({Key? key, this.fromContainer = false, this.packingCharge,this.isopen})
//       : super(key: key);
//
//   @override
//   _CartScreenState createState() => _CartScreenState();
// }
//
// class _CartScreenState extends State<CartScreen> {
//   late Future<List<CartProduct>> cartFuture;
//   late List<CartProduct> cartProducts = [];
//
//   //coupan
//   var nameCoupon = "Apply";
//   final TextEditingController couponTextField = TextEditingController();
//   var editableCoupon = true;
//
//   double subTotal = 0.0;
//   double bevafapdama = 0.0;
//   double razorpayvendoramounttrafar = 0.0;
//   double toatvendoramount = 0.0;
//   String formatTime12Hour(Timestamp timestamp) {
//     DateTime dateTime = timestamp.toDate(); // Timestamp ને DateTime માં ફેરવો
//     return DateFormat("hh:mm a").format(dateTime); // 12-કલાકના AM/PM ફોર્મેટમાં ફેરવો
//   }
//
//   double specialDiscount = 0.0;
//   double specialDiscountAmount = 0.0;
//   String specialType = "";
//   String coponid123 = "";
//   bool isSchedule = false;
//   bool isLiveandScheduled = false;
//
//   TextEditingController noteController = TextEditingController(text: '');
//   late CartDatabase cartDatabase;
//   double grandtotal = 00.0;
//   double discountAmount = 00.0;
//   num? charge;
//   int? quantitycharge;
//   var per = 0.0;
//   late Future<List<OfferModel>> coupon;
//   TextEditingController txt = TextEditingController(text: '');
//   FireStoreUtils _fireStoreUtils = FireStoreUtils();
//   String vendorID = "";
//   late List<AddAddonsDemo> lstExtras = [];
//   late List<String> commaSepratedAddOns = [];
//   late List<String> commaSepratedAddSize = [];
//   String? commaSepratedAddOnsString = "";
//   String? commaSepratedAddSizeString = "";
//   String? adminCommissionValue = "", addminCommissionType = "";
//   bool? isEnableAdminCommission = false;
//   var deliveryCharges = "0.0";
//   VendorModel? vendorModel;
//   String? selctedOrderTypeValue = "Delivery";
//   bool isDeliverFound = false;
//   var tipValue = 0.0;
//   bool isTipSelected = false,
//       isTipSelected1 = false,
//       isTipSelected2 = false,
//       isTipSelected3 = false;
//   TextEditingController _textFieldController = TextEditingController();
//   String? Dynamicminutes;
//   late Map<String, dynamic>? adminCommission;
//
//   Timestamp? scheduleTime;
//   Timestamp? scheduleTime1;
//   String? deleverychargeshare;
//
//   Future<String?> fetchScheduleOrderMinutes() async {
//     try {
//       // Reference to Firestore
//       FirebaseFirestore firestore = FirebaseFirestore.instance;
//
//       // Get the document from the collection
//       DocumentSnapshot docSnapshot = await firestore
//           .collection('settings')
//           .doc('orderCancellationMinutes')
//           .get();
//
//       // Check if the document exists
//       if (docSnapshot.exists) {
//         // Access the 'scheduleOrderMinutes' field as a string
//         var data = docSnapshot.data() as Map<String, dynamic>;
//         return data['scheduleOrderMinutes']?.toString();
//       } else {
//         print("Document does not exist!");
//         return null;
//       }
//     } catch (e) {
//       print("Error fetching scheduleOrderMinutes: $e");
//       return null;
//     }
//   }
//
//   void getScheduleOrderMinutes() async {
//     Dynamicminutes = await fetchScheduleOrderMinutes();
//     if (Dynamicminutes != null) {
//       print("Schedule Order Minutes as String: $Dynamicminutes");
//     } else {
//       print("Failed to fetch scheduleOrderMinutes.");
//     }
//   }
//
//   void initializeFlutterFire() async {
//     try {
//       await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
//
//       final FlutterExceptionHandler? originalOnError = FlutterError.onError;
//       FlutterError.onError = (FlutterErrorDetails errorDetails) async {
//         await FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
//         originalOnError!(errorDetails);
//         // Forward to original handler.
//       };
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("globalSettings")
//           .get()
//           .then((dineinresult) {
//         if (dineinresult.exists &&
//             dineinresult.data() != null &&
//             dineinresult.data()!.containsKey("website_color")) {
//           COLOR_PRIMARY = int.parse(
//               dineinresult.data()!["website_color"].replaceFirst("#", "0xff"));
//         }
//       });
//
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("DineinForRestaurant")
//           .get()
//           .then((dineinresult) {
//         if (dineinresult.exists) {
//           isDineInEnable = dineinresult.data()!["isEnabledForCustomer"];
//         }
//       });
//
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("emailSetting")
//           .get()
//           .then((value) {
//         if (value.exists) {
//           mailSettings = MailSettings.fromJson(value.data()!);
//         }
//       });
//
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("home_page_theme")
//           .get()
//           .then((value) {
//         if (value.exists) {
//           homePageThem = value.data()!["theme"];
//         }
//       });
//
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("Version")
//           .get()
//           .then((value) {
//         debugPrint(value.data().toString());
//         appVersion = value.data()!['app_version'].toString();
//       });
//
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("googleMapKey")
//           .get()
//           .then((value) {
//         print(value.data());
//         GOOGLE_API_KEY = value.data()!['key'].toString();
//       });
//     } catch (e) {
//       debugPrint(e.toString());
//     }
//   }
//
//   String? commissionType;
//   double? fixCommission;
//   bool isEnabled = false;
//   bool isload = true;
//
//   Future<void> fetchAdminCommission() async {
//     try {
//       // Firestore instance
//       FirebaseFirestore firestore = FirebaseFirestore.instance;
//
//       // Document reference for "AdminCommission"
//       DocumentSnapshot<Map<String, dynamic>> docSnapshot =
//           await firestore.collection('settings').doc('AdminCommission').get();
//
//       if (docSnapshot.exists) {
//         // Get data from the document
//         Map<String, dynamic>? data = docSnapshot.data();
//
//         if (data != null) {
//           // Extract specific fields
//           commissionType = data['commissionType'] ?? 'N/A';
//           fixCommission = data['fix_commission']?.toDouble() ?? 0.0;
//           isEnabled = data['isEnabled'] ?? false;
//
//           // Print the values
//           print('Commission Type: $commissionType');
//           print('Fix Commission: $fixCommission');
//           print('Is Enabled: $isEnabled');
//         }
//       } else {
//         print('Document does not exist!');
//       }
//     } catch (e) {
//       print('Error fetching data: $e');
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     coupon = _fireStoreUtils.getAllCoupons();
//     fetchAdminCommission();
//     getFoodType();
//     initializeFlutterFire();
//     print("location ave che${ MyAppState.currentUser?.location?.latitude ?? ""}");
//     print("location ave che${MyAppState.currentUser?.location?.longitude ?? ""}");
//     print("lstExtras${lstExtras}");
//     print("couponIdasfasdff1:-${deliveryCharges}");
//     print("===============>>>>>>>>>>>>>>>>>:-${vendorModel?.title ?? ""}");
//     print(
//         "vendorModeldhhghghfghfghfgh:-${vendorModel?.razorpayBankAcname ?? ""}");
//   }
//
//   getFoodType() async {
//     SharedPreferences sp = await SharedPreferences.getInstance();
//     setState(() {
//       selctedOrderTypeValue =
//           sp.getString("foodType") == "" || sp.getString("foodType") == null
//               ? "Delivery"
//               : sp.getString("foodType");
//     });
//   }
//
//   String? vendorbankholdername;
//   num? wallamountvendor;
//   String? rzorpaybankaccountnumber;
//   String? ScheduledHrs;
//   String? vendoridvendorid;
//
// bool? codWallet;
//   Future<void> getDeliveyData() async {
//     isDeliverFound = true;
//     await _fireStoreUtils
//         .getVendorByVendorID(cartProducts.first.vendorID)
//         .then((value) {
//       vendorModel = value;
//
//
//       setState(() {
//         vendoridvendorid=cartProducts.first.vendorID;
//         vendorbankholdername = vendorModel?.razorpayBankAcname ?? "";
//         rzorpaybankaccountnumber = vendorModel?.razorpayBankAcno ?? "";
//         isSchedule = vendorModel!.isScheduled;
//         isLiveandScheduled = vendorModel!.isLiveandScheduled;
//         wallamountvendor = vendorModel!.walletAmount;
//         // wallamountvendor = vendorModel!.walletAmount;
//         codWallet = vendorModel?.codWallet;
//         print("vendoridvendoridvendoridvendoridvendoridvendorid${vendoridvendorid}");
//         print("codWalletcodWalletcodWallet${codWallet}");
//         print("wallamountvendor wallamountvendor${wallamountvendor}");
//         print("vendorbank holder name${vendorbankholdername}");
//         print("vendor modal razorpay data${rzorpaybankaccountnumber}");
//         print("Vendor Schedule:-${isSchedule}");
//         print("Vendor Scheduled Hrs:-${ScheduledHrs}");
//         fetchWorkingHours();
//       });
//       // print("vendor modal razorpay data${vendorModel?.razorpayBankAcname ?? ""}");
//     });
//     if (selctedOrderTypeValue == "Delivery") {
//
//       num km = num.parse(getKm(
//
//           // MyAppState.selectedPosotion,
//           Position.fromMap({'latitude':addrss?MyAppState.currentUser!.shippingAddress.location.latitude==0.01?MyAppState.selectedPosotion.latitude:MyAppState.currentUser!.shippingAddress.location.latitude:MyAppState.selectedPosotion.latitude, 'longitude': addrss? MyAppState.currentUser!.shippingAddress.location.longitude==0.01?MyAppState.selectedPosotion.longitude:MyAppState.currentUser!.shippingAddress.location.longitude:MyAppState.selectedPosotion.longitude}),
//           Position.fromMap({
//             'latitude': vendorModel!.latitude,
//             'longitude': vendorModel!.longitude
//           })));
//       print("hkkm${km}");
//       _fireStoreUtils.getDeliveryCharges().then((value) {
//         if (value != null) {
//           DeliveryChargeModel deliveryChargeModel = value;
//
//           if (!deliveryChargeModel.vendorCanModify) {
//             if (km > 1) {
//               deliveryCharges = (deliveryChargeModel.minimumDeliveryCharges +
//                       km * deliveryChargeModel.deliveryChargesPerKm)
//                   .toDouble()
//                   .toString();
//               print("zxczxczxczxczxcckm${km}");
//               print("deliveryCharges${deliveryCharges}");
//               setState(() {});
//             } else {
//               // deliveryCharges = deliveryChargeModel.minimumDeliveryCharges
//               //     .toDouble()
//               //     .toString();
//               print("bhai katala km cho tu ${km}");
//               deliveryCharges = km <=
//                       num.parse(
//                           deliveryChargeModel.deliveryChargesPerKm.toString())
//                   ? deliveryChargeModel.minimumDeliveryChargesWithinKm
//                       .toDouble()
//                       .toString()
//                   : (deliveryChargeModel.minimumDeliveryCharges +
//                           km * deliveryChargeModel.deliveryChargesPerKm)
//                       .toDouble()
//                       .toString();
//
//               print("deliveryCharges123456${deliveryCharges}");
//               setState(() {});
//             }
//           } else {
//             if (vendorModel != null && vendorModel!.deliveryCharge != null) {
//               if (km > 1) {
//                 deliveryCharges = (vendorModel!
//                             .deliveryCharge!.minimumDeliveryCharges +
//                         km * vendorModel!.deliveryCharge!.deliveryChargesPerKm)
//                     .toDouble()
//                     .toString();
//                 print("jaylo guruji${deliveryCharges}");
//                 setState(() {});
//               } else {
//                 deliveryCharges = vendorModel!
//                     .deliveryCharge!.minimumDeliveryCharges
//                     .toDouble()
//                     .toString();
//                 setState(() {});
//               }
//             } else {
//               if (km > 1) {
//                 deliveryCharges = (deliveryChargeModel.minimumDeliveryCharges +
//                         km * deliveryChargeModel.deliveryChargesPerKm)
//                     .toDouble()
//                     .toString();
//                 print("ramla mer${deliveryCharges}");
//                 setState(() {});
//               } else {
//                 deliveryCharges = deliveryChargeModel.minimumDeliveryCharges
//                     .toDouble()
//                     .toString();
//                 print("hariyomer${deliveryCharges}");
//                 setState(() {});
//               }
//             }
//           }
//         }
//       });
//     }
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//
//     cartDatabase = Provider.of<CartDatabase>(context, listen: true);
//     cartFuture = cartDatabase.allCartProducts;
//
//     _fireStoreUtils.getAdminCommission().then((value) {
//       if (value != null) {
//         setState(() {
//           adminCommission = value;
//           adminCommissionValue = adminCommission!["adminCommission"].toString();
//           addminCommissionType =
//               adminCommission!["addminCommissionType"].toString();
//           isEnableAdminCommission = adminCommission!["isAdminCommission"];
//         });
//       }
//     });
//     getPrefData();
//     //setPrefData();
//   }
//   Future<void> checkIfVendorIsOpen(String vendorId) async {
//     // Current time in "HH:mm" format
//     final currentTime = DateFormat('HH:mm').format(DateTime.now());
//     final currentDay = DateFormat('EEEE').format(DateTime.now()); // Get current day
//
//     try {
//       // Fetch vendor document from Firestore
//       final vendorDoc = await FirebaseFirestore.instance
//           .collection('vendors')
//           .doc(vendorId)
//           .get();
//
//       if (vendorDoc.exists) {
//         final workingHours = vendorDoc.data()?['workingHours'] ?? [];
//
//         // Check for matching day in workingHours
//         for (var dayData in workingHours) {
//           if (dayData['day'] == currentDay) {
//             final timeSlots = dayData['timeslot'] as List<dynamic>;
//
//             // Check if the current time falls within any timeslot
//             for (var slot in timeSlots) {
//               final fromTime = slot['from'];
//               final toTime = slot['to'];
//
//               if (_isTimeWithinRange(currentTime, fromTime, toTime)) {
//                 print('Vendor is open');
//                 widget.isopen=true;
//                 return;
//               }
//             }
//           }
//         }
//       }
//       widget.isopen=false;
//       // If no matching time slot is found
//       print('Vendor is closed');
//     } catch (e) {
//       print('Error: $e');
//     }
//   }
//   String? catproducatmart;
//   bool _isTimeWithinRange(String currentTime, String fromTime, String toTime) {
//     final current = _convertTimeToMinutes(currentTime);
//     final from = _convertTimeToMinutes(fromTime);
//     final to = _convertTimeToMinutes(toTime);
//
//     return current >= from && current <= to;
//   }
//
// // Helper function to convert "HH:mm" to total minutes
//   int _convertTimeToMinutes(String time) {
//     final parts = time.split(':');
//     final hours = int.parse(parts[0]);
//     final minutes = int.parse(parts[1]);
//     return hours * 60 + minutes;
//   }
//   @override
//   Widget build(BuildContext context) {
//     cartDatabase = Provider.of<CartDatabase>(context, listen: true);
//     return Scaffold(
//       extendBody: true,
//       backgroundColor: isDarkMode(context)
//           ? const Color(DARK_COLOR)
//           : const Color(0xffFFFFFF),
//       body: StreamBuilder<List<CartProduct>>(
//         stream: cartDatabase.watchProducts,
//         initialData: const [],
//         builder: (context, snapshot) {
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(
//               child: CircularProgressIndicator.adaptive(
//                 valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
//               ),
//             );
//           }
//           if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
//             return SizedBox(
//               width: MediaQuery.of(context).size.width * 1,
//               child: Center(
//                 child: showEmptyState('Empty Cart'.tr(), context),
//               ),
//             );
//           } else {
//             cartProducts = snapshot.data!;
//             getDatafromVendor();
//             if (!isDeliverFound) {
//               getDeliveyData();
//             }
//             return Column(
//               children: [
//                 Expanded(
//                   child: isload?Center(child: CircularProgressIndicator(color: Colors.deepOrange,)):SingleChildScrollView(
//                     child: Column(
//                       children: [
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: const ClampingScrollPhysics(),
//                           itemCount: cartProducts.length,
//                           itemBuilder: (context, index) {
//                             vendorID = cartProducts[index].vendorID;
//                             checkIfVendorIsOpen(vendorID);
//                             // fetchWorkingHours(vendorID);
//                             print("vendor id ave che ${vendorID}");
//                             return Container(
//                               margin: const EdgeInsets.only(
//                                   left: 13, top: 13, right: 13, bottom: 13),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10),
//                                 border: Border.all(
//                                     color: isDarkMode(context)
//                                         ? const Color(DarkContainerBorderColor)
//                                         : Colors.grey.shade100,
//                                     width: 1),
//                                 color: isDarkMode(context)
//                                     ? const Color(DarkContainerColor)
//                                     : Colors.white,
//                                 boxShadow: [
//                                   isDarkMode(context)
//                                       ? const BoxShadow()
//                                       : BoxShadow(
//                                           color: Colors.grey.withOpacity(0.5),
//                                           blurRadius: 5,
//                                         ),
//                                 ],
//                               ),
//                               child: Column(
//                                 children: [
//                                   isload?CircularProgressIndicator(color: Colors.deepOrange,):buildCartRow(cartProducts[index], lstExtras),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                         buildTotalRow(snapshot.data!, lstExtras, vendorID),
//                       ],
//                     ),
//                   ),
//                 ),
//                 isload?Container():widget.isopen==false?GestureDetector(
//                   onTap: scheduleTime1 == null
//                       ? () {
//                     final snackBar = SnackBar(
//                       backgroundColor: !isDarkMode(context)
//                           ? Colors.white
//                           : Color(DARK_BG_COLOR),
//                       content: Text(
//                         'Please Select Schedule Order Time',
//                         style: TextStyle(
//                             color: !isDarkMode(context)
//                                 ? Colors.black
//                                 : Colors.white),
//                       ),
//                     );
//                     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//                   }
//                       : () {
//                     txt.clear();
//
//                     Map<String, dynamic> specialDiscountMap = {
//                       'special_discount': specialDiscountAmount,
//                       'special_discount_label': specialDiscount,
//                       'specialType': specialType
//                     };
//
//                     if (selctedOrderTypeValue == "Delivery") {
//
//
//                       Navigator.of(context)
//                           .push(
//                         PageRouteBuilder(
//                           pageBuilder:
//                               (context, animation, secondaryAnimation) =>
//                               DeliveryAddressScreen(
//                                 autoapplydiscount:num.parse( discountadmindiscount.toString()),
//                                 auto_apply: auto_apply,
//                                  cityaveche:cityaveche ,
//                                 isMyTime:isMyTime,
//                                 codWallet: codWallet,
//                                 wallamountvendor: num.parse(wallamountvendor.toString()),
//                                 toatvendoramount: toatvendoramount,
//                                 groceryitem: cartProducts[0].item.toString(),
//                                 chargepacking: charge == "" || charge == null
//                                     ? "0.0"
//                                     : charge.toString(),
//                                 razorpayaccount: rzorpaybankaccountnumber,
//                                 vendoraccountnumber: vendorbankholdername,
//                                 total: grandtotal,
//                                 couponId1: coponid123,
//                                 products: cartProducts,
//                                 discount: discountAmount,
//                                 couponCode: couponModel != null
//                                     ? couponModel!.offerCode
//                                     : "",
//                                 notes: noteController.text,
//                                 couponId: couponModel != null
//                                     ? couponModel?.offerId
//                                     : "",
//                                 extraAddons: commaSepratedAddOns,
//                                 tipValue: tipValue.toString(),
//                                 takeAway: selctedOrderTypeValue == "Delivery"
//                                     ? false
//                                     : true,
//                                 deliveryCharge: deliveryCharges,
//                                 taxModel: taxList,
//                                 specialDiscountMap: specialDiscountMap,
//                                 scheduleTime: scheduleTime1,
//                               ),
//
//                           transitionsBuilder: (context, animation,
//                               secondaryAnimation, child) {
//                             const begin = Offset(1.0, 0.0);
//                             const end = Offset.zero;
//                             const curve = Curves.ease;
//
//                             final tween = Tween(begin: begin, end: end);
//                             final curvedAnimation = CurvedAnimation(
//                               parent: animation,
//                               curve: curve,
//                             );
//                             print(
//                                 "jayala tu beshi ja ${deliveryCharges}");
//                             print("scheduleTime1scheduleTime1scheduleTime1${scheduleTime1}");
//                             return SlideTransition(
//                               position: tween.animate(curvedAnimation),
//                               child: child,
//                             );
//                           },
//                         ),
//                       )
//                           .then((value) {
//                         print("value${value}");
//                         if (value != null && mounted) {
//                           setState(() {
//                             deliveryCharges = value;
//                           });
//                         }
//                         print(
//                             "cartscreendeliveryCharges${deliveryCharges}");
//                       });
//
//                       print(
//                           "couponModel?.offerId${couponModel?.offerId}");
//                       print("coponid123${coponid123}");
//                     } else {
//                       push(
//                         context,
//                         PaymentScreen(
//                           cityaveche:cityaveche ,
//                           isMyTime:isMyTime,
//                           autoapplydiscount: num.parse( discountadmindiscount.toString()),
//                           auto_apply: auto_apply,
//                           codWallet: codWallet,
//                           wallamountvendor:num.parse(wallamountvendor.toString()),
//                           toatvendoramount: toatvendoramount,
//                           razorpayaccount: rzorpaybankaccountnumber,
//                           vendoraccountnumber: vendorbankholdername,
//                           total: grandtotal,
//                           discount: discountAmount,
//                           groceryitem: cartProducts[0].item.toString(),
//                           couponCode: couponModel != null
//                               ? couponModel!.offerCode
//                               : "",
//                           couponId: couponModel != null
//                               ? couponModel!.offerId
//                               : "",
//                           couponId1: coponid123,
//                           notes: noteController.text,
//                           products: cartProducts,
//                           extraAddons: commaSepratedAddOns,
//                           tipValue: "0",
//                           takeAway: true,
//                           deliveryCharge: "0",
//                           taxModel: taxList,
//                           specialDiscountMap: specialDiscountMap,
//                           scheduleTime: scheduleTime1,
//                         ),
//                       );
//                       print("scheduleTime1scheduleTime1scheduleTime1${scheduleTime1}");
//                       print(
//                           "couponModel?.offerId${couponModel?.offerId}");
//                       print("coponid123${coponid123}");
//                       // placeOrder();
//                       print(
//                           "couponModel?.offerId${couponModel?.offerId}");
//                     }
//                   },
//                   child: SizedBox(
//                     width: MediaQuery.of(context).size.width * 1,
//                     height: MediaQuery.of(context).size.height * 0.080,
//                     child: Container(
//                       color: Color(COLOR_PRIMARY),
//                       padding: const EdgeInsets.only(
//                           left: 15, right: 10, bottom: 8, top: 8),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(children: [
//                             Text("Total : ".tr(),
//                                 style: const TextStyle(
//                                   fontFamily: "Poppinsl",
//                                   color: Color(0xFFFFFFFF),
//                                 )),
//                             Text(
//                               amountShow(amount: grandtotal.toString()),
//                               style: const TextStyle(
//                                 fontFamily: "Poppinsm",
//                                 color: Color(0xFFFFFFFF),
//                               ),
//                             ),
//                           ]),
//                           Text("PROCEED TO CHECKOUT".tr(),
//                               style: const TextStyle(
//                                 fontFamily: "Poppinsm",
//                                 color: Color(0xFFFFFFFF),
//                               )),
//                         ],
//                       ),
//                     ),
//                   ),
//                 )
//                :GestureDetector(
//                   onTap: isSchedule && scheduleTime == null
//                       ? () {
//                           final snackBar = SnackBar(
//                             backgroundColor: !isDarkMode(context)
//                                 ? Colors.white
//                                 : Color(DARK_BG_COLOR),
//                             content: Text(
//                               'Please Select Schedule Order Time',
//                               style: TextStyle(
//                                   color: !isDarkMode(context)
//                                       ? Colors.black
//                                       : Colors.white),
//                             ),
//                           );
//                           ScaffoldMessenger.of(context).showSnackBar(snackBar);
//                         }
//                       : () {
//                           txt.clear();
//
//                           Map<String, dynamic> specialDiscountMap = {
//                             'special_discount': specialDiscountAmount,
//                             'special_discount_label': specialDiscount,
//                             'specialType': specialType
//                           };
//
//                           if (selctedOrderTypeValue == "Delivery") {
//                             // push(
//                             //   context,
//                             //   DeliveryAddressScreen(
//                             //     chargepacking: charge == "" || charge == null
//                             //         ? "0.0"
//                             //         : charge.toString(),
//                             //     total: grandtotal,
//                             //     couponId1: coponid123,
//                             //     products: cartProducts,
//                             //     discount: discountAmount,
//                             //     couponCode:
//                             //         couponModel != null ? couponModel!.offerCode : "",
//                             //     notes: noteController.text,
//                             //     couponId:
//                             //         couponModel != null ? couponModel?.offerId : "",
//                             //     extraAddons: commaSepratedAddOns,
//                             //     tipValue: tipValue.toString(),
//                             //     takeAway: selctedOrderTypeValue == "Delivery"
//                             //         ? false
//                             //         : true,
//                             //     deliveryCharge: deliveryCharges,
//                             //     taxModel: taxList,
//                             //     specialDiscountMap: specialDiscountMap,
//                             //     scheduleTime: scheduleTime,
//                             //   ),
//
//                             Navigator.of(context)
//                                 .push(
//                               PageRouteBuilder(
//                                 pageBuilder:
//                                     (context, animation, secondaryAnimation) =>
//                                         DeliveryAddressScreen(
//                                           autoapplydiscount: num.parse(discountadmindiscount.toString()),
//                                           auto_apply:auto_apply,
//                                           codWallet:codWallet,
//                                           cityaveche:cityaveche,
//                                           isMyTime:isMyTime,
//                                           wallamountvendor: num.parse(wallamountvendor.toString()),
//                                   toatvendoramount: toatvendoramount,
//                                   groceryitem: cartProducts[0].item.toString(),
//                                   chargepacking: charge == "" || charge == null
//                                       ? "0.0"
//                                       : charge.toString(),
//                                   razorpayaccount: rzorpaybankaccountnumber,
//                                   vendoraccountnumber: vendorbankholdername,
//                                   total: grandtotal,
//                                   couponId1: coponid123,
//                                   products: cartProducts,
//                                   discount: discountAmount,
//                                   couponCode: couponModel != null
//                                       ? couponModel!.offerCode
//                                       : "",
//                                   notes: noteController.text,
//                                   couponId: couponModel != null
//                                       ? couponModel?.offerId
//                                       : "",
//                                   extraAddons: commaSepratedAddOns,
//                                   tipValue: tipValue.toString(),
//                                   takeAway: selctedOrderTypeValue == "Delivery"
//                                       ? false
//                                       : true,
//                                   deliveryCharge: deliveryCharges,
//                                   taxModel: taxList,
//                                   specialDiscountMap: specialDiscountMap,
//                                   scheduleTime: scheduleTime1,
//                                 ),
//                                 transitionsBuilder: (context, animation,
//                                     secondaryAnimation, child) {
//                                   const begin = Offset(1.0, 0.0);
//                                   const end = Offset.zero;
//                                   const curve = Curves.ease;
//
//                                   final tween = Tween(begin: begin, end: end);
//                                   final curvedAnimation = CurvedAnimation(
//                                     parent: animation,
//                                     curve: curve,
//                                   );
//                                   print(
//                                       "jayala tu beshi ja ${deliveryCharges}");print(
//                                       "jayala tu beshi ja ${auto_apply}");
//                                   print("scheduleTime1scheduleTime1scheduleTime1${scheduleTime1}");
//                                   return SlideTransition(
//                                     position: tween.animate(curvedAnimation),
//                                     child: child,
//                                   );
//                                 },
//                               ),
//                             )
//                                 .then((value) {
//                               print("value${value}");
//                               if (value != null && mounted) {
//                                 setState(() {
//                                   deliveryCharges = value;
//                                 });
//                               }
//                               print(
//                                   "cartscreendeliveryCharges${deliveryCharges}");
//                             });
//
//                             print(
//                                 "couponModel?.offerId${couponModel?.offerId}");
//                             print("coponid123${coponid123}");
//                           } else {
//                             push(
//                               context,
//                               PaymentScreen(
//                                 autoapplydiscount: num.parse( discountadmindiscount.toString()),
//                                 auto_apply: auto_apply,
//                                 cityaveche:cityaveche ,
//                                 isMyTime:isMyTime ,
//                                 codWallet: codWallet,
//                                 wallamountvendor:num.parse(wallamountvendor.toString()),
//                                 toatvendoramount: toatvendoramount,
//                                 razorpayaccount: rzorpaybankaccountnumber,
//                                 vendoraccountnumber: vendorbankholdername,
//                                 total: grandtotal,
//                                 discount: discountAmount,
//                                 groceryitem: cartProducts[0].item.toString(),
//                                 couponCode: couponModel != null
//                                     ? couponModel!.offerCode
//                                     : "",
//                                 couponId: couponModel != null
//                                     ? couponModel!.offerId
//                                     : "",
//                                 couponId1: coponid123,
//                                 notes: noteController.text,
//                                 products: cartProducts,
//                                 extraAddons: commaSepratedAddOns,
//                                 tipValue: "0",
//                                 takeAway: true,
//                                 deliveryCharge: "0",
//                                 taxModel: taxList,
//                                 specialDiscountMap: specialDiscountMap,
//                                 scheduleTime: scheduleTime1,
//                               ),
//                             );
//                             print("scheduleTime1scheduleTime1scheduleTime1${scheduleTime1}");
//                             print(
//                                 "couponModel?.offerId${couponModel?.offerId}");
//                             print("coponid123${coponid123}");
//                             // placeOrder();
//                             print(
//                                 "couponModel?.offerId${couponModel?.offerId}");
//                           }
//                         },
//                   child: SizedBox(
//                     width: MediaQuery.of(context).size.width * 1,
//                     height: MediaQuery.of(context).size.height * 0.080,
//                     child: Container(
//                       color: Color(COLOR_PRIMARY),
//                       padding: const EdgeInsets.only(
//                           left: 15, right: 10, bottom: 8, top: 8),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(children: [
//                             Text("Total : ".tr(),
//                                 style: const TextStyle(
//                                   fontFamily: "Poppinsl",
//                                   color: Color(0xFFFFFFFF),
//                                 )),
//                             Text(
//                               amountShow(amount: grandtotal.toString()),
//                               style: const TextStyle(
//                                 fontFamily: "Poppinsm",
//                                 color: Color(0xFFFFFFFF),
//                               ),
//                             ),
//                           ]),
//                           Text("PROCEED TO CHECKOUT".tr(),
//                               style: const TextStyle(
//                                 fontFamily: "Poppinsm",
//                                 color: Color(0xFFFFFFFF),
//                               )),
//                         ],
//                       ),
//                     ),
//                   ),
//                 )
//               ],
//             );
//           }
//         },
//       ),
//     );
//   }
//
//   getDatafromVendor() async {
//     await _fireStoreUtils
//         .getVendorByVendorID(cartProducts.first.vendorID)
//         .then((value) {
//       vendorModel = value;
//       isSchedule = vendorModel!.isScheduled;
//       isLiveandScheduled = vendorModel!.isLiveandScheduled;
//     });
//   }
//   Future<List<String>> getresturantcities() async {
//     print('athata che');
//
//     // Firestore instance
//     FirebaseFirestore firestore = FirebaseFirestore.instance;
//
//     // Settings document fetch karo
//     DocumentSnapshot documentSnapshot = await firestore
//         .collection('coupons')
//         .doc('${auto_apply_coupon_id}')
//         .get();
//     if (documentSnapshot.exists) {
//       List<String> cities = List<String>.from(documentSnapshot.get('cities'));
//       setState(() {
//         Timestamp expiresAt = documentSnapshot['expiresAt'];
//         Timestamp startsAt = documentSnapshot['startsAt'];
//         isEnabled1 = documentSnapshot['isEnabled'];
//         DateTime now = DateTime.now();
//         // Convert to DateTime
//         DateTime expiresAtDateTime = expiresAt.toDate();
//         DateTime startsAtDateTime = startsAt.toDate();
//         print('Expires At (DateTime): $expiresAtDateTime');
//         print('Expires At (DateTime): $startsAtDateTime');
//         print('Expires At (DateTime): $isEnabled');
//         isMyTime =
//             now.isAfter(startsAtDateTime) && now.isBefore(expiresAtDateTime);
//       });
//
//
//       print("Is My Time: $isMyTime");
//       print("Is My Time: $cityaveche");
//       print("Is My Time: $auto_apply");
//       print("citiescitiedfdsfsdfsfsfsdfdsffs${cities}");
//
//       return cities;
//     } else {
//       // Default empty list return karo jya data na male
//       return [];
//     }
//   }
//
//   String? city1;
//   bool? cityaveche;
//   bool? isMyTime;
//   bool? isEnabled1;
//
//   Future<void> getCityrestaurantcity() async {
//     try {
//       // Latitude ane longitude thi location details melvo
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//           MyAppState.currentUser?.userID == null ||
//               MyAppState.currentUser?.userID == ""
//               ? MyAppState.selectedPosotion.latitude
//               : MyAppState.currentUser?.location.latitude == null ||
//               MyAppState.currentUser?.location.latitude == 0.01
//               ? MyAppState.selectedPosotion.latitude
//               : double.parse(
//               (MyAppState.currentUser?.location.latitude).toString()),
//           MyAppState.currentUser?.userID == null ||
//               MyAppState.currentUser?.userID == ""
//               ? MyAppState.selectedPosotion.longitude
//               : MyAppState.currentUser?.location.longitude == null ||
//               MyAppState.currentUser?.location.longitude == 0.01
//               ? MyAppState.selectedPosotion.longitude
//               : double.parse(
//               (MyAppState.currentUser?.location.longitude).toString()));
//
//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks[0];
//         setState(() {
//           city1 = place.locality ?? 'City not found';
//         });
//
//         print('vendorcity ave che: $city1');
//         List<String> cities = await getresturantcities();
//         if (cities.contains(city1)) {
//           // cityaveche = true;
//           setState(() {
//             cityaveche = true;
//             isload=false;
//           });
//
//            print("call nay thay");
//            print("cityavechecityavechecityavechecityavechecall nay thay${cityaveche}");
//           print(
//               'restaurant valu ave che  "$city1" is available in the Firestore cities.');
//         } else {
//
//           setState(() {
//             cityaveche = false;
//             isload=false;
//           });
//           print("cityavechecityavechecityavechecityavechecall nay thay${cityaveche}");
//           print(
//               'restaurant valu ave che "$city1" is not available in the Firestore cities.');
//         }
//       } else {
//         print('No location found for the given coordinates.');
//
//         print("======????????????????????????????????${cityaveche}");
//         setState(() {
//           cityaveche = false;
//           isload=false;
//         });
//       }
//     } catch (e) {
//       print('Error: $e');
//
//       setState(() {
//         cityaveche = false;
//         isload=false;
//       });
//     }
//   }
//   buildCartRow(CartProduct cartProduct, List<AddAddonsDemo> addons) {
//     List addOnVal = [];
//     catproducatmart:cartProduct?.item;
//     var quen = cartProduct.quantity;
//     double priceTotalValue = 0.0;
//     // priceTotalValue   = double.parse(cartProduct.price);
//     double addOnValDoule = 0;
//     for (int i = 0; i < lstExtras.length; i++) {
//       AddAddonsDemo addAddonsDemo = lstExtras[i];
//       if (addAddonsDemo.categoryID == cartProduct.id) {
//         addOnValDoule = addOnValDoule + double.parse(addAddonsDemo.price!);
//       }
//     }
//
//     ProductModel? productModel;
//     FireStoreUtils()
//         .getProductByID(cartProduct.id.split('~').first)
//         .then((value) {
//       productModel = value;
//     });
//
//     VariantInfo? variantInfo;
//     if (cartProduct.variant_info != null) {
//       variantInfo =
//           VariantInfo.fromJson(jsonDecode(cartProduct.variant_info.toString()));
//     }
//     if (cartProduct.extras == null) {
//       addOnVal.clear();
//     } else {
//       if (cartProduct.extras is String) {
//         if (cartProduct.extras == '[]') {
//           addOnVal.clear();
//         } else {
//           String extraDecode = cartProduct.extras
//               .toString()
//               .replaceAll("[", "")
//               .replaceAll("]", "")
//               .replaceAll("\"", "");
//           if (extraDecode.contains(",")) {
//             addOnVal = extraDecode.split(",");
//           } else {
//             if (extraDecode.trim().isNotEmpty) {
//               addOnVal = [extraDecode];
//             }
//           }
//         }
//       }
//
//       if (cartProduct.extras is List) {
//         addOnVal = List.from(cartProduct.extras);
//       }
//     }
//
//     if (cartProduct.extras_price != null &&
//         cartProduct.extras_price != "" &&
//         double.parse(cartProduct.extras_price!) != 0.0) {
//       if(auto_apply==true&& cityaveche==true && isMyTime==true){
//         pricenew =double.parse(cartProduct.extras_price!) *
//             num.parse(discountadmindiscount.toString()) /
//             100;
//         double originalPrice = double.parse(cartProduct.extras_price!);
//         // print("originalPriceoriginalPrice${originalPrice}");
//         originalPrice =double.parse(cartProduct.extras_price!) - num.parse(pricenew.toString());
//         priceTotalValue +=
//             double.parse(originalPrice.toString()) * cartProduct.quantity;
//       }else{
//         priceTotalValue +=
//             double.parse(cartProduct.extras_price!) * cartProduct.quantity;
//       }
//     }
//     print("first a call thay che pachi a call ${auto_apply}");
//     print("first a call thay che pachi a call ${cityaveche}");
//     print("first a call thay che pachi a call ${isMyTime}");
//     if(auto_apply==true&&cityaveche==true && isMyTime==true){
//       print("caart screen shu ave che ${discountadmindiscount}");
//       print("caart screen shu ave che shun ave che  ${cartProduct.price}");
//       pricenew =double.parse(cartProduct.price) *
//           num.parse(discountadmindiscount.toString()) /
//           100;
//       double originalPrice = double.parse(cartProduct.extras_price!);
//       print("caart screen shu ave che ${originalPrice}");
//       // print("originalPriceoriginalPrice${originalPrice}");
//       originalPrice =double.parse(cartProduct.price) - num.parse(pricenew.toString());
//       print("caart screen shu ave che minum thay shu ave che  ${originalPrice}");
//       priceTotalValue +=
//           double.parse(originalPrice.toString()) * cartProduct.quantity;
//       print("priceTotalValuepriceTotalValue${priceTotalValue}");
//     }else{
//       print("first a call thay che");
//       priceTotalValue += double.parse(cartProduct.price) * cartProduct.quantity;
//     }
//
//
//     // VariantInfo variantInfo= cartProduct.variant_info;
//     return InkWell(
//       onTap: () {
//         _fireStoreUtils.getVendorByVendorID(cartProduct.vendorID).then((value) {
//           push(
//             context,
//             NewVendorProductsScreen(vendorModel: value),
//           );
//         });
//       },
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: CachedNetworkImage(
//                       height: 80,
//                       width: 80,
//                       imageUrl: getImageVAlidUrl(cartProduct.photo),
//                       imageBuilder: (context, imageProvider) => Container(
//                             width: 80,
//                             height: 80,
//                             decoration: BoxDecoration(
//                                 image: DecorationImage(
//                               image: imageProvider,
//                               fit: BoxFit.cover,
//                             )),
//                           ),
//                       errorWidget: (context, url, error) => ClipRRect(
//                           borderRadius: BorderRadius.circular(5),
//                           child: Image.network(
//                             AppGlobal.placeHolderImage!,
//                             fit: BoxFit.cover,
//                           ))),
//                 ),
//                 const SizedBox(
//                   width: 10,
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         cartProduct.item == "grocery"
//                             ? cartProduct.name +
//                                 ' (${cartProduct.groceryWeight} ${cartProduct.groceryUnit})'
//                             : cartProduct.name,
//                         style: const TextStyle(
//                             fontSize: 18, fontFamily: "Poppinsm"),
//                       ),
//                       // Text(
//                       //   cartProduct.packingcharges,
//                       //   style: const TextStyle(
//                       //       fontSize: 18, fontFamily: "Poppinsm"),
//                       // ),
//
//                       isload?CircularProgressIndicator(color: Colors.deepOrange,):Text(
//                         amountShow(amount: priceTotalValue.toString()),
//                         style: TextStyle(
//                             fontSize: 20,
//                             fontFamily: "Poppinsm",
//                             color: Color(COLOR_PRIMARY)),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         if (quen != 0) {
//                           quen--;
//                           _apply();
//                           removetocard(cartProduct, quen);
//                         }
//                       },
//                       child: Image(
//                         image: const AssetImage("assets/images/minus.png"),
//                         color: Color(COLOR_PRIMARY),
//                         height: 30,
//                       ),
//                     ),
//                     const SizedBox(
//                       width: 5,
//                     ),
//                     Text(
//                       '${cartProduct.quantity}'.tr(),
//                       style: const TextStyle(fontSize: 20),
//                     ),
//                     const SizedBox(
//                       width: 5,
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         if (productModel!.itemAttributes != null) {
//                           if (productModel!.itemAttributes!.variants!
//                               .where((element) =>
//                                   element.variantSku == variantInfo!.variantSku)
//                               .isNotEmpty) {
//                             if (int.parse(productModel!
//                                         .itemAttributes!.variants!
//                                         .where((element) =>
//                                             element.variantSku ==
//                                             variantInfo!.variantSku)
//                                         .first
//                                         .variantQuantity
//                                         .toString()) >
//                                     quen ||
//                                 int.parse(productModel!
//                                         .itemAttributes!.variants!
//                                         .where((element) =>
//                                             element.variantSku ==
//                                             variantInfo!.variantSku)
//                                         .first
//                                         .variantQuantity
//                                         .toString()) ==
//                                     -1) {
//                               quen++;
//                               _apply();
//                               addtocard(cartProduct, quen);
//                             } else {
//                               cartProduct.item == "grocery"?ScaffoldMessenger.of(context)
//                                   .showSnackBar(SnackBar(
//                                 content: Text("Item out of stock".tr()),
//                               )):ScaffoldMessenger.of(context)
//                                   .showSnackBar(SnackBar(
//                                 content: Text("food out of stock".tr()),
//                               ));
//                             }
//                           } else {
//                             if (productModel!.quantity > quen ||
//                                 productModel!.quantity == -1) {
//                               quen++;
//                               addtocard(cartProduct, quen);
//                             } else {
//                               cartProduct.item == "grocery"?ScaffoldMessenger.of(context)
//                                   .showSnackBar(SnackBar(
//                                 content: Text("Item out of stock".tr()),
//                               )):ScaffoldMessenger.of(context)
//                                   .showSnackBar(SnackBar(
//                                 content: Text("food out of stock".tr()),
//                               ));
//                             }
//                           }
//                         } else {
//                           if (productModel!.quantity > quen ||
//                               productModel!.quantity == -1) {
//                             quen++;
//                             addtocard(cartProduct, quen);
//                           } else {
//                             cartProduct.item == "grocery"?ScaffoldMessenger.of(context)
//                                 .showSnackBar(SnackBar(
//                               content: Text("Item out of stock".tr()),
//                             )):ScaffoldMessenger.of(context)
//                                 .showSnackBar(SnackBar(
//                               content: Text("food out of stock".tr()),
//                             ));
//                           }
//                         }
//                       },
//                       child: Image(
//                         image: const AssetImage("assets/images/plus.png"),
//                         color: Color(COLOR_PRIMARY),
//                         height: 30,
//                       ),
//                     )
//                   ],
//                 )
//               ],
//             ),
//             variantInfo == null || variantInfo.variantOptions!.isEmpty
//                 ? Container()
//                 : Padding(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
//                     child: Wrap(
//                       spacing: 6.0,
//                       runSpacing: 6.0,
//                       children: List.generate(
//                         variantInfo.variantOptions!.length,
//                         (i) {
//                           return _buildChip(
//                               "${variantInfo!.variantOptions!.keys.elementAt(i)} : ${variantInfo.variantOptions![variantInfo.variantOptions!.keys.elementAt(i)]}",
//                               i);
//                         },
//                       ).toList(),
//                     ),
//                   ),
//             SizedBox(
//               height: addOnVal.isEmpty ? 0 : 30,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 5),
//                 child: ListView.builder(
//                     itemCount: addOnVal.length,
//                     scrollDirection: Axis.horizontal,
//                     itemBuilder: (context, index) {
//                       return Text(
//                         "${addOnVal[index].toString().replaceAll("\"", "")} ${(index == addOnVal.length - 1) ? "" : ","}",
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         textAlign: TextAlign.start,
//                       );
//                     }),
//               ),
//             ),
//             // cartProduct.variant_info != null?ListView.builder(
//             //   itemCount: variantInfo.variantOptions!.length,
//             //   shrinkWrap: true,
//             //   itemBuilder: (context, index) {
//             //     String key = cartProduct.variant_info.variantOptions!.keys.elementAt(index);
//             //     return Padding(
//             //       padding: const EdgeInsets.symmetric(vertical: 2),
//             //       child: Row(
//             //         children: [
//             //           Text("$key : "),
//             //           Text("${cartProduct.variant_info.variantOptions![key]}"),
//             //         ],
//             //       ),
//             //     );
//             //   },
//             // ):Container(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
//     final currentDate = DateTime.now();
//     return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
//   }
//
//   Widget buildTotalRow(
//       List<CartProduct> data, List<AddAddonsDemo> lstExtras, String vendorID) {
//     var _font = 16.00;
//     subTotal = 0.00;
//     grandtotal = 0;
//     num totalPackingCharge=0;
//     for (int a = 0; a < data.length; a++) {
//       CartProduct e = data[a];
//       double addOnValDoule = 0;
//       for (int i = 0; i < lstExtras.length; i++) {
//         print(" lstExtras.length${lstExtras.length}");
//         AddAddonsDemo addAddonsDemo = lstExtras[i];
//         print(" lstExtras.length${addAddonsDemo}");
//         if (addAddonsDemo.categoryID == e.id) {
//           addOnValDoule = addOnValDoule + double.parse(addAddonsDemo.price!);
//         }
//       }
//       if (e.extras_price != null &&
//           e.extras_price != "" &&
//           double.parse(e.extras_price!) != 0.0) {
//         subTotal += double.parse(e.extras_price!) * e.quantity;
//       }
//       if(auto_apply==true&&cityaveche==true && isMyTime==true){
//         print("caart screen shu ave che ${discountadmindiscount}");
//         print("caart screen shu ave che shun ave che  ${e.price}");
//         bevafapdama =double.parse(e.price) *
//             num.parse(discountadmindiscount.toString()) /
//             100;
//         double originalPrice = double.parse(e.price);
//         print("caart screen shu ave che ${originalPrice}");
//         // print("originalPriceoriginalPrice${originalPrice}");
//         originalPrice =double.parse(e.price) - num.parse(bevafapdama.toString());
//         subTotal += double.parse(originalPrice.toString()) * e.quantity;
//         print("caart screen shu ave che minum thay shu ave che  ${originalPrice}");
//       }else{
//         subTotal += double.parse(e.price) * e.quantity;
//       }
//       totalPackingCharge +=num.parse(e.packingcharges ?? '0');
//       charge = totalPackingCharge ;
//       print("chargecharge${charge}");
//       quantitycharge = e.quantity;
//       razorpayvendoramounttrafar = subTotal + num.parse(charge.toString());
//       // double sprintamount = commissionType == "Percent"
//       //     ? razorpayvendoramounttrafar *
//       //         double.parse(fixCommission.toString()) /
//       //         100
//       //     : razorpayvendoramounttrafar + double.parse(fixCommission.toString());
//       double sprintamount = commissionType == "Percent"
//           ? razorpayvendoramounttrafar * (fixCommission != null ? double.parse(fixCommission.toString()) : 0) / 100
//           : razorpayvendoramounttrafar + (fixCommission != null ? double.parse(fixCommission.toString()) : 0);
//       toatvendoramount = razorpayvendoramounttrafar - sprintamount;
//
//     }
//     // var charge=widget.packingCharge.toString();
//     // grandtotal = subTotal + double.parse(deliveryCharges) + tipValue + charge;
//
//     try {
//       charge = charge;
//
//
//
//     } catch (e) {
//       charge = 0.0;
//      // Or handle the error in a way that makes sense for your application
//     }
//     grandtotal = subTotal +
//         double.parse(deliveryCharges) +
//         tipValue +
//         double.parse(charge.toString());
//
//     //discountAmount = calculateDiscount(amount: subTotal.toString(), offerModel: couponModel);
//     grandtotal = grandtotal - discountAmount;
//
//     if (vendorModel != null) {
//       if (vendorModel!.specialDiscountEnable) {
//         final now = new DateTime.now();
//         var day = DateFormat('EEEE', 'en_US').format(now);
//         var date = DateFormat('dd-MM-yyyy').format(now);
//         vendorModel!.specialDiscount.forEach((element) {
//           if (day == element.day.toString()) {
//             if (element.timeslot!.isNotEmpty) {
//               element.timeslot!.forEach((element) {
//                 if (element.discountType == "delivery") {
//                   var start = DateFormat("dd-MM-yyyy HH:mm")
//                       .parse(date + " " + element.from.toString());
//                   var end = DateFormat("dd-MM-yyyy HH:mm")
//                       .parse(date + " " + element.to.toString());
//                   if (isCurrentDateInRange(start, end)) {
//                     specialDiscount = double.parse(element.discount.toString());
//                     specialType = element.type.toString();
//                     if (element.type == "percentage") {
//                       specialDiscountAmount = subTotal * specialDiscount / 100;
//                     } else {
//                       specialDiscountAmount = specialDiscount;
//                     }
//                     grandtotal = grandtotal - specialDiscountAmount;
//                   }
//                 }
//               });
//             }
//           }
//         });
//       } else {
//         specialDiscount = double.parse("0");
//         specialType = "amount";
//       }
//     }
//     String taxAmount = " 0.0";
//     if (taxList != null) {
//       for (var element in taxList!) {
//         taxAmount = (double.parse(taxAmount) +
//                 calculateTax(
//                     amount: (subTotal - discountAmount - specialDiscountAmount)
//                         .toString(),
//                     taxModel: element))
//             .toString();
//       }
//     }
//     grandtotal += double.parse(taxAmount);
//     print("parkpalme@parkpal.co.inparkpalme@parkpal.co.in${auto_apply}");
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//        auto_apply==true&&cityaveche==true && isMyTime==true?Container():Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//             margin:
//                 const EdgeInsets.only(left: 13, top: 13, right: 13, bottom: 13),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(
//                   color: isDarkMode(context)
//                       ? const Color(DarkContainerBorderColor)
//                       : Colors.grey.shade100,
//                   width: 1),
//               color: isDarkMode(context)
//                   ? const Color(DarkContainerColor)
//                   : Colors.white,
//               boxShadow: [
//                 isDarkMode(context)
//                     ? const BoxShadow()
//                     : BoxShadow(
//                         color: Colors.grey.withOpacity(0.5),
//                         blurRadius: 5,
//                       ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   width: 222, // Set the width of the first element
//                   height: 100, // Set the height of the first element
//                   child: Center(
//                     child: RoundedInputBox(couponTextField, editableCoupon),
//                   ),
//                 ),
//                 nameCoupon == "Apply"
//                     ? Container(
//                         width: 70,
//                         // Set the width of the second element
//                         height: 65,
//                         margin: EdgeInsets.all(10.0),
//                         // Set the height of the second element
//                         child: Container(
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10),
//                               // Set the border radius
//                               color: Colors.blue, // Background color
//                             ),
//                             child: GestureDetector(
//                                 child: Center(
//                                   child: Text(
//                                     nameCoupon,
//                                     style: TextStyle(
//                                       color: Colors.white, // Text color
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                                 onTap:
//                                 // couponTextField.text == '' ||
//                                 //         couponTextField.text.isEmpty
//                                 //     ? () {
//                                 //         final snackBar = SnackBar(
//                                 //           backgroundColor: isDarkMode(context)
//                                 //               ? Colors.white
//                                 //               : Color(DARK_BG_COLOR),
//                                 //           content: Text(
//                                 //             'Please Enter Coupon Code',
//                                 //             style: TextStyle(
//                                 //                 color: isDarkMode(context)
//                                 //                     ? Colors.black
//                                 //                     : Colors.white),
//                                 //           ),
//                                 //         );
//                                 //         ScaffoldMessenger.of(context)
//                                 //             .showSnackBar(snackBar);
//                                 //       }
//                                 //     :
//                                     () async {
//                                         await _apply();
//                                         setState(() {});
//                                       })))
//                     : Container(
//                         width: 70,
//                         // Set the width of the second element
//                         height: 65,
//                         margin: EdgeInsets.all(10.0),
//                         // Set the height of the second element
//                         child: Container(
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10),
//                               // Set the border radius
//                               color: Colors.grey, // Background color
//                             ),
//                             child: GestureDetector(
//                                 child: Center(
//                                   child: Text(
//                                     nameCoupon,
//                                     style: TextStyle(
//                                       color: Colors.black, // Text color
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                                 onTap: () async {
//                                   await _apply();
//                                   // setState(() {});
//                                 }))),
//               ],
//             )),
//         Container(
//             padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
//             margin: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(
//                   color: isDarkMode(context)
//                       ? const Color(DarkContainerBorderColor)
//                       : Colors.grey.shade100,
//                   width: 1),
//               color: isDarkMode(context)
//                   ? const Color(DarkContainerColor)
//                   : Colors.white,
//               boxShadow: [
//                 isDarkMode(context)
//                     ? const BoxShadow()
//                     : BoxShadow(
//                         color: Colors.grey.withOpacity(0.5),
//                         blurRadius: 5,
//                       ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Instructions".tr(),
//                       style: const TextStyle(
//                         fontFamily: "Poppinsm",
//                       ),
//                     ),
//                     Text("Write instructions for restaurant".tr(),
//                         style: const TextStyle(
//                           fontFamily: "Poppinsr",
//                         )),
//                   ],
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     showModalBottomSheet(
//                         isScrollControlled: true,
//                         isDismissible: true,
//                         context: context,
//                         backgroundColor: Colors.transparent,
//                         enableDrag: true,
//                         builder: (BuildContext context) => noteSheet());
//                   },
//                   child: const Image(
//                       image: AssetImage("assets/images/add.png"), width: 40),
//                 )
//               ],
//             )),
//
//         if (isSchedule || isLiveandScheduled)
//           widget.isopen==false?Container(): Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               margin: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(
//                     color: isDarkMode(context)
//                         ? const Color(DarkContainerBorderColor)
//                         : Colors.grey.shade100,
//                     width: 1),
//                 color: isDarkMode(context)
//                     ? const Color(DarkContainerColor)
//                     : Colors.white,
//                 boxShadow: [
//                   isDarkMode(context)
//                       ? const BoxShadow()
//                       : BoxShadow(
//                           color: Colors.grey.withOpacity(0.5),
//                           blurRadius: 5,
//                         ),
//                 ],
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Schedule Order Time".tr(),
//                         style: const TextStyle(
//                           fontFamily: "Poppinsm",
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(
//                     width: 140,
//                     child:
//                     // GestureDetector(
//                     //   onTap: () {
//                     //     showDateTimeBottomSheet(context,
//                     //         (DateTime dateAndTime) {
//                     //       setState(() {
//                     //         // scheduleTime = Timestamp.fromDate(dateAndTime.add(Duration(hours: 12)));
//                     //         scheduleTime = Timestamp.fromDate(dateAndTime);
//                     //       });
//                     //     });
//                     //   },
//                     //   child: Text(
//                     //     scheduleTime == null
//                     //         ? "Select Time".tr()
//                     //         : DateFormat("EEE dd MMMM , hh:mm aa")
//                     //             .format(scheduleTime!.toDate().toLocal()),
//                     //     textAlign: TextAlign.end,
//                     //     style: TextStyle(
//                     //         fontFamily: "Poppinsm",
//                     //         color: Color(COLOR_PRIMARY)),
//                     //   ),
//                     // ),
//                     GestureDetector(
//                       onTap: () {
//                         fetchWorkingHours().then((workingHours) {
//                           showDateTimeBottomSheet12(
//                             context,
//                                 (DateTime dateAndTime) {
//                               setState(() {
//                                 // scheduleTime1 = Timestamp.fromDate(dateAndTime.add(Duration(hours: 12)));
//                                 scheduleTime1 = Timestamp.fromDate(dateAndTime);
//                               });
//                             },
//                             workingHours, // Pass working hours as the third argument
//                           );
//                         }).catchError((e) {
//                           // Handle errors when fetching working hours
//                           print("Error fetching working hours: $e");
//                         });
//                         // showDateTimeBottomSheet12(context,
//                         //     (DateTime dateAndTime) {
//                         //   setState(() {
//                         //     scheduleTime1 = Timestamp.fromDate(dateAndTime);
//                         //   });
//                         // });
//                       },
//                       child: Text(
//                         scheduleTime1 == null
//                             ? "Select Time".tr()
//                             : DateFormat("EEE dd MMMM , hh:mm aa")
//                             .format(scheduleTime1!.toDate().toLocal()),
//                         textAlign: TextAlign.end,
//                         style: TextStyle(
//                             fontFamily: "Poppinsm",
//                             color: Color(COLOR_PRIMARY)),
//                       ),
//                     ),
//                   )
//                 ],
//               )),
//         if (widget.isopen==false)
//           Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               margin: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(
//                     color: isDarkMode(context)
//                         ? const Color(DarkContainerBorderColor)
//                         : Colors.grey.shade100,
//                     width: 1),
//                 color: isDarkMode(context)
//                     ? const Color(DarkContainerColor)
//                     : Colors.white,
//                 boxShadow: [
//                   isDarkMode(context)
//                       ? const BoxShadow()
//                       : BoxShadow(
//                           color: Colors.grey.withOpacity(0.5),
//                           blurRadius: 5,
//                         ),
//                 ],
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Schedule Order Time".tr(),
//                         style: const TextStyle(
//                           fontFamily: "Poppinsm",
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(
//                     width: 140,
//                     child: GestureDetector(
//                       onTap: () {
//                         fetchWorkingHours().then((workingHours) {
//                           showDateTimeBottomSheet12(
//                             context,
//                                 (DateTime dateAndTime) {
//                               setState(() {
//                                 // scheduleTime1 = Timestamp.fromDate(dateAndTime.add(Duration(hours: 12)));
//                                 scheduleTime1 = Timestamp.fromDate(dateAndTime);
//                               });
//                             },
//                             workingHours, // Pass working hours as the third argument
//                           );
//                         }).catchError((e) {
//                           // Handle errors when fetching working hours
//                           print("Error fetching working hours: $e");
//                         });
//                         // showDateTimeBottomSheet12(context,
//                         //     (DateTime dateAndTime) {
//                         //   setState(() {
//                         //     scheduleTime1 = Timestamp.fromDate(dateAndTime);
//                         //   });
//                         // });
//                       },
//                       child: Text(
//                         scheduleTime1 == null
//                             ? "Select Time".tr()
//                             : DateFormat("EEE dd MMMM , hh:mm aa")
//                                 .format(scheduleTime1!.toDate().toLocal()),
//                         textAlign: TextAlign.end,
//                         style: TextStyle(
//                             fontFamily: "Poppinsm",
//                             color: Color(COLOR_PRIMARY)),
//                       ),
//                     ),
//                   )
//                 ],
//               )),
//         Container(
//           margin:
//               const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(
//                 color: isDarkMode(context)
//                     ? const Color(DarkContainerBorderColor)
//                     : Colors.grey.shade100,
//                 width: 1),
//             color: isDarkMode(context)
//                 ? const Color(DarkContainerColor)
//                 : Colors.white,
//             boxShadow: [
//               isDarkMode(context)
//                   ? const BoxShadow()
//                   : BoxShadow(
//                       color: Colors.grey.withOpacity(0.5),
//                       blurRadius: 5,
//                     ),
//             ],
//           ),
//           child: Column(
//             children: [
//               // Container(
//               //     padding:
//               //         const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               //     child: Row(
//               //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               //       children: [
//               //         Text(
//               //           "Delivery Option: ".tr(),
//               //           style:
//               //               TextStyle(fontFamily: "Poppinsm", fontSize: _font),
//               //         ),
//               //         // Text(
//               //         //   selctedOrderTypeValue == "Delivery"
//               //         //       ? "Delivery (${amountShow(amount: deliveryCharges.toString())})"
//               //         //       : selctedOrderTypeValue! + " (Free)",
//               //         //   style: TextStyle(
//               //         //       fontFamily: "Poppinsm",
//               //         //       color: isDarkMode(context)
//               //         //           ? const Color(0xffFFFFFF)
//               //         //           : const Color(0xff333333),
//               //         //       fontSize: selctedOrderTypeValue == "Delivery"
//               //         //           ? _font
//               //         //           : 14),
//               //         // ),
//               //       ],
//               //     )),
//               // const Divider(
//               //   color: Color(0xffE2E8F0),
//               //   height: 0.1,
//               // ),
//               SizedBox(
//                 height: 5,
//               ),
//               Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "Subtotal".tr(),
//                         style:
//                             TextStyle(fontFamily: "Poppinsm", fontSize: _font),
//                       ),
//                       Text(
//                         amountShow(amount: subTotal.toString()),
//                         style: TextStyle(
//                             fontFamily: "Poppinsm",
//                             color: isDarkMode(context)
//                                 ? const Color(0xffFFFFFF)
//                                 : const Color(0xff333333),
//                             fontSize: _font),
//                       ),
//                     ],
//                   )),
//               const Divider(
//                 thickness: 1,
//               ),
//               Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "Packing Charge".tr(),
//                         style:
//                             TextStyle(fontFamily: "Poppinsm", fontSize: _font),
//                       ),
//                       Text(
//                         amountShow(amount: charge.toString()),
//                         style: TextStyle(
//                             fontFamily: "Poppinsm",
//                             color: isDarkMode(context)
//                                 ? const Color(0xffFFFFFF)
//                                 : const Color(0xff333333),
//                             fontSize: _font),
//                       ),
//                     ],
//                   )),
//               auto_apply==true&&cityaveche==true&&isMyTime==true?Container(): const Divider(
//                 thickness: 1,
//               ),
//               auto_apply==true&&cityaveche==true&&isMyTime==true?Container():Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "Discount".tr(),
//                         style:
//                             TextStyle(fontFamily: "Poppinsm", fontSize: _font),
//                       ),
//                       Text(
//                         "(-${discountAmount == null ? amountShow(amount: "0.0") : amountShow(amount: discountAmount.toString())})",
//                         style: TextStyle(
//                             fontFamily: "Poppinsm",
//                             color: Colors.red,
//                             fontSize: _font),
//                       ),
//                     ],
//                   )),
//               const Divider(
//                 thickness: 1,
//               ),
//               Visibility(
//                 visible: vendorModel != null
//                     ? vendorModel!.specialDiscountEnable
//                     : false,
//                 child: Column(
//                   children: [
//                     Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 20, vertical: 5),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               "Special Discount".tr() +
//                                   "($specialDiscount ${specialType == "amount" ? currencyModel!.symbol : "%"})",
//                               style: TextStyle(
//                                   fontFamily: "Poppinsm", fontSize: _font),
//                             ),
//                             Text(
//                               "(-${amountShow(amount: specialDiscountAmount.toString())})",
//                               style: TextStyle(
//                                   fontFamily: "Poppinsm",
//                                   color: Colors.red,
//                                   fontSize: _font),
//                             ),
//                           ],
//                         )),
//                     const Divider(
//                       thickness: 1,
//                     ),
//                   ],
//                 ),
//               ),
//
//               selctedOrderTypeValue == "Delivery"
//                   ? (widget.fromContainer &&
//                           !isDeliverFound &&
//                           MyAppState.selectedPosotion.latitude == 0.0 &&
//                           MyAppState.selectedPosotion.longitude == 0)
//                       ? Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 5),
//                           child: Text(
//                               "Delivery Charge Will Applied Next Step.".tr(),
//                               style: TextStyle(
//                                   fontFamily: "Poppinsm", fontSize: _font)),
//                         )
//                       : Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 5),
//                           child: Column(
//                             children: [
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     "Delivery Charges".tr(),
//                                     style: TextStyle(
//                                         fontFamily: "Poppinsm",
//                                         fontSize: _font),
//                                   ),
//                                   Text(
//                                     amountShow(
//                                         amount: deliveryCharges.toString()),
//                                     style: TextStyle(
//                                         fontFamily: "Poppinsm",
//                                         color: isDarkMode(context)
//                                             ? const Color(0xffFFFFFF)
//                                             : const Color(0xff333333),
//                                         fontSize: _font),
//                                   ),
//                                 ],
//                               ),
//                               const Divider(
//                                 thickness: 1,
//                               ),
//                             ],
//                           ))
//                   : Container(),
//
//               ListView.builder(
//                 itemCount: taxList!.length,
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemBuilder: (context, index) {
//                   TaxModel taxModel = taxList![index];
//                   return Column(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 20, vertical: 5),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 "${taxModel.title.toString()} ",
//                                 // "(${taxModel.type == "fix" ? amountShow(amount: taxModel.tax) : "${taxModel.tax}%"})",
//                                 style: TextStyle(
//                                     fontFamily: "Poppinsm", fontSize: _font),
//                               ),
//                             ),
//                             Text(
//                               amountShow(
//                                   amount: calculateTax(
//                                           amount: (double.parse(
//                                                       subTotal.toString()) -
//                                                   discountAmount -
//                                                   specialDiscountAmount)
//                                               .toString(),
//                                           taxModel: taxModel)
//                                       .toString()),
//                               style: TextStyle(
//                                   fontFamily: "Poppinsm",
//                                   color: isDarkMode(context)
//                                       ? const Color(0xffFFFFFF)
//                                       : const Color(0xff333333),
//                                   fontSize: _font),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const Divider(
//                         thickness: 1,
//                       ),
//                     ],
//                   );
//                 },
//               ),
//
//               // taxModel != null
//               //     ? Container(
//               //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//               //         child: Row(
//               //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               //           children: [
//               //             Text(
//               //               ((taxModel!.label!.isNotEmpty) ? taxModel!.label.toString() : "Tax".tr()) + " ${(taxModel!.type == "fix") ? "" : "(${taxModel!.tax} %)"}",
//               //               style: TextStyle(fontFamily: "Poppinsm", fontSize: _font),
//               //             ),
//               //             Text(
//               //               amountShow(amount: getTaxValue(taxModel, subTotal - discountVal - specialDiscountAmount).toString()),
//               //               style: TextStyle(fontFamily: "Poppinsm", color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: _font),
//               //             ),
//               //           ],
//               //         ))
//               //     : Container(),
//               Visibility(
//                   visible: ((tipValue) > 0),
//                   child: Column(
//                     children: [
//                       Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 5),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Tip amount".tr(),
//                                 style: TextStyle(
//                                     fontFamily: "Poppinsm",
//                                     color: isDarkMode(context)
//                                         ? const Color(0xffFFFFFF)
//                                         : const Color(0xff333333),
//                                     fontSize: _font),
//                               ),
//                               Text(
//                                 '${amountShow(amount: tipValue.toString())}',
//                                 style: TextStyle(
//                                     fontFamily: "Poppinsm",
//                                     color: isDarkMode(context)
//                                         ? const Color(0xffFFFFFF)
//                                         : const Color(0xff333333),
//                                     fontSize: _font),
//                               ),
//                             ],
//                           )),
//                       const Divider(
//                         thickness: 1,
//                       ),
//                     ],
//                   )),
//               Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "Order Total".tr(),
//                         style: TextStyle(
//                             fontFamily: "Poppinsm",
//                             color: isDarkMode(context)
//                                 ? const Color(0xffFFFFFF)
//                                 : const Color(0xff333333),
//                             fontSize: _font),
//                       ),
//                       Text(
//                         amountShow(amount: grandtotal.toString()),
//                         style: TextStyle(
//                             fontFamily: "Poppinsm",
//                             color: isDarkMode(context)
//                                 ? const Color(0xffFFFFFF)
//                                 : const Color(0xff333333),
//                             fontSize: _font),
//                       ),
//                     ],
//                   )),
//             ],
//           ),
//         ),
//         selctedOrderTypeValue == "Delivery"
//             ? Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Tip your delivery partner".tr(),
//                       textAlign: TextAlign.start,
//                       style: TextStyle(
//                           fontFamily: "Poppinsm",
//                           fontWeight: FontWeight.bold,
//                           color: isDarkMode(context)
//                               ? const Color(0xffFFFFFF)
//                               : const Color(0xff333333),
//                           fontSize: 15),
//                     ),
//                     Text(
//                       "100% of the tip will go to your delivery partner".tr(),
//                       style: const TextStyle(
//                           fontFamily: "Poppinsm",
//                           color: Color(0xff9091A4),
//                           fontSize: 14),
//                     ),
//                     const SizedBox(
//                       height: 15,
//                     ),
//                     Row(
//                       // mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               if (isTipSelected) {
//                                 isTipSelected = false;
//                                 tipValue = 0;
//                               } else {
//                                 tipValue = 10;
//                                 isTipSelected = true;
//                               }
//
//                               isTipSelected1 = false;
//                               isTipSelected2 = false;
//                               isTipSelected3 = false;
//                             });
//                           },
//                           child: Container(
//                             margin: const EdgeInsets.only(right: 5),
//                             padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
//                             decoration: BoxDecoration(
//                               color: tipValue == 10 && isTipSelected
//                                   ? Color(COLOR_PRIMARY)
//                                   : isDarkMode(context)
//                                       ? const Color(DARK_COLOR)
//                                       : const Color(0xffFFFFFF),
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(
//                                   color: const Color(0xff9091A4), width: 1),
//                             ),
//                             child: Center(
//                                 child: Text(
//                               amountShow(amount: "10"),
//                               style: TextStyle(
//                                   fontFamily: "Poppinsm",
//                                   color: isDarkMode(context)
//                                       ? const Color(0xffFFFFFF)
//                                       : const Color(0xff333333),
//                                   fontSize: 12),
//                             )),
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               if (isTipSelected1) {
//                                 isTipSelected1 = false;
//                                 tipValue = 0;
//                               } else {
//                                 tipValue = 20;
//                                 isTipSelected1 = true;
//                               }
//                               isTipSelected = false;
//                               isTipSelected2 = false;
//                               isTipSelected3 = false;
//                             });
//                           },
//                           child: Container(
//                             margin: const EdgeInsets.only(right: 5),
//                             padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
//                             decoration: BoxDecoration(
//                               color: tipValue == 20 && isTipSelected1
//                                   ? Color(COLOR_PRIMARY)
//                                   : isDarkMode(context)
//                                       ? const Color(DARK_COLOR)
//                                       : const Color(0xffFFFFFF),
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(
//                                   color: const Color(0xff9091A4), width: 1),
//                             ),
//                             child: Center(
//                                 child: Text(
//                               amountShow(amount: "20"),
//                               style: TextStyle(
//                                   fontFamily: "Poppinsm",
//                                   color: isDarkMode(context)
//                                       ? const Color(0xffFFFFFF)
//                                       : const Color(0xff333333),
//                                   fontSize: 12),
//                             )),
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               if (isTipSelected2) {
//                                 isTipSelected2 = false;
//                                 tipValue = 0;
//                               } else {
//                                 tipValue = 30;
//                                 isTipSelected2 = true;
//                               }
//
//                               isTipSelected = false;
//                               isTipSelected1 = false;
//
//                               isTipSelected3 = false;
//                             });
//                           },
//                           child: Container(
//                             margin: const EdgeInsets.only(right: 5),
//                             padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
//                             decoration: BoxDecoration(
//                               color: tipValue == 30 && isTipSelected2
//                                   ? Color(COLOR_PRIMARY)
//                                   : isDarkMode(context)
//                                       ? const Color(DARK_COLOR)
//                                       : const Color(0xffFFFFFF),
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(
//                                   color: const Color(0xff9091A4), width: 1),
//                             ),
//                             child: Center(
//                                 child: Text(
//                               amountShow(amount: "30"),
//                               style: TextStyle(
//                                   fontFamily: "Poppinsm",
//                                   color: isDarkMode(context)
//                                       ? const Color(0xffFFFFFF)
//                                       : const Color(0xff333333),
//                                   fontSize: 12),
//                             )),
//                           ),
//                         ),
//                         Expanded(
//                           child: GestureDetector(
//                             onTap: () {
//                               if (isTipSelected3) {
//                                 setState(() {
//                                   if (isTipSelected3) {
//                                     isTipSelected3 = false;
//                                     tipValue = 0;
//                                   }
//                                   isTipSelected = false;
//                                   isTipSelected1 = false;
//                                   isTipSelected2 = false;
//                                   // grandtotal += tipValue;
//                                 });
//                               } else {
//                                 _displayDialog(context);
//                               }
//                             },
//                             child: Container(
//                               padding:
//                                   const EdgeInsets.fromLTRB(15, 10, 15, 10),
//                               decoration: BoxDecoration(
//                                 color: isTipSelected3
//                                     ? Color(COLOR_PRIMARY)
//                                     : isDarkMode(context)
//                                         ? const Color(DARK_COLOR)
//                                         : const Color(0xffFFFFFF),
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(
//                                     color: const Color(0xff9091A4), width: 1),
//                               ),
//                               child: Center(
//                                   child: Text(
//                                 "Other".tr(),
//                                 style: TextStyle(
//                                     fontFamily: "Poppinsm",
//                                     color: isDarkMode(context)
//                                         ? const Color(0xffFFFFFF)
//                                         : const Color(0xff333333),
//                                     fontSize: 10),
//                               )),
//                             ),
//                           ),
//                         )
//                       ],
//                     ),
//                     // SizedBox(height: 10,),
//                     // Row(
//                     //   children: [
//                     //     GestureDetector(
//                     //       onTap: () {
//                     //         if (isTipSelected3) {
//                     //           setState(() {
//                     //             if (isTipSelected3) {
//                     //               isTipSelected3 = false;
//                     //               tipValue = 0;
//                     //             }
//                     //             isTipSelected = false;
//                     //             isTipSelected1 = false;
//                     //             isTipSelected2 = false;
//                     //             // grandtotal += tipValue;
//                     //           });
//                     //         } else {
//                     //           _displayDialog(context);
//                     //         }
//                     //       },
//                     //       child: Container(
//                     //         padding:
//                     //         const EdgeInsets.fromLTRB(15, 10, 15, 10),
//                     //         decoration: BoxDecoration(
//                     //           color: isTipSelected3
//                     //               ? Color(COLOR_PRIMARY)
//                     //               : isDarkMode(context)
//                     //               ? const Color(DARK_COLOR)
//                     //               : const Color(0xffFFFFFF),
//                     //           borderRadius: BorderRadius.circular(8),
//                     //           border: Border.all(
//                     //               color: const Color(0xff9091A4), width: 1),
//                     //         ),
//                     //         child: Center(
//                     //             child: Text(
//                     //               "Other".tr(),
//                     //               style: TextStyle(
//                     //                   fontFamily: "Poppinsm",
//                     //                   color: isDarkMode(context)
//                     //                       ? const Color(0xffFFFFFF)
//                     //                       : const Color(0xff333333),
//                     //                   fontSize: 14),
//                     //             )),
//                     //       ),
//                     //     ),
//                     //   ],
//                     // )
//                   ],
//                 ),
//               )
//             : Container(),
//       ],
//     );
//   }
//
//   // showSheet(CartProduct cartProduct) async {
//   //   bool? shouldUpdate = await showModalBottomSheet(
//   //     isDismissible: true,
//   //     context: context,
//   //     backgroundColor: Colors.transparent,
//   //     builder: (context) => CartOptionsSheet(
//   //       cartProduct: cartProduct,
//   //     ),
//   //   );
//   //   if (shouldUpdate != null) {
//   //     cartFuture = cartDatabase.allCartProducts;
//   //     setState(() {});
//   //   }
//   // }
//
//   addtocard(CartProduct cartProduct, qun) async {
//     await cartDatabase.updateProduct(CartProduct(
//         id: cartProduct.id,
//         name: cartProduct.name,
//         photo: cartProduct.photo,
//         packingcharges: cartProduct.packingcharges,
//         price: cartProduct.price,
//         vendorID: cartProduct.vendorID,
//         quantity: qun,
//         category_id: cartProduct.category_id,
//         discountPrice: cartProduct.discountPrice?.toString() ?? "0.0"));
//   }
//
//   removetocard(CartProduct cartProduct, qun) async {
//     if (qun >= 1) {
//       await cartDatabase.updateProduct(CartProduct(
//           id: cartProduct.id,
//           category_id: cartProduct.category_id,
//           name: cartProduct.name,
//           photo: cartProduct.photo,
//           packingcharges: cartProduct.packingcharges,
//           price: cartProduct.price,
//           vendorID: cartProduct.vendorID,
//           quantity: qun,
//           discountPrice: cartProduct.discountPrice));
//     } else {
//       cartDatabase.removeProduct(cartProduct.id);
//     }
//   }
//
//   OfferModel? couponModel;
//
//   sheet() {
//     return Container(
//         padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).size.height / 4.3,
//             left: 25,
//             right: 25),
//         height: MediaQuery.of(context).size.height * 0.88,
//         decoration: BoxDecoration(
//             color: Colors.transparent,
//             border: Border.all(style: BorderStyle.none)),
//         child: FutureBuilder<List<OfferModel>>(
//             future: coupon,
//             initialData: const [],
//             builder: (context, snapshot) {
//               snapshot = snapshot;
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(
//                   child: CircularProgressIndicator.adaptive(
//                     valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
//                   ),
//                 );
//               }
//
//               // coupon = snapshot.data as Future<List<CouponModel>> ;
//               return Column(children: [
//                 InkWell(
//                     onTap: () => Navigator.pop(context),
//                     child: Container(
//                       height: 45,
//                       decoration: BoxDecoration(
//                           border: Border.all(color: Colors.white, width: 0.3),
//                           color: Colors.transparent,
//                           shape: BoxShape.circle),
//
//                       // radius: 20,
//                       child: const Center(
//                         child: Icon(
//                           Icons.close,
//                           color: Colors.white,
//                           size: 28,
//                         ),
//                       ),
//                     )),
//                 const SizedBox(
//                   height: 25,
//                 ),
//                 Expanded(
//                     child: Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                         color: isDarkMode(context)
//                             ? const Color(DarkContainerBorderColor)
//                             : Colors.grey.shade100,
//                         width: 1),
//                     color: isDarkMode(context)
//                         ? const Color(DarkContainerColor)
//                         : Colors.white,
//                     boxShadow: [
//                       isDarkMode(context)
//                           ? const BoxShadow()
//                           : BoxShadow(
//                               color: Colors.grey.withOpacity(0.5),
//                               blurRadius: 5,
//                             ),
//                     ],
//                   ),
//                   alignment: Alignment.center,
//                   child: SingleChildScrollView(
//                     child: Column(
//                       children: [
//                         Container(
//                             padding: const EdgeInsets.only(top: 30),
//                             child: const Image(
//                               image:
//                                   AssetImage('assets/images/redeem_coupon.png'),
//                               width: 100,
//                             )),
//                         Container(
//                             padding: const EdgeInsets.only(top: 20),
//                             child: Text(
//                               'Redeem Your Coupons'.tr(),
//                               style: const TextStyle(
//                                   fontFamily: 'Poppinssb', fontSize: 16),
//                             )),
//                         Container(
//                             padding: const EdgeInsets.only(top: 10),
//                             child: Text(
//                               "Voucher or Coupon code".tr(),
//                               style: const TextStyle(
//                                   fontFamily: 'Poppinsr',
//                                   color: Color(0XFF9091A4),
//                                   letterSpacing: 0.5,
//                                   height: 2),
//                             ).tr()),
//                         Container(
//                             padding: const EdgeInsets.only(
//                                 left: 20, right: 20, top: 20),
//                             // height: 120,
//                             child: DottedBorder(
//                                 borderType: BorderType.RRect,
//                                 radius: const Radius.circular(12),
//                                 dashPattern: const [4, 2],
//                                 color: const Color(0XFFB7B7B7),
//                                 child: ClipRRect(
//                                     borderRadius: const BorderRadius.all(
//                                         Radius.circular(12)),
//                                     child: Container(
//                                         padding: const EdgeInsets.only(
//                                             left: 20,
//                                             right: 20,
//                                             top: 20,
//                                             bottom: 20),
//                                         // height: 120,
//                                         alignment: Alignment.center,
//                                         child: TextFormField(
//                                           textAlign: TextAlign.center,
//                                           controller: txt,
//
//                                           // textAlignVertical: TextAlignVertical.center,
//                                           decoration: InputDecoration(
//                                             border: InputBorder.none,
//                                             hintText: "Write Coupon Code".tr(),
//                                             //  hintTextDirection: TextDecoration.lineThrough
//                                             // contentPadding: EdgeInsets.only(left: 80,right: 30),
//                                           ),
//                                         ))))),
//                         Padding(
//                           padding: const EdgeInsets.only(top: 30, bottom: 30),
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 100, vertical: 15),
//                               backgroundColor: Color(COLOR_PRIMARY),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             onPressed: () {
//                               setState(() {
//                                 for (int a = 0;
//                                     a < snapshot.data!.length;
//                                     a++) {
//                                   OfferModel coupon = snapshot.data![a];
//
//                                   if (vendorID == coupon.restaurantId ||
//                                       coupon.restaurantId == "") {
//                                     if (txt.text.toString() ==
//                                         coupon.offerCode!.toString()) {
//                                       print(coupon.toJson());
//                                       setState(() {
//                                         couponModel = coupon;
//                                       });
//
//                                       // if (couponModel.discountTypeOffer == 'Percentage' || couponModel.discountTypeOffer == 'Percent') {
//                                       //   percentage = double.parse(couponModel.discountOffer!);
//                                       //   couponId = couponModel.offerId!;
//                                       //   break;
//                                       // } else {
//                                       //   type = double.parse(couponModel.discountOffer!);
//                                       //   couponId = couponModel.offerId!;
//                                       // }
//                                     }
//                                   }
//                                 }
//                               });
//
//                               Navigator.pop(context);
//                             },
//                             child: Text(
//                               "REDEEM NOW".tr(),
//                               style: TextStyle(
//                                   color: isDarkMode(context)
//                                       ? Colors.black
//                                       : Colors.white,
//                                   fontFamily: 'Poppinsm',
//                                   fontSize: 16),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )),
//                 //buildcouponItem(snapshot)
//                 //  listData(snapshot)
//               ]);
//             }));
//   }
//
//   _displayDialog(BuildContext context) async {
//     return showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) {
//           return AlertDialog(
//             title: Text('Tip your driver partner'.tr()),
//             content: TextField(
//               controller: _textFieldController,
//               textInputAction: TextInputAction.go,
//               keyboardType: TextInputType.numberWithOptions(),
//               decoration: InputDecoration(hintText: "Enter your tip".tr()),
//             ),
//             actions: <Widget>[
//               new ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(COLOR_PRIMARY),
//                     textStyle: TextStyle(fontWeight: FontWeight.normal)),
//                 child: new Text('Cancel'.tr()),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//               new ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(COLOR_PRIMARY),
//                     textStyle: TextStyle(fontWeight: FontWeight.normal)),
//                 child: new Text('Submit'.tr()),
//                 onPressed: () {
//                   setState(() {
//                     var value = _textFieldController.text.toString();
//                     if (value.isEmpty) {
//                       isTipSelected3 = false;
//                       tipValue = 0;
//                     } else {
//                       isTipSelected3 = true;
//                       tipValue = double.parse(value);
//                     }
//                     isTipSelected = false;
//                     isTipSelected1 = false;
//                     isTipSelected2 = false;
//
//                     Navigator.of(context).pop();
//                   });
//                 },
//               )
//             ],
//           );
//         });
//   }
//
//   Future<void> getPrefData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     if (prefs.containsKey('musics_key')) {
//       final String musicsString = prefs.getString('musics_key')!;
//       if (musicsString.isNotEmpty) {
//         lstExtras = AddAddonsDemo.decode(musicsString);
//         lstExtras.forEach((element) {
//           commaSepratedAddOns.add(element.name!);
//         });
//         commaSepratedAddOnsString = commaSepratedAddOns.join(", ");
//         commaSepratedAddSizeString = commaSepratedAddSize.join(", ");
//       }
//     }
//   }
//
//   Future<void> setPrefData() async {
//     SharedPreferences sp = await SharedPreferences.getInstance();
//
//     sp.setString("musics_key", "");
//     sp.setString("addsize", "");
//   }
//
//   Widget tipWidgetMethod({String? amount}) {
//     return Expanded(
//       child: Container(
//         margin: EdgeInsets.only(right: 5),
//         padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
//         decoration: BoxDecoration(
//           color: tipValue == 10 && isTipSelected
//               ? Color(COLOR_PRIMARY)
//               : tipValue == 20 && isTipSelected1
//                   ? Color(COLOR_PRIMARY)
//                   : tipValue == 30 && isTipSelected2
//                       ? Color(COLOR_PRIMARY)
//                       : Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Color(0xff9091A4), width: 1),
//         ),
//         child: Center(
//             child: Text(
//           amountShow(amount: amount),
//           style: TextStyle(
//               fontFamily: "Poppinssm",
//               color:
//                   isDarkMode(context) ? Color(0xffFFFFFF) : Color(0xff333333),
//               fontSize: 14),
//         )),
//       ),
//     );
//   }
//
//   noteSheet() {
//     return Container(
//         padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).size.height / 4.3,
//             left: 25,
//             right: 25),
//         height: MediaQuery.of(context).size.height * 0.88,
//         decoration: BoxDecoration(
//             color: Colors.transparent,
//             border: Border.all(style: BorderStyle.none)),
//         child: Column(children: [
//           InkWell(
//               onTap: () => Navigator.pop(context),
//               child: Container(
//                 height: 45,
//                 decoration: BoxDecoration(
//                     border: Border.all(color: Colors.white, width: 0.3),
//                     color: Colors.transparent,
//                     shape: BoxShape.circle),
//
//                 // radius: 20,
//                 child: Center(
//                   child: Icon(
//                     Icons.close,
//                     color: Colors.white,
//                     size: 28,
//                   ),
//                 ),
//               )),
//           SizedBox(
//             height: 25,
//           ),
//           Expanded(
//               child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                   color: isDarkMode(context)
//                       ? const Color(DarkContainerBorderColor)
//                       : Colors.grey.shade100,
//                   width: 1),
//               color: isDarkMode(context)
//                   ? const Color(DarkContainerColor)
//                   : Colors.white,
//               boxShadow: [
//                 isDarkMode(context)
//                     ? const BoxShadow()
//                     : BoxShadow(
//                         color: Colors.grey.withOpacity(0.5),
//                         blurRadius: 5,
//                       ),
//               ],
//             ),
//             alignment: Alignment.center,
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   Container(
//                       padding: EdgeInsets.only(top: 20),
//                       child: Text(
//                         'Remarks'.tr(),
//                         style: TextStyle(
//                             fontFamily: 'Poppinssb',
//                             color: isDarkMode(context)
//                                 ? Color(0XFFD5D5D5)
//                                 : Color(0XFF2A2A2A),
//                             fontSize: 16),
//                       )),
//                   Container(
//                       padding: EdgeInsets.only(top: 10),
//                       child: Text(
//                         'Write remarks for restaurant',
//                         style: TextStyle(
//                             fontFamily: 'Poppinsr',
//                             color: isDarkMode(context)
//                                 ? Colors.white70
//                                 : Color(0XFF9091A4),
//                             letterSpacing: 0.5,
//                             height: 2),
//                       ).tr()),
//                   Container(
//                       padding: EdgeInsets.only(left: 20, right: 20, top: 20),
//                       // height: 120,
//                       child: DottedBorder(
//                           borderType: BorderType.RRect,
//                           radius: Radius.circular(12),
//                           dashPattern: [4, 2],
//                           child: ClipRRect(
//                               borderRadius:
//                                   BorderRadius.all(Radius.circular(12)),
//                               child: Container(
//                                   padding: EdgeInsets.only(
//                                       left: 20, right: 20, top: 20, bottom: 20),
//                                   alignment: Alignment.center,
//                                   child: TextFormField(
//                                     textAlign: TextAlign.center,
//                                     controller: noteController,
//                                     decoration: InputDecoration(
//                                       border: InputBorder.none,
//                                       hintText: 'Write Remarks'.tr(),
//                                     ),
//                                   ))))),
//                   Padding(
//                     padding: const EdgeInsets.only(top: 30, bottom: 30),
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 100, vertical: 15),
//                         backgroundColor: Color(COLOR_PRIMARY),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       child: Text(
//                         'SUBMIT'.tr(),
//                         style: TextStyle(
//                             color: isDarkMode(context)
//                                 ? Colors.white
//                                 : Colors.black,
//                             fontFamily: 'Poppinsm',
//                             fontSize: 16),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           )),
//         ]));
//   }
//
//   void showDateTimeBottomSheet(
//       BuildContext context, Function(DateTime) onDateTimeSelected) {
//     getScheduleOrderMinutes();
//     DateTime now = DateTime.now();
//     DateTime minimumAllowedTime = now.add(
//       Duration(
//         minutes: (int.parse(Dynamicminutes ?? '') + 5),
//       ),
//     ); // Add 30 minutes
//     DateTime selectedDate = minimumAllowedTime;
//
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setState) {
//             return Container(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     'Select Date & Time',
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold, fontSize: 18),
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     height: 200,
//                     child: CupertinoDatePicker(
//                       initialDateTime: selectedDate,
//                       minimumDate: minimumAllowedTime,
//                       mode: CupertinoDatePickerMode.dateAndTime,
//                       onDateTimeChanged: (DateTime newDate) {
//                         setState(() => selectedDate = newDate);
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF007AFF),
//                       alignment: Alignment.center,
//                     ),
//                     onPressed: () {
//                       onDateTimeSelected(selectedDate);
//                       print("selectedDateselectedDate${selectedDate}");
//                       Navigator.of(context).pop();
//                     },
//                     child: const Text(
//                       'Confirm',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//   // Future<List<Map<String, dynamic>>> fetchWorkingHours(String vendorId) async {
//   //   DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
//   //       .collection('vendors')
//   //       .doc(vendorId)
//   //       .get();
//   //
//   //   if (vendorDoc.exists) {
//   //     var workingHours = vendorDoc['workingHours'] as List<dynamic>? ?? [];
//   //     print("workingHoursworkingHoursworkingHours${workingHours}");
//   //     return workingHours.map((e) => e as Map<String, dynamic>).toList();
//   //   } else {
//   //     throw Exception("Vendor not found");
//   //   }
//   // }
//   // void showDateTimeBottomSheet12(
//   //     BuildContext context,
//   //     Function(DateTime) onDateTimeSelected,
//   //     List<Map<String, dynamic>> workingHours,
//   //     ) {
//   //   DateTime now = DateTime.now();
//   //   DateTime selectedDate = now.add(const Duration(days: 1)); // Start from tomorrow
//   //
//   //   showModalBottomSheet(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return StatefulBuilder(
//   //         builder: (BuildContext context, StateSetter setState) {
//   //           String selectedDay = [
//   //             "Sunday",
//   //             "Monday",
//   //             "Tuesday",
//   //             "Wednesday",
//   //             "Thursday",
//   //             "Friday",
//   //             "Saturday"
//   //           ][selectedDate.weekday % 7];
//   //
//   //           List<Map<String, String>> availableTimeSlots =
//   //           getTimeSlotsForDay(workingHours, selectedDay);
//   //
//   //           return Container(
//   //             padding: const EdgeInsets.all(16),
//   //             child: Column(
//   //               mainAxisSize: MainAxisSize.min,
//   //               children: [
//   //                 const Text(
//   //                   'Select Date & Time',
//   //                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 SizedBox(
//   //                   height: 200,
//   //                   child: CupertinoDatePicker(
//   //                     initialDateTime: selectedDate,
//   //                     minimumDate: now.add(const Duration(days: 1)),
//   //                     mode: CupertinoDatePickerMode.dateAndTime,
//   //                     onDateTimeChanged: (DateTime newDate) {
//   //                       setState(() {
//   //                         selectedDate = newDate;
//   //                         selectedDay = [
//   //                           "Sunday",
//   //                           "Monday",
//   //                           "Tuesday",
//   //                           "Wednesday",
//   //                           "Thursday",
//   //                           "Friday",
//   //                           "Saturday"
//   //                         ][newDate.weekday % 7];
//   //                         availableTimeSlots =
//   //                             getTimeSlotsForDay(workingHours, selectedDay);
//   //                       });
//   //                     },
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 availableTimeSlots.isEmpty
//   //                     ? const Text('No available slots for this day.')
//   //                     : Expanded(
//   //                   child: ListView.builder(
//   //                     shrinkWrap: true,
//   //                     itemCount: availableTimeSlots.length,
//   //                     itemBuilder: (context, index) {
//   //                       final slot = availableTimeSlots[index];
//   //                       return Card(
//   //                         child: ListTile(
//   //                           title: Text(
//   //                             "From: ${slot['from']} To: ${slot['to']}",
//   //                             style: const TextStyle(fontSize: 16),
//   //                           ),
//   //                         ),
//   //                       );
//   //                     },
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 ElevatedButton(
//   //                   style: ElevatedButton.styleFrom(
//   //                     backgroundColor: const Color(0xFF007AFF),
//   //                   ),
//   //                   onPressed: () {
//   //                     onDateTimeSelected(selectedDate);
//   //                     Navigator.of(context).pop();
//   //                   },
//   //                   child: const Text(
//   //                     'Confirm',
//   //                     style: TextStyle(color: Colors.white),
//   //                   ),
//   //                 ),
//   //               ],
//   //             ),
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   // }
//
// String? auto_apply_coupon_id;
// num discountadmindiscount=0;
// num? pricenew;
// bool?auto_apply;
// /// code already working
// //   Future<List<Map<String, dynamic>>> fetchWorkingHours(String vendorId) async {
// //     print("fetchworking valu call thaya che");
// //     DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
// //         .collection('vendors')
// //         .doc(vendorId)
// //         .get();
// //
// //     if (vendorDoc.exists) {
// //       var workingHours = vendorDoc['workingHours'] as List<dynamic>? ?? [];
// //       auto_apply_coupon_id=vendorDoc['auto_apply_coupon_id'].toString();
// //       auto_apply = vendorDoc['auto_apply'];
// //
// //       // discountadmindiscount = vendorDoc['auto_apply_discount'];
// //        discountadmindiscount =num.parse(vendorDoc['auto_apply_discount'].toString());
// //
// //
// //       print("workingHours: $workingHours");
// //       print("workingHours gdfgdfg: $auto_apply_coupon_id");
// //       print("workingHoursgdfgdfgdfgdfgdfg:  $auto_apply");
// //       print("workingHoursgdfgdfgdfgdfgdfg:  $discountadmindiscount");
// //       auto_apply==true? getCityrestaurantcity():print("aoto apply  false ave che");
// //       // Convert to a list of maps
// //       return workingHours.map((e) => e as Map<String, dynamic>).toList();
// //     } else {
// //       throw Exception("Vendor not found");
// //     }
// //   }
//
//
//   Future<List<Map<String, dynamic>>> fetchWorkingHours() async {
//     print("fetchworking valu call thaya che${vendoridvendorid}");
//
//     DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
//         .collection('vendors')
//         .doc(vendoridvendorid)
//         .get();
//
//     if (vendorDoc.exists) {
//       var vendorData = vendorDoc.data() as Map<String, dynamic>? ?? {};
//
//       var workingHours = vendorData['workingHours'] as List<dynamic>? ?? [];
//       setState(() {
//         auto_apply_coupon_id = vendorData.containsKey('auto_apply_coupon_id')
//             ? vendorData['auto_apply_coupon_id'].toString()
//             : "";
//
//         auto_apply = vendorData.containsKey('auto_apply')
//             ? vendorData['auto_apply']
//             : false;
//
//         discountadmindiscount = vendorData.containsKey('auto_apply_discount')
//             ? num.tryParse(vendorData['auto_apply_discount'].toString()) ?? 0
//             : 0;
//
//         print("workingHours: $workingHours");
//         print("auto_apply_coupon_id: $auto_apply_coupon_id");
//         print("auto_apply: $auto_apply");
//         print("discountadmindiscount: $discountadmindiscount");
//       });
//
// if(auto_apply==true){
//   getCityrestaurantcity();
// }else{
//   setState(() {
//     isload=false;
//   });
//   print("auto apply false che");
// }
//       // auto_apply == true ?  : ;
//
//       // Convert to a list of maps
//       return workingHours.map((e) => e as Map<String, dynamic>).toList();
//     } else {
//       throw Exception("Vendor not found");
//     }
//   }
//
//   // void showDateTimeBottomSheet12(
//   //     BuildContext context,
//   //     Function(DateTime) onDateTimeSelected,
//   //     List<Map<String, dynamic>> workingHours,
//   //     ) {
//   //   DateTime now = DateTime.now();
//   //   DateTime selectedDate = now.add(const Duration(days: 1)); // Start from tomorrow
//   //
//   //   showModalBottomSheet(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return StatefulBuilder(
//   //         builder: (BuildContext context, StateSetter setState) {
//   //           String selectedDay = [
//   //             "Sunday",
//   //             "Monday",
//   //             "Tuesday",
//   //             "Wednesday",
//   //             "Thursday",
//   //             "Friday",
//   //             "Saturday"
//   //           ][selectedDate.weekday % 7];
//   //
//   //           // Get available time slots for the selected day
//   //           List<Map<String, String>> availableTimeSlots =
//   //           getTimeSlotsForDay(workingHours, selectedDay);
//   //
//   //           return Container(
//   //             padding: const EdgeInsets.all(16),
//   //             child: Column(
//   //               mainAxisSize: MainAxisSize.min,
//   //               children: [
//   //                 const Text(
//   //                   'Select Date & Time',
//   //                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 SizedBox(
//   //                   height: 200,
//   //                   child: CupertinoDatePicker(
//   //                     initialDateTime: selectedDate,
//   //                     minimumDate: now.add(const Duration(days: 1)),
//   //                     mode: CupertinoDatePickerMode.dateAndTime,
//   //                     onDateTimeChanged: (DateTime newDate) {
//   //                       setState(() {
//   //                         selectedDate = newDate;
//   //                         selectedDay = [
//   //                           "Sunday",
//   //                           "Monday",
//   //                           "Tuesday",
//   //                           "Wednesday",
//   //                           "Thursday",
//   //                           "Friday",
//   //                           "Saturday"
//   //                         ][newDate.weekday % 7];
//   //                         availableTimeSlots =
//   //                             getTimeSlotsForDay(workingHours, selectedDay);
//   //                       });
//   //                     },
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 availableTimeSlots.isEmpty
//   //                     ? catproducatmart=="grocery"?Text('Mart closed for this time.'):Text('Restaurant closed for this time.')
//   //                     : Expanded(
//   //                   child: ListView.builder(
//   //                     shrinkWrap: true,
//   //                     itemCount: availableTimeSlots.length,
//   //                     itemBuilder: (context, index) {
//   //                       final slot = availableTimeSlots[index];
//   //                       return Card(
//   //                         child: ListTile(
//   //                           title: Text(
//   //                             "From: ${slot['from']} To: ${slot['to']}",
//   //                             style: const TextStyle(fontSize: 16),
//   //                           ),
//   //                         ),
//   //                       );
//   //                     },
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 availableTimeSlots.isEmpty?Container():ElevatedButton(
//   //                   style: ElevatedButton.styleFrom(
//   //                     backgroundColor: const Color(0xFF007AFF),
//   //                   ),
//   //                   onPressed: () {
//   //                     onDateTimeSelected(selectedDate);
//   //                     Navigator.of(context).pop();
//   //                   },
//   //                   child: const Text(
//   //                     'Confirm',
//   //                     style: TextStyle(color: Colors.white),
//   //                   ),
//   //                 ),
//   //               ],
//   //             ),
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   // }
//
//   ///code work kare che
//   // void showDateTimeBottomSheet12(
//   //     BuildContext context,
//   //     Function(DateTime) onDateTimeSelected,
//   //     List<Map<String, dynamic>> workingHours,
//   //     ) {
//   //   DateTime now = DateTime.now();
//   //   DateTime selectedDate = now; // Start from tomorrow
//   //
//   //   showModalBottomSheet(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return StatefulBuilder(
//   //         builder: (BuildContext context, StateSetter setState) {
//   //           String selectedDay = [
//   //             "Sunday",
//   //             "Monday",
//   //             "Tuesday",
//   //             "Wednesday",
//   //             "Thursday",
//   //             "Friday",
//   //             "Saturday"
//   //           ][selectedDate.weekday % 7];
//   //
//   //           // Get available time slots for the selected day
//   //           List<Map<String, String>> availableTimeSlots =
//   //           getTimeSlotsForDay(workingHours, selectedDay);
//   //
//   //           // Function to check if selected time is within working hours
//   //           bool isSelectedTimeValid(DateTime selectedDateTime) {
//   //             for (var slot in availableTimeSlots) {
//   //               var fromTime = _parseTime(slot['from']!);
//   //               var toTime = _parseTime(slot['to']!);
//   //
//   //               DateTime slotStart = DateTime(
//   //                 selectedDateTime.year,
//   //                 selectedDateTime.month,
//   //                 selectedDateTime.day,
//   //                 fromTime['hour']!,
//   //                 fromTime['minute']!,
//   //               );
//   //
//   //               DateTime slotEnd = DateTime(
//   //                 selectedDateTime.year,
//   //                 selectedDateTime.month,
//   //                 selectedDateTime.day,
//   //                 toTime['hour']!,
//   //                 toTime['minute']!,
//   //               );
//   //
//   //               if (selectedDateTime.isAfter(slotStart) && selectedDateTime.isBefore(slotEnd)) {
//   //                 return true;
//   //               }
//   //             }
//   //             return false;
//   //           }
//   //
//   //
//   //           return Container(
//   //             padding: const EdgeInsets.all(16),
//   //             child: Column(
//   //               mainAxisSize: MainAxisSize.min,
//   //               children: [
//   //                 const Text(
//   //                   'Select Date & Time',
//   //                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 SizedBox(
//   //                   height: 200,
//   //                   child: CupertinoDatePicker(
//   //                     initialDateTime: selectedDate,
//   //                     minimumDate: now.add(const Duration(days: 1)),
//   //                     mode: CupertinoDatePickerMode.dateAndTime,
//   //                     onDateTimeChanged: (DateTime newDate) {
//   //                       setState(() {
//   //                         selectedDate = newDate;
//   //                         selectedDay = [
//   //                           "Sunday",
//   //                           "Monday",
//   //                           "Tuesday",
//   //                           "Wednesday",
//   //                           "Thursday",
//   //                           "Friday",
//   //                           "Saturday"
//   //                         ][newDate.weekday % 7];
//   //                         availableTimeSlots =
//   //                             getTimeSlotsForDay(workingHours, selectedDay);
//   //                       });
//   //                     },
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 availableTimeSlots.isEmpty
//   //                     ? catproducatmart == "grocery"
//   //                     ? Text('Mart closed for this time.')
//   //                     : Text('Restaurant closed for this time.')
//   //                     : Expanded(
//   //                   child: ListView.builder(
//   //                     shrinkWrap: true,
//   //                     itemCount: availableTimeSlots.length,
//   //                     itemBuilder: (context, index) {
//   //                       final slot = availableTimeSlots[index];
//   //                       return Card(
//   //                         child: ListTile(
//   //                           title: Text(
//   //                             "From: ${slot['from']} To: ${slot['to']}",
//   //                             style: const TextStyle(fontSize: 16),
//   //                           ),
//   //                         ),
//   //                       );
//   //                     },
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 availableTimeSlots.isEmpty
//   //                     ? Container()
//   //                     : ElevatedButton(
//   //                   style: ElevatedButton.styleFrom(
//   //                     backgroundColor: const Color(0xFF007AFF),
//   //                   ),
//   //                   onPressed: () {
//   //                     // Check if the selected time is within working hours
//   //                     if (isSelectedTimeValid(selectedDate)) {
//   //                       onDateTimeSelected(selectedDate);
//   //                       Navigator.of(context).pop();
//   //                     } else {
//   //                       Navigator.of(context).pop();
//   //                       // Show error message
//   //                       ScaffoldMessenger.of(context).showSnackBar(
//   //                         SnackBar(content: Text('Selected time is outside working hours.')),
//   //                       );
//   //                     }
//   //                   },
//   //                   child: const Text(
//   //                     'Confirm',
//   //                     style: TextStyle(color: Colors.white),
//   //                   ),
//   //                 ),
//   //               ],
//   //             ),
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   // }
// /// new code che
// //   void showDateTimeBottomSheet12(
// //       BuildContext context,
// //       Function(DateTime) onDateTimeSelected,
// //       List<Map<String, dynamic>> workingHours,
// //       // Added parameter to check Mart or Restaurant
// //       ) {
// //     DateTime now = DateTime.now();
// //     DateTime minimumDate = now.add(const Duration(days: 1));
// //     DateTime selectedDate = minimumDate; // Ensure it starts from tomorrow
// //
// //     showModalBottomSheet(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return StatefulBuilder(
// //           builder: (BuildContext context, StateSetter setState) {
// //             String selectedDay = [
// //               "Sunday",
// //               "Monday",
// //               "Tuesday",
// //               "Wednesday",
// //               "Thursday",
// //               "Friday",
// //               "Saturday"
// //             ][selectedDate.weekday % 7];
// //
// //             // Get available time slots for the selected day
// //             List<Map<String, String>> availableTimeSlots =
// //             getTimeSlotsForDay(workingHours, selectedDay);
// //
// //             // Function to check if selected time is within working hours
// //             bool isSelectedTimeValid(DateTime selectedDateTime) {
// //               for (var slot in availableTimeSlots) {
// //                 var fromTime = _parseTime(slot['from']!);
// //                 var toTime = _parseTime(slot['to']!);
// //
// //                 DateTime slotStart = DateTime(
// //                   selectedDateTime.year,
// //                   selectedDateTime.month,
// //                   selectedDateTime.day,
// //                   fromTime['hour']!,
// //                   fromTime['minute']!,
// //                 );
// //
// //                 DateTime slotEnd = DateTime(
// //                   selectedDateTime.year,
// //                   selectedDateTime.month,
// //                   selectedDateTime.day,
// //                   toTime['hour']!,
// //                   toTime['minute']!,
// //                 );
// //
// //                 if (selectedDateTime.isAfter(slotStart) &&
// //                     selectedDateTime.isBefore(slotEnd)) {
// //                   return true;
// //                 }
// //               }
// //               return false;
// //             }
// //
// //             return Container(
// //               padding: const EdgeInsets.all(16),
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   const Text(
// //                     'Select Date & Time',
// //                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
// //                   ),
// //                   const SizedBox(height: 20),
// //                   SizedBox(
// //                     height: 200,
// //                     child: CupertinoDatePicker(
// //                       initialDateTime: selectedDate,
// //                       minimumDate: minimumDate,
// //                       mode: CupertinoDatePickerMode.dateAndTime,
// //                       onDateTimeChanged: (DateTime newDate) {
// //                         setState(() {
// //                           selectedDate = newDate.isBefore(minimumDate)
// //                               ? minimumDate
// //                               : newDate;
// //                           selectedDay = [
// //                             "Sunday",
// //                             "Monday",
// //                             "Tuesday",
// //                             "Wednesday",
// //                             "Thursday",
// //                             "Friday",
// //                             "Saturday"
// //                           ][selectedDate.weekday % 7];
// //                           availableTimeSlots =
// //                               getTimeSlotsForDay(workingHours, selectedDay);
// //                         });
// //                       },
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),
// //                   availableTimeSlots.isEmpty
// //                       ? Text(catproducatmart == "grocery"
// //                       ? 'Mart closed for this time.'
// //                       : 'Restaurant closed for this time.')
// //                       : Expanded(
// //                     child: ListView.builder(
// //                       shrinkWrap: true,
// //                       itemCount: availableTimeSlots.length,
// //                       itemBuilder: (context, index) {
// //                         final slot = availableTimeSlots[index];
// //                         return Card(
// //                           child: ListTile(
// //                             title: Text(
// //                               "From: ${slot['from']} To: ${slot['to']}",
// //                               style: const TextStyle(fontSize: 16),
// //                             ),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),
// //                   availableTimeSlots.isEmpty
// //                       ? Container()
// //                       : ElevatedButton(
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: const Color(0xFF007AFF),
// //                     ),
// //                     onPressed: () {
// //                       // Check if the selected time is within working hours
// //                       if (isSelectedTimeValid(selectedDate)) {
// //                         onDateTimeSelected(selectedDate);
// //                         Navigator.of(context).pop();
// //                       } else {
// //                         Navigator.of(context).pop();
// //                         // Show error message
// //                         ScaffoldMessenger.of(context).showSnackBar(
// //                           SnackBar(
// //                               content: Text(
// //                                   'Selected time is outside working hours.')),
// //                         );
// //                       }
// //                     },
// //                     child: const Text(
// //                       'Confirm',
// //                       style: TextStyle(color: Colors.white),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// //
// //   Map<String, int> _parseTime(String time) {
// //     List<String> timeParts = time.split(':');
// //     int hour = int.parse(timeParts[0]);
// //     int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
// //
// //     return {'hour': hour, 'minute': minute};
// //   }
// //
//   List<Map<String, String>> getTimeSlotsForDay(
//       List<Map<String, dynamic>> workingHours, String selectedDay) {
//     var daySlots = workingHours.where((slot) => slot['day'] == selectedDay).toList();
//
//     List<Map<String, String>> availableSlots = daySlots.expand((daySlot) {
//       List<Map<String, String>> slots = [];
//       for (var timeSlot in daySlot['timeslot'] as List<dynamic>) {
//         slots.add({
//           'from': timeSlot['from'], // Ensure this is in 24-hour format
//           'to': timeSlot['to'], // Ensure this is in 24-hour format
//         });
//       }
//       return slots;
//     }).toList();
//
//     print("availableSlots: $availableSlots");
//     return availableSlots;
//   }
//
//   void showDateTimeBottomSheet12(
//       BuildContext context,
//       Function(DateTime) onDateTimeSelected,
//       List<Map<String, dynamic>> workingHours,
//      // Added parameter to check Mart or Restaurant
//       ) {
//     DateTime now = DateTime.now();
//     DateTime minimumDate = now; // Allow today also
//     DateTime selectedDate = minimumDate; // Ensure it starts from today
//
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setState) {
//             String selectedDay = [
//               "Sunday",
//               "Monday",
//               "Tuesday",
//               "Wednesday",
//               "Thursday",
//               "Friday",
//               "Saturday"
//             ][selectedDate.weekday % 7];
//
//             // Get available time slots for the selected day
//             List<Map<String, String>> availableTimeSlots =
//             getTimeSlotsForDay(workingHours, selectedDay);
//
//             // Function to check if selected time is within working hours
//             bool isSelectedTimeValid(DateTime selectedDateTime) {
//               for (var slot in availableTimeSlots) {
//                 var fromTime = _parseTime(slot['from']!);
//                 var toTime = _parseTime(slot['to']!);
//
//                 DateTime slotStart = DateTime(
//                   selectedDateTime.year,
//                   selectedDateTime.month,
//                   selectedDateTime.day,
//                   fromTime['hour']!,
//                   fromTime['minute']!,
//                 );
//
//                 DateTime slotEnd = DateTime(
//                   selectedDateTime.year,
//                   selectedDateTime.month,
//                   selectedDateTime.day,
//                   toTime['hour']!,
//                   toTime['minute']!,
//                 );
//
//                 if (selectedDateTime.isAfter(slotStart) &&
//                     selectedDateTime.isBefore(slotEnd)) {
//                   return true;
//                 }
//               }
//               return false;
//             }
//
//             return Container(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Select Date & Time',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     height: 200,
//                     child: CupertinoDatePicker(
//                       initialDateTime: selectedDate,
//                       minimumDate: minimumDate,
//                       mode: CupertinoDatePickerMode.dateAndTime,
//
//                       onDateTimeChanged: (DateTime newDate) {
//                         setState(() {
//                           selectedDate = newDate.isBefore(minimumDate)
//                               ? minimumDate
//                               : newDate;
//                           selectedDay = [
//                             "Sunday",
//                             "Monday",
//                             "Tuesday",
//                             "Wednesday",
//                             "Thursday",
//                             "Friday",
//                             "Saturday"
//                           ][selectedDate.weekday % 7];
//                           availableTimeSlots =
//                               getTimeSlotsForDay(workingHours, selectedDay);
//                         });
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   availableTimeSlots.isEmpty
//                       ? Text(catproducatmart == "grocery"
//                       ? 'Mart closed for this time.'
//                       : 'Restaurant closed for this time.')
//                       : Expanded(
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: availableTimeSlots.length,
//                       itemBuilder: (context, index) {
//                         final slot = availableTimeSlots[index];
//                         return Card(
//                           child: ListTile(
//                             title: Text(
//                               "From: ${formatTime(slot['from'].toString())} To: ${formatTime(slot['to'].toString())}",
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   availableTimeSlots.isEmpty
//                       ? Container()
//                       : ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF007AFF),
//                     ),
//                     onPressed: () {
//                       // Check if the selected time is within working hours
//                       if (isSelectedTimeValid(selectedDate)) {
//                         onDateTimeSelected(selectedDate);
//                         print("selectedDatedsfdsfsd${formatTime1(selectedDate.toString())}");
//
//                         Navigator.of(context).pop();
//                       } else {
//                         Navigator.of(context).pop();
//                         // Show error message
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                               content: Text(
//                                   'Selected time is outside working hours.')),
//                         );
//                       }
//                     },
//                     child: const Text(
//                       'Confirm',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//   String formatTime(String time) {
//     DateTime dateTime = DateTime.parse("2024-01-01 $time"); // ફક્ત સમય માટે ડેટા ઉમેરવો જરૂરી છે
//     return DateFormat.jm().format(dateTime); // 12-કલાકનું ફોર્મેટ (AM/PM)
//   }
//   String formatTime1(String time) {
//     DateTime dateTime = DateTime.parse("$time"); // ફક્ત સમય માટે ડેટા ઉમેરવો જરૂરી છે
//     return DateFormat.jm().format(dateTime); // 12-કલાકનું ફોર્મેટ (AM/PM)
//   }
// // Function to parse time string into hours and minutes
//   Map<String, int> _parseTime(String time) {
//     List<String> parts = time.split(':');
//     return {
//       'hour': int.parse(parts[0]),
//       'minute': int.parse(parts[1]),
//     };
//   }
//
// // Dummy function for fetching available time slots
//
//   /// a code haresh karelo che
//   // void showDateTimeBottomSheet1(
//   //     BuildContext context, Function(DateTime) onDateTimeSelected) {
//   //   getScheduleOrderMinutes();
//   //   DateTime now = DateTime.now();
//   //   int dynamicMinutes = int.tryParse(Dynamicminutes ?? '') ?? 0; // Default to 0 if null or invalid
//   //
//   //   // Set minimum allowed date to tomorrow
//   //   DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
//   //   DateTime minimumAllowedTime = tomorrow.add(Duration(minutes: dynamicMinutes)); // Add any dynamic minutes
//   //
//   //   DateTime selectedDate = minimumAllowedTime;
//   //
//   //   showModalBottomSheet(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return StatefulBuilder(
//   //         builder: (BuildContext context, StateSetter setState) {
//   //           return Container(
//   //             padding: const EdgeInsets.all(16),
//   //             child: Column(
//   //               mainAxisSize: MainAxisSize.min,
//   //               children: [
//   //                 const Text(
//   //                   'Select Date & Time',
//   //                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 SizedBox(
//   //                   height: 200,
//   //                   child: CupertinoDatePicker(
//   //                     initialDateTime: selectedDate,
//   //                     minimumDate: minimumAllowedTime,
//   //                     mode: CupertinoDatePickerMode.dateAndTime,
//   //                     onDateTimeChanged: (DateTime newDate) {
//   //                       setState(() => selectedDate = newDate);
//   //                     },
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 20),
//   //                 ElevatedButton(
//   //                   style: ElevatedButton.styleFrom(
//   //                     backgroundColor: const Color(0xFF007AFF),
//   //                     alignment: Alignment.center,
//   //                   ),
//   //                   onPressed: () {
//   //                     onDateTimeSelected(selectedDate);
//   //                     Navigator.of(context).pop();
//   //                   },
//   //                   child: const Text(
//   //                     'Confirm',
//   //                     style: TextStyle(color: Colors.white),
//   //                   ),
//   //                 ),
//   //               ],
//   //             ),
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   // }
//
//
//   /// chat gpt code
//
//
//   // _apply() async {
//   //   if (nameCoupon == "Applied") {
//   //     discountAmount = 0.0;
//   //     editableCoupon = true;
//   //     nameCoupon = "Apply";
//   //     couponTextField.text = "";
//   //     return;
//   //   } else {
//   //     var discount = 0.0;
//   //     int? maxdiscount = 0;
//   //     int? minamount = 0;
//   //     var type = "";
//   //     var data = await _fireStoreUtils.getAllCoupons();
//   //     if (data.length > 0) {
//   //       data.forEach((dataItem) =>
//   //       {
//   //         if (dataItem.offerCode == couponTextField.text)
//   //           {
//   //             discount = double.parse(dataItem.discount!),
//   //             maxdiscount = int.parse(dataItem.maxdiscount!),
//   //             type = dataItem.discountType!,
//   //             minamount = int.parse(dataItem.minamount!),
//   //             coponid123=dataItem.offerId.toString()
//   //           }
//   //       });
//   //     }
//   //
//   //     if (type == "Percent") {
//   //       discountAmount = (subTotal * discount) / 100;
//   //     } else {
//   //       discountAmount = discount;
//   //     }
//   //     if (subTotal < minamount!) {
//   //       discountAmount = 0.0;
//   //       editableCoupon = true;
//   //       showAlertDialog(context, minamount!);
//   //     } else if (discountAmount > maxdiscount!) {
//   //       discountAmount = maxdiscount!.toDouble();
//   //       editableCoupon = false;
//   //       nameCoupon = "Applied";
//   //     } else {
//   //       editableCoupon = false;
//   //       nameCoupon = "Applied";
//   //     }
//   //   }
//   // }
//   // _apply() async {
//   //   if (nameCoupon == "Applied") {
//   //     discountAmount = 0.0;
//   //     editableCoupon = true;
//   //     nameCoupon = "Apply";
//   //     couponTextField.text = "";
//   //     return;
//   //   } else {
//   //     var discount = 0.0;
//   //     int? maxdiscount = 0;
//   //     int? minamount = 0;
//   //     var type = "";
//   //
//   //     var data = await _fireStoreUtils.getAllCoupons();
//   //     if (data.length > 0) {
//   //       data.forEach((dataItem) {
//   //         if (dataItem.offerCode == couponTextField.text) {
//   //           discount = double.parse(dataItem.discount!);
//   //           maxdiscount = int.parse(dataItem.maxdiscount!);
//   //           type = dataItem.discountType!;
//   //           minamount = int.parse(dataItem.minamount!);
//   //           coponid123 = dataItem.offerId.toString();
//   //         }
//   //       });
//   //     }
//   //
//   //     // Ensure coponid123 is not empty before checking coupon usage
//   //     if (coponid123.isNotEmpty) {
//   //       String userId = MyAppState.currentUser?.userID ??
//   //           ""; // replace with the actual user ID
//   //       bool hasExceededLimit =
//   //           await hasUserExceededCouponUseLimit(userId, coponid123);
//   //
//   //       if (hasExceededLimit) {
//   //         final snackBar = SnackBar(
//   //           backgroundColor:
//   //               isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
//   //           content: Text(
//   //             'coupon_limit'.tr(),
//   //             style: TextStyle(
//   //                 color: isDarkMode(context) ? Colors.black : Colors.white),
//   //           ),
//   //         );
//   //         return ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   //       }
//   //     }
//   //
//   //     if (type == "Percent") {
//   //       discountAmount = (subTotal * discount) / 100;
//   //     } else {
//   //       discountAmount = discount;
//   //     }
//   //
//   //     if (subTotal < minamount!) {
//   //       discountAmount = 0.0;
//   //       editableCoupon = true;
//   //     } else if (discountAmount > maxdiscount!) {
//   //       discountAmount = maxdiscount!.toDouble();
//   //       editableCoupon = false;
//   //       nameCoupon = "Applied";
//   //     } else {
//   //       editableCoupon = false;
//   //       nameCoupon = "Applied";
//   //     }
//   //   }
//   // }
//   //
//   // Future<bool> hasUserExceededCouponUseLimit(
//   //     String userId, String couponId) async {
//   //   // Reference to the coupons collection
//   //   CollectionReference couponsCollection =
//   //       FirebaseFirestore.instance.collection('coupons');
//   //
//   //   // Reference to the coupon_used collection
//   //   CollectionReference couponUsedCollection =
//   //       FirebaseFirestore.instance.collection('coupon_used');
//   //
//   //   // Get the coupon document from the coupons collection
//   //   DocumentSnapshot couponDoc = await couponsCollection.doc(couponId).get();
//   //
//   //   if (!couponDoc.exists) {
//   //     throw Exception('Coupon not found');
//   //   }
//   //
//   //   // Get the coupon_use_count from the coupon document
//   //   int couponUseCount;
//   //   try {
//   //     couponUseCount = couponDoc['coupon_use_count'] is int
//   //         ? couponDoc['coupon_use_count']
//   //         : int.parse(couponDoc['coupon_use_count']);
//   //     print("couponUseCount${couponUseCount}");
//   //   } catch (e) {
//   //     print("Invalid coupon_use_count value");
//   //     throw Exception('Invalid coupon_use_count value');
//   //   }
//   //
//   //   // Query the coupon_used collection to count how many times the user has used the coupon
//   //   QuerySnapshot userCouponUsage = await couponUsedCollection
//   //       .where('coupon_id', isEqualTo: couponId)
//   //       .where('user_id', isEqualTo: userId)
//   //       .get();
//   //
//   //   int userUsageCount = userCouponUsage.size;
//   //   print("userId${userId}");
//   //   print("couponId${couponId}");
//   //   print("userUsageCount${userUsageCount}");
//   //
//   //   // Check if the user has used the coupon more times than allowed
//   //   return userUsageCount >= couponUseCount;
//   // }
//
//   //upar code working
//   /// a code working che 17-02-2025
// //   _apply() async {
// //     if (nameCoupon == "Applied") {
// //       discountAmount = 0.0;
// //       editableCoupon = true;
// //       nameCoupon = "Apply";
// //       couponTextField.text = "";
// //       return;
// //     } else {
// //       var discount = 0.0;
// //       int? maxdiscount = 0;
// //       int? minamount = 0;
// //       var type = "";
// //
// //       var data = await _fireStoreUtils.getAllCoupons();
// //       if (data.length > 0) {
// //         data.forEach((dataItem) {
// //           if (dataItem.offerCode == couponTextField.text) {
// //             discount = double.parse(dataItem.discount!);
// //             maxdiscount = int.parse(dataItem.maxdiscount!);
// //             type = dataItem.discountType!;
// //             minamount = int.parse(dataItem.minamount!);
// //             coponid123 = dataItem.offerId.toString();
// //           }
// //         });
// //       }
// //
// //       // Ensure coponid123 is not empty before checking coupon usage
// //       if (coponid123.isNotEmpty) {
// //         String userId = MyAppState.currentUser?.userID ?? "";
// //
// //         bool hasExceededLimit =
// //             await hasUserExceededCouponUseLimit(userId, coponid123);
// // print("hasExceededLimithasExceededLimit${hasExceededLimit}");
// //         if (hasExceededLimit) {
// //           final snackBar = SnackBar(
// //             backgroundColor:
// //                 isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
// //             content: Text(
// //               'coupon_limit'.tr(),
// //               style: TextStyle(
// //                   color: isDarkMode(context) ? Colors.black : Colors.white),
// //             ),
// //           );
// //           return ScaffoldMessenger.of(context).showSnackBar(snackBar);
// //         }
// //       }
// //
// //       if (type == "Percent") {
// //         discountAmount = (subTotal * discount) / 100;
// //       } else {
// //         discountAmount = discount;
// //       }
// //
// //       if (subTotal < minamount!) {
// //         discountAmount = 0.0;
// //         editableCoupon = true;
// //       } else if (discountAmount > maxdiscount!) {
// //         discountAmount = maxdiscount!.toDouble();
// //         editableCoupon = false;
// //         nameCoupon = "Applied";
// //       } else {
// //         editableCoupon = false;
// //         nameCoupon = "Applied";
// //       }
// //     }
// //   }
//   /// a code working che
//   _apply() async {
//     if (nameCoupon == "Applied") {
//       discountAmount = 0.0;
//       editableCoupon = true;
//       nameCoupon = "Apply";
//       couponTextField.text = "";
//       return;
//     } else {
//       var discount = 0.0;
//       int? maxdiscount = 0;
//       int? minamount = 0;
//       var type = "";
//       bool isExpired = false;
//       bool isValidCoupon = false;
//
//       var data = await _fireStoreUtils.getAllCoupons();
//       if (data.isNotEmpty) {
//         for (var dataItem in data) {
//           if (dataItem.offerCode == couponTextField.text) {
//             Timestamp expireTime = dataItem.expireOfferDate!;
//             if (expireTime.toDate().isBefore(DateTime.now())) {
//               isExpired = true;
//               break;
//             }
//
//             discount = double.parse(dataItem.discount!.toString());
//             maxdiscount = int.parse(dataItem.maxdiscount!);
//             type = dataItem.discountType!;
//             minamount = int.parse(dataItem.minamount!);
//             coponid123 = dataItem.offerId.toString();
//             isValidCoupon = true;
//           }
//         }
//       }
//
//       // **Check if Coupon is Expired First**
//       if (isExpired) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             backgroundColor: isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
//             content: Text(
//               'Coupon is expired!',
//               style: TextStyle(
//                   color: isDarkMode(context) ? Colors.black : Colors.white),
//             ),
//           ),
//         );
//         return;
//       }
//
//       // **Ensure coupon is valid before applying any logic**
//       // if (!isValidCoupon) {
//       //   ScaffoldMessenger.of(context).showSnackBar(
//       //     SnackBar(
//       //       backgroundColor: isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
//       //       content: Text(
//       //         'Invalid coupon code!',
//       //         style: TextStyle(
//       //             color: isDarkMode(context) ? Colors.black : Colors.white),
//       //       ),
//       //     ),
//       //   );
//       //   return;
//       // }
//
//       if (coponid123.isNotEmpty) {
//         String userId = MyAppState.currentUser?.userID ?? "";
//
//         bool hasExceededLimit = await hasUserExceededCouponUseLimit(userId, coponid123);
//         if (hasExceededLimit) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               backgroundColor: isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
//               content: Text(
//                 'You have exceeded the coupon usage limit!',
//                 style: TextStyle(
//                     color: isDarkMode(context) ? Colors.black : Colors.white),
//               ),
//             ),
//           );
//           return;
//         }
//       }
//
//       // **Only apply discount if coupon is valid**
//       if (type == "Percent") {
//         discountAmount = (subTotal * discount) / 100;
//       } else {
//         discountAmount = discount;
//       }
//
//       if (subTotal < minamount!) {
//         discountAmount = 0.0;
//         editableCoupon = true;
//       } else if (discountAmount > maxdiscount!) {
//         discountAmount = maxdiscount!.toDouble();
//         editableCoupon = false;
//         nameCoupon = "Applied";
//       } else {
//         editableCoupon = false;
//         nameCoupon = "Applied";
//       }
//     }
//   }
//
//
//   Future<bool> hasUserExceededCouponUseLimit(
//       String userId, String couponId) async {
//     // Reference to the coupons collection
//     CollectionReference couponsCollection =
//         FirebaseFirestore.instance.collection('coupons');
//
//     // Reference to the coupon_used collection
//     CollectionReference couponUsedCollection =
//         FirebaseFirestore.instance.collection('coupon_used');
//
//     // Get the coupon document from the coupons collection
//     DocumentSnapshot couponDoc = await couponsCollection.doc(couponId).get();
//
//     if (!couponDoc.exists) {
//       throw Exception('Coupon not found');
//     }
//
//     // Get the coupon_use_count from the coupon document
//     dynamic couponUseCount = couponDoc['coupon_use_count'];
//
//     // If coupon_use_count is null or an empty string, it means unlimited usage
//     if (couponUseCount == null || couponUseCount.toString().isEmpty) {
//       return false;
//     }
//
//     int couponUseCountInt;
//     try {
//       couponUseCountInt =
//           couponUseCount is int ? couponUseCount : int.parse(couponUseCount);
//       print("couponUseCountInt${couponUseCountInt}");
//     } catch (e) {
//       print("Invalid coupon_use_count value");
//       throw Exception('Invalid coupon_use_count value');
//     }
//
//     // Query the coupon_used collection to count how many times the user has used the coupon
//     QuerySnapshot userCouponUsage = await couponUsedCollection
//         .where('coupon_id', isEqualTo: couponId)
//         .where('user_id', isEqualTo: userId)
//         .get();
//
//     int userUsageCount = userCouponUsage.size;
//     print("userId${userId}");
//     print("couponId${couponId}");
//     print("userUsageCount${userUsageCount}");
//
//     // Check if the user has used the coupon more times than allowed
//     return userUsageCount >= couponUseCountInt;
//   }
// }
//
// Widget _buildChip(String label, int attributesOptionIndex) {
//   return Container(
//     decoration: BoxDecoration(
//         color: const Color(0xffEEEDED), borderRadius: BorderRadius.circular(4)),
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       child: Text(
//         label,
//         style: const TextStyle(
//           color: Colors.black,
//         ),
//       ),
//     ),
//   );
// }
//
// showAlertDialog(BuildContext context, int minamount) {
//   // set up the button
//   Widget okButton = TextButton(
//     child: Text("OK"),
//     onPressed: () {
//       Navigator.pop(context);
//     },
//   );
//
//   // set up the AlertDialog
//   AlertDialog alert = AlertDialog(
//     title: Text("Coupon not available!"),
//     content:
//         Text("This coupon can be applied only on orders above $minamount ₹"),
//     actions: [
//       okButton,
//     ],
//   );
//
//   // show the dialog
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return alert;
//     },
//   );
// }
//
// class RoundedInputBox extends StatelessWidget {
//   late TextEditingController couponTextField;
//   late bool editableCoupon;
//
//   RoundedInputBox(TextEditingController couponTextField, bool editableCoupon) {
//     this.couponTextField = couponTextField;
//     this.editableCoupon = editableCoupon;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color:
//           isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
//       child: TextField(
//         controller: couponTextField,
//         enabled: editableCoupon,
//         decoration: InputDecoration(
//           // labelText: 'Please Enter Coupon Code',
//           hintText: 'Enter Coupon Code',
//           hintStyle: TextStyle(
//               color: isDarkMode(context) ? Colors.white : Colors.black),
//           filled: true,
//
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class ButtonExample extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Button Example'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextButton(
//               onPressed: () {
//                 // Add your button's action here
//               },
//               child: Text('Text Button'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
