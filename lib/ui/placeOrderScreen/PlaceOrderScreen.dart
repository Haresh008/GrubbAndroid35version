import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/OrderModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/container/ContainerScreen.dart';
import 'package:foodie_customer/ui/ordersScreen/OrdersScreen.dart';
import 'package:provider/provider.dart';

import '../../model/mail_setting.dart';

class PlaceOrderScreen extends StatefulWidget {
  final OrderModel orderModel;
  String? couponid;

  PlaceOrderScreen({Key? key, required this.orderModel, required this.couponid})
    : super(key: key);

  @override
  _PlaceOrderScreenState createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  FireStoreUtils fireStoreUtils = FireStoreUtils();
  late Timer timer;

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

  DateTime now = DateTime.now();
  String? formattedDate;
  String collectionid = '';
  String useridasd = '';

  @override
  void initState() {
    timer = Timer(Duration(seconds: 3), () => animateOut());
    super.initState();
    initializeFlutterFire();
    print("order id ${widget.orderModel?.id ?? ""}");
    print(" widget.couponId Chekout: -${widget.couponid}");
    setState(() {
      formattedDate = "${now.day}/${now.month}/${now.year}";
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Container(
        padding: EdgeInsets.all(8),
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: BoxDecoration(
          color: isDarkMode(context) ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Placing Order...'.tr(),
                style: TextStyle(
                  color:
                      isDarkMode(context)
                          ? Colors.grey.shade300
                          : Colors.grey.shade800,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Container(
                width: 24,
                height: 24,
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                ),
              ),
            ),
            Visibility(
              visible: widget.orderModel.takeAway == false,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 40),
                    title: Text(
                      '${widget.orderModel.address.line1} ${widget.orderModel.address.line2} ${widget.orderModel.address.city}',
                      style: TextStyle(
                        color:
                            isDarkMode(context)
                                ? Colors.grey.shade300
                                : Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: Text('Delivering to you ❤️'.tr()),
                    leading: Icon(
                      CupertinoIcons.checkmark_alt,
                      color: Color(COLOR_PRIMARY),
                    ),
                  ),
                  Divider(indent: 40, endIndent: 40),
                ],
              ),
            ),

            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 40),
              title: Text(
                'Your order, {}'.tr(
                  args: ['${widget.orderModel.address.name}'],
                ),
                style: TextStyle(
                  color:
                      isDarkMode(context)
                          ? Colors.grey.shade300
                          : Colors.grey.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              leading: Icon(
                CupertinoIcons.checkmark_alt,
                color: Color(COLOR_PRIMARY),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsetsDirectional.only(start: 56),
                itemCount: widget.orderModel.products.length,
                itemBuilder:
                    (context, index) => Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            color:
                                isDarkMode(context)
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade200,
                            padding: EdgeInsets.all(6),
                            child: Text('${index + 1}'),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 150,
                            child: Text(
                              '${widget.orderModel.products[index].name}',
                              style: TextStyle(
                                color:
                                    isDarkMode(context)
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
            // RaisedButton(onPressed: () => deleteOrder(), child: Text('Undo'))
          ],
        ),
      ),
    );
  }

  void addCouponUsedData() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // યુઝર આઈડી મેળવો
    User? user = auth.currentUser;
    String userId = user?.uid ?? "";
    print("userId${userId}");

    // તારીખ સ્વરૂપમાં બનાવો
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy').format(now);
    setState(() {
      useridasd = RandomIdGenerator.generateRandomId();
    });
    // ડેટા ઓબ્જેક્ટ બનાવો
    Map<String, dynamic> data = {
      'id': useridasd,
      'coupon_id': widget.couponid,
      'user_id': userId,
      'use_date': formattedDate,
    };
    print("widget.couponid${widget.couponid}");
    print("data${data}");
    await firestore.collection('coupon_used').add(data);
  }

  animateOut() async {
    print("a code work kare che");
    await FireStoreUtils.sendOrderEmail(orderModel: widget.orderModel);
    await FireStoreUtils.sendAdminOrderEmail(orderModel: widget.orderModel);
    widget.couponid == null || widget.couponid == ""
        ? print("widget.couponid")
        : addCouponUsedData();
    print(widget.orderModel.vendor.fcmToken.toString() + "{======TOKEN}");

    if (widget.orderModel.scheduleTime != null) {
      await FireStoreUtils.sendOneNotification(
        type: scheduleOrder,
        token: widget.orderModel.vendor.fcmToken.toString(),
      );
      await FireStoreUtils.sendFcmMessage(
        scheduleOrder,
        widget.orderModel.vendor.fcmToken,
      );
    } else {
      await FireStoreUtils.sendOneNotification(
        type: orderPlaced,
        token: widget.orderModel.vendor.fcmToken.toString(),
      );
      await FireStoreUtils.sendFcmMessage(
        orderPlaced,
        widget.orderModel.vendor.fcmToken,
      );
    }

    Provider.of<CartDatabase>(context, listen: false).deleteAllProducts();

    pushAndRemoveUntil(
      context,
      ContainerScreen(
        user: MyAppState.currentUser!,
        currentWidget: OrdersScreen(
          isAnimation: true,
          scheduleTime: widget.orderModel.scheduleTime,
        ),
        appBarTitle: 'Orders'.tr(),
        drawerSelection: DrawerSelection.Orders,
      ),
      false,
    );
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
