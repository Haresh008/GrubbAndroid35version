import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/CodModel.dart';
import 'package:foodie_customer/model/FlutterWaveSettingDataModel.dart';
import 'package:foodie_customer/model/OrderCretedRazorpayModal.dart';
import 'package:foodie_customer/model/PayFastSettingData.dart';
import 'package:foodie_customer/model/PayStackSettingsModel.dart';
import 'package:foodie_customer/model/ProductModel.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/model/payStackURLModel.dart';
import 'package:foodie_customer/model/razorpayKeyModel.dart';
import 'package:foodie_customer/model/stripeSettingData.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/services/paystack_url_genrater.dart';
import 'package:foodie_customer/ui/cartScreen/CartScreen.dart';
import 'package:foodie_customer/ui/checkoutScreen/CheckoutScreen.dart';
import 'package:foodie_customer/ui/container/ContainerScreen.dart';
import 'package:foodie_customer/ui/wallet/PayFastScreen.dart';
import 'package:foodie_customer/ui/wallet/payStackScreen.dart';
import 'package:foodie_customer/userPrefrence.dart';
import 'package:http/http.dart' as http;
import 'package:mercadopago_sdk/mercadopago_sdk.dart';
// import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/MercadoPagoSettingsModel.dart';
import '../../model/OrderModel.dart';
import '../../model/RazorPayFailedModel.dart';
import '../../model/StripePayFailedModel.dart';
import '../../model/TaxModel.dart';
import '../../model/VendorModel.dart';
import '../../model/getPaytmTxtToken.dart';
import '../../model/mail_setting.dart';
import '../../model/paypalSettingData.dart';
import '../../model/paytmSettingData.dart';
import '../placeOrderScreen/PlaceOrderScreen.dart';
import '../wallet/MercadoPagoScreen.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  final double toatvendoramount;
  final num wallamountvendor;
  final num autoapplydiscount;
  final double? discount;
  final String? couponCode;
  final String? groceryitem;
  final String? razorpayaccount;
  final String? vendoraccountnumber;
  final String? couponId1;
  final String? couponId, notes;
  final List<CartProduct> products;
  final String? chargepacking;
  final List<String>? extraAddons;
  final String? tipValue;
  final bool? takeAway;
  final bool? codWallet;
  final bool? auto_apply;
  final bool? cityaveche;
  final bool? isMyTime;
  final String? deliveryCharge;
  final List<TaxModel>? taxModel;
  final Map<String, dynamic>? specialDiscountMap;
  final Timestamp? scheduleTime;

  const PaymentScreen({
    Key? key,
    required this.total,
    required this.toatvendoramount,
    required this.couponId1,
    required this.groceryitem,
    required this.wallamountvendor,
    required this.autoapplydiscount,
    required this.codWallet,
    required this.auto_apply,
    required this.isMyTime,
    required this.cityaveche,
    this.discount,
    required this.razorpayaccount,
    required this.vendoraccountnumber,
    this.couponCode,
    this.couponId,
    this.chargepacking,
    required this.products,
    this.extraAddons,
    this.tipValue,
    this.takeAway,
    this.deliveryCharge,
    this.notes,
    this.taxModel,
    this.specialDiscountMap,
    this.scheduleTime,
  }) : super(key: key);

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

int? saturdayTimestamp;

class PaymentScreenState extends State<PaymentScreen> {
  String selectedCardID = '';
  final fireStoreUtils = FireStoreUtils();
  late Future<bool> hasNativePay;

  //List<PaymentMethod> _cards = [];
  late Future<CodModel?> futurecod;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? userQuery;

  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String paymentOption = 'Pay Via Wallet'.tr();
  RazorPayModel? razorPayData = UserPreference.getRazorPayData();

  Razorpay _razorPay = Razorpay();
  StripeSettingData? stripeData;
  PaytmSettingData? paytmSettingData;
  PaypalSettingData? paypalSettingData;
  PayStackSettingData? payStackSettingData;
  FlutterWaveSettingData? flutterWaveSettingData;
  PayFastSettingData? payFastSettingData;
  MercadoPagoSettingData? mercadoPagoSettingData;
  bool proceed = true;
  bool walletBalanceError = false;

  bool isStaging = true;
  String callbackUrl =
      "http://162.241.125.167/~foodie/payments/paytmpaymentcallback?ORDER_ID=";
  bool restrictAppInvoke = false;
  bool enableAssist = true;
  String result = "";
  String paymentType = "";

  late Map<String, dynamic>? adminCommission;
  String? adminCommissionValue = "", addminCommissionType = "";
  bool? isEnableAdminCommission = false;

  getPaymentSettingData() async {
    userQuery =
        fireStore
            .collection(USERS)
            .doc(MyAppState.currentUser!.userID)
            .snapshots();
    await UserPreference.getStripeData().then((value) async {
      stripeData = value;
      stripe1.Stripe.publishableKey = stripeData!.clientpublishableKey;
      stripe1.Stripe.merchantIdentifier = 'Grubb';
      await stripe1.Stripe.instance.applySettings();
    });
    razorPayData = await UserPreference.getRazorPayData();
    paytmSettingData = await UserPreference.getPaytmData();
    paypalSettingData = await UserPreference.getPayPalData();
    payStackSettingData = await UserPreference.getPayStackData();
    flutterWaveSettingData = await UserPreference.getFlutterWaveData();
    payFastSettingData = await UserPreference.getPayFastData();
    mercadoPagoSettingData = await UserPreference.getMercadoPago();

    ///set Refrence for FlutterWave
    setRef();
  }

  showAlert(context, {required String response, required Color colors}) {
    return ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response), backgroundColor: colors));
  }

  bool chakchak = true;
  num merchantamountminimum = 0;
  bool jumpnam = false;

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
          .doc("orderCancellationMinutes")
          .get()
          .then((value) {
            debugPrint(value.data().toString());
            setState(() {
              merchantamountminimum = num.parse(
                value.data()!['minimumDepositAmountMerchant'].toString(),
              );
              print(
                "merchantmimimum amou shu ave che ${merchantamountminimum}",
              );
              print(
                "merchantmimimum amou shu ave che ${widget.wallamountvendor}",
              );
              chakchak = false;
            });
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

  num? autoApplyFixCommission;
  num? adminCommissionValue1;
  num? grocerycommissionfix1;
  String? grocerycommissionfix = "";

  @override
  void initState() {
    super.initState();
    // getRazorPayDemo();
    getSaturdayTimestamp();
    getPaymentSettingData();
    initializeFlutterFire();
    FireStoreUtils.createOrder();
    print("widget.couponId1.toString()${widget.couponId1.toString()}");
    print("codWallet${widget.codWallet.toString()}");
    print("codWallet${widget.wallamountvendor.toString()}");
    print("codWallet${widget.total.toString()}");
    print(
      "ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja z${widget.auto_apply.toString()}",
    );
    // print("codWallet${widget..toString()}");
    futurecod = fireStoreUtils.getCod();
    _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
    _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    fireStoreUtils.getAdminCommission().then((value) {
      if (value != null) {
        setState(() {
          adminCommission = value;
          adminCommissionValue1 = adminCommission!["adminCommissionValue1"];
          grocerycommissionfix1 = adminCommission!["groceryatocommssion"];
          adminCommissionValue = adminCommission!["adminCommission"].toString();
          addminCommissionType =
              adminCommission!["adminCommissionType"].toString();
          autoApplyFixCommission = adminCommission!["autoApplyFixCommission"];
          isEnableAdminCommission = adminCommission!["isAdminCommission"];
          grocerycommissionfix =
              adminCommission!["grocerycommissionfix"].toString();
        });
        // if (widget.auto_apply == true &&
        //     widget.isMyTime == true &&
        //     widget.cityaveche == true) {
        //   if (widget.groceryitem == "grocery") {
        //     if (grocerycommissionfix1 == widget.autoapplydiscount) {
        //       setState(() {
        //         grocerycommissionfix ="0";
        //       });
        //       print("widget.groceryitem == ${grocerycommissionfix}");
        //     } else {
        //       if (grocerycommissionfix1 == 0 && grocerycommissionfix == "0") {
        //         setState(() {
        //           grocerycommissionfix = widget.autoapplydiscount.toString();
        //           print(
        //               "grocerycommissionfix1 00000.00000000000 ${grocerycommissionfix}");
        //         });
        //       } else {
        //         setState(() {
        //           grocerycommissionfix =
        //               (double.parse(grocerycommissionfix1.toString()) -
        //                       double.parse(widget.autoapplydiscount.toString()))
        //                   .abs()
        //                   .toStringAsFixed(2);
        //
        //           print(
        //               "else ave che jayare grocery hoy tayare ${grocerycommissionfix}");
        //         });
        //       }
        //     }
        //   }
        //   if (adminCommissionValue1 == widget.autoapplydiscount) {
        //     setState(() {
        //       adminCommissionValue = "0";
        //       jumpnam = true;
        //     });
        //     print(
        //         "adminCommissionValue>>>>>>>value shu ave che ${adminCommissionValue}");
        //   } else {
        //     setState(() {
        //       adminCommissionValue =
        //           (double.parse(adminCommissionValue1.toString()) -
        //                   double.parse(widget.autoapplydiscount.toString()))
        //               .abs()
        //               .toStringAsFixed(2);
        //
        //       print(
        //           "else vendor commssion shu ave che  ${adminCommissionValue}");
        //     });
        //   }
        // }
      }
    });
  }

  // void getSaturdayTimestamp() {
  //   DateTime now = DateTime.now();
  //
  //   // Calculate days to next Saturday
  //   int daysToSaturday = DateTime.saturday - now.weekday;
  //
  //   // If today is Saturday, move to next week's Saturday
  //   if (daysToSaturday < 0) {
  //     daysToSaturday += 7;
  //   }
  //
  //   // Calculate the next Saturday
  //   DateTime nextSaturday = now.add(Duration(days: daysToSaturday));
  //
  //   // Get timestamp at 6 AM of next Saturday
  //   DateTime saturdayStart =
  //   DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 6);
  //
  //   int timestamp =
  //   (saturdayStart.millisecondsSinceEpoch ~/ 1000); // Convert to seconds
  //
  //   // Validate timestamp range
  //   if (timestamp < 946684800 || timestamp > 4765046400) {
  //     print('Error: Timestamp out of range: $timestamp');
  //     return;
  //   }
  //
  //   // Set the state with the calculated timestamp
  //   setState(() {
  //     saturdayTimestamp = timestamp;
  //     print('Timestamp of Saturday (6 AM) is : $saturdayTimestamp');
  //
  //     getRazorPayDemo();
  //   });
  // }
  void getSaturdayTimestamp() {
    DateTime now = DateTime.now();

    // Calculate days to next Saturday
    int daysToSaturday = DateTime.saturday - now.weekday;

    // If today is Saturday, move to next week's Saturday if after 6 AM
    if (daysToSaturday < 0 || (daysToSaturday == 0 && now.hour >= 6)) {
      daysToSaturday += 7;
    }

    // Calculate the next Saturday
    DateTime nextSaturday = now.add(Duration(days: daysToSaturday));

    // Get timestamp at 6 AM of next Saturday
    DateTime saturdayStart = DateTime(
      nextSaturday.year,
      nextSaturday.month,
      nextSaturday.day,
      6,
    );

    int timestamp =
        saturdayStart.millisecondsSinceEpoch ~/ 1000; // Convert to seconds

    // Validate timestamp range
    if (timestamp < 946684800 || timestamp > 4765046400) {
      print('Error: Timestamp out of range: $timestamp');
      return;
    }

    // Set the state with the calculated timestamp
    setState(() {
      saturdayTimestamp = timestamp;
      print('Timestamp of Saturday (6 AM) is: $saturdayTimestamp');

      // Optionally call other functions
      getRazorPayDemo();
    });
  }

  // void getSaturdayTimestamp() {
  //   DateTime now = DateTime.now();
  //
  //   // Calculate days to next Saturday
  //   int daysToSaturday = DateTime.saturday - now.weekday;
  //
  //   // If today is Saturday, move to next week's Saturday
  //   if (daysToSaturday < 0) {
  //     daysToSaturday += 7;
  //   }
  //
  //   // Calculate the next Saturday
  //   DateTime nextSaturday = now.add(Duration(days: daysToSaturday));
  //
  //   // Get timestamp at 6 AM of next Saturday
  //   DateTime saturdayStart =
  //       DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 6);
  //
  //   // Set the state with the calculated timestamp
  //   setState(() {
  //     saturdayTimestamp = saturdayStart.millisecondsSinceEpoch;
  //     print('Time Stamp of Saturday (6 AM) is : $saturdayTimestamp');
  //     loginapp();
  //   });
  // }

  OrderCretedRazorpayModal? ordercretedrazorpaymodal;

  loginapp(String? razorpayKey, String? razorpaySecret) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(("please wait"))));

    String keyId = razorpayKey.toString();
    String secret = razorpaySecret.toString();
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$keyId:$secret'));
    print("Razorpay account id ave che ${widget.vendoraccountnumber}");
    print("ven dor nu accoun name ave che ${widget.razorpayaccount}");
    final Map<String, dynamic> data = {
      "amount": (widget.total * 100).toInt(),
      "payment_capture": 1,
      "currency": "INR",
      "transfers": [
        {
          "account": widget.razorpayaccount,
          //Please replace with appropriate ID.
          "amount": (widget.toatvendoramount * 100).toInt(),
          "currency": "INR",
          "notes": {
            "branch": "Acme Corp Bangalore South",
            "name": widget.vendoraccountnumber,
          },
          "linked_account_notes": ["branch"],
          "on_hold": 1,
          "on_hold_until": saturdayTimestamp ?? 0,
        },
      ],
    };
    // Convert 'billing' to a string

    print("datadatadatadatadata${data}");
    final apiUrl = "https://api.razorpay.com/v1/orders";

    final headers = {
      'Content-Type': 'application/json',
      'authorization': basicAuth,
    };
    // Construct the request body
    final requestBody = json.encode(data);

    // Make the API call using http.post
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: requestBody,
    );

    print("requestBody${requestBody}");
    print("responsefkglkfdlgkfdg${response}");

    // Handle the response

    if (response.statusCode == 200) {
      ordercretedrazorpaymodal = OrderCretedRazorpayModal.fromJson(
        json.decode(response.body),
      );
      print("loginapp api sucessfuuly ");
      print(
        "ordercretedrazorpaymodal?.id${ordercretedrazorpaymodal?.id ?? ""}",
      );
      setState(() {
        proceed = false;
      });
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Payment data to be stored
      Map<String, dynamic> paymentData = {
        "customerid": MyAppState.currentUser?.userID ?? "",
        "orderidrazorpay": ordercretedrazorpaymodal?.id ?? "",
        "amount": widget.total * 100,
        "payment_capture": 1,
        "currency": "INR",
        "transfers": [
          {
            "account": widget.razorpayaccount,
            "amount": widget.toatvendoramount * 100,
            "currency": "INR",
            "notes": {
              "branch": "Acme Corp Bangalore South",
              "name": widget.vendoraccountnumber,
            },
            "linked_account_notes": ["branch"],
            "on_hold": false,
            "on_hold_until": null,
          },
        ],
      };

      // Adding the data to a Firestore collection (e.g., 'payments')
      await firestore
          .collection('razorpayLinkedAccountsPayments')
          .add(paymentData);
    } else {
      setState(() {
        proceed = false;
      });
      // errorresponse = ErrorResponse.fromJson(json.decode(response.body));
      print("sdsdfsdfsdfsdfsdf");
      print("sgssfsd${response.body}");
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text((errorresponse?.error?.description ?? "")),
      // ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      key: _scaffoldKey,
      appBar: AppBar(),
      body:
          chakchak
              ? Center(
                child: CircularProgressIndicator(color: Colors.deepOrange),
              )
              : ListView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                children: [
                  Visibility(
                    visible: UserPreference.getWalletData() ?? false,
                    child: Column(
                      children: [
                        Divider(),
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: userQuery,
                          builder: (
                            context,
                            AsyncSnapshot<
                              DocumentSnapshot<Map<String, dynamic>>
                            >
                            asyncSnapshot,
                          ) {
                            if (asyncSnapshot.hasError) {
                              return Text(
                                "error".tr(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              );
                            }
                            if (asyncSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 0.8,
                                    color: Colors.white,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              );
                            }
                            if (asyncSnapshot.data == null) {
                              return Container();
                            }
                            User userData = User.fromJson(
                              asyncSnapshot.data!.data()!,
                            );

                            walletBalanceError =
                                double.parse(userData.walletAmount.toString()) <
                                        double.parse(widget.total.toString())
                                    ? true
                                    : false;
                            return Column(
                              children: [
                                CheckboxListTile(
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (!walletBalanceError) {
                                        wallet = true;
                                      } else {
                                        wallet = false;
                                      }
                                      payStack = false;
                                      mercadoPago = false;
                                      flutterWave = false;
                                      razorPay = false;
                                      codPay = false;
                                      payTm = false;
                                      pay = false;
                                      payFast = false;
                                      paypal = false;
                                      stripe = false;
                                      selectedCardID = '';
                                      paymentOption =
                                          "Pay Online Via Wallet".tr();
                                    });
                                  },
                                  value: wallet,
                                  contentPadding: EdgeInsets.all(0),
                                  secondary: FaIcon(FontAwesomeIcons.wallet),
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Wallet'.tr()),
                                      Column(
                                        children: [
                                          Text(
                                            amountShow(
                                              amount:
                                                  userData.walletAmount
                                                      .toString(),
                                            ),
                                            style: TextStyle(
                                              color:
                                                  walletBalanceError
                                                      ? Colors.red
                                                      : Colors.green,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Visibility(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 0.0,
                                        ),
                                        child:
                                            walletBalanceError
                                                ? Text(
                                                  "Your wallet doesn't have sufficient balance"
                                                      .tr(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.red,
                                                  ),
                                                )
                                                : Text(
                                                  'Sufficient Balance'.tr(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  widget.codWallet == false
                      ? Container()
                      : Visibility(
                        visible:
                            widget.wallamountvendor >= merchantamountminimum,
                        child: Column(
                          children: [
                            FutureBuilder<CodModel?>(
                              future: futurecod,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  return Center(
                                    child: CircularProgressIndicator.adaptive(
                                      valueColor: AlwaysStoppedAnimation(
                                        Color(COLOR_PRIMARY),
                                      ),
                                    ),
                                  );
                                if (snapshot.hasData) {
                                  return snapshot.data!.cod == true
                                      ? CheckboxListTile(
                                        onChanged: (bool? value) {
                                          setState(() {
                                            mercadoPago = false;
                                            payStack = false;
                                            flutterWave = false;
                                            razorPay = false;
                                            wallet = false;
                                            codPay =
                                                true; //codPay ? false : true;
                                            selectedCardID = '';
                                            payTm = false;
                                            payFast = false;
                                            pay = false;
                                            paypal = false;
                                            stripe = false;
                                            paymentOption =
                                                'Cash on Delivery'.tr();
                                          });
                                        },
                                        value: codPay,
                                        contentPadding: EdgeInsets.all(0),
                                        secondary: Image.asset(
                                          'assets/images/money.png',
                                          width: 25,
                                          height: 25,
                                        ),
                                        title: Text('Cash on Delivery'.tr()),
                                      )
                                      : Center();
                                }
                                return Center();
                              },
                            ),
                          ],
                        ),
                      ),
                  Visibility(
                    visible: razorPayData?.isEnabled ?? true,
                    child: Column(
                      children: [
                        Divider(),
                        CheckboxListTile(
                          onChanged: (bool? value) {
                            setState(() {
                              mercadoPago = false;
                              payStack = false;
                              flutterWave = false;
                              wallet = false;
                              razorPay = true; //razorPay ? false : true;
                              codPay = false;
                              payTm = false;
                              pay = false;
                              paypal = false;
                              payFast = false;
                              stripe = false;
                              selectedCardID = '';
                              paymentOption =
                                  "Pay Online Via".tr() + "RazorPay";
                            });
                          },
                          value: razorPay,
                          contentPadding: EdgeInsets.all(0),
                          secondary: Image.asset(
                            'assets/images/secure.png',
                            width: 25,
                            height: 25,
                          ),
                          title: Text('Online Payment'.tr()),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible:
                        (stripeData == null) ? false : stripeData!.isEnabled,
                    child: Column(
                      children: [
                        Divider(),
                        CheckboxListTile(
                          onChanged: (bool? value) {
                            setState(() {
                              mercadoPago = false;
                              payStack = false;
                              flutterWave = false;
                              stripe = true;
                              wallet = false;
                              razorPay = false; //razorPay ? false : true;
                              codPay = false;
                              payTm = false;
                              payFast = false;
                              pay = false;
                              paypal = false;
                              selectedCardID = '';
                              paymentOption = "Pay Online Via".tr() + "Stripe";
                            });
                          },
                          value: stripe,
                          contentPadding: EdgeInsets.all(0),
                          secondary: FaIcon(FontAwesomeIcons.stripe),
                          title: Text('Stripe'.tr()),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible:
                        (paytmSettingData == null)
                            ? false
                            : paytmSettingData!.isEnabled,
                    child: Column(
                      children: [
                        Divider(),
                        CheckboxListTile(
                          onChanged: (bool? value) {
                            setState(() {
                              mercadoPago = false;
                              payStack = false;
                              flutterWave = false;
                              razorPay = false;
                              wallet = false; //razorPay ? false : true;
                              codPay = false;
                              payTm = true;
                              pay = false;
                              payFast = false;
                              paypal = false;
                              stripe = false;
                              selectedCardID = '';
                              paymentOption = "Pay Online Via".tr() + "PayTm";
                            });
                          },
                          value: payTm,
                          contentPadding: EdgeInsets.all(0),
                          secondary: FaIcon(FontAwesomeIcons.alipay),
                          title: Text('PayTm'.tr()),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible:
                        (paypalSettingData == null)
                            ? false
                            : paypalSettingData!.isEnabled,
                    child: Column(
                      children: [
                        Divider(),
                        CheckboxListTile(
                          onChanged: (bool? value) {
                            setState(() {
                              mercadoPago = false;
                              paypal = true;
                              payStack = false;
                              flutterWave = false;
                              wallet = false;
                              razorPay = false;
                              codPay = false;
                              payTm = false;
                              payFast = false;
                              pay = false;
                              stripe = false;
                              selectedCardID = '';
                              paymentOption = "Pay Online Via".tr() + "PayPal";
                            });
                          },
                          value: paypal,
                          contentPadding: EdgeInsets.all(0),
                          secondary: FaIcon(FontAwesomeIcons.paypal),
                          title: Text(' Paypal'.tr()),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: false,
                    child: Column(
                      children: [
                        Divider(),
                        CheckboxListTile(
                          onChanged: (bool? value) {
                            setState(() {
                              mercadoPago = false;
                              payStack = false;
                              flutterWave = false;
                              razorPay = false; //razorPay ? false : true;
                              codPay = false;
                              payTm = false;
                              wallet = false;
                              payFast = false;
                              pay = true;
                              paypal = false;
                              stripe = false;
                              selectedCardID = '';
                              paymentOption = "Pay Online Via".tr() + "Pay";
                            });
                          },
                          value: pay,
                          contentPadding: EdgeInsets.all(0),
                          secondary: FaIcon(FontAwesomeIcons.googlePay),
                          title: Text(' Pay'.tr()),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible:
                        (payFastSettingData == null)
                            ? false
                            : payFastSettingData!.isEnable,
                    child: Column(
                      children: [
                        Divider(),
                        CheckboxListTile(
                          onChanged: (bool? value) {
                            setState(() {
                              mercadoPago = false;
                              payFast = true;
                              paypal = false;
                              wallet = false;
                              razorPay = false;
                              payStack = false;
                              codPay = false;
                              payTm = false;
                              pay = false;
                              flutterWave = false;
                              stripe = false;
                              selectedCardID = '';
                              paymentOption = "Pay Online Via".tr() + "PayFast";
                            });
                          },
                          value: payFast,
                          contentPadding: EdgeInsets.all(0),
                          secondary: Image.asset(
                            'assets/images/payfastmini.png',
                            width: 25,
                            height: 25,
                          ),
                          title: Text(' PayFast'.tr()),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible:
                        (payStackSettingData == null)
                            ? false
                            : payStackSettingData?.isEnabled ?? false,
                    child: Column(
                      children: [
                        Divider(),
                        CheckboxListTile(
                          onChanged: (bool? value) {
                            setState(() {
                              mercadoPago = false;
                              payStack = true;
                              paypal = false;
                              flutterWave = false;
                              wallet = false;
                              razorPay = false;
                              codPay = false;
                              payFast = false;
                              payTm = false;
                              pay = false;
                              stripe = false;
                              selectedCardID = '';
                              paymentOption =
                                  "Pay Online Via".tr() + "PayStack";
                            });
                          },
                          value: payStack,
                          contentPadding: EdgeInsets.all(0),
                          secondary: Image.asset(
                            'assets/images/paystackmini.png',
                            width: 25,
                            height: 25,
                          ),
                          title: Text(' PayStack'.tr()),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible:
                        (flutterWaveSettingData == null)
                            ? false
                            : flutterWaveSettingData!.isEnable,
                    child: Column(
                      children: [
                        Divider(),
                        CheckboxListTile(
                          onChanged: (bool? value) {
                            setState(() {
                              mercadoPago = false;
                              payStack = false;
                              flutterWave = true;
                              razorPay = false; //razorPay ? false : true;
                              codPay = false;
                              payTm = false;
                              wallet = false;
                              pay = false;
                              payFast = false;
                              paypal = false;
                              stripe = false;
                              selectedCardID = '';
                              paymentOption =
                                  "Pay Online Via".tr() + "FlutterWave";
                            });
                          },
                          value: flutterWave,
                          contentPadding: EdgeInsets.all(0),
                          secondary: FaIcon(FontAwesomeIcons.moneyBillWave),
                          title: Text(' FlutterWave'.tr()),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible:
                        (mercadoPagoSettingData == null)
                            ? false
                            : mercadoPagoSettingData!.isEnabled,
                    child: Column(
                      children: [
                        Divider(),
                        CheckboxListTile(
                          onChanged: (bool? value) {
                            setState(() {
                              mercadoPago = true;
                              payFast = false;
                              paypal = false;
                              wallet = false;
                              razorPay = false;
                              payStack = false;
                              codPay = false;
                              payTm = false;
                              pay = false;
                              flutterWave = false;
                              stripe = false;
                              selectedCardID = '';
                              paymentOption =
                                  "Pay Online Via".tr() + "Mercado Pago";
                            });
                          },
                          value: mercadoPago,
                          contentPadding: EdgeInsets.all(0),
                          secondary: Image.asset(
                            'assets/images/payfastmini.png',
                            width: 25,
                            height: 25,
                          ),
                          title: Text(' Mercado Pago'.tr()),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  SizedBox(height: 24),
                  proceed
                      ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Color(COLOR_PRIMARY),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                      : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Color(COLOR_PRIMARY),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          await FireStoreUtils.createPaymentId();

                          if (razorPay) {
                            paymentType = 'razorpay';
                            showLoadingAlert();
                            openCheckout(
                              amount: widget.total,
                              orderId: ordercretedrazorpaymodal?.id,
                            );
                            // RazorPayController()
                            //     .createOrderRazorPay(amount: widget.total.toInt())
                            //     .then((value) {
                            //   if (value == null) {
                            //     Navigator.pop(context);
                            //     showAlert(_scaffoldKey.currentContext!,
                            //         response:
                            //             "Something went wrong, please contact admin.".tr(),
                            //         colors: Colors.red);
                            //   } else {
                            //     CreateRazorPayOrderModel result = value;
                            //     openCheckout(
                            //       amount:2 * 100,
                            //       orderId:ordercretedrazorpaymodal?.id,
                            //     );
                            //   }
                            // });
                          } else if (payFast) {
                            paymentType = 'payfast';
                            showLoadingAlert();
                            PayStackURLGen.getPayHTML(
                              payFastSettingData: payFastSettingData!,
                              amount: widget.total.toString(),
                            ).then((value) async {
                              bool isDone = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => PayFastScreen(
                                        htmlData: value,
                                        payFastSettingData: payFastSettingData!,
                                      ),
                                ),
                              );

                              if (isDone) {
                                if (widget.takeAway!) {
                                  placeOrder(_scaffoldKey.currentContext!);
                                } else {
                                  toCheckOutScreen(true, context);
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Payment Successful!!".tr() + "\n",
                                    ),
                                    backgroundColor: Colors.green.shade400,
                                    duration: Duration(seconds: 6),
                                  ),
                                );
                              } else {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Payment Unsuccessful!!".tr() + "\n",
                                    ),
                                    backgroundColor: Colors.red.shade400,
                                    duration: Duration(seconds: 6),
                                  ),
                                );
                              }
                            });
                          } else if (payTm) {
                            paymentType = 'paytm';
                            showLoadingAlert();
                            getPaytmCheckSum(context, amount: widget.total);
                          } else if (stripe) {
                            paymentType = 'stripe';
                            showLoadingAlert();
                            stripeMakePayment(amount: widget.total.toString());
                          } else if (pay) {
                            // Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //         builder: (context) =>
                            //             FlutterWavePayService() //UniPaymentService()
                            //         ));
                          } else if (payStack) {
                            paymentType = 'paystack';
                            showLoadingAlert();
                            payStackPayment(context);
                          } else if (mercadoPago) {
                            mercadoPagoMakePayment();
                          } else if (flutterWave) {
                            paymentType = 'flutterwave';
                            _flutterWaveInitiatePayment(context);
                          } else if (paypal) {
                            paymentType = 'paypal';
                            showLoadingAlert();
                            // _makePaypalPayment(amount: widget.total.toString());
                          } else if (wallet && walletBalanceError == false) {
                            paymentType = 'wallet';
                            showLoadingAlert();
                            FireStoreUtils.createPaymentId().then((value) {
                              final paymentID = value;
                              String orderId = UserPreference.getOrderId();
                              FireStoreUtils.topUpWalletAmount(
                                paymentMethod: "Wallet",
                                isTopup: false,
                                orderId: orderId,
                                amount: widget.total,
                                id: paymentID,
                              ).then((value) {
                                FireStoreUtils.updateWalletAmount(
                                      amount: -widget.total,
                                    )
                                    .then((value) {
                                      if (widget.takeAway!) {
                                        placeOrder(
                                          _scaffoldKey.currentContext!,
                                          oid: orderId,
                                        );
                                      } else {
                                        Navigator.pop(context);
                                        toCheckOutScreen(true, context);
                                      }
                                    })
                                    .whenComplete(() {
                                      showAlert(
                                        _scaffoldKey.currentContext!,
                                        response:
                                            "Payment Successful Via".tr() +
                                            " "
                                                    "Wallet"
                                                .tr(),
                                        colors: Colors.green,
                                      );
                                    });
                              });
                            });
                          } else if (codPay) {
                            paymentType = 'cod';
                            if (widget.takeAway!) {
                              placeOrder(_scaffoldKey.currentContext!);
                            } else {
                              toCheckOutScreen(false, context);
                            }
                          } else {
                            final SnackBar snackBar = SnackBar(
                              content: Text(
                                "Select Payment Method".tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Color(COLOR_PRIMARY),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
                          }
                        },
                        child: Text(
                          'PROCEED'.tr(),
                          style: TextStyle(
                            color:
                                isDarkMode(context)
                                    ? Colors.black
                                    : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Color(COLOR_PRIMARY),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      pushAndRemoveUntil(
                        context,
                        ContainerScreen(
                          user: MyAppState.currentUser!,
                          drawerSelection: DrawerSelection.Cart,
                          currentWidget: CartScreen(),
                          appBarTitle: 'Your Cart'.tr(),
                        ),
                        false,
                      );
                    },
                    child: Text(
                      'Back To Cart'.tr(),
                      style: TextStyle(
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  String? razorpayKey;
  String? razorpaySecret;

  getRazorPayDemo() async {
    RazorPayModel razorPayModel;
    FirebaseFirestore.instance
        .collection(Setting)
        .doc("razorpaySettings")
        .get()
        .then((user) {
          debugPrint(user.data().toString());
          try {
            razorPayModel = RazorPayModel.fromJson(user.data() ?? {});
            UserPreference.setRazorPayData(razorPayModel);
            RazorPayModel fhg = UserPreference.getRazorPayData();
            debugPrint(fhg.razorpayKey);
            //
            // RazorPayController().updateRazorPayData(razorPayData: userModel);

            setState(() {
              // isRazorPayEnabled = userModel.isEnabled;
              // isRazorPaySandboxEnabled = userModel.isSandboxEnabled;
              razorpayKey = razorPayModel.razorpayKey;
              razorpaySecret = razorPayModel.razorpaySecret;
            });
            loginapp(razorpayKey, razorpaySecret);
            print("razorpayKeyrazorpayKeyrazorpayKey${razorpayKey}");
            print("razorpayKeyrazorpayKeyrazorpayKey${razorpaySecret}");
          } catch (e) {
            debugPrint(
              'FireStoreUtils.getUserByID failed to parse user object ${user.id}',
            );
          }
        });

    //yield* razorPayStreamController.stream;
  }

  bool payStack = false;
  bool flutterWave = false;
  bool wallet = false;
  bool razorPay = false;
  bool payFast = false;
  bool mercadoPago = false;
  bool codPay = false;
  bool payTm = false;
  bool pay = false;
  bool stripe = false;
  bool paypal = false;

  ///RazorPay payment function
  // void openCheckout({required amount, required orderId}) async {
  //   var options = {
  //     'key': razorpayKey,
  //     'amount': amount * 100,
  //     'name': 'Grubb',
  //     'order_id': orderId,
  //     "currency": currencyModel?.code,
  //     'description': 'Payment for Order $orderId',
  //     'retry': {'enabled': true, 'max_count': 1},
  //     'send_sms_hash': true,
  //     'one_click_checkout': true,
  //     'force_cod': true,
  //     'prefill': {
  //       'contact': MyAppState.currentUser!.phoneNumber,
  //       'email': MyAppState.currentUser!.email,
  //     },
  //     'external': {
  //       'wallets': ['paytm'],
  //     },
  //   };
  //
  //   try {
  //     _razorPay.open(options);
  //   } catch (e) {
  //     debugPrint('Error: $e');
  //   }
  // }
  void openCheckout({required var amount, required orderId}) async {
    print("amount shu ave che $amount");

    int finalAmount = (amount * 100).toInt();
    print("final amount shu ave che $finalAmount");

    var options = {
      'key': razorPayData!.razorpayKey,
      'amount': finalAmount, // Must be int in paise
      'name': 'Grubb',
      'order_id': orderId,
      "currency": currencyModel?.code,
      'description': 'Payment for Order $orderId',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': MyAppState.currentUser!.phoneNumber,
        'email': MyAppState.currentUser!.email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorPay.open(options);
    } catch (e) {
      debugPrint('error: $e');
    }
  }
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("response.paymentId!${response.paymentId!}");
    print("response.paymentId!${widget.total}");
    capturePayment(response.paymentId!, widget.total);
    Navigator.pop(_scaffoldKey.currentContext!);
    if (widget.takeAway!) {
      placeOrder(_scaffoldKey.currentContext!);
    } else {
      toCheckOutScreen(true, _scaffoldKey.currentContext!);
    }

    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text("Payment Successful!!".tr()),
        backgroundColor: Colors.green.shade400,
        duration: Duration(seconds: 6),
      ),
    );
  }

  Future<void> capturePayment(String paymentId, dynamic amount) async {
    int finalAmount =
        (double.parse(amount.toString()) * 100)
            .toInt(); // Ensuring valid integer value

    var url = Uri.parse(
      'https://api.razorpay.com/v1/payments/$paymentId/capture',
    );
    print("Capture URL: $url");
    String keyId = razorpayKey.toString();
    String secret = razorpaySecret.toString();

    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$keyId:$secret')),
        'Content-Type': 'application/json',
      },
      body: '{"amount":$finalAmount, "currency":"INR"}',
    );

    print("Final Amount Sent: $finalAmount");

    if (response.statusCode == 200) {
      debugPrint('Payment Captured Successfully');
    } else {
      debugPrint('Capture Failed: ${response.body}');
    }
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    Navigator.pop(_scaffoldKey.currentContext!);
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(
          "Payment Processing!! via".tr() + "\n" + response.walletName!,
        ),
        backgroundColor: Colors.blue.shade400,
        duration: Duration(seconds: 8),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Navigator.pop(_scaffoldKey.currentContext!);
    RazorPayFailedModel lom = RazorPayFailedModel.fromJson(
      jsonDecode(response.message!.toString()),
    );
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text("Payment Failed!!".tr() + "\n" + lom.error.description),
        backgroundColor: Colors.red.shade400,
        duration: Duration(seconds: 8),
      ),
    );
  }

  ///Stripe payment function
  Map<String, dynamic>? paymentIntentData;

  Future<void> stripeMakePayment({required String amount}) async {
    try {
      paymentIntentData = await createStripeIntent(amount);
      if (paymentIntentData!.containsKey("error")) {
        Navigator.pop(context);
        showAlert(
          _scaffoldKey.currentContext!,
          response: "Something went wrong, please contact admin.".tr(),
          colors: Colors.red,
        );
      } else {
        await stripe1.Stripe.instance
            .initPaymentSheet(
              paymentSheetParameters: stripe1.SetupPaymentSheetParameters(
                paymentIntentClientSecret: paymentIntentData!['client_secret'],
                applePay: const stripe1.PaymentSheetApplePay(
                  merchantCountryCode: 'US',
                ),
                allowsDelayedPaymentMethods: false,
                googlePay: stripe1.PaymentSheetGooglePay(
                  merchantCountryCode: 'US',
                  testEnv: true,
                  currencyCode: currencyModel!.code,
                ),
                style: ThemeMode.system,
                appearance: stripe1.PaymentSheetAppearance(
                  colors: stripe1.PaymentSheetAppearanceColors(
                    primary: Color(COLOR_PRIMARY),
                  ),
                ),
                merchantDisplayName: 'Grubb',
              ),
            )
            .then((value) {});
        setState(() {});
        displayStripePaymentSheet(amount: amount);
      }
    } catch (e, s) {
      print('exception:$e$s');
    }
  }

  displayStripePaymentSheet({required amount}) async {
    try {
      await stripe1.Stripe.instance
          .presentPaymentSheet()
          .then((value) {
            if (widget.takeAway!) {
              placeOrder(_scaffoldKey.currentContext!);
            } else {
              toCheckOutScreen(true, context);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Payment Successful!!".tr()),
                duration: Duration(seconds: 8),
                backgroundColor: Colors.green,
              ),
            );
            paymentIntentData = null;
          })
          .onError((error, stackTrace) {
            Navigator.pop(context);
            var lo1 = jsonEncode(error);
            var lo2 = jsonDecode(lo1);
            StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
            showDialog(
              context: context,
              builder:
                  (_) => AlertDialog(content: Text("${lom.error.message}")),
            );
          });
    } on stripe1.StripeException catch (e) {
      Navigator.pop(context);
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(content: Text("${lom.error.message}")),
      );
    } catch (e) {
      print('$e');
      Navigator.pop(context);
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text("$e"),
          duration: Duration(seconds: 8),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  createStripeIntent(String amount) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currencyModel!.code,
        'payment_method_types[0]': 'card',
        // 'payment_method_types[1]': 'ideal',
        "description": "${MyAppState.currentUser?.userID} Wallet Topup",
        "shipping[name]":
            "${MyAppState.currentUser?.firstName} ${MyAppState.currentUser?.lastName}",
        "shipping[address][line1]": "510 Townsend St",
        "shipping[address][postal_code]": "98140",
        "shipping[address][city]": "San Francisco",
        "shipping[address][state]": "CA",
        "shipping[address][country]": "US",
      };
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        body: body,
        headers: {
          'Authorization': 'Bearer ${stripeData?.stripeSecret}',
          //$_paymentIntentClientSecret',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      return jsonDecode(response.body);
    } catch (err) {
      print('error charging user: ${err.toString()}');
    }
  }

  calculateAmount(String amount) {
    final a = ((double.parse(amount)) * 100).toInt();
    print(a);
    return a.toString();
  }

  ///PayPal payment function
  // _makePaypalPayment({required amount}) async {
  //   PayPalClientTokenGen.paypalClientToken(paypalSettingData: paypalSettingData!).then((value) async {
  //     final String tokenizationKey = paypalSettingData!.braintreeTokenizationKey;
  //
  //     var request = BraintreePayPalRequest(amount: amount, currencyCode: currencyModel!.code, billingAgreementDescription: "djsghxghf", displayName: 'Grubb company');
  //
  //     BraintreePaymentMethodNonce? resultData;
  //     try {
  //       resultData = await Braintree.requestPaypalNonce(tokenizationKey, request);
  //     } on Exception {
  //       print("Stripe error");
  //       showAlert(_scaffoldKey.currentContext!, response: "Something went wrong, please contact admin.".tr(), colors: Colors.red);
  //     }
  //     print(resultData?.nonce);
  //     print(resultData?.paypalPayerId);
  //     if (resultData?.nonce != null) {
  //       PayPalClientTokenGen.paypalSettleAmount(
  //         paypalSettingData: paypalSettingData!,
  //         nonceFromTheClient: resultData?.nonce,
  //         amount: amount,
  //         deviceDataFromTheClient: resultData?.typeLabel,
  //       ).then((value) {
  //         print('payment done!!');
  //         if (value['success'] == "true" || value['success'] == true) {
  //           if (value['data']['success'] == "true" || value['data']['success'] == true) {
  //             payPalSettel.PayPalClientSettleModel settleResult = payPalSettel.PayPalClientSettleModel.fromJson(value);
  //
  //             if (widget.takeAway!) {
  //               placeOrder(_scaffoldKey.currentContext!);
  //             } else {
  //               toCheckOutScreen(true, _scaffoldKey.currentContext!);
  //             }
  //
  //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //               content: Text(
  //                 "Status : ${settleResult.data.transaction.status}\n"
  //                 "Transaction id : ${settleResult.data.transaction.id}\n"
  //                 "Amount : ${settleResult.data.transaction.amount}",
  //               ),
  //               duration: Duration(seconds: 8),
  //               backgroundColor: Colors.green,
  //             ));
  //           } else {
  //             payPalCurrModel.PayPalCurrencyCodeErrorModel settleResult = payPalCurrModel.PayPalCurrencyCodeErrorModel.fromJson(value);
  //             Navigator.pop(_scaffoldKey.currentContext!);
  //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //               content: Text("Status :".tr() + " ${settleResult.data.message}"),
  //               duration: Duration(seconds: 8),
  //               backgroundColor: Colors.red,
  //             ));
  //           }
  //         } else {
  //           PayPalErrorSettleModel settleResult = PayPalErrorSettleModel.fromJson(value);
  //           Navigator.pop(_scaffoldKey.currentContext!);
  //           ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
  //             content: Text("Status :".tr() + " ${settleResult.data.message}"),
  //             duration: Duration(seconds: 8),
  //             backgroundColor: Colors.red,
  //           ));
  //         }
  //       });
  //     } else {
  //       Navigator.pop(_scaffoldKey.currentContext!);
  //       ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
  //         content: Text("Status :".tr() + "Payment Unsuccessful!!".tr()),
  //         duration: Duration(seconds: 8),
  //         backgroundColor: Colors.red,
  //       ));
  //     }
  //   });
  // }

  showLoadingAlert() {
    return showDialog<void>(
      context: _scaffoldKey.currentContext!,
      useRootNavigator: true,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [CircularProgressIndicator(), Text('Please wait!!'.tr())],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                SizedBox(height: 15),
                Text(
                  'Please wait!! while completing Transaction'.tr(),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

  ///Paytm payment function
  getPaytmCheckSum(context, {required double amount}) async {
    final String orderId = await UserPreference.getPaymentId();
    String getChecksum = "${GlobalURL}payments/getpaytmchecksum";

    final response = await http.post(
      Uri.parse(getChecksum),
      headers: {},
      body: {
        "mid": paytmSettingData?.paytmMID,
        "order_id": orderId,
        "key_secret": paytmSettingData?.paytmMerchantKey,
      },
    );

    final data = jsonDecode(response.body);
    await verifyCheckSum(
      checkSum: data["code"],
      amount: amount,
      orderId: orderId,
    ).then((value) {
      initiatePayment(amount: amount, orderId: orderId).then((value) {
        GetPaymentTxtTokenModel result = value;
        String callback = "";
        if (paytmSettingData!.isSandboxEnabled) {
          callback =
              callback +
              "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
        } else {
          callback =
              callback +
              "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
        }

        _startTransaction(
          context,
          txnTokenBy: result.body.txnToken,
          orderId: orderId,
          amount: amount,
          callBackURL: callback,
        );
      });
    });
  }

  Future<void> _startTransaction(
    context, {
    required String txnTokenBy,
    required orderId,
    required double amount,
    required callBackURL,
  }) async {
    try {
      // var response = AllInOneSdk.startTransaction(
      //   paytmSettingData!.paytmMID,
      //   orderId,
      //   amount.toString(),
      //   txnTokenBy,
      //   callbackUrl,
      //   //"https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId",
      //   isStaging,
      //   true,
      //   enableAssist,
      // );
      //
      // response
      //     .then((value) {
      //       if (value!["RESPMSG"] == "Txn Success") {
      //         print("txt done!!");
      //         if (widget.takeAway!) {
      //           placeOrder(_scaffoldKey.currentContext!);
      //         } else {
      //           toCheckOutScreen(true, context);
      //         }
      //         showAlert(
      //           context,
      //           response:
      //               "Payment Successful!!".tr() + "\n ${value['RESPMSG']}",
      //           colors: Colors.green,
      //         );
      //       }
      //     })
      //     .catchError((onError) {
      //       if (onError is PlatformException) {
      //         print("======>>1");
      //         Navigator.pop(_scaffoldKey.currentContext!);
      //
      //         print("Error124 : $onError");
      //         result =
      //             onError.message.toString() +
      //             " \n  " +
      //             onError.code.toString();
      //         showAlert(
      //           _scaffoldKey.currentContext!,
      //           response: onError.message.toString(),
      //           colors: Colors.red,
      //         );
      //       } else {
      //         print("======>>2");
      //
      //         result = onError.toString();
      //         Navigator.pop(_scaffoldKey.currentContext!);
      //         showAlert(
      //           _scaffoldKey.currentContext!,
      //           response: result,
      //           colors: Colors.red,
      //         );
      //       }
      //     });
    } catch (err) {
      print("======>>3");
      result = err.toString();
      Navigator.pop(_scaffoldKey.currentContext!);
      showAlert(
        _scaffoldKey.currentContext!,
        response: result,
        colors: Colors.red,
      );
    }
  }

  Future verifyCheckSum({
    required String checkSum,
    required double amount,
    required orderId,
  }) async {
    String getChecksum = "${GlobalURL}payments/validatechecksum";
    final response = await http.post(
      Uri.parse(getChecksum),
      headers: {},
      body: {
        "mid": paytmSettingData?.paytmMID,
        "order_id": orderId,
        "key_secret": paytmSettingData?.paytmMerchantKey,
        "checksum_value": checkSum,
      },
    );
    final data = jsonDecode(response.body);
    print('here one');
    print(checkSum);
    print(data['status']);
    return data['status'];
  }

  Future<GetPaymentTxtTokenModel> initiatePayment({
    required double amount,
    required orderId,
  }) async {
    String initiateURL = "${GlobalURL}payments/initiatepaytmpayment";
    print('payment initiated now!@!');
    String callback = "";
    if (paytmSettingData!.isSandboxEnabled) {
      callback =
          callback +
          "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    } else {
      callback =
          callback +
          "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    }
    final response = await http.post(
      Uri.parse(initiateURL),
      headers: {},
      body: {
        "mid": paytmSettingData?.paytmMID,
        "order_id": orderId,
        "key_secret": paytmSettingData?.paytmMerchantKey.toString(),
        "amount": amount.toString(),
        "currency": currencyModel!.code,
        "callback_url": callback,
        "custId": MyAppState.currentUser!.userID,
        "issandbox": paytmSettingData!.isSandboxEnabled ? "1" : "2",
      },
    );
    print(response.body);
    final data = jsonDecode(response.body);
    print(data);
    if (data["body"]["txnToken"] == null ||
        data["body"]["txnToken"].toString().isEmpty) {
      Navigator.pop(_scaffoldKey.currentContext!);
      showAlert(
        _scaffoldKey.currentContext!,
        response: "something went wrong, please contact admin.".tr(),
        colors: Colors.red,
      );
    }
    return GetPaymentTxtTokenModel.fromJson(data);
  }

  ///PayStack Payment Method
  payStackPayment(BuildContext context) async {
    await PayStackURLGen.payStackURLGen(
      amount: (widget.total * 100).toString(),
      currency: currencyModel!.code,
      secretKey: payStackSettingData!.secretKey.toString(),
    ).then((value) async {
      if (value != null) {
        PayStackUrlModel _payStackModel = value;
        bool isDone = await Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => PayStackScreen(
                  secretKey: payStackSettingData!.secretKey.toString(),
                  callBackUrl: payStackSettingData!.callbackURL.toString(),
                  initialURl: _payStackModel.data.authorizationUrl,
                  amount: widget.total.toString(),
                  reference: _payStackModel.data.reference,
                ),
          ),
        );
        //Navigator.pop(_globalKey.currentContext!);

        if (isDone) {
          if (widget.takeAway!) {
            placeOrder(_scaffoldKey.currentContext!);
          } else {
            toCheckOutScreen(true, _scaffoldKey.currentContext!);
          }
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text("Payment Successful!!".tr() + "\n"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          Navigator.pop(_scaffoldKey.currentContext!);
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text("Payment Unsuccessful!!".tr() + "\n"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        Navigator.pop(_scaffoldKey.currentContext!);
        showAlert(
          _scaffoldKey.currentContext!,
          response: "something went wrong, please contact admin.".tr(),
          colors: Colors.red,
        );
      }
    });
  }

  ///MercadoPago Payment Method

  mercadoPagoMakePayment() {
    makePreference().then((result) async {
      if (result.isNotEmpty) {
        var preferenceId = result['response']['id'];
        print(result['response']['init_point']);

        final bool isDone = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MercadoPagoScreen(
                  initialURl: result['response']['init_point'],
                ),
          ),
        );
        print(isDone);
        print(result.toString());
        print(preferenceId);

        if (isDone) {
          if (widget.takeAway!) {
            placeOrder(_scaffoldKey.currentContext!);
          } else {
            toCheckOutScreen(true, _scaffoldKey.currentContext!);
          }
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text("Payment Successful!!".tr() + "\n"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          Navigator.pop(_scaffoldKey.currentContext!);
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text("Payment Unsuccessful!!".tr() + "\n"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        hideProgress();

        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text("Error while transaction!".tr() + "\n"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<Map<String, dynamic>> makePreference() async {
    final mp = MP.fromAccessToken(mercadoPagoSettingData!.accessToken);
    var pref = {
      "items": [
        {
          "title": "Wallet TopUp",
          "quantity": 1,
          "unit_price": double.parse(widget.total.toString().trim()),
        },
      ],
      "auto_return": "all",
      "back_urls": {
        "failure": "${GlobalURL}payment/failure",
        "pending": "${GlobalURL}payment/pending",
        "success": "${GlobalURL}payment/success",
      },
    };

    var result = await mp.createPreference(pref);
    return result;
  }

  ///FlutterWave Payment Method
  String? _ref;

  setRef() {
    Random numRef = Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      setState(() {
        _ref = "AndroidRef$year$refNumber";
      });
    } else if (Platform.isIOS) {
      setState(() {
        _ref = "IOSRef$year$refNumber";
      });
    }
  }

  _flutterWaveInitiatePayment(BuildContext context) async {
    // final style = FlutterwaveStyle(
    //   appBarText: "Grubb",
    //   buttonColor: Color(COLOR_PRIMARY),
    //   buttonTextStyle: TextStyle(
    //     color: Colors.white,
    //     fontSize: 20,
    //   ),
    //   appBarColor: Color(COLOR_PRIMARY),
    //   dialogCancelTextStyle: TextStyle(
    //     color: Colors.black,
    //     fontSize: 18,
    //   ),
    //   dialogContinueTextStyle: TextStyle(
    //     color: Color(COLOR_PRIMARY),
    //     fontSize: 18,
    //   ),
    //   mainTextStyle:
    //       TextStyle(color: Colors.black, fontSize: 19, letterSpacing: 2),
    //   dialogBackgroundColor: Colors.white,
    //   appBarTitleTextStyle: TextStyle(
    //     color: Colors.white,
    //     fontSize: 18,
    //   ),
    // );
    // final flutterwave = Flutterwave(
    //   amount: widget.total.toString().trim(),
    //   currency: currencyModel!.code,
    // style: style,
    //   customer: Customer(
    //       name: MyAppState.currentUser!.firstName,
    //       phoneNumber: MyAppState.currentUser!.phoneNumber.trim(),
    //       email: MyAppState.currentUser!.email.trim()),
    //   context: context,
    //   publicKey: flutterWaveSettingData!.publicKey.trim(),
    //   paymentOptions: "card, payattitude",
    //   customization: Customization(title: "Grubb"),
    //   txRef: _ref!,
    //   isTestMode: flutterWaveSettingData!.isSandbox,
    //   redirectUrl: '${GlobalURL}success',
    // );
    // final ChargeResponse response = await flutterwave.charge();
    // if (response.success!) {
    //   ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
    //     content: Text("Payment Successful!!".tr() + "\n"),
    //     backgroundColor: Colors.green,
    //   ));
    //   if (widget.takeAway!) {
    //     placeOrder(_scaffoldKey.currentContext!);
    //   } else {
    //     toCheckOutScreen(true, _scaffoldKey.currentContext!);
    //   }
    // } else {
    //   this.showLoading(message: response.status!);
    // }
    // print("${response.toJson()}");
  }

  Future<void> showLoading({
    required String message,
    Color txtColor = Colors.black,
  }) {
    return showDialog(
      context: this.context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            margin: EdgeInsets.fromLTRB(30, 20, 30, 20),
            width: double.infinity,
            height: 30,
            child: Text(message, style: TextStyle(color: txtColor)),
          ),
        );
      },
    );
  }

  placeOrder(BuildContext buildContext, {String? oid}) async {
    double pricenew = 0.0;
    FireStoreUtils fireStoreUtils = FireStoreUtils();
    List<CartProduct> tempProduc = [];
    List<CartProduct> admincommssionproducts = [];
    if (paymentType.isEmpty) {
      ShowDialogToDismiss(
        title: "Empty payment type".tr(),
        buttonText: "ok".tr(),
        content: "Select payment type".tr(),
      );
      return;
    }
    if (widget.auto_apply == true &&
        widget.cityaveche == true &&
        widget.isMyTime == true) {
      for (CartProduct cartProduct in widget.products) {
        pricenew =
            double.parse(cartProduct.price) * widget.autoapplydiscount / 100;
        double originalPrice = double.parse(cartProduct.price);
        // print("originalPriceoriginalPrice${originalPrice}");
        originalPrice = double.parse(cartProduct.price) - pricenew;
        // price અપડેટ કરી નવી instance બનાવો
        print("chak chak chak chak ${originalPrice}");
        CartProduct tempCart = CartProduct(
          id: cartProduct.id,
          category_id: cartProduct.category_id,
          name: cartProduct.name,
          photo: cartProduct.photo,
          price: originalPrice.toString(),
          // નવી કિંમત મૂકો
          discountPrice: cartProduct.discountPrice,
          item: cartProduct.item,
          groceryUnit: cartProduct.groceryUnit,
          groceryWeight: cartProduct.groceryWeight,
          vendorID: cartProduct.vendorID,
          quantity: cartProduct.quantity,
          extras_price: cartProduct.extras_price,
          extras: cartProduct.extras,
          variant_info: cartProduct.variant_info,
          packingcharges: cartProduct.packingcharges,
        );

        tempProduc.add(tempCart); // અપડેટ થયેલા tempCart ને લિસ્ટમાં એડ કરો
        print("Updated tempCart: $tempCart");
      }
    } else {
      for (CartProduct cartProduct in widget.products) {
        CartProduct tempCart = cartProduct;
        tempProduc.add(tempCart);
        print("tempCarttempCarttempCarttempCart${tempCart.price}");
      }
    }
    for (CartProduct cartProduct in widget.products) {
      CartProduct tempCart1 = cartProduct;
      admincommssionproducts.add(tempCart1);
      print("tempCarttempCarttempCarttempCart${tempCart1.price}");
    }
    //place order
    showProgress(buildContext, 'Placing Order...'.tr(), false);
    VendorModel vendorModel = await fireStoreUtils
        .getVendorByVendorID(widget.products.first.vendorID)
        .whenComplete(() => setPrefData());
    OrderModel orderModel = OrderModel(
      address: MyAppState.currentUser!.shippingAddress,
      author: MyAppState.currentUser,
      authorID: MyAppState.currentUser!.userID,
      createdAt: Timestamp.now(),
      products: tempProduc,
      admincommssionproducts: admincommssionproducts,
      status: ORDER_STATUS_PLACED,
      vendor: vendorModel,
      paymentMethod: paymentType,
      notes: widget.notes,
      freeDelivery: vendorModel.freeDelivery,
      taxModel: widget.taxModel,
      vendorID: widget.products.first.vendorID,
      discount: widget.discount,
      specialDiscount: widget.specialDiscountMap,
      couponCode: widget.couponCode,
      couponId: widget.couponId,
      customAdminCommission:
          // widget.isMyTime == true &&
          //         widget.cityaveche == true &&
          //         widget.auto_apply == true
          //     ? false
          //     :
          vendorModel.customAdminCommission,
      customAdminCommissionType: vendorModel.customAdminCommissionType,
      customAdminCommissionValue: vendorModel.customAdminCommissionValue,
      adminCommission:
          widget.groceryitem == "grocery"
              ? grocerycommissionfix
              : isEnableAdminCommission!
              ? adminCommissionValue
              : "0",
      admindiscountbyadmincommssiontype:
          isEnableAdminCommission! ? addminCommissionType : "",
      admindiscountbyadmincommssion:
          widget.groceryitem == "grocery"
              ? grocerycommissionfix1.toString()
              : adminCommissionValue1.toString(),
      adminCommissionType:
          // jumpnam == true
          //     ? "Fixed"
          //     :
          isEnableAdminCommission! ? addminCommissionType : "",
      takeAway: true,
      scheduleTime: widget.scheduleTime,
    );

    if (oid != null && oid.isNotEmpty) {
      orderModel.id = oid;
    }

    OrderModel placedOrder = await fireStoreUtils.placeOrderWithTakeAWay(
      orderModel,
    );
    print("||||{}" + orderModel.toJson().toString());
    for (int i = 0; i < tempProduc.length; i++) {
      await FireStoreUtils()
          .getProductByID(tempProduc[i].id.split('~').first)
          .then((value) async {
            ProductModel? productModel = value;
            if (tempProduc[i].variant_info != null) {
              for (
                int j = 0;
                j < productModel.itemAttributes!.variants!.length;
                j++
              ) {
                if (productModel.itemAttributes!.variants![j].variantId ==
                    tempProduc[i].id.split('~').last) {
                  if (productModel
                          .itemAttributes!
                          .variants![j]
                          .variantQuantity !=
                      "-1") {
                    productModel.itemAttributes!.variants![j].variantQuantity =
                        (int.parse(
                                  productModel
                                      .itemAttributes!
                                      .variants![j]
                                      .variantQuantity
                                      .toString(),
                                ) -
                                tempProduc[i].quantity)
                            .toString();
                  }
                }
              }
            } else {
              if (productModel.quantity != -1) {
                productModel.quantity =
                    productModel.quantity - tempProduc[i].quantity;
              }
            }

            await FireStoreUtils.updateProduct(productModel).then((value) {});
          });
    }

    hideProgress();
    print('_CheckoutScreenState.placeOrder ${placedOrder.id}');
    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: false,
      context: buildContext,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder:
          (context) => PlaceOrderScreen(
            orderModel: placedOrder,
            couponid: widget.couponId,
          ),
    );
  }

  Future<void> setPrefData() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString("musics_key", "");
  }

  toCheckOutScreen(bool val, BuildContext context) {
    push(
      context,
      CheckoutScreen(
        isMyTime: widget.isMyTime,
        cityaveche: widget.cityaveche,
        auto_apply: widget.auto_apply,
        autoapplydiscount: num.parse(widget.autoapplydiscount.toString()),
        isPaymentDone: val,
        razorpayorderid: ordercretedrazorpaymodal?.id ?? "",
        paymentType: this.paymentType,
        total: widget.total,
        groceryitem: widget.groceryitem,
        chargepaking: widget.chargepacking,
        discount: widget.discount!,
        couponCode: widget.couponCode!,
        couponId: widget.couponId!,
        couponId1: widget.couponId1,
        notes: widget.notes!,
        paymentOption: paymentOption,
        products: widget.products,
        deliveryCharge: widget.deliveryCharge,
        tipValue: widget.tipValue,
        takeAway: widget.takeAway,
        taxModel: widget.taxModel,
        specialDiscountMap: widget.specialDiscountMap,
        scheduleTime: widget.scheduleTime,
      ),
    );
  }
}

/// Old Code
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// // import 'package:flutter_braintree/flutter_braintree.dart';
// import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;
// import 'package:flutterwave_standard/flutterwave.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:foodie_customer/constants.dart';
// import 'package:foodie_customer/main.dart';
// import 'package:foodie_customer/model/CodModel.dart';
// import 'package:foodie_customer/model/FlutterWaveSettingDataModel.dart';
// import 'package:foodie_customer/model/OrderCretedRazorpayModal.dart';
// import 'package:foodie_customer/model/PayFastSettingData.dart';
// import 'package:foodie_customer/model/PayStackSettingsModel.dart';
// import 'package:foodie_customer/model/ProductModel.dart';
// import 'package:foodie_customer/model/User.dart';
// import 'package:foodie_customer/model/payStackURLModel.dart';
// import 'package:foodie_customer/model/razorpayKeyModel.dart';
// import 'package:foodie_customer/model/stripeSettingData.dart';
// import 'package:foodie_customer/services/FirebaseHelper.dart';
// import 'package:foodie_customer/services/helper.dart';
// import 'package:foodie_customer/services/localDatabase.dart';
// import 'package:foodie_customer/services/paystack_url_genrater.dart';
// import 'package:foodie_customer/ui/cartScreen/CartScreen.dart';
// import 'package:foodie_customer/ui/checkoutScreen/CheckoutScreen.dart';
// import 'package:foodie_customer/ui/container/ContainerScreen.dart';
// import 'package:foodie_customer/ui/wallet/PayFastScreen.dart';
// import 'package:foodie_customer/ui/wallet/payStackScreen.dart';
// import 'package:foodie_customer/userPrefrence.dart';
// import 'package:http/http.dart' as http;
// import 'package:mercadopago_sdk/mercadopago_sdk.dart';
// import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../model/MercadoPagoSettingsModel.dart';
// import '../../model/OrderModel.dart';
// import '../../model/RazorPayFailedModel.dart';
// import '../../model/StripePayFailedModel.dart';
// import '../../model/TaxModel.dart';
// import '../../model/VendorModel.dart';
// import '../../model/getPaytmTxtToken.dart';
// import '../../model/mail_setting.dart';
// import '../../model/paypalSettingData.dart';
// import '../../model/paytmSettingData.dart';
// import '../placeOrderScreen/PlaceOrderScreen.dart';
// import '../wallet/MercadoPagoScreen.dart';
//
// class PaymentScreen extends StatefulWidget {
//   final double total;
//   final double toatvendoramount;
//   final num wallamountvendor;
//   final num autoapplydiscount;
//   final double? discount;
//   final String? couponCode;
//   final String? groceryitem;
//   final String? razorpayaccount;
//   final String? vendoraccountnumber;
//   final String? couponId1;
//   final String? couponId, notes;
//   final List<CartProduct> products;
//   final String? chargepacking;
//   final List<String>? extraAddons;
//   final String? tipValue;
//   final bool? takeAway;
//   final bool? codWallet;
//   final bool? auto_apply;
//   final bool? cityaveche;
//   final bool? isMyTime;
//   final String? deliveryCharge;
//   final List<TaxModel>? taxModel;
//   final Map<String, dynamic>? specialDiscountMap;
//   final Timestamp? scheduleTime;
//
//   const PaymentScreen(
//       {Key? key,
//         required this.total,
//         required this.toatvendoramount,
//         required this.couponId1,
//         required this.groceryitem,
//         required this.wallamountvendor,
//         required this.autoapplydiscount,
//         required this.codWallet,
//         required this.auto_apply,
//         required this.isMyTime,
//         required this.cityaveche,
//         this.discount,
//         required this.razorpayaccount,
//         required this.vendoraccountnumber,
//         this.couponCode,
//         this.couponId,
//         this.chargepacking,
//         required this.products,
//         this.extraAddons,
//         this.tipValue,
//         this.takeAway,
//         this.deliveryCharge,
//         this.notes,
//         this.taxModel,
//         this.specialDiscountMap,
//         this.scheduleTime})
//       : super(key: key);
//
//   @override
//   PaymentScreenState createState() => PaymentScreenState();
// }
//
// int? saturdayTimestamp;
//
// class PaymentScreenState extends State<PaymentScreen> {
//   String selectedCardID = '';
//   final fireStoreUtils = FireStoreUtils();
//   late Future<bool> hasNativePay;
//
//   //List<PaymentMethod> _cards = [];
//   late Future<CodModel?> futurecod;
//
//   Stream<DocumentSnapshot<Map<String, dynamic>>>? userQuery;
//
//   static FirebaseFirestore fireStore = FirebaseFirestore.instance;
//
//   GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   String paymentOption = 'Pay Via Wallet'.tr();
//   RazorPayModel? razorPayData = UserPreference.getRazorPayData();
//
//   Razorpay _razorPay = Razorpay();
//   StripeSettingData? stripeData;
//   PaytmSettingData? paytmSettingData;
//   PaypalSettingData? paypalSettingData;
//   PayStackSettingData? payStackSettingData;
//   FlutterWaveSettingData? flutterWaveSettingData;
//   PayFastSettingData? payFastSettingData;
//   MercadoPagoSettingData? mercadoPagoSettingData;
//   bool proceed = true;
//   bool walletBalanceError = false;
//
//   bool isStaging = true;
//   String callbackUrl =
//       "http://162.241.125.167/~foodie/payments/paytmpaymentcallback?ORDER_ID=";
//   bool restrictAppInvoke = false;
//   bool enableAssist = true;
//   String result = "";
//   String paymentType = "";
//
//   late Map<String, dynamic>? adminCommission;
//   String? adminCommissionValue = "", addminCommissionType = "";
//   bool? isEnableAdminCommission = false;
//
//   getPaymentSettingData() async {
//     userQuery = fireStore
//         .collection(USERS)
//         .doc(MyAppState.currentUser!.userID)
//         .snapshots();
//     await UserPreference.getStripeData().then((value) async {
//       stripeData = value;
//       stripe1.Stripe.publishableKey = stripeData!.clientpublishableKey;
//       stripe1.Stripe.merchantIdentifier = 'Grubb';
//       await stripe1.Stripe.instance.applySettings();
//     });
//     razorPayData = await UserPreference.getRazorPayData();
//     paytmSettingData = await UserPreference.getPaytmData();
//     paypalSettingData = await UserPreference.getPayPalData();
//     payStackSettingData = await UserPreference.getPayStackData();
//     flutterWaveSettingData = await UserPreference.getFlutterWaveData();
//     payFastSettingData = await UserPreference.getPayFastData();
//     mercadoPagoSettingData = await UserPreference.getMercadoPago();
//
//     ///set Refrence for FlutterWave
//     setRef();
//   }
//
//   showAlert(context, {required String response, required Color colors}) {
//     return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(response),
//       backgroundColor: colors,
//     ));
//   }
//   bool chakchak=true;
// num merchantamountminimum=0;
//   bool jumpnam=false;
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
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("orderCancellationMinutes")
//           .get()
//           .then((value) {
//         debugPrint(value.data().toString());
//         setState(() {
//           merchantamountminimum = num.parse(value.data()!['minimumDepositAmountMerchant'].toString());
//          print("merchantmimimum amou shu ave che ${merchantamountminimum}");
//          print("merchantmimimum amou shu ave che ${widget.wallamountvendor}");
//           chakchak=false;
//         });
//       });
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
//   num? autoApplyFixCommission;
//   num? adminCommissionValue1;
//   num? grocerycommissionfix1;
//   String? grocerycommissionfix = "";
//   @override
//   void initState() {
//     super.initState();
//     // getRazorPayDemo();
//     getSaturdayTimestamp();
//     getPaymentSettingData();
//     initializeFlutterFire();
//     FireStoreUtils.createOrder();
//     print("widget.couponId1.toString()${widget.couponId1.toString()}");
//     print("codWallet${widget.codWallet.toString()}");
//     print("codWallet${widget.wallamountvendor.toString()}");
//     print("codWallet${widget.total.toString()}");
//     print("ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja ayala tu beshi ja z${widget.auto_apply.toString()}");
//     // print("codWallet${widget..toString()}");
//     futurecod = fireStoreUtils.getCod();
//     _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
//     _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     fireStoreUtils.getAdminCommission().then((value) {
//       if (value != null) {
//         setState(() {
//           adminCommission = value;
//           adminCommissionValue1 = adminCommission!["adminCommissionValue1"];
//           grocerycommissionfix1 = adminCommission!["groceryatocommssion"];
//           adminCommissionValue = adminCommission!["adminCommission"].toString();
//           addminCommissionType =
//               adminCommission!["adminCommissionType"].toString();
//           autoApplyFixCommission =
//           adminCommission!["autoApplyFixCommission"];
//           isEnableAdminCommission = adminCommission!["isAdminCommission"];
//           grocerycommissionfix =
//               adminCommission!["grocerycommissionfix"].toString();
//         });
//         if(widget.auto_apply==true&&widget.isMyTime==true&&widget.cityaveche==true){
//           if(widget.groceryitem == "grocery"){
//             if(grocerycommissionfix1==widget.autoapplydiscount){
//               setState(() {
//                 grocerycommissionfix=autoApplyFixCommission.toString();
//               });
//               print("widget.groceryitem == ${grocerycommissionfix}");
//             }else{
//               if(grocerycommissionfix1==0&&grocerycommissionfix=="0"){
//                 setState(() {
//                   grocerycommissionfix =  widget.autoapplydiscount.toString();
//                   print("grocerycommissionfix1 00000.00000000000 ${grocerycommissionfix}");
//                 });
//               }else{
//                 setState(() {
//                   grocerycommissionfix = (double.parse(grocerycommissionfix1.toString()) - double.parse(widget.autoapplydiscount.toString())).abs().toStringAsFixed(2);
//
//                   print("else ave che jayare grocery hoy tayare ${grocerycommissionfix}");
//
//                 });
//               }
//
//             }
//           }
//           if(adminCommissionValue1==widget.autoapplydiscount){
//             setState(() {
//               adminCommissionValue = autoApplyFixCommission.toString();
//               jumpnam=true;
//             });
//             print("adminCommissionValue>>>>>>>value shu ave che ${adminCommissionValue}");
//           }else{
//             setState(() {
//               adminCommissionValue = (double.parse(adminCommissionValue1.toString()) - double.parse(widget.autoapplydiscount.toString())).abs().toStringAsFixed(2);
//
//               print("else vendor commssion shu ave che  ${adminCommissionValue}");
//
//             });
//           }
//         }
//         print("grocerycommissionfixgrocerycommissionfixgrocerycommissionfix${adminCommissionValue1}");
//         print("grocerycommissionfixgrocerycommissionfixgrocerycommissionfix${grocerycommissionfix}");
//         print("grocerycommissionfixgrocerycommissionfixgrocerycommissionfix${grocerycommissionfix1}");
//         print("grocerycommissionfixgrocerycommissionfixgrocerycommissionfix${addminCommissionType}");
//         print("adminCommissionValue>>>>>>>>>>>>>>>${adminCommissionValue}");
//         print("adminCommissionValue>>>>>>>>>>>>>>>${autoApplyFixCommission}");
//         print("adminCommissionValue>>>>>>>>>>>>>>>${isEnableAdminCommission}");
//       }
//     });
//
//
//   }
//
//   // void getSaturdayTimestamp() {
//   //   DateTime now = DateTime.now();
//   //
//   //   // Calculate days to next Saturday
//   //   int daysToSaturday = DateTime.saturday - now.weekday;
//   //
//   //   // If today is Saturday, move to next week's Saturday
//   //   if (daysToSaturday < 0) {
//   //     daysToSaturday += 7;
//   //   }
//   //
//   //   // Calculate the next Saturday
//   //   DateTime nextSaturday = now.add(Duration(days: daysToSaturday));
//   //
//   //   // Get timestamp at 6 AM of next Saturday
//   //   DateTime saturdayStart =
//   //   DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 6);
//   //
//   //   int timestamp =
//   //   (saturdayStart.millisecondsSinceEpoch ~/ 1000); // Convert to seconds
//   //
//   //   // Validate timestamp range
//   //   if (timestamp < 946684800 || timestamp > 4765046400) {
//   //     print('Error: Timestamp out of range: $timestamp');
//   //     return;
//   //   }
//   //
//   //   // Set the state with the calculated timestamp
//   //   setState(() {
//   //     saturdayTimestamp = timestamp;
//   //     print('Timestamp of Saturday (6 AM) is : $saturdayTimestamp');
//   //
//   //     getRazorPayDemo();
//   //   });
//   // }
//   void getSaturdayTimestamp() {
//     DateTime now = DateTime.now();
//
//     // Calculate days to next Saturday
//     int daysToSaturday = DateTime.saturday - now.weekday;
//
//     // If today is Saturday, move to next week's Saturday if after 6 AM
//     if (daysToSaturday < 0 || (daysToSaturday == 0 && now.hour >= 6)) {
//       daysToSaturday += 7;
//     }
//
//     // Calculate the next Saturday
//     DateTime nextSaturday = now.add(Duration(days: daysToSaturday));
//
//     // Get timestamp at 6 AM of next Saturday
//     DateTime saturdayStart =
//     DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 6);
//
//     int timestamp = saturdayStart.millisecondsSinceEpoch ~/ 1000; // Convert to seconds
//
//     // Validate timestamp range
//     if (timestamp < 946684800 || timestamp > 4765046400) {
//       print('Error: Timestamp out of range: $timestamp');
//       return;
//     }
//
//     // Set the state with the calculated timestamp
//     setState(() {
//       saturdayTimestamp = timestamp;
//       print('Timestamp of Saturday (6 AM) is: $saturdayTimestamp');
//
//       // Optionally call other functions
//       getRazorPayDemo();
//     });
//   }
//
//   // void getSaturdayTimestamp() {
//   //   DateTime now = DateTime.now();
//   //
//   //   // Calculate days to next Saturday
//   //   int daysToSaturday = DateTime.saturday - now.weekday;
//   //
//   //   // If today is Saturday, move to next week's Saturday
//   //   if (daysToSaturday < 0) {
//   //     daysToSaturday += 7;
//   //   }
//   //
//   //   // Calculate the next Saturday
//   //   DateTime nextSaturday = now.add(Duration(days: daysToSaturday));
//   //
//   //   // Get timestamp at 6 AM of next Saturday
//   //   DateTime saturdayStart =
//   //       DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 6);
//   //
//   //   // Set the state with the calculated timestamp
//   //   setState(() {
//   //     saturdayTimestamp = saturdayStart.millisecondsSinceEpoch;
//   //     print('Time Stamp of Saturday (6 AM) is : $saturdayTimestamp');
//   //     loginapp();
//   //   });
//   // }
//
//   OrderCretedRazorpayModal? ordercretedrazorpaymodal;
//
//   loginapp(String? razorpayKey,String? razorpaySecret) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(("please wait")),
//     ));
//
//     String keyId = razorpayKey.toString();
//     String secret =razorpaySecret.toString();
//     String basicAuth = 'Basic ' + base64Encode(utf8.encode('$keyId:$secret'));
//     print("Razorpay account id ave che ${widget.vendoraccountnumber}");
//     print("ven dor nu accoun name ave che ${widget.razorpayaccount}");
//     final Map<String, dynamic> data = {
//       "amount": (widget.total * 100).toInt(),
//       "payment_capture": 1,
//       "currency": "INR",
//       "transfers": [
//         {
//           "account": widget.razorpayaccount,
//           //Please replace with appropriate ID.
//           "amount":( widget.toatvendoramount * 100).toInt(),
//           "currency": "INR",
//           "notes": {
//             "branch": "Acme Corp Bangalore South",
//             "name": widget.vendoraccountnumber
//           },
//           "linked_account_notes": ["branch"],
//           "on_hold": 1,
//           "on_hold_until": saturdayTimestamp ?? 0
//         }
//       ]
//     };
//     // Convert 'billing' to a string
//
//     print("datadatadatadatadata${data}");
//     final apiUrl = "https://api.razorpay.com/v1/orders";
//
//     final headers = {
//       'Content-Type': 'application/json',
//       'authorization': basicAuth,
//     };
//     // Construct the request body
//     final requestBody = json.encode(data);
//
//     // Make the API call using http.post
//     final response = await http.post(
//       Uri.parse(apiUrl),
//       headers: headers,
//       body: requestBody,
//     );
//
//     print("requestBody${requestBody}");
//     print("responsefkglkfdlgkfdg${response}");
//
//     // Handle the response
//
//     if (response.statusCode == 200) {
//       ordercretedrazorpaymodal =
//           OrderCretedRazorpayModal.fromJson(json.decode(response.body));
//       print("loginapp api sucessfuuly ");
//       print(
//           "ordercretedrazorpaymodal?.id${ordercretedrazorpaymodal?.id ?? ""}");
//       setState(() {
//         proceed = false;
//       });
//       FirebaseFirestore firestore = FirebaseFirestore.instance;
//
//       // Payment data to be stored
//       Map<String, dynamic> paymentData = {
//         "customerid": MyAppState.currentUser?.userID ?? "",
//         "orderidrazorpay": ordercretedrazorpaymodal?.id ?? "",
//         "amount": widget.total * 100,
//         "payment_capture": 1,
//         "currency": "INR",
//         "transfers": [
//           {
//             "account": widget.razorpayaccount,
//             "amount": widget.toatvendoramount * 100,
//             "currency": "INR",
//             "notes": {
//               "branch": "Acme Corp Bangalore South",
//               "name": widget.vendoraccountnumber,
//             },
//             "linked_account_notes": ["branch"],
//             "on_hold": false,
//             "on_hold_until": null,
//           }
//         ]
//       };
//
//       // Adding the data to a Firestore collection (e.g., 'payments')
//       await firestore
//           .collection('razorpayLinkedAccountsPayments')
//           .add(paymentData);
//     } else {
//       setState(() {
//         proceed = false;
//       });
//       // errorresponse = ErrorResponse.fromJson(json.decode(response.body));
//       print("sdsdfsdfsdfsdfsdf");
//       print("sgssfsd${response.body}");
//       // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       //   content: Text((errorresponse?.error?.description ?? "")),
//       // ));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBody: true,
//       extendBodyBehindAppBar: false,
//       key: _scaffoldKey,
//       appBar: AppBar(),
//       body: chakchak? Center(child: CircularProgressIndicator(color: Colors.deepOrange,)):ListView(
//         physics: BouncingScrollPhysics(),
//         padding: EdgeInsets.all(16),
//         children: [
//           Visibility(
//             visible: UserPreference.getWalletData() ?? false,
//             child: Column(
//               children: [
//                 Divider(),
//                 StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//                     stream: userQuery,
//                     builder: (context,
//                         AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
//                         asyncSnapshot) {
//                       if (asyncSnapshot.hasError) {
//                         return Text(
//                           "error".tr(),
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16),
//                         );
//                       }
//                       if (asyncSnapshot.connectionState ==
//                           ConnectionState.waiting) {
//                         return Center(
//                             child: SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 0.8,
//                                   color: Colors.white,
//                                   backgroundColor: Colors.transparent,
//                                 )));
//                       }
//                       if (asyncSnapshot.data == null) {
//                         return Container();
//                       }
//                       User userData =
//                       User.fromJson(asyncSnapshot.data!.data()!);
//
//                       walletBalanceError =
//                       double.parse(userData.walletAmount.toString()) <
//                           double.parse(widget.total.toString())
//                           ? true
//                           : false;
//                       return Column(
//                         children: [
//                           CheckboxListTile(
//                             onChanged: (bool? value) {
//                               setState(() {
//                                 if (!walletBalanceError) {
//                                   wallet = true;
//                                 } else {
//                                   wallet = false;
//                                 }
//                                 payStack = false;
//                                 mercadoPago = false;
//                                 flutterWave = false;
//                                 razorPay = false;
//                                 codPay = false;
//                                 payTm = false;
//                                 pay = false;
//                                 payFast = false;
//                                 paypal = false;
//                                 stripe = false;
//                                 selectedCardID = '';
//                                 paymentOption = "Pay Online Via Wallet".tr();
//                               });
//                             },
//                             value: wallet,
//                             contentPadding: EdgeInsets.all(0),
//                             secondary: FaIcon(FontAwesomeIcons.wallet),
//                             title: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text('Wallet'.tr()),
//                                 Column(
//                                   children: [
//                                     Text(
//                                       amountShow(
//                                           amount:
//                                           userData.walletAmount.toString()),
//                                       style: TextStyle(
//                                           color: walletBalanceError
//                                               ? Colors.red
//                                               : Colors.green,
//                                           fontWeight: FontWeight.w600,
//                                           fontSize: 18),
//                                     ),
//                                   ],
//                                 )
//                               ],
//                             ),
//                           ),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               Visibility(
//                                 child: Padding(
//                                   padding: const EdgeInsets.only(right: 0.0),
//                                   child: walletBalanceError
//                                       ? Text(
//                                     "Your wallet doesn't have sufficient balance"
//                                         .tr(),
//                                     style: TextStyle(
//                                         fontSize: 14, color: Colors.red),
//                                   )
//                                       : Text(
//                                     'Sufficient Balance'.tr(),
//                                     style: TextStyle(
//                                         fontSize: 14,
//                                         color: Colors.green),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       );
//                     }),
//               ],
//             ),
//           ),
//     widget.codWallet==false? Container():
//           Visibility(
//             visible: widget.wallamountvendor >= merchantamountminimum,
//             child: Column(
//               children: [
//                 FutureBuilder<CodModel?>(
//                     future: futurecod,
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting)
//                         return Center(
//                           child: CircularProgressIndicator.adaptive(
//                             valueColor:
//                             AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
//                           ),
//                         );
//                       if (snapshot.hasData) {
//                         return snapshot.data!.cod == true
//                             ? CheckboxListTile(
//                           onChanged: (bool? value) {
//                             setState(() {
//                               mercadoPago = false;
//                               payStack = false;
//                               flutterWave = false;
//                               razorPay = false;
//                               wallet = false;
//                               codPay = true; //codPay ? false : true;
//                               selectedCardID = '';
//                               payTm = false;
//                               payFast = false;
//                               pay = false;
//                               paypal = false;
//                               stripe = false;
//                               paymentOption = 'Cash on Delivery'.tr();
//                             });
//                           },
//                           value: codPay,
//                           contentPadding: EdgeInsets.all(0),
//                           secondary: Image.asset(
//                             'assets/images/money.png',
//                             width: 25,
//                             height: 25,
//                           ),
//                           title: Text('Cash on Delivery'.tr()),
//                         )
//                             : Center();
//                       }
//                       return Center();
//                     }),
//               ],
//             ),
//           ),
//           Visibility(
//             visible: razorPayData?.isEnabled ?? true,
//             child: Column(
//               children: [
//                 Divider(),
//                 CheckboxListTile(
//                   onChanged: (bool? value) {
//                     setState(() {
//                       mercadoPago = false;
//                       payStack = false;
//                       flutterWave = false;
//                       wallet = false;
//                       razorPay = true; //razorPay ? false : true;
//                       codPay = false;
//                       payTm = false;
//                       pay = false;
//                       paypal = false;
//                       payFast = false;
//                       stripe = false;
//                       selectedCardID = '';
//                       paymentOption = "Pay Online Via".tr() + "RazorPay";
//                     });
//                   },
//                   value: razorPay,
//                   contentPadding: EdgeInsets.all(0),
//                   secondary: Image.asset(
//                     'assets/images/secure.png',
//                     width: 25,
//                     height: 25,
//                   ),
//                   title: Text('Online Payment'.tr()),
//                 ),
//               ],
//             ),
//           ),
//           Visibility(
//             visible: (stripeData == null) ? false : stripeData!.isEnabled,
//             child: Column(
//               children: [
//                 Divider(),
//                 CheckboxListTile(
//                   onChanged: (bool? value) {
//                     setState(() {
//                       mercadoPago = false;
//                       payStack = false;
//                       flutterWave = false;
//                       stripe = true;
//                       wallet = false;
//                       razorPay = false; //razorPay ? false : true;
//                       codPay = false;
//                       payTm = false;
//                       payFast = false;
//                       pay = false;
//                       paypal = false;
//                       selectedCardID = '';
//                       paymentOption = "Pay Online Via".tr() + "Stripe";
//                     });
//                   },
//                   value: stripe,
//                   contentPadding: EdgeInsets.all(0),
//                   secondary: FaIcon(FontAwesomeIcons.stripe),
//                   title: Text('Stripe'.tr()),
//                 ),
//               ],
//             ),
//           ),
//           Visibility(
//             visible: (paytmSettingData == null)
//                 ? false
//                 : paytmSettingData!.isEnabled,
//             child: Column(
//               children: [
//                 Divider(),
//                 CheckboxListTile(
//                   onChanged: (bool? value) {
//                     setState(() {
//                       mercadoPago = false;
//                       payStack = false;
//                       flutterWave = false;
//                       razorPay = false;
//                       wallet = false; //razorPay ? false : true;
//                       codPay = false;
//                       payTm = true;
//                       pay = false;
//                       payFast = false;
//                       paypal = false;
//                       stripe = false;
//                       selectedCardID = '';
//                       paymentOption = "Pay Online Via".tr() + "PayTm";
//                     });
//                   },
//                   value: payTm,
//                   contentPadding: EdgeInsets.all(0),
//                   secondary: FaIcon(FontAwesomeIcons.alipay),
//                   title: Text('PayTm'.tr()),
//                 ),
//               ],
//             ),
//           ),
//           Visibility(
//             visible: (paypalSettingData == null)
//                 ? false
//                 : paypalSettingData!.isEnabled,
//             child: Column(
//               children: [
//                 Divider(),
//                 CheckboxListTile(
//                   onChanged: (bool? value) {
//                     setState(() {
//                       mercadoPago = false;
//                       paypal = true;
//                       payStack = false;
//                       flutterWave = false;
//                       wallet = false;
//                       razorPay = false;
//                       codPay = false;
//                       payTm = false;
//                       payFast = false;
//                       pay = false;
//                       stripe = false;
//                       selectedCardID = '';
//                       paymentOption = "Pay Online Via".tr() + "PayPal";
//                     });
//                   },
//                   value: paypal,
//                   contentPadding: EdgeInsets.all(0),
//                   secondary: FaIcon(FontAwesomeIcons.paypal),
//                   title: Text(' Paypal'.tr()),
//                 ),
//               ],
//             ),
//           ),
//           Visibility(
//             visible: false,
//             child: Column(
//               children: [
//                 Divider(),
//                 CheckboxListTile(
//                   onChanged: (bool? value) {
//                     setState(() {
//                       mercadoPago = false;
//                       payStack = false;
//                       flutterWave = false;
//                       razorPay = false; //razorPay ? false : true;
//                       codPay = false;
//                       payTm = false;
//                       wallet = false;
//                       payFast = false;
//                       pay = true;
//                       paypal = false;
//                       stripe = false;
//                       selectedCardID = '';
//                       paymentOption = "Pay Online Via".tr() + "Pay";
//                     });
//                   },
//                   value: pay,
//                   contentPadding: EdgeInsets.all(0),
//                   secondary: FaIcon(FontAwesomeIcons.googlePay),
//                   title: Text(' Pay'.tr()),
//                 ),
//               ],
//             ),
//           ),
//           Visibility(
//             visible: (payFastSettingData == null)
//                 ? false
//                 : payFastSettingData!.isEnable,
//             child: Column(
//               children: [
//                 Divider(),
//                 CheckboxListTile(
//                   onChanged: (bool? value) {
//                     setState(() {
//                       mercadoPago = false;
//                       payFast = true;
//                       paypal = false;
//                       wallet = false;
//                       razorPay = false;
//                       payStack = false;
//                       codPay = false;
//                       payTm = false;
//                       pay = false;
//                       flutterWave = false;
//                       stripe = false;
//                       selectedCardID = '';
//                       paymentOption = "Pay Online Via".tr() + "PayFast";
//                     });
//                   },
//                   value: payFast,
//                   contentPadding: EdgeInsets.all(0),
//                   secondary: Image.asset(
//                     'assets/images/payfastmini.png',
//                     width: 25,
//                     height: 25,
//                   ),
//                   title: Text(' PayFast'.tr()),
//                 ),
//               ],
//             ),
//           ),
//           Visibility(
//             visible: (payStackSettingData == null)
//                 ? false
//                 : payStackSettingData?.isEnabled ?? false,
//             child: Column(
//               children: [
//                 Divider(),
//                 CheckboxListTile(
//                   onChanged: (bool? value) {
//                     setState(() {
//                       mercadoPago = false;
//                       payStack = true;
//                       paypal = false;
//                       flutterWave = false;
//                       wallet = false;
//                       razorPay = false;
//                       codPay = false;
//                       payFast = false;
//                       payTm = false;
//                       pay = false;
//                       stripe = false;
//                       selectedCardID = '';
//                       paymentOption = "Pay Online Via".tr() + "PayStack";
//                     });
//                   },
//                   value: payStack,
//                   contentPadding: EdgeInsets.all(0),
//                   secondary: Image.asset(
//                     'assets/images/paystackmini.png',
//                     width: 25,
//                     height: 25,
//                   ),
//                   title: Text(' PayStack'.tr()),
//                 ),
//               ],
//             ),
//           ),
//           Visibility(
//             visible: (flutterWaveSettingData == null)
//                 ? false
//                 : flutterWaveSettingData!.isEnable,
//             child: Column(
//               children: [
//                 Divider(),
//                 CheckboxListTile(
//                   onChanged: (bool? value) {
//                     setState(() {
//                       mercadoPago = false;
//                       payStack = false;
//                       flutterWave = true;
//                       razorPay = false; //razorPay ? false : true;
//                       codPay = false;
//                       payTm = false;
//                       wallet = false;
//                       pay = false;
//                       payFast = false;
//                       paypal = false;
//                       stripe = false;
//                       selectedCardID = '';
//                       paymentOption = "Pay Online Via".tr() + "FlutterWave";
//                     });
//                   },
//                   value: flutterWave,
//                   contentPadding: EdgeInsets.all(0),
//                   secondary: FaIcon(FontAwesomeIcons.moneyBillWave),
//                   title: Text(' FlutterWave'.tr()),
//                 ),
//               ],
//             ),
//           ),
//           Visibility(
//             visible: (mercadoPagoSettingData == null)
//                 ? false
//                 : mercadoPagoSettingData!.isEnabled,
//             child: Column(
//               children: [
//                 Divider(),
//                 CheckboxListTile(
//                   onChanged: (bool? value) {
//                     setState(() {
//                       mercadoPago = true;
//                       payFast = false;
//                       paypal = false;
//                       wallet = false;
//                       razorPay = false;
//                       payStack = false;
//                       codPay = false;
//                       payTm = false;
//                       pay = false;
//                       flutterWave = false;
//                       stripe = false;
//                       selectedCardID = '';
//                       paymentOption = "Pay Online Via".tr() + "Mercado Pago";
//                     });
//                   },
//                   value: mercadoPago,
//                   contentPadding: EdgeInsets.all(0),
//                   secondary: Image.asset(
//                     'assets/images/payfastmini.png',
//                     width: 25,
//                     height: 25,
//                   ),
//                   title: Text(' Mercado Pago'.tr()),
//                 ),
//               ],
//             ),
//           ),
//           Divider(),
//           SizedBox(
//             height: 24,
//           ),
//           proceed
//               ? ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.all(20),
//                 backgroundColor: Color(COLOR_PRIMARY),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () {},
//               child: Center(
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                 ),
//               ))
//               : ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.all(20),
//               backgroundColor: Color(COLOR_PRIMARY),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () async {
//               await FireStoreUtils.createPaymentId();
//
//               if (razorPay) {
//                 paymentType = 'razorpay';
//                 showLoadingAlert();
//                 openCheckout(
//                   amount: widget.total,
//                   orderId: ordercretedrazorpaymodal?.id,
//                 );
//                 // RazorPayController()
//                 //     .createOrderRazorPay(amount: widget.total.toInt())
//                 //     .then((value) {
//                 //   if (value == null) {
//                 //     Navigator.pop(context);
//                 //     showAlert(_scaffoldKey.currentContext!,
//                 //         response:
//                 //             "Something went wrong, please contact admin.".tr(),
//                 //         colors: Colors.red);
//                 //   } else {
//                 //     CreateRazorPayOrderModel result = value;
//                 //     openCheckout(
//                 //       amount:2 * 100,
//                 //       orderId:ordercretedrazorpaymodal?.id,
//                 //     );
//                 //   }
//                 // });
//               } else if (payFast) {
//                 paymentType = 'payfast';
//                 showLoadingAlert();
//                 PayStackURLGen.getPayHTML(
//                     payFastSettingData: payFastSettingData!,
//                     amount: widget.total.toString())
//                     .then((value) async {
//                   bool isDone =
//                   await Navigator.of(context).push(MaterialPageRoute(
//                       builder: (context) => PayFastScreen(
//                         htmlData: value,
//                         payFastSettingData: payFastSettingData!,
//                       )));
//
//                   if (isDone) {
//                     if (widget.takeAway!) {
//                       placeOrder(_scaffoldKey.currentContext!);
//                     } else {
//                       toCheckOutScreen(true, context);
//                     }
//
//                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       content: Text(
//                         "Payment Successful!!".tr() + "\n",
//                       ),
//                       backgroundColor: Colors.green.shade400,
//                       duration: Duration(seconds: 6),
//                     ));
//                   } else {
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       content: Text(
//                         "Payment Unsuccessful!!".tr() + "\n",
//                       ),
//                       backgroundColor: Colors.red.shade400,
//                       duration: Duration(seconds: 6),
//                     ));
//                   }
//                 });
//               } else if (payTm) {
//                 paymentType = 'paytm';
//                 showLoadingAlert();
//                 getPaytmCheckSum(context, amount: widget.total);
//               } else if (stripe) {
//                 paymentType = 'stripe';
//                 showLoadingAlert();
//                 stripeMakePayment(amount: widget.total.toString());
//               } else if (pay) {
//                 // Navigator.push(
//                 //     context,
//                 //     MaterialPageRoute(
//                 //         builder: (context) =>
//                 //             FlutterWavePayService() //UniPaymentService()
//                 //         ));
//               } else if (payStack) {
//                 paymentType = 'paystack';
//                 showLoadingAlert();
//                 payStackPayment(context);
//               } else if (mercadoPago) {
//                 mercadoPagoMakePayment();
//               } else if (flutterWave) {
//                 paymentType = 'flutterwave';
//                 _flutterWaveInitiatePayment(context);
//               } else if (paypal) {
//                 paymentType = 'paypal';
//                 showLoadingAlert();
//                 // _makePaypalPayment(amount: widget.total.toString());
//               } else if (wallet && walletBalanceError == false) {
//                 paymentType = 'wallet';
//                 showLoadingAlert();
//                 FireStoreUtils.createPaymentId().then((value) {
//                   final paymentID = value;
//                   String orderId = UserPreference.getOrderId();
//                   FireStoreUtils.topUpWalletAmount(
//                       paymentMethod: "Wallet",
//                       isTopup: false,
//                       orderId: orderId,
//                       amount: widget.total,
//                       id: paymentID)
//                       .then((value) {
//                     FireStoreUtils.updateWalletAmount(
//                         amount: -widget.total)
//                         .then((value) {
//                       if (widget.takeAway!) {
//                         placeOrder(_scaffoldKey.currentContext!,
//                             oid: orderId);
//                       } else {
//                         Navigator.pop(context);
//                         toCheckOutScreen(true, context);
//                       }
//                     }).whenComplete(() {
//                       showAlert(_scaffoldKey.currentContext!,
//                           response: "Payment Successful Via".tr() +
//                               " " "Wallet".tr(),
//                           colors: Colors.green);
//                     });
//                   });
//                 });
//               } else if (codPay) {
//                 paymentType = 'cod';
//                 if (widget.takeAway!) {
//                   placeOrder(_scaffoldKey.currentContext!);
//                 } else {
//                   toCheckOutScreen(false, context);
//                 }
//               } else {
//                 final SnackBar snackBar = SnackBar(
//                   content: Text(
//                     "Select Payment Method".tr(),
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   backgroundColor: Color(COLOR_PRIMARY),
//                 );
//                 ScaffoldMessenger.of(context).showSnackBar(snackBar);
//               }
//             },
//             child: Text(
//               'PROCEED'.tr(),
//               style: TextStyle(
//                   color:
//                   isDarkMode(context) ? Colors.black : Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18),
//             ),
//           ),
//           SizedBox(height: 10,),
//           ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.all(20),
//                 backgroundColor: Color(COLOR_PRIMARY),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () {
//                 pushAndRemoveUntil(
//                     context,
//                     ContainerScreen(
//                       user: MyAppState.currentUser!,
//                       drawerSelection: DrawerSelection.Cart,
//                       currentWidget: CartScreen(
//                       ),
//                       appBarTitle: 'Your Cart'.tr(),
//                     ),
//                     false);
//               },
//               child:Text(
//                 'Back To Cart'.tr(),
//                 style: TextStyle(
//                     color:
//                     isDarkMode(context) ? Colors.black : Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18),
//               ),)
//         ],
//       ),
//     );
//   }
//   String? razorpayKey;
//   String? razorpaySecret;
//   getRazorPayDemo() async {
//     RazorPayModel razorPayModel;
//     FirebaseFirestore.instance
//         .collection(Setting)
//         .doc("razorpaySettings")
//         .get()
//         .then((user) {
//       debugPrint(user.data().toString());
//       try {
//         razorPayModel = RazorPayModel.fromJson(user.data() ?? {});
//         UserPreference.setRazorPayData(razorPayModel);
//         RazorPayModel fhg = UserPreference.getRazorPayData();
//         debugPrint(fhg.razorpayKey);
//         //
//         // RazorPayController().updateRazorPayData(razorPayData: userModel);
//
//         setState(() {
//           // isRazorPayEnabled = userModel.isEnabled;
//           // isRazorPaySandboxEnabled = userModel.isSandboxEnabled;
//           razorpayKey = razorPayModel.razorpayKey;
//           razorpaySecret = razorPayModel.razorpaySecret;
//         });
//         loginapp(razorpayKey,razorpaySecret);
//         print("razorpayKeyrazorpayKeyrazorpayKey${razorpayKey}");
//         print("razorpayKeyrazorpayKeyrazorpayKey${razorpaySecret}");
//
//       } catch (e) {
//         debugPrint(
//             'FireStoreUtils.getUserByID failed to parse user object ${user.id}');
//       }
//     });
//
//     //yield* razorPayStreamController.stream;
//   }
//   bool payStack = false;
//   bool flutterWave = false;
//   bool wallet = false;
//   bool razorPay = false;
//   bool payFast = false;
//   bool mercadoPago = false;
//   bool codPay = false;
//   bool payTm = false;
//   bool pay = false;
//   bool stripe = false;
//   bool paypal = false;
//
//   ///RazorPay payment function
//   void openCheckout({required amount, required orderId}) async {
//     var options = {
//       'key': razorpayKey,
//       'amount': amount * 100,
//       'name': 'Grubb',
//       'order_id': orderId,
//       "currency": currencyModel?.code,
//       'description': 'Payment for Order $orderId',
//       'retry': {'enabled': true, 'max_count': 1},
//       'send_sms_hash': true,
//       'one_click_checkout': true,
//       'force_cod': true,
//       'prefill': {
//         'contact': MyAppState.currentUser!.phoneNumber,
//         'email': MyAppState.currentUser!.email,
//       },
//       'external': {
//         'wallets': ['paytm']
//       }
//     };
//
//     try {
//       _razorPay.open(options);
//     } catch (e) {
//       debugPrint('Error: $e');
//     }
//   }
//
//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     print("response.paymentId!${response.paymentId!}");
//     print("response.paymentId!${widget.total}");
//     capturePayment(response.paymentId!,widget.total);
//     Navigator.pop(_scaffoldKey.currentContext!);
//     if (widget.takeAway!) {
//       placeOrder(_scaffoldKey.currentContext!);
//     } else {
//       toCheckOutScreen(true, _scaffoldKey.currentContext!);
//     }
//
//     ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
//       content: Text(
//         "Payment Successful!!".tr(),
//       ),
//       backgroundColor: Colors.green.shade400,
//       duration: Duration(seconds: 6),
//     ));
//
//   }
//   Future<void> capturePayment(String paymentId, dynamic amount) async {
//     int finalAmount = (double.parse(amount.toString()) * 100).toInt(); // Ensuring valid integer value
//
//     var url = Uri.parse('https://api.razorpay.com/v1/payments/$paymentId/capture');
//     print("Capture URL: $url");
//     String keyId = razorpayKey.toString();
//     String secret =razorpaySecret.toString();
//
//     var response = await http.post(
//       url,
//       headers: {
//         'Authorization': 'Basic ' + base64Encode(utf8.encode('$keyId:$secret')),
//         'Content-Type': 'application/json'
//       },
//       body: '{"amount":$finalAmount, "currency":"INR"}',
//     );
//
//     print("Final Amount Sent: $finalAmount");
//
//     if (response.statusCode == 200) {
//       debugPrint('Payment Captured Successfully');
//
//
//     } else {
//       debugPrint('Capture Failed: ${response.body}');
//
//     }
//   }
//   void _handleExternalWaller(ExternalWalletResponse response) {
//     Navigator.pop(_scaffoldKey.currentContext!);
//     ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
//       content: Text(
//         "Payment Processing!! via".tr() + "\n" + response.walletName!,
//       ),
//       backgroundColor: Colors.blue.shade400,
//       duration: Duration(seconds: 8),
//     ));
//   }
//
//   void _handlePaymentError(PaymentFailureResponse response) {
//     Navigator.pop(_scaffoldKey.currentContext!);
//     RazorPayFailedModel lom =
//     RazorPayFailedModel.fromJson(jsonDecode(response.message!.toString()));
//     ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
//       content: Text(
//         "Payment Failed!!".tr() + "\n" + lom.error.description,
//       ),
//       backgroundColor: Colors.red.shade400,
//       duration: Duration(seconds: 8),
//     ));
//   }
//
//   ///Stripe payment function
//   Map<String, dynamic>? paymentIntentData;
//
//   Future<void> stripeMakePayment({required String amount}) async {
//     try {
//       paymentIntentData = await createStripeIntent(amount);
//       if (paymentIntentData!.containsKey("error")) {
//         Navigator.pop(context);
//         showAlert(_scaffoldKey.currentContext!,
//             response: "Something went wrong, please contact admin.".tr(),
//             colors: Colors.red);
//       } else {
//         await stripe1.Stripe.instance
//             .initPaymentSheet(
//             paymentSheetParameters: stripe1.SetupPaymentSheetParameters(
//               paymentIntentClientSecret: paymentIntentData!['client_secret'],
//               applePay: const stripe1.PaymentSheetApplePay(
//                 merchantCountryCode: 'US',
//               ),
//               allowsDelayedPaymentMethods: false,
//               googlePay: stripe1.PaymentSheetGooglePay(
//                 merchantCountryCode: 'US',
//                 testEnv: true,
//                 currencyCode: currencyModel!.code,
//               ),
//               style: ThemeMode.system,
//               appearance: stripe1.PaymentSheetAppearance(
//                 colors: stripe1.PaymentSheetAppearanceColors(
//                   primary: Color(COLOR_PRIMARY),
//                 ),
//               ),
//               merchantDisplayName: 'Grubb',
//             ))
//             .then((value) {});
//         setState(() {});
//         displayStripePaymentSheet(amount: amount);
//       }
//     } catch (e, s) {
//       print('exception:$e$s');
//     }
//   }
//
//   displayStripePaymentSheet({required amount}) async {
//     try {
//       await stripe1.Stripe.instance.presentPaymentSheet().then((value) {
//         if (widget.takeAway!) {
//           placeOrder(_scaffoldKey.currentContext!);
//         } else {
//           toCheckOutScreen(true, context);
//         }
//
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text("Payment Successful!!".tr()),
//           duration: Duration(seconds: 8),
//           backgroundColor: Colors.green,
//         ));
//         paymentIntentData = null;
//       }).onError((error, stackTrace) {
//         Navigator.pop(context);
//         var lo1 = jsonEncode(error);
//         var lo2 = jsonDecode(lo1);
//         StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
//         showDialog(
//             context: context,
//             builder: (_) => AlertDialog(
//               content: Text("${lom.error.message}"),
//             ));
//       });
//     } on stripe1.StripeException catch (e) {
//       Navigator.pop(context);
//       var lo1 = jsonEncode(e);
//       var lo2 = jsonDecode(lo1);
//       StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
//       showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             content: Text("${lom.error.message}"),
//           ));
//     } catch (e) {
//       print('$e');
//       Navigator.pop(context);
//       ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
//         content: Text("$e"),
//         duration: Duration(seconds: 8),
//         backgroundColor: Colors.red,
//       ));
//     }
//   }
//
//   createStripeIntent(
//       String amount,
//       ) async {
//     try {
//       Map<String, dynamic> body = {
//         'amount': calculateAmount(amount),
//         'currency': currencyModel!.code,
//         'payment_method_types[0]': 'card',
//         // 'payment_method_types[1]': 'ideal',
//         "description": "${MyAppState.currentUser?.userID} Wallet Topup",
//         "shipping[name]":
//         "${MyAppState.currentUser?.firstName} ${MyAppState.currentUser?.lastName}",
//         "shipping[address][line1]": "510 Townsend St",
//         "shipping[address][postal_code]": "98140",
//         "shipping[address][city]": "San Francisco",
//         "shipping[address][state]": "CA",
//         "shipping[address][country]": "US",
//       };
//       var response = await http.post(
//           Uri.parse('https://api.stripe.com/v1/payment_intents'),
//           body: body,
//           headers: {
//             'Authorization': 'Bearer ${stripeData?.stripeSecret}',
//             //$_paymentIntentClientSecret',
//             'Content-Type': 'application/x-www-form-urlencoded'
//           });
//
//       return jsonDecode(response.body);
//     } catch (err) {
//       print('error charging user: ${err.toString()}');
//     }
//   }
//
//   calculateAmount(String amount) {
//     final a = ((double.parse(amount)) * 100).toInt();
//     print(a);
//     return a.toString();
//   }
//
//   ///PayPal payment function
//   // _makePaypalPayment({required amount}) async {
//   //   PayPalClientTokenGen.paypalClientToken(paypalSettingData: paypalSettingData!).then((value) async {
//   //     final String tokenizationKey = paypalSettingData!.braintreeTokenizationKey;
//   //
//   //     var request = BraintreePayPalRequest(amount: amount, currencyCode: currencyModel!.code, billingAgreementDescription: "djsghxghf", displayName: 'Grubb company');
//   //
//   //     BraintreePaymentMethodNonce? resultData;
//   //     try {
//   //       resultData = await Braintree.requestPaypalNonce(tokenizationKey, request);
//   //     } on Exception {
//   //       print("Stripe error");
//   //       showAlert(_scaffoldKey.currentContext!, response: "Something went wrong, please contact admin.".tr(), colors: Colors.red);
//   //     }
//   //     print(resultData?.nonce);
//   //     print(resultData?.paypalPayerId);
//   //     if (resultData?.nonce != null) {
//   //       PayPalClientTokenGen.paypalSettleAmount(
//   //         paypalSettingData: paypalSettingData!,
//   //         nonceFromTheClient: resultData?.nonce,
//   //         amount: amount,
//   //         deviceDataFromTheClient: resultData?.typeLabel,
//   //       ).then((value) {
//   //         print('payment done!!');
//   //         if (value['success'] == "true" || value['success'] == true) {
//   //           if (value['data']['success'] == "true" || value['data']['success'] == true) {
//   //             payPalSettel.PayPalClientSettleModel settleResult = payPalSettel.PayPalClientSettleModel.fromJson(value);
//   //
//   //             if (widget.takeAway!) {
//   //               placeOrder(_scaffoldKey.currentContext!);
//   //             } else {
//   //               toCheckOutScreen(true, _scaffoldKey.currentContext!);
//   //             }
//   //
//   //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//   //               content: Text(
//   //                 "Status : ${settleResult.data.transaction.status}\n"
//   //                 "Transaction id : ${settleResult.data.transaction.id}\n"
//   //                 "Amount : ${settleResult.data.transaction.amount}",
//   //               ),
//   //               duration: Duration(seconds: 8),
//   //               backgroundColor: Colors.green,
//   //             ));
//   //           } else {
//   //             payPalCurrModel.PayPalCurrencyCodeErrorModel settleResult = payPalCurrModel.PayPalCurrencyCodeErrorModel.fromJson(value);
//   //             Navigator.pop(_scaffoldKey.currentContext!);
//   //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//   //               content: Text("Status :".tr() + " ${settleResult.data.message}"),
//   //               duration: Duration(seconds: 8),
//   //               backgroundColor: Colors.red,
//   //             ));
//   //           }
//   //         } else {
//   //           PayPalErrorSettleModel settleResult = PayPalErrorSettleModel.fromJson(value);
//   //           Navigator.pop(_scaffoldKey.currentContext!);
//   //           ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
//   //             content: Text("Status :".tr() + " ${settleResult.data.message}"),
//   //             duration: Duration(seconds: 8),
//   //             backgroundColor: Colors.red,
//   //           ));
//   //         }
//   //       });
//   //     } else {
//   //       Navigator.pop(_scaffoldKey.currentContext!);
//   //       ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
//   //         content: Text("Status :".tr() + "Payment Unsuccessful!!".tr()),
//   //         duration: Duration(seconds: 8),
//   //         backgroundColor: Colors.red,
//   //       ));
//   //     }
//   //   });
//   // }
//
//   showLoadingAlert() {
//     return showDialog<void>(
//       context: _scaffoldKey.currentContext!,
//       useRootNavigator: true,
//       barrierDismissible: false, // user must tap button!
//       builder: (BuildContext context) {
//         return CupertinoAlertDialog(
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               CircularProgressIndicator(),
//               Text('Please wait!!'.tr()),
//             ],
//           ),
//           content: SingleChildScrollView(
//             child: ListBody(
//               children: <Widget>[
//                 SizedBox(
//                   height: 15,
//                 ),
//                 Text(
//                   'Please wait!! while completing Transaction'.tr(),
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 SizedBox(
//                   height: 15,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   ///Paytm payment function
//   getPaytmCheckSum(
//       context, {
//         required double amount,
//       }) async {
//     final String orderId = await UserPreference.getPaymentId();
//     String getChecksum = "${GlobalURL}payments/getpaytmchecksum";
//
//     final response = await http.post(
//         Uri.parse(
//           getChecksum,
//         ),
//         headers: {},
//         body: {
//           "mid": paytmSettingData?.paytmMID,
//           "order_id": orderId,
//           "key_secret": paytmSettingData?.paytmMerchantKey,
//         });
//
//     final data = jsonDecode(response.body);
//     await verifyCheckSum(
//         checkSum: data["code"], amount: amount, orderId: orderId)
//         .then((value) {
//       initiatePayment(amount: amount, orderId: orderId).then((value) {
//         GetPaymentTxtTokenModel result = value;
//         String callback = "";
//         if (paytmSettingData!.isSandboxEnabled) {
//           callback = callback +
//               "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
//         } else {
//           callback = callback +
//               "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
//         }
//
//         _startTransaction(context,
//             txnTokenBy: result.body.txnToken,
//             orderId: orderId,
//             amount: amount,
//             callBackURL: callback);
//       });
//     });
//   }
//
//   Future<void> _startTransaction(
//       context, {
//         required String txnTokenBy,
//         required orderId,
//         required double amount,
//         required callBackURL,
//       }) async {
//     try {
//       var response = AllInOneSdk.startTransaction(
//         paytmSettingData!.paytmMID,
//         orderId,
//         amount.toString(),
//         txnTokenBy,
//         callbackUrl,
//         //"https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId",
//         isStaging,
//         true,
//         enableAssist,
//       );
//
//       response.then((value) {
//         if (value!["RESPMSG"] == "Txn Success") {
//           print("txt done!!");
//           if (widget.takeAway!) {
//             placeOrder(_scaffoldKey.currentContext!);
//           } else {
//             toCheckOutScreen(true, context);
//           }
//           showAlert(context,
//               response: "Payment Successful!!".tr() + "\n ${value['RESPMSG']}",
//               colors: Colors.green);
//         }
//       }).catchError((onError) {
//         if (onError is PlatformException) {
//           print("======>>1");
//           Navigator.pop(_scaffoldKey.currentContext!);
//
//           print("Error124 : $onError");
//           result =
//               onError.message.toString() + " \n  " + onError.code.toString();
//           showAlert(_scaffoldKey.currentContext!,
//               response: onError.message.toString(), colors: Colors.red);
//         } else {
//           print("======>>2");
//
//           result = onError.toString();
//           Navigator.pop(_scaffoldKey.currentContext!);
//           showAlert(_scaffoldKey.currentContext!,
//               response: result, colors: Colors.red);
//         }
//       });
//     } catch (err) {
//       print("======>>3");
//       result = err.toString();
//       Navigator.pop(_scaffoldKey.currentContext!);
//       showAlert(_scaffoldKey.currentContext!,
//           response: result, colors: Colors.red);
//     }
//   }
//
//   Future verifyCheckSum(
//       {required String checkSum,
//         required double amount,
//         required orderId}) async {
//     String getChecksum = "${GlobalURL}payments/validatechecksum";
//     final response = await http.post(
//         Uri.parse(
//           getChecksum,
//         ),
//         headers: {},
//         body: {
//           "mid": paytmSettingData?.paytmMID,
//           "order_id": orderId,
//           "key_secret": paytmSettingData?.paytmMerchantKey,
//           "checksum_value": checkSum,
//         });
//     final data = jsonDecode(response.body);
//     print('here one');
//     print(checkSum);
//     print(data['status']);
//     return data['status'];
//   }
//
//   Future<GetPaymentTxtTokenModel> initiatePayment(
//       {required double amount, required orderId}) async {
//     String initiateURL = "${GlobalURL}payments/initiatepaytmpayment";
//     print('payment initiated now!@!');
//     String callback = "";
//     if (paytmSettingData!.isSandboxEnabled) {
//       callback = callback +
//           "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
//     } else {
//       callback = callback +
//           "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
//     }
//     final response =
//     await http.post(Uri.parse(initiateURL), headers: {}, body: {
//       "mid": paytmSettingData?.paytmMID,
//       "order_id": orderId,
//       "key_secret": paytmSettingData?.paytmMerchantKey.toString(),
//       "amount": amount.toString(),
//       "currency": currencyModel!.code,
//       "callback_url": callback,
//       "custId": MyAppState.currentUser!.userID,
//       "issandbox": paytmSettingData!.isSandboxEnabled ? "1" : "2",
//     });
//     print(response.body);
//     final data = jsonDecode(response.body);
//     print(data);
//     if (data["body"]["txnToken"] == null ||
//         data["body"]["txnToken"].toString().isEmpty) {
//       Navigator.pop(_scaffoldKey.currentContext!);
//       showAlert(_scaffoldKey.currentContext!,
//           response: "something went wrong, please contact admin.".tr(),
//           colors: Colors.red);
//     }
//     return GetPaymentTxtTokenModel.fromJson(data);
//   }
//
//   ///PayStack Payment Method
//   payStackPayment(BuildContext context) async {
//     await PayStackURLGen.payStackURLGen(
//       amount: (widget.total * 100).toString(),
//       currency: currencyModel!.code,
//       secretKey: payStackSettingData!.secretKey.toString(),
//     ).then((value) async {
//       if (value != null) {
//         PayStackUrlModel _payStackModel = value;
//         bool isDone = await Navigator.of(context).push(MaterialPageRoute(
//             builder: (context) => PayStackScreen(
//               secretKey: payStackSettingData!.secretKey.toString(),
//               callBackUrl: payStackSettingData!.callbackURL.toString(),
//               initialURl: _payStackModel.data.authorizationUrl,
//               amount: widget.total.toString(),
//               reference: _payStackModel.data.reference,
//             )));
//         //Navigator.pop(_globalKey.currentContext!);
//
//         if (isDone) {
//           if (widget.takeAway!) {
//             placeOrder(_scaffoldKey.currentContext!);
//           } else {
//             toCheckOutScreen(true, _scaffoldKey.currentContext!);
//           }
//           ScaffoldMessenger.of(_scaffoldKey.currentContext!)
//               .showSnackBar(SnackBar(
//             content: Text("Payment Successful!!".tr() + "\n"),
//             backgroundColor: Colors.green,
//           ));
//         } else {
//           Navigator.pop(_scaffoldKey.currentContext!);
//           ScaffoldMessenger.of(_scaffoldKey.currentContext!)
//               .showSnackBar(SnackBar(
//             content: Text("Payment Unsuccessful!!".tr() + "\n"),
//             backgroundColor: Colors.red,
//           ));
//         }
//       } else {
//         Navigator.pop(_scaffoldKey.currentContext!);
//         showAlert(_scaffoldKey.currentContext!,
//             response: "something went wrong, please contact admin.".tr(),
//             colors: Colors.red);
//       }
//     });
//   }
//
//   ///MercadoPago Payment Method
//
//   mercadoPagoMakePayment() {
//     makePreference().then((result) async {
//       if (result.isNotEmpty) {
//         var preferenceId = result['response']['id'];
//         print(result['response']['init_point']);
//
//         final bool isDone = await Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => MercadoPagoScreen(
//                     initialURl: result['response']['init_point'])));
//         print(isDone);
//         print(result.toString());
//         print(preferenceId);
//
//         if (isDone) {
//           if (widget.takeAway!) {
//             placeOrder(_scaffoldKey.currentContext!);
//           } else {
//             toCheckOutScreen(true, _scaffoldKey.currentContext!);
//           }
//           ScaffoldMessenger.of(_scaffoldKey.currentContext!)
//               .showSnackBar(SnackBar(
//             content: Text("Payment Successful!!".tr() + "\n"),
//             backgroundColor: Colors.green,
//           ));
//         } else {
//           Navigator.pop(_scaffoldKey.currentContext!);
//           ScaffoldMessenger.of(_scaffoldKey.currentContext!)
//               .showSnackBar(SnackBar(
//             content: Text("Payment Unsuccessful!!".tr() + "\n"),
//             backgroundColor: Colors.red,
//           ));
//         }
//       } else {
//         hideProgress();
//
//         ScaffoldMessenger.of(_scaffoldKey.currentContext!)
//             .showSnackBar(SnackBar(
//           content: Text("Error while transaction!".tr() + "\n"),
//           backgroundColor: Colors.red,
//         ));
//       }
//     });
//   }
//
//   Future<Map<String, dynamic>> makePreference() async {
//     final mp = MP.fromAccessToken(mercadoPagoSettingData!.accessToken);
//     var pref = {
//       "items": [
//         {
//           "title": "Wallet TopUp",
//           "quantity": 1,
//           "unit_price": double.parse(widget.total.toString().trim())
//         }
//       ],
//       "auto_return": "all",
//       "back_urls": {
//         "failure": "${GlobalURL}payment/failure",
//         "pending": "${GlobalURL}payment/pending",
//         "success": "${GlobalURL}payment/success"
//       },
//     };
//
//     var result = await mp.createPreference(pref);
//     return result;
//   }
//
//   ///FlutterWave Payment Method
//   String? _ref;
//
//   setRef() {
//     Random numRef = Random();
//     int year = DateTime.now().year;
//     int refNumber = numRef.nextInt(20000);
//     if (Platform.isAndroid) {
//       setState(() {
//         _ref = "AndroidRef$year$refNumber";
//       });
//     } else if (Platform.isIOS) {
//       setState(() {
//         _ref = "IOSRef$year$refNumber";
//       });
//     }
//   }
//
//   _flutterWaveInitiatePayment(
//       BuildContext context,
//       ) async {
//     // final style = FlutterwaveStyle(
//     //   appBarText: "Grubb",
//     //   buttonColor: Color(COLOR_PRIMARY),
//     //   buttonTextStyle: TextStyle(
//     //     color: Colors.white,
//     //     fontSize: 20,
//     //   ),
//     //   appBarColor: Color(COLOR_PRIMARY),
//     //   dialogCancelTextStyle: TextStyle(
//     //     color: Colors.black,
//     //     fontSize: 18,
//     //   ),
//     //   dialogContinueTextStyle: TextStyle(
//     //     color: Color(COLOR_PRIMARY),
//     //     fontSize: 18,
//     //   ),
//     //   mainTextStyle:
//     //       TextStyle(color: Colors.black, fontSize: 19, letterSpacing: 2),
//     //   dialogBackgroundColor: Colors.white,
//     //   appBarTitleTextStyle: TextStyle(
//     //     color: Colors.white,
//     //     fontSize: 18,
//     //   ),
//     // );
//     final flutterwave = Flutterwave(
//       amount: widget.total.toString().trim(),
//       currency: currencyModel!.code,
//       // style: style,
//       customer: Customer(
//           name: MyAppState.currentUser!.firstName,
//           phoneNumber: MyAppState.currentUser!.phoneNumber.trim(),
//           email: MyAppState.currentUser!.email.trim()),
//       context: context,
//       publicKey: flutterWaveSettingData!.publicKey.trim(),
//       paymentOptions: "card, payattitude",
//       customization: Customization(title: "Grubb"),
//       txRef: _ref!,
//       isTestMode: flutterWaveSettingData!.isSandbox,
//       redirectUrl: '${GlobalURL}success',
//     );
//     final ChargeResponse response = await flutterwave.charge();
//     if (response.success!) {
//       ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
//         content: Text("Payment Successful!!".tr() + "\n"),
//         backgroundColor: Colors.green,
//       ));
//       if (widget.takeAway!) {
//         placeOrder(_scaffoldKey.currentContext!);
//       } else {
//         toCheckOutScreen(true, _scaffoldKey.currentContext!);
//       }
//     } else {
//       this.showLoading(message: response.status!);
//     }
//     print("${response.toJson()}");
//   }
//
//   Future<void> showLoading(
//       {required String message, Color txtColor = Colors.black}) {
//     return showDialog(
//       context: this.context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           content: Container(
//             margin: EdgeInsets.fromLTRB(30, 20, 30, 20),
//             width: double.infinity,
//             height: 30,
//             child: Text(
//               message,
//               style: TextStyle(color: txtColor),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   placeOrder(BuildContext buildContext, {String? oid}) async {
//     double pricenew=0.0;
//     FireStoreUtils fireStoreUtils = FireStoreUtils();
//     List<CartProduct> tempProduc = [];
//     List<CartProduct> admincommssionproducts = [];
//     if (paymentType.isEmpty) {
//       ShowDialogToDismiss(
//           title: "Empty payment type".tr(),
//           buttonText: "ok".tr(),
//           content: "Select payment type".tr());
//       return;
//     }
//     if(widget.auto_apply==true&&widget.cityaveche==true&&widget.isMyTime==true){
//       for (CartProduct cartProduct in widget.products) {
//         pricenew =double.parse(cartProduct.price) *
//             widget.autoapplydiscount/
//             100;
//         double originalPrice = double.parse(cartProduct.price);
//         // print("originalPriceoriginalPrice${originalPrice}");
//         originalPrice =double.parse(cartProduct.price) - pricenew;
//         // price અપડેટ કરી નવી instance બનાવો
//         print("chak chak chak chak ${originalPrice}");
//         CartProduct tempCart = CartProduct(
//           id: cartProduct.id,
//           category_id: cartProduct.category_id,
//           name: cartProduct.name,
//           photo: cartProduct.photo,
//           price:  originalPrice.toString(), // નવી કિંમત મૂકો
//           discountPrice: cartProduct.discountPrice,
//           item: cartProduct.item,
//           groceryUnit: cartProduct.groceryUnit,
//           groceryWeight: cartProduct.groceryWeight,
//           vendorID: cartProduct.vendorID,
//           quantity: cartProduct.quantity,
//           extras_price: cartProduct.extras_price,
//           extras: cartProduct.extras,
//           variant_info: cartProduct.variant_info,
//           packingcharges: cartProduct.packingcharges,
//         );
//
//         tempProduc.add(tempCart); // અપડેટ થયેલા tempCart ને લિસ્ટમાં એડ કરો
//         print("Updated tempCart: $tempCart");
//       }
//     }else{
//       for (CartProduct cartProduct in widget.products) {
//         CartProduct tempCart = cartProduct;
//         tempProduc.add(tempCart);
//         print("tempCarttempCarttempCarttempCart${tempCart.price}");
//       }
//     }
//     for (CartProduct cartProduct in widget.products) {
//       CartProduct tempCart1 = cartProduct;
//       admincommssionproducts.add(tempCart1);
//       print("tempCarttempCarttempCarttempCart${tempCart1.price}");
//     }
//     //place order
//     showProgress(buildContext, 'Placing Order...'.tr(), false);
//     VendorModel vendorModel = await fireStoreUtils
//         .getVendorByVendorID(widget.products.first.vendorID)
//         .whenComplete(() => setPrefData());
//     OrderModel orderModel = OrderModel(
//       address: MyAppState.currentUser!.shippingAddress,
//       author: MyAppState.currentUser,
//       authorID: MyAppState.currentUser!.userID,
//       createdAt: Timestamp.now(),
//       products: tempProduc,
//       admincommssionproducts: admincommssionproducts,
//       status: ORDER_STATUS_PLACED,
//       vendor: vendorModel,
//       paymentMethod: paymentType,
//       notes: widget.notes,
//       taxModel: widget.taxModel,
//       vendorID: widget.products.first.vendorID,
//       discount: widget.discount,
//       specialDiscount: widget.specialDiscountMap,
//       couponCode: widget.couponCode,
//       couponId: widget.couponId,
//       customAdminCommission:widget.isMyTime==true&&widget.cityaveche==true&&widget.auto_apply==true?false:vendorModel.customAdminCommission ,
//       customAdminCommissionType:vendorModel.customAdminCommissionType ,
//       customAdminCommissionValue: vendorModel.customAdminCommissionValue,
//       adminCommission: widget.groceryitem == "grocery"
//           ? grocerycommissionfix
//           : isEnableAdminCommission!
//           ? adminCommissionValue
//           : "0",
//       admindiscountbyadmincommssiontype:isEnableAdminCommission! ? addminCommissionType:"",
//       admindiscountbyadmincommssion: widget.groceryitem == "grocery"
//           ? grocerycommissionfix1.toString()
//           :adminCommissionValue1.toString(),
//       adminCommissionType: jumpnam==true?"Fixed":isEnableAdminCommission! ? addminCommissionType : "",
//       takeAway: true,
//       scheduleTime: widget.scheduleTime,
//     );
//
//     if (oid != null && oid.isNotEmpty) {
//       orderModel.id = oid;
//     }
//
//     OrderModel placedOrder =
//     await fireStoreUtils.placeOrderWithTakeAWay(orderModel);
//     print("||||{}" + orderModel.toJson().toString());
//     for (int i = 0; i < tempProduc.length; i++) {
//       await FireStoreUtils()
//           .getProductByID(tempProduc[i].id.split('~').first)
//           .then((value) async {
//         ProductModel? productModel = value;
//         if (tempProduc[i].variant_info != null) {
//           for (int j = 0;
//           j < productModel.itemAttributes!.variants!.length;
//           j++) {
//             if (productModel.itemAttributes!.variants![j].variantId ==
//                 tempProduc[i].id.split('~').last) {
//               if (productModel.itemAttributes!.variants![j].variantQuantity !=
//                   "-1") {
//                 productModel.itemAttributes!.variants![j].variantQuantity =
//                     (int.parse(productModel
//                         .itemAttributes!.variants![j].variantQuantity
//                         .toString()) -
//                         tempProduc[i].quantity)
//                         .toString();
//               }
//             }
//           }
//         } else {
//           if (productModel.quantity != -1) {
//             productModel.quantity =
//                 productModel.quantity - tempProduc[i].quantity;
//           }
//         }
//
//         await FireStoreUtils.updateProduct(productModel).then((value) {});
//       });
//     }
//
//     hideProgress();
//     print('_CheckoutScreenState.placeOrder ${placedOrder.id}');
//     showModalBottomSheet(
//       isScrollControlled: true,
//       isDismissible: false,
//       context: buildContext,
//       enableDrag: false,
//       backgroundColor: Colors.transparent,
//       builder: (context) => PlaceOrderScreen(
//         orderModel: placedOrder,
//         couponid: widget.couponId,
//       ),
//     );
//   }
//
//   Future<void> setPrefData() async {
//     SharedPreferences sp = await SharedPreferences.getInstance();
//     sp.setString("musics_key", "");
//   }
//
//   toCheckOutScreen(bool val, BuildContext context) {
//     push(
//       context,
//       CheckoutScreen(
//         isMyTime: widget.isMyTime,
//         cityaveche: widget.cityaveche,
//         auto_apply: widget.auto_apply,
//         autoapplydiscount: num.parse(widget.autoapplydiscount.toString()),
//         isPaymentDone: val,
//         razorpayorderid: ordercretedrazorpaymodal?.id ?? "",
//         paymentType: this.paymentType,
//         total: widget.total,
//         groceryitem: widget.groceryitem,
//         chargepaking: widget.chargepacking,
//         discount: widget.discount!,
//         couponCode: widget.couponCode!,
//         couponId: widget.couponId!,
//         couponId1: widget.couponId1,
//         notes: widget.notes!,
//         paymentOption: paymentOption,
//         products: widget.products,
//         deliveryCharge: widget.deliveryCharge,
//         tipValue: widget.tipValue,
//         takeAway: widget.takeAway,
//         taxModel: widget.taxModel,
//         specialDiscountMap: widget.specialDiscountMap,
//         scheduleTime: widget.scheduleTime,
//       ),
//     );
//   }
// }
