import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/OrderModel.dart';
import 'package:foodie_customer/model/ProductModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/cartScreen/CartScreen.dart';
import 'package:foodie_customer/ui/container/ContainerScreen.dart';
import 'package:foodie_customer/ui/placeOrderScreen/PlaceOrderScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/TaxModel.dart';
import '../../model/mail_setting.dart';

class CheckoutScreen extends StatefulWidget {
  final String paymentOption, paymentType;
  final String razorpayorderid;
  final double total;
  final double? discount;
  final num? autoapplydiscount;
  final String? couponCode;
  final String? groceryitem;
  final String? chargepaking;
  final String? couponId, notes;
  final String? couponId1;

  final List<CartProduct> products;
  final List<String>? extraAddons;
  final String? tipValue;
  final bool? takeAway;
  final bool? auto_apply;
  final bool? isMyTime;
  final bool? cityaveche;
  final String? deliveryCharge;
  final String? size;
  final bool isPaymentDone;
  final List<TaxModel>? taxModel;
  final Map<String, dynamic>? specialDiscountMap;
  final Timestamp? scheduleTime;

  const CheckoutScreen({
    Key? key,
    required this.isPaymentDone,
    required this.paymentOption,
    required this.razorpayorderid,
    required this.paymentType,
    required this.groceryitem,
    required this.total,
    required this.couponId1,
    required this.autoapplydiscount,
    required this.auto_apply,
    required this.cityaveche,
    required this.isMyTime,
    this.discount,
    this.couponCode,
    this.chargepaking,
    this.couponId,
    this.notes,
    required this.products,
    this.extraAddons,
    this.tipValue,
    this.takeAway,
    this.deliveryCharge,
    this.taxModel,
    this.specialDiscountMap,
    this.size,
    this.scheduleTime,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final fireStoreUtils = FireStoreUtils();
  late Map<String, dynamic>? adminCommission;
  String? adminCommissionValue = "", addminCommissionType = "";
  num? autoApplyFixCommission;
  num? adminCommissionValue1;
  bool? isEnableAdminCommission = false;
  String collectionid = '';
  DateTime now = DateTime.now();
  String? formattedDate;

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

  String? grocerycommissionfix = "";
  num? grocerycommissionfix1;
  bool jumpnam = false;
  num totalfaydo = 0;

  getvendor() async {
    VendorModel vendorModel = await fireStoreUtils.getVendorByVendorID(
      widget.products.first.vendorID,
    );
    if (widget.auto_apply == true &&
        widget.cityaveche == true &&
        widget.isMyTime == true) {
      for (CartProduct cartProduct in widget.products) {
        // price અપડેટ કરી નવી instance બનાવો
        pricenew =
            double.parse(cartProduct.price) *
            num.parse(widget.autoapplydiscount.toString()) /
            100;
        if (vendorModel.freeDelivery == true) {
          setState(() {
            totalfaydo +=
                pricenew + num.parse(widget.deliveryCharge.toString()) + 20;
            print("delivery free hoy tayare shu ave che ${totalfaydo}");
            print(
              "delivery free hoy tayare shu ave che ${widget.deliveryCharge.toString()}",
            );
          });
        } else {
          setState(() {
            totalfaydo += pricenew + 20;
          });
        }

        print("totalfaydototalfaydo====>>>>${totalfaydo}");
        print("pricenewpricenew==========???????????${pricenew}");
        double originalPrice = double.parse(cartProduct.price);
        // print("originalPriceoriginalPrice${originalPrice}");
        originalPrice = double.parse(cartProduct.price) - pricenew;
        // price અપડેટ કરી નવી instance બનાવો
        print("chak chak chak chak ${originalPrice}");
        placeAutoOrder();
      }
    } else {
      placeAutoOrder();
    }
  }

  @override
  void initState() {
    super.initState();
    getvendor();

    setState(() {
      formattedDate = "${now.day}/${now.month}/${now.year}";
    });
    initializeFlutterFire();
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
        //     widget.cityaveche == true &&
        //     widget.isMyTime == true) {
        //   if (widget.groceryitem == "grocery") {
        //     if (grocerycommissionfix1 == widget.autoapplydiscount) {
        //       setState(() {
        //         grocerycommissionfix = "0";
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

  placeAutoOrder() {
    if (widget.isPaymentDone) {
      Future.delayed(Duration(microseconds: 1), () {
        placeOrder();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode(context) ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Checkout'.tr(),
              style: TextStyle(
                fontSize: 24,
                color:
                    isDarkMode(context)
                        ? Colors.grey.shade300
                        : Colors.grey.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Container(
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                  child: ListTile(
                    leading: Text(
                      'Payment'.tr(),
                      style: TextStyle(
                        color: Color(COLOR_PRIMARY),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    trailing: Text(
                      widget.paymentOption,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Divider(height: 3),
                Container(
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deliver to'.tr(),
                          style: TextStyle(
                            color: Color(COLOR_PRIMARY),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Text(
                            '${MyAppState.currentUser!.shippingAddress.line1} ${MyAppState.currentUser!.shippingAddress.line2}',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 3),
                Container(
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                  child: ListTile(
                    leading: Text(
                      'Total'.tr(),
                      style: TextStyle(
                        color: Color(COLOR_PRIMARY),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    trailing: Text(
                      amountShow(amount: widget.total.toString()),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                widget.auto_apply == true &&
                        widget.cityaveche == true &&
                        widget.isMyTime == true
                    ? Divider(height: 3)
                    : Container(),
                widget.auto_apply == true &&
                        widget.cityaveche == true &&
                        widget.isMyTime == true
                    ? Container(
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                      child: ListTile(
                        leading: Text(
                          'You Save On This Order'.tr(),
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        trailing: Text(
                          amountShow(amount: totalfaydo.toString()),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    )
                    : Container(),
              ],
              shrinkWrap: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                backgroundColor: Color(COLOR_PRIMARY),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (!widget.isPaymentDone) {
                  Future.delayed(Duration(microseconds: 1), () {
                    placeOrder();
                  });
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Visibility(
                    visible: widget.isPaymentDone,
                    child: SizedBox(
                      height: 25,
                      width: 25,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'PLACE ORDER'.tr(),
                    style: TextStyle(
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: ElevatedButton(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Visibility(
                  //     visible: widget.isPaymentDone,
                  //     child: SizedBox(
                  //         height: 25,
                  //         width: 25,
                  //         child: CircularProgressIndicator(
                  //           color: Colors.white,
                  //         ))),
                  // SizedBox(
                  //   width: 10,
                  // ),
                  Text(
                    'Back To Cart'.tr(),
                    style: TextStyle(
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> setPrefData() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString("musics_key", "");
    sp.setString("addsize", "");
  }

  // placeOrder() async {
  //   List<CartProduct> tempProduc = [];
  //
  //   for (CartProduct cartProduct in widget.products) {
  //     CartProduct tempCart = cartProduct;
  //     tempProduc.add(tempCart);
  //   }
  //   FireStoreUtils fireStoreUtils = FireStoreUtils();
  //   //place order
  //   showProgress(context, 'Placing Order...'.tr(), false);
  //   VendorModel vendorModel = await fireStoreUtils.getVendorByVendorID(widget.products.first.vendorID).whenComplete(() => setPrefData());
  //   log(vendorModel.fcmToken.toString() + "{}{}{}{======TOKENADD" + vendorModel.toJson().toString());
  //   OrderModel orderModel = OrderModel(
  //       address: MyAppState.currentUser!.shippingAddress,
  //       author: MyAppState.currentUser,
  //       authorID: MyAppState.currentUser!.userID,
  //       createdAt: Timestamp.now(),
  //       products: tempProduc,
  //       status: ORDER_STATUS_PLACED,
  //       vendor: vendorModel,
  //       vendorID: widget.products.first.vendorID,
  //       discount: widget.discount,
  //       couponCode: widget.couponCode,
  //       couponId: widget.couponId,
  //       notes: widget.notes,
  //       taxModel: widget.taxModel,
  //       paymentMethod: widget.paymentType,
  //       specialDiscount: widget.specialDiscountMap,
  //       tipValue: widget.tipValue,
  //       adminCommission: isEnableAdminCommission! ? adminCommissionValue : "0",
  //       adminCommissionType: isEnableAdminCommission! ? addminCommissionType : "",
  //       takeAway: widget.takeAway,
  //       deliveryCharge: widget.deliveryCharge,
  //       scheduleTime: widget.scheduleTime);
  //
  //   OrderModel placedOrder = await fireStoreUtils.placeOrder(orderModel);
  //   for (int i = 0; i < tempProduc.length; i++) {
  //     await FireStoreUtils().getProductByID(tempProduc[i].id.split('~').first).then((value) async {
  //       ProductModel? productModel = value;
  //       log("-----------1>${value.toJson()}");
  //       if (tempProduc[i].variant_info != null) {
  //         for (int j = 0; j < productModel.itemAttributes!.variants!.length; j++) {
  //           if (productModel.itemAttributes!.variants![j].variantId == tempProduc[i].id.split('~').last) {
  //             if (productModel.itemAttributes!.variants![j].variantQuantity != "-1") {
  //               productModel.itemAttributes!.variants![j].variantQuantity = (int.parse(productModel.itemAttributes!.variants![j].variantQuantity.toString()) - tempProduc[i].quantity).toString();
  //             }
  //           }
  //         }
  //       } else {
  //         if (productModel.quantity != -1) {
  //           productModel.quantity = productModel.quantity - tempProduc[i].quantity;
  //         }
  //       }
  //
  //       await FireStoreUtils.updateProduct(productModel).then((value) {
  //         log("-----------2>${value!.toJson()}");
  //       });
  //     });
  //   }
  //
  //   hideProgress();
  //   showModalBottomSheet(
  //     isScrollControlled: true,
  //     isDismissible: false,
  //     context: context,
  //     enableDrag: false,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => PlaceOrderScreen(orderModel: placedOrder),
  //   );
  // }
  double pricenew = 0.0;

  placeOrder() async {
    List<CartProduct> tempProduc = [];
    List<CartProduct> admincommssionproducts = [];

    for (CartProduct cartProduct in widget.products) {
      CartProduct tempCart1 = cartProduct;
      print("tempCarttempCart${tempCart1}");
      admincommssionproducts.add(tempCart1);
    }
    if (widget.auto_apply == true &&
        widget.cityaveche == true &&
        widget.isMyTime == true) {
      for (CartProduct cartProduct in widget.products) {
        // price અપડેટ કરી નવી instance બનાવો
        pricenew =
            double.parse(cartProduct.price) *
            num.parse(widget.autoapplydiscount.toString()) /
            100;
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
        // price અપડેટ કરી નવી instance બનાવો
        CartProduct tempCart = CartProduct(
          id: cartProduct.id,
          category_id: cartProduct.category_id,
          name: cartProduct.name,
          photo: cartProduct.photo,
          price: cartProduct.price,
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

        tempProduc.add(tempCart);
        print("Updated tempCart: $tempCart");
      }
    }

    FireStoreUtils fireStoreUtils = FireStoreUtils();

    showProgress(context, 'Placing Order...'.tr(), false);

    try {
      VendorModel vendorModel = await fireStoreUtils.getVendorByVendorID(
        widget.products.first.vendorID,
      );
      print("vendorModel?.dfdsfsdf${vendorModel?.speedCashId ?? ""}");
      print("vendorModel?.dfdsfsdf${vendorModel.customAdminCommission}");
      print("vendorModel?.dfdsfsdf${vendorModel.customAdminCommissionType}");
      print("vendorModel?.dfdsfsdf${vendorModel.customAdminCommissionValue}");
      OrderModel orderModel = OrderModel(
        razorpayorderid: widget.razorpayorderid,
        address: MyAppState.currentUser!.shippingAddress,
        author: MyAppState.currentUser,
        authorID: MyAppState.currentUser!.userID,
        createdAt: Timestamp.now(),
        products: tempProduc,
        admincommssionproducts: admincommssionproducts,
        status: ORDER_STATUS_PLACED,
        item: widget.groceryitem,
        vendor: vendorModel,
        vendorID: widget.products.first.vendorID,
        discount: widget.discount,
        couponCode: widget.couponCode,
        couponId: widget.couponId,
        notes: widget.notes,
        taxModel: widget.taxModel,
        paymentMethod: widget.paymentType,
        specialDiscount: widget.specialDiscountMap,
        tipValue: widget.tipValue,
        freeDelivery: vendorModel.freeDelivery,
        customAdminCommission:
            // widget.auto_apply == true &&
            //         widget.cityaveche == true &&
            //         widget.isMyTime == true
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
        takeAway: widget.takeAway,
        deliveryCharge: widget.deliveryCharge,
        packingcharges: widget.chargepaking,
        scheduleTime: widget.scheduleTime,
      );

      print("widget.products:-${orderModel.products[0].quantity}");
      print("widget.deliveryCharge:-${widget.deliveryCharge}");
      OrderModel placedOrder = await fireStoreUtils.placeOrder(orderModel);

      for (int i = 0; i < tempProduc.length; i++) {
        ProductModel? productModel = await fireStoreUtils.getProductByID(
          tempProduc[i].id.split('~').first,
        );

        if (productModel != null) {
          if (tempProduc[i].variant_info != null) {
            for (
              int j = 0;
              j < productModel.itemAttributes!.variants!.length;
              j++
            ) {
              if (productModel.itemAttributes!.variants![j].variantId ==
                  tempProduc[i].id.split('~').last) {
                if (productModel.itemAttributes!.variants![j].variantQuantity !=
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

          await FireStoreUtils.updateProduct(productModel);
        }
      }

      hideProgress();
      print("placedOrder : ${placedOrder.products.length}");
      print("placedOrder :${orderModel?.id ?? ""}");
      print("razorpay order id :${orderModel?.razorpayorderid ?? ""}");
      print(" widget.couponId Chekout: -${widget.couponId}");

      // showModalBottomSheet(
      //
      //   isScrollControlled: true,
      //   isDismissible: false,
      //   context: context,
      //   enableDrag: false,
      //   backgroundColor: Colors.transparent,
      //   builder:
      //       (context) => PlaceOrderScreen(
      //         orderModel: placedOrder,
      //         couponid: widget.couponId1,
      //       ),
      // );
      Future.microtask(() {
        showModalBottomSheet(
          isScrollControlled: true,
          isDismissible: false,
          context: context,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (context) => PlaceOrderScreen(
            orderModel: placedOrder,
            couponid: widget.couponId1,
          ),
        );
      });

    } catch (e) {
      // Handle any errors that occur during the process
      print(e);
      hideProgress();
    }
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
// FirebaseFirestore.instance
//     .collection("coupon_used")
// .doc(collectionid)
//     .set({
// 'id': collectionid,
// 'coupon_id': widget.couponId,
// 'user_id': MyAppState.currentUser ?? "",
// 'use_date': formattedDate,
// }).then((value) {
// final snackBar = SnackBar(
// backgroundColor:
// !isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
// content: Text(
// 'Address Added Successfully',
// style: TextStyle(
// color: !isDarkMode(context) ? Colors.black : Colors.white),
// ),
// );
// ScaffoldMessenger.of(context).showSnackBar(snackBar);
// print("Address Added");
//
// }).catchError((error) {
// print("Failed to add address: $error");
//
// });

/// old code
// import 'dart:math';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:foodie_customer/constants.dart';
// import 'package:foodie_customer/main.dart';
// import 'package:foodie_customer/model/OrderModel.dart';
// import 'package:foodie_customer/model/ProductModel.dart';
// import 'package:foodie_customer/model/VendorModel.dart';
// import 'package:foodie_customer/services/FirebaseHelper.dart';
// import 'package:foodie_customer/services/helper.dart';
// import 'package:foodie_customer/services/localDatabase.dart';
// import 'package:foodie_customer/ui/cartScreen/CartScreen.dart';
// import 'package:foodie_customer/ui/container/ContainerScreen.dart';
// import 'package:foodie_customer/ui/placeOrderScreen/PlaceOrderScreen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../model/TaxModel.dart';
// import '../../model/mail_setting.dart';
//
// class CheckoutScreen extends StatefulWidget {
//   final String paymentOption, paymentType;
//   final String razorpayorderid;
//   final double total;
//   final double? discount;
//   final num? autoapplydiscount;
//   final String? couponCode;
//   final String? groceryitem;
//   final String? chargepaking;
//   final String? couponId, notes;
//   final String? couponId1;
//
//   final List<CartProduct> products;
//   final List<String>? extraAddons;
//   final String? tipValue;
//   final bool? takeAway;
//   final bool? auto_apply;
//   final bool? isMyTime;
//   final bool? cityaveche;
//   final String? deliveryCharge;
//   final String? size;
//   final bool isPaymentDone;
//   final List<TaxModel>? taxModel;
//   final Map<String, dynamic>? specialDiscountMap;
//   final Timestamp? scheduleTime;
//
//   const CheckoutScreen(
//       {Key? key,
//       required this.isPaymentDone,
//       required this.paymentOption,
//       required this.razorpayorderid,
//       required this.paymentType,
//       required this.groceryitem,
//       required this.total,
//       required this.couponId1,
//       required this.autoapplydiscount,
//       required this.auto_apply,
//       required this.cityaveche,
//       required this.isMyTime,
//       this.discount,
//
//       this.couponCode,
//       this.chargepaking,
//       this.couponId,
//       this.notes,
//       required this.products,
//       this.extraAddons,
//       this.tipValue,
//       this.takeAway,
//
//       this.deliveryCharge,
//       this.taxModel,
//       this.specialDiscountMap,
//       this.size,
//       this.scheduleTime})
//       : super(key: key);
//
//   @override
//   _CheckoutScreenState createState() => _CheckoutScreenState();
// }
//
// class _CheckoutScreenState extends State<CheckoutScreen> {
//   final fireStoreUtils = FireStoreUtils();
//   late Map<String, dynamic>? adminCommission;
//   String? adminCommissionValue = "",
//       addminCommissionType = "";
//   num? autoApplyFixCommission;
//   num? adminCommissionValue1;
//   bool? isEnableAdminCommission = false;
//   String collectionid = '';
//   DateTime now = DateTime.now();
//   String? formattedDate;
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
//   String? grocerycommissionfix = "";
//   num? grocerycommissionfix1;
// bool jumpnam=false;
//   @override
//   void initState() {
//     super.initState();
//     placeAutoOrder();
//     print("widget.couponId1${widget.couponId1}");
//     print("Checkout screen shu ave che widget.auto_apply${widget.auto_apply==true&&widget.cityaveche==true&&widget.isMyTime==true}");
//     print("Checkout screen shu ave che widget.auto_apply${widget.autoapplydiscount}");
//     setState(() {
//       formattedDate = "${now.day}/${now.month}/${now.year}";
//     });
//     initializeFlutterFire();
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
//               adminCommission!["autoApplyFixCommission"];
//           isEnableAdminCommission = adminCommission!["isAdminCommission"];
//           grocerycommissionfix =
//               adminCommission!["grocerycommissionfix"].toString();
//         });
//        if(widget.auto_apply==true&&widget.cityaveche==true&&widget.isMyTime==true){
//          if(widget.groceryitem == "grocery"){
//            if(grocerycommissionfix1==widget.autoapplydiscount){
//              setState(() {
//                grocerycommissionfix=autoApplyFixCommission.toString();
//              });
//              print("widget.groceryitem == ${grocerycommissionfix}");
//            }else{
//              if(grocerycommissionfix1==0&&grocerycommissionfix=="0"){
//                setState(() {
//                  grocerycommissionfix =  widget.autoapplydiscount.toString();
//                  print("grocerycommissionfix1 00000.00000000000 ${grocerycommissionfix}");
//                });
//              }else{
//                setState(() {
//                  grocerycommissionfix = (double.parse(grocerycommissionfix1.toString()) - double.parse(widget.autoapplydiscount.toString())).abs().toStringAsFixed(2);
//
//                  print("else ave che jayare grocery hoy tayare ${grocerycommissionfix}");
//
//                });
//              }
//
//            }
//          }
//          if(adminCommissionValue1==widget.autoapplydiscount){
//            setState(() {
//              adminCommissionValue = autoApplyFixCommission.toString();
//              jumpnam=true;
//            });
//            print("adminCommissionValue>>>>>>>value shu ave che ${adminCommissionValue}");
//          }else{
//            setState(() {
//              adminCommissionValue = (double.parse(adminCommissionValue1.toString()) - double.parse(widget.autoapplydiscount.toString())).abs().toStringAsFixed(2);
//
//              print("else vendor commssion shu ave che  ${adminCommissionValue}");
//
//            });
//          }
//        }
//        print("grocerycommissionfixgrocerycommissionfixgrocerycommissionfix${adminCommissionValue1}");
//        print("grocerycommissionfixgrocerycommissionfixgrocerycommissionfix${grocerycommissionfix}");
//        print("grocerycommissionfixgrocerycommissionfixgrocerycommissionfix${grocerycommissionfix1}");
//        print("grocerycommissionfixgrocerycommissionfixgrocerycommissionfix${addminCommissionType}");
//        print("adminCommissionValue>>>>>>>>>>>>>>>${adminCommissionValue}");
//        print("adminCommissionValue>>>>>>>>>>>>>>>${autoApplyFixCommission}");
//        print("adminCommissionValue>>>>>>>>>>>>>>>${isEnableAdminCommission}");
//       }
//     });
//   }
//
//   placeAutoOrder() {
//     if (widget.isPaymentDone) {
//       Future.delayed(Duration(microseconds: 1), () {
//         placeOrder();
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:
//           isDarkMode(context) ? Colors.grey.shade900 : Colors.grey.shade50,
//       appBar: AppBar(),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Text(
//               'Checkout'.tr(),
//               style: TextStyle(
//                   fontSize: 24,
//                   color: isDarkMode(context)
//                       ? Colors.grey.shade300
//                       : Colors.grey.shade800,
//                   fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               children: [
//                 Container(
//                   color: isDarkMode(context) ? Colors.black : Colors.white,
//                   child: ListTile(
//                     leading: Text(
//                       'Payment'.tr(),
//                       style: TextStyle(
//                           color: Color(COLOR_PRIMARY),
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18),
//                     ),
//                     trailing: Text(
//                       widget.paymentOption,
//                       style:
//                           TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//                     ),
//                   ),
//                 ),
//                 Divider(
//                   height: 3,
//                 ),
//                 Container(
//                   color: isDarkMode(context) ? Colors.black : Colors.white,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Deliver to'.tr(),
//                           style: TextStyle(
//                               color: Color(COLOR_PRIMARY),
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18),
//                         ),
//                         Container(
//                           width: MediaQuery.of(context).size.width / 2,
//                           child: Text(
//                             '${MyAppState.currentUser!.shippingAddress.line1} ${MyAppState.currentUser!.shippingAddress.line2}',
//                             textAlign: TextAlign.end,
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold, fontSize: 18),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Divider(
//                   height: 3,
//                 ),
//                 Container(
//                   color: isDarkMode(context) ? Colors.black : Colors.white,
//                   child: ListTile(
//                     leading: Text(
//                       'Total'.tr(),
//                       style: TextStyle(
//                           color: Color(COLOR_PRIMARY),
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18),
//                     ),
//                     trailing: Text(
//                       amountShow(amount: widget.total.toString()),
//                       style:
//                           TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//                     ),
//                   ),
//                 ),
//               ],
//               shrinkWrap: true,
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(22.0),
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.all(20),
//                 backgroundColor: Color(COLOR_PRIMARY),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () {
//                 if (!widget.isPaymentDone) {
//                   Future.delayed(Duration(microseconds: 1), () {
//                     placeOrder();
//                   });
//                 }
//
//               },
//               child:Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Visibility(
//                       visible: widget.isPaymentDone,
//                       child: SizedBox(
//                           height: 25,
//                           width: 25,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                           ))),
//                   SizedBox(
//                     width: 10,
//                   ),
//                   Text(
//                     'PLACE ORDER'.tr(),
//                     style: TextStyle(
//                         color:
//                         isDarkMode(context) ? Colors.black : Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18),
//                   ),
//
//                 ],
//               ),),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(22.0),
//             child: ElevatedButton(
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
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Visibility(
//                   //     visible: widget.isPaymentDone,
//                   //     child: SizedBox(
//                   //         height: 25,
//                   //         width: 25,
//                   //         child: CircularProgressIndicator(
//                   //           color: Colors.white,
//                   //         ))),
//                   // SizedBox(
//                   //   width: 10,
//                   // ),
//                   Text(
//                     'Back To Cart'.tr(),
//                     style: TextStyle(
//                         color:
//                             isDarkMode(context) ? Colors.black : Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//         ],
//       ),
//     );
//   }
//
//   Future<void> setPrefData() async {
//     SharedPreferences sp = await SharedPreferences.getInstance();
//
//     sp.setString("musics_key", "");
//     sp.setString("addsize", "");
//   }
//
//   // placeOrder() async {
//   //   List<CartProduct> tempProduc = [];
//   //
//   //   for (CartProduct cartProduct in widget.products) {
//   //     CartProduct tempCart = cartProduct;
//   //     tempProduc.add(tempCart);
//   //   }
//   //   FireStoreUtils fireStoreUtils = FireStoreUtils();
//   //   //place order
//   //   showProgress(context, 'Placing Order...'.tr(), false);
//   //   VendorModel vendorModel = await fireStoreUtils.getVendorByVendorID(widget.products.first.vendorID).whenComplete(() => setPrefData());
//   //   log(vendorModel.fcmToken.toString() + "{}{}{}{======TOKENADD" + vendorModel.toJson().toString());
//   //   OrderModel orderModel = OrderModel(
//   //       address: MyAppState.currentUser!.shippingAddress,
//   //       author: MyAppState.currentUser,
//   //       authorID: MyAppState.currentUser!.userID,
//   //       createdAt: Timestamp.now(),
//   //       products: tempProduc,
//   //       status: ORDER_STATUS_PLACED,
//   //       vendor: vendorModel,
//   //       vendorID: widget.products.first.vendorID,
//   //       discount: widget.discount,
//   //       couponCode: widget.couponCode,
//   //       couponId: widget.couponId,
//   //       notes: widget.notes,
//   //       taxModel: widget.taxModel,
//   //       paymentMethod: widget.paymentType,
//   //       specialDiscount: widget.specialDiscountMap,
//   //       tipValue: widget.tipValue,
//   //       adminCommission: isEnableAdminCommission! ? adminCommissionValue : "0",
//   //       adminCommissionType: isEnableAdminCommission! ? addminCommissionType : "",
//   //       takeAway: widget.takeAway,
//   //       deliveryCharge: widget.deliveryCharge,
//   //       scheduleTime: widget.scheduleTime);
//   //
//   //   OrderModel placedOrder = await fireStoreUtils.placeOrder(orderModel);
//   //   for (int i = 0; i < tempProduc.length; i++) {
//   //     await FireStoreUtils().getProductByID(tempProduc[i].id.split('~').first).then((value) async {
//   //       ProductModel? productModel = value;
//   //       log("-----------1>${value.toJson()}");
//   //       if (tempProduc[i].variant_info != null) {
//   //         for (int j = 0; j < productModel.itemAttributes!.variants!.length; j++) {
//   //           if (productModel.itemAttributes!.variants![j].variantId == tempProduc[i].id.split('~').last) {
//   //             if (productModel.itemAttributes!.variants![j].variantQuantity != "-1") {
//   //               productModel.itemAttributes!.variants![j].variantQuantity = (int.parse(productModel.itemAttributes!.variants![j].variantQuantity.toString()) - tempProduc[i].quantity).toString();
//   //             }
//   //           }
//   //         }
//   //       } else {
//   //         if (productModel.quantity != -1) {
//   //           productModel.quantity = productModel.quantity - tempProduc[i].quantity;
//   //         }
//   //       }
//   //
//   //       await FireStoreUtils.updateProduct(productModel).then((value) {
//   //         log("-----------2>${value!.toJson()}");
//   //       });
//   //     });
//   //   }
//   //
//   //   hideProgress();
//   //   showModalBottomSheet(
//   //     isScrollControlled: true,
//   //     isDismissible: false,
//   //     context: context,
//   //     enableDrag: false,
//   //     backgroundColor: Colors.transparent,
//   //     builder: (context) => PlaceOrderScreen(orderModel: placedOrder),
//   //   );
//   // }
//
//   placeOrder() async {
//     List<CartProduct> tempProduc = [];
//     List<CartProduct> admincommssionproducts = [];
//     double pricenew=0.0;
//     for (CartProduct cartProduct in widget.products) {
//       CartProduct tempCart1 = cartProduct;
//       print("tempCarttempCart${tempCart1}");
//       admincommssionproducts.add(tempCart1);
//     }
//     if(widget.auto_apply==true&&widget.cityaveche==true&&widget.isMyTime==true){
//       for (CartProduct cartProduct in widget.products) {
//         // price અપડેટ કરી નવી instance બનાવો
//         pricenew =double.parse(cartProduct.price) *
//             num.parse(widget.autoapplydiscount.toString())/
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
//         // price અપડેટ કરી નવી instance બનાવો
//         CartProduct tempCart = CartProduct(
//           id: cartProduct.id,
//           category_id: cartProduct.category_id,
//           name: cartProduct.name,
//           photo: cartProduct.photo,
//           price:  cartProduct.price, // નવી કિંમત મૂકો
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
//         tempProduc.add(tempCart);
//         print("Updated tempCart: $tempCart");
//       }
//     }
//
//
//     FireStoreUtils fireStoreUtils = FireStoreUtils();
//
//     showProgress(context, 'Placing Order...'.tr(), false);
//
//     try {
//       VendorModel vendorModel = await fireStoreUtils
//           .getVendorByVendorID(widget.products.first.vendorID);
// print("vendorModel?.dfdsfsdf${vendorModel?.speedCashId ?? ""}");
// print("vendorModel?.dfdsfsdf${vendorModel.customAdminCommission}");
// print("vendorModel?.dfdsfsdf${vendorModel.customAdminCommissionType}");
// print("vendorModel?.dfdsfsdf${ vendorModel.customAdminCommissionValue}");
//       OrderModel orderModel = OrderModel(
//           razorpayorderid: widget.razorpayorderid,
//           address: MyAppState.currentUser!.shippingAddress,
//           author: MyAppState.currentUser,
//           authorID: MyAppState.currentUser!.userID,
//           createdAt: Timestamp.now(),
//           products: tempProduc,
//           admincommssionproducts: admincommssionproducts,
//           status: ORDER_STATUS_PLACED,
//           item: widget.groceryitem,
//           vendor: vendorModel,
//           vendorID: widget.products.first.vendorID,
//           discount: widget.discount,
//           couponCode: widget.couponCode,
//           couponId: widget.couponId,
//           notes: widget.notes,
//           taxModel: widget.taxModel,
//           paymentMethod: widget.paymentType,
//           specialDiscount: widget.specialDiscountMap,
//           tipValue: widget.tipValue,
//           customAdminCommission:widget.auto_apply==true&&widget.cityaveche==true&&widget.isMyTime==true?false:vendorModel.customAdminCommission ,
//           customAdminCommissionType:vendorModel.customAdminCommissionType ,
//           customAdminCommissionValue: vendorModel.customAdminCommissionValue,
//           adminCommission: widget.groceryitem == "grocery"
//               ? grocerycommissionfix
//               : isEnableAdminCommission!
//                   ? adminCommissionValue
//                   : "0",
//           admindiscountbyadmincommssiontype:isEnableAdminCommission! ? addminCommissionType:"",
//           admindiscountbyadmincommssion: widget.groceryitem == "grocery"
//               ? grocerycommissionfix1.toString()
//               :adminCommissionValue1.toString(),
//
//           adminCommissionType:
//           jumpnam==true?"Fixed":isEnableAdminCommission! ? addminCommissionType : "",
//           takeAway: widget.takeAway,
//           deliveryCharge: widget.deliveryCharge,
//           packingcharges: widget.chargepaking,
//           scheduleTime: widget.scheduleTime);
//
//       print("widget.products:-${orderModel.products[0].quantity}");
//       print("widget.deliveryCharge:-${widget.deliveryCharge}");
//
//       OrderModel placedOrder = await fireStoreUtils.placeOrder(orderModel);
//
//       for (int i = 0; i < tempProduc.length; i++) {
//         ProductModel? productModel = await fireStoreUtils
//             .getProductByID(tempProduc[i].id.split('~').first);
//
//         if (productModel != null) {
//           if (tempProduc[i].variant_info != null) {
//             for (int j = 0;
//                 j < productModel.itemAttributes!.variants!.length;
//                 j++) {
//               if (productModel.itemAttributes!.variants![j].variantId ==
//                   tempProduc[i].id.split('~').last) {
//                 if (productModel.itemAttributes!.variants![j].variantQuantity !=
//                     "-1") {
//                   productModel.itemAttributes!.variants![j].variantQuantity =
//                       (int.parse(productModel
//                                   .itemAttributes!.variants![j].variantQuantity
//                                   .toString()) -
//                               tempProduc[i].quantity)
//                           .toString();
//                 }
//               }
//             }
//           } else {
//             if (productModel.quantity != -1) {
//               productModel.quantity =
//                   productModel.quantity - tempProduc[i].quantity;
//             }
//           }
//
//           await FireStoreUtils.updateProduct(productModel);
//         }
//       }
//
//       hideProgress();
//       print("placedOrder : -${placedOrder.products.length}");
//       print("placedOrder : -${orderModel?.id ?? ""}");
//       print("razorpay order id : -${orderModel?.razorpayorderid ?? ""}");
//       print(" widget.couponId Chekout: -${widget.couponId}");
//       showModalBottomSheet(
//         isScrollControlled: true,
//         isDismissible: false,
//         context: context,
//         enableDrag: false,
//         backgroundColor: Colors.transparent,
//         builder: (context) => PlaceOrderScreen(
//           orderModel: placedOrder,
//           couponid: widget.couponId1,
//         ),
//       );
//     } catch (e) {
//       // Handle any errors that occur during the process
//       print(e);
//       hideProgress();
//     }
//   }
// }
//
// class RandomIdGenerator {
//   static String generateRandomId() {
//     const chars =
//         'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
//     const length = 10; // Adjust the length of the random ID as needed
//
//     Random random = Random();
//     String id = '';
//
//     for (int i = 0; i < length; i++) {
//       id += chars[random.nextInt(chars.length)];
//     }
//     return id;
//   }
// }
// // FirebaseFirestore.instance
// //     .collection("coupon_used")
// // .doc(collectionid)
// //     .set({
// // 'id': collectionid,
// // 'coupon_id': widget.couponId,
// // 'user_id': MyAppState.currentUser ?? "",
// // 'use_date': formattedDate,
// // }).then((value) {
// // final snackBar = SnackBar(
// // backgroundColor:
// // !isDarkMode(context) ? Colors.white : Color(DARK_BG_COLOR),
// // content: Text(
// // 'Address Added Successfully',
// // style: TextStyle(
// // color: !isDarkMode(context) ? Colors.black : Colors.white),
// // ),
// // );
// // ScaffoldMessenger.of(context).showSnackBar(snackBar);
// // print("Address Added");
// //
// // }).catchError((error) {
// // print("Failed to add address: $error");
// //
// // });
