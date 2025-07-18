// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/OrderModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/orderDetailsScreen/OrderDetailsScreen.dart';
import 'package:provider/provider.dart';

import '../../model/PhoneCallModal.dart';
import '../../model/mail_setting.dart';

class OrdersScreen extends StatefulWidget {
  bool? isAnimation = true;

  Timestamp? scheduleTime;

  OrdersScreen({super.key, this.isAnimation, this.scheduleTime});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Stream<List<OrderModel>> ordersFuture;
  FireStoreUtils _fireStoreUtils = FireStoreUtils();
  List<OrderModel> ordersList = [];
  late CartDatabase cartDatabase;
  String? versions;
  String? version;
  int? remainingSeconds;
  int? totalSeconds;
  OrderModel? orderModel;
  var firstOrder;
  String? firstOrdertwo;
  String? firstOrderthree;
  final _formKey = GlobalKey<FormState>();
  PhoneCallModal? phonecallmodal;
  String? phoneNumber;
  TextEditingController _phoneController = TextEditingController();

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

  void getUserPhoneNumber() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      // Firestore thi data fetch karo
      DocumentSnapshot document =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (document.exists) {
        Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;
        if (data != null && data['role'] == 'customer') {
          phoneNumber = data['phoneNumber'];
          print('User Phone Number: $phoneNumber');
          _phoneController.text = phoneNumber.toString();
        } else {
          print('Role is not customer or data is missing');
        }
      } else {
        print('User document does not exist');
      }
    } else {
      print('No user logged in');
    }
  }

  // void fetchUpdates() async {
  //   var appUpdate = FirebaseFirestore.instance
  //       .collection('settings')
  //       .doc("orderCancellationMinutes");
  //
  //   try {
  //     var snapshots = await appUpdate.get();
  //     var updatesData = snapshots.data();
  //     if (updatesData != null) {
  //       versions = updatesData['orderCancellationMinutes'];
  //     setState(() {
  //       version = versions;
  //     });
  //
  //       print("Time Of Minitus $version");
  //       if (version != null) {
  //         int minutes = int.parse(version!);
  //         setState(() {
  //           remainingSeconds = minutes * 60;
  //         });
  //         Timer.periodic(Duration(seconds: 1), (timer) {
  //           if (remainingSeconds! > 0) {
  //             setState(() {
  //               remainingSeconds = remainingSeconds! - 1;
  //             });
  //           } else {
  //             timer.cancel();
  //           }
  //         });
  //       }
  //       Future.delayed( Duration(minutes: int.parse(version!)), () {
  //         setState(() {
  //           widget.isAnimation = false;
  //         });
  //       });
  //     }
  //   } catch (e) {
  //     print('Error fetching updates: $e');
  //   }
  // }
  OrderModel? Ordermodel123;
  OrderModel? Ordermodel1234;

  // void fetchUpdates() async {
  //   var appUpdate = FirebaseFirestore.instance
  //       .collection('settings')
  //       .doc("orderCancellationMinutes");
  //
  //   try {
  //     var snapshots = await appUpdate.get();
  //     var updatesData = snapshots.data();
  //     if (updatesData != null) {
  //       version = updatesData['orderCancellationMinutes'];
  //       setState(() {
  //         version = version;
  //       });
  //
  //       if (version != null) {
  //         int minutes = int.parse(version!);
  //         totalSeconds = minutes * 60;
  //         remainingSeconds = totalSeconds;
  //
  //         Timer.periodic(Duration(seconds: 1), (timer) {
  //           if (remainingSeconds! > 0) {
  //             setState(() {
  //               remainingSeconds = remainingSeconds! - 1;
  //             });
  //           } else {
  //             timer.cancel();
  //           }
  //         });
  //
  //         Future.delayed(Duration(minutes: int.parse(version!)), () {
  //           setState(() {
  //             widget.isAnimation = false;
  //             rejectOrder();
  //             print("orderModel?.status${orderModel?.status}");
  //           });
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print('Error fetching updates: $e');
  //   }
  // }
  Timer? _timer;

  void fetchUpdates() async {
    var appUpdate = FirebaseFirestore.instance
        .collection('settings')
        .doc("orderCancellationMinutes");

    try {
      var snapshots = await appUpdate.get();
      var updatesData = snapshots.data();
      if (updatesData != null) {
        version = updatesData['orderCancellationMinutes'];
        setState(() {
          version = version;
        });

        if (version != null) {
          int minutes = int.parse(version!);
          totalSeconds = minutes * 60;
          remainingSeconds = totalSeconds;

          (firstOrderthree == "Order Accepted" ||
                      firstOrderthree == "Order Completed" ||
                      firstOrderthree == "Driver Pending" ||
                      firstOrderthree == "Driver Rejected" ||
                      firstOrderthree == "Order Shipped" ||
                      firstOrderthree == "Assign Driver" ||
                      firstOrderthree == "In Transit" ||
                      firstOrderthree == "Order Rejected") ||
                  (widget.scheduleTime != null)
              ? _timer!.cancel()
              : _timer = Timer.periodic(Duration(seconds: 1), (timer) {
                if (remainingSeconds! > 0) {
                  setState(() {
                    remainingSeconds = remainingSeconds! - 1;
                  });
                  print('Remaining seconds: $remainingSeconds');
                } else {
                  setState(() {
                    widget.isAnimation = false;

                    updateOrderStatus(firstOrdertwo.toString());
                    print(
                      "updateOrderStatus((orderModel?.id).toString())${firstOrdertwo}",
                    );
                  });
                  timer.cancel();
                  print('Timer completed, rejecting order...');
                }
              });
        }
      }
    } catch (e) {
      print('Error fetching updates: $e');
    }
  }

  Future<void> updateOrderStatus(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('restaurant_orders')
          .doc(id)
          .update({'status': 'Order Rejected'});
      await FireStoreUtils.sendOneNotification(
        type: ORDER_STATUS_REJECTED,
        token: orderModel?.vendor.fcmToken ?? '',
      );
      await FireStoreUtils.sendFcmMessage(
        ORDER_STATUS_REJECTED,
        orderModel?.vendor.fcmToken ?? '',
      );
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    ordersFuture = _fireStoreUtils.getOrders(MyAppState.currentUser!.userID);
    initializeFlutterFire();
    fetchUpdates();
    getUserPhoneNumber();

    print("Time Of Minitus instate $version");
    print("Time Of Minitus instate $firstOrderthree");
  }

  @override
  void didChangeDependencies() {
    cartDatabase = Provider.of<CartDatabase>(context, listen: false);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    FireStoreUtils().closeOrdersStream();
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFFFFF),
      body: StreamBuilder<List<OrderModel>>(
        stream: ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Container(
              child: Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                ),
              ),
            );
          if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
            return Center(
              child: showEmptyState(
                'No Previous Orders'.tr(),
                context,
                description: "Let's orders food!".tr(),
              ),
            );
          } else {
            firstOrder = snapshot.data!.first;
            firstOrdertwo = snapshot.data!.first.id;
            firstOrderthree = snapshot.data!.first.status;
            print(
              "firstOrderthreefirstOrderthreefirstOrderthreefirstOrderthreefirstOrderthree $firstOrderthree",
            );
            (firstOrderthree == "Order Accepted" ||
                        firstOrderthree == "Order Completed" ||
                        firstOrderthree == "Driver Pending" ||
                        firstOrderthree == "Driver Rejected" ||
                        firstOrderthree == "Order Shipped" ||
                        firstOrderthree == "Assign Driver" ||
                        firstOrderthree == "In Transit" ||
                        firstOrderthree == "Order Rejected") ||
                    (widget.scheduleTime != null)
                ? _timer?.cancel()
                : print('Timer On');
            firstOrderthree != "Order Placed"
                ? widget.isAnimation = false
                : print('Accepted On');
            print("firstOrdertwo${firstOrdertwo}");

            if (firstOrder.status == "Order Accepted" ||
                firstOrder.status == "Order Rejected") {
              print('Order Status : ${firstOrder.status}');
              print('Animate : ${widget.isAnimation}');
              if (widget.isAnimation ?? false) {
                widget.isAnimation = false;
              }
            }

            return (widget.isAnimation ?? false) &&
                    (widget.scheduleTime == null)
                ? Stack(
                  children: [
                    Image.asset('assets/orderpage.gif', fit: BoxFit.cover),
                    Positioned(
                      bottom: 10,
                      right: 135,
                      child:
                          remainingSeconds != null
                              ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 85,
                                    height: 85,
                                    child: CircularProgressIndicator(
                                      value: remainingSeconds! / totalSeconds!,
                                      strokeWidth: 8.0,
                                      backgroundColor: Colors.black12,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.deepOrangeAccent,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${formatDuration(Duration(seconds: remainingSeconds!))}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                              : CircularProgressIndicator(),
                    ),
                  ],
                )
                : ListView.builder(
                  itemCount: snapshot.data!.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder:
                      (context, index) => buildOrderItem(snapshot.data![index]),
                );
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Color(COLOR_PRIMARY),
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => ContainerScreen(
      //           drawerSelection: DrawerSelection.contactUs,
      //           user: MyAppState.currentUser,
      //           appBarTitle: 'Contact Us'.tr(),
      //           currentWidget: ContactUsScreen(),
      //         ),
      //       ),
      //     );
      //   },
      //   child: Icon(Icons.call, color: Colors.white),
      //   tooltip: 'Contact Us', // Tooltip when the button is long-pressed
      // ),
    );
  }

  Widget buildOrderItem(OrderModel orderModel) {
    double total = 0.0;
    orderModel.products.forEach((element) {
      try {
        if (element.extras_price!.isNotEmpty &&
            double.parse(element.extras_price!) != 0.0) {
          total += element.quantity * double.parse(element.extras_price!);
        }
        total += element.quantity * double.parse(element.price);
      } catch (ex) {}
    });
    total = total - orderModel.discount!;

    return Container(
      width: MediaQuery.of(context).size.width,
      child: Card(
        color:
            isDarkMode(context) ? Color(DARK_CARD_BG_COLOR) : Color(0xffFFFFFF),
        // margin: EdgeInsets.only(bottom: 30, right: 5, left: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 15, right: 8, left: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap:
                () => push(context, OrderDetailsScreen(orderModel: orderModel)),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(
                            (orderModel.products.first.photo.isNotEmpty)
                                ? orderModel.products.first.photo
                                : placeholderImage,
                          ),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.5),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ORDER ID:'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Poppinsm',
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                  color:
                                      isDarkMode(context)
                                          ? Colors.grey.shade300
                                          : Color(0xff9091A4),
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                orderModel.id,
                                style: TextStyle(
                                  fontSize: 18,
                                  color:
                                      isDarkMode(context)
                                          ? Colors.grey.shade200
                                          : Color(0XFF000000),
                                  fontFamily: "Poppinsm",
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: orderModel.products.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(top: 00),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      orderModel.products[index].item ==
                                              'grocery'
                                          ? orderModel.products[index].name +
                                              " (${orderModel.products[index].groceryWeight} ${orderModel.products[index].groceryUnit})"
                                          : orderModel.products[index].name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            isDarkMode(context)
                                                ? Colors.grey.shade200
                                                : Color(0XFF000000),
                                        fontFamily: "Poppinsm",
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 70,
                                          child: Text(
                                            orderModel.status ==
                                                    ORDER_STATUS_SHIPPED
                                                ? ORDER_STATUS_PICKED
                                                : orderModel.status.tr(),
                                            style: TextStyle(
                                              color:
                                                  isDarkMode(context)
                                                      ? Colors.grey.shade200
                                                      : Color(0XFF555353),
                                              fontFamily: "Poppinsr",
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Image(
                                          image: AssetImage(
                                            "assets/images/verti_divider.png",
                                          ),
                                          height: 10,
                                          width: 10,
                                          color: Color(0XFF555353),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            orderDate(orderModel.createdAt),
                                            style: TextStyle(
                                              color:
                                                  isDarkMode(context)
                                                      ? Colors.grey.shade200
                                                      : Color(0XFF555353),
                                              fontFamily: "Poppinsr",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    getPriceTotalText(
                                      orderModel.products[index],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget buildOrderItem(OrderModel orderModel) {
  //   double total = 0.0;
  //   orderModel.products.forEach((element) {
  //     try {
  //       if (element.extras_price!.isNotEmpty &&
  //           double.parse(element.extras_price!) != 0.0) {
  //         total += element.quantity * double.parse(element.extras_price!);
  //       }
  //       total += element.quantity * double.parse(element.price);
  //     } catch (ex) {}
  //   });
  //   total = total - orderModel.discount!;
  //
  //   return Card(color: isDarkMode(context) ? Color(DARK_CARD_BG_COLOR) : Color(
  //       0xffFFFFFF),
  //       margin: EdgeInsets.only(bottom: 30, right: 5, left: 5),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //       child: Padding(padding: const EdgeInsets.only(
  //           top: 5, bottom: 15, right: 10, left: 10),
  //         child: GestureDetector(
  //             behavior: HitTestBehavior.translucent,
  //             onTap: () =>
  //                 push(context, OrderDetailsScreen(orderModel: orderModel,)),
  //             child: Column(children: [
  //               Row(crossAxisAlignment: CrossAxisAlignment.start,
  //                 // mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Container(height: 90, width: 90,
  //
  //                     decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(12),
  //                       image: DecorationImage(image: NetworkImage((orderModel
  //                           .products.first.photo.isNotEmpty) ? orderModel
  //                           .products.first.photo : placeholderImage),
  //                         fit: BoxFit.cover,
  //                         colorFilter: ColorFilter.mode(
  //                             Colors.black.withOpacity(0.5),
  //                             BlendMode.darken),),),
  //
  //                     // child: Center(
  //                     //   child: Text(
  //                     //     '${orderDate(orderModel.createdAt)}                      // ), - ${orderModel.status}',
  //                     //     style: TextStyle(color: Colors.white, fontSize: 17),
  //                     //   ),
  //                   ),
  //                   SizedBox(width: 15,),
  //                   Expanded(child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.start,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Column(mainAxisAlignment: MainAxisAlignment.start,
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text('ORDER ID:'.tr(), style: TextStyle(
  //                             fontFamily: 'Poppinsm',
  //                             fontSize: 16,
  //                             letterSpacing: 0.5,
  //                             color: isDarkMode(context)
  //                                 ? Colors.grey.shade300
  //                                 : Color(0xff9091A4),),),
  //                           SizedBox(width: 5,),
  //                           Text(orderModel.id, style: TextStyle(fontSize: 18,
  //                               color: isDarkMode(context) ? Colors.grey
  //                                   .shade200 : Color(0XFF000000),
  //                               fontFamily: "Poppinsm"),),
  //                         ],),
  //                       SizedBox(height: 5,),
  //                       ListView.builder(
  //                           physics: NeverScrollableScrollPhysics(),
  //                           itemCount: orderModel.products.length,
  //                           shrinkWrap: true,
  //                           itemBuilder: (context, index) {
  //                             return Padding(padding: EdgeInsets.only(top: 00),
  //                                 child: Column(
  //                                     crossAxisAlignment: CrossAxisAlignment
  //                                         .start,
  //                                     // mainAxisAlignment: MainAxisAlignment.end,
  //                                     children: [
  //                                       Text(orderModel.products[index].name,
  //                                         style: TextStyle(fontSize: 18,
  //                                             color: isDarkMode(context)
  //                                                 ? Colors.grey.shade200
  //                                                 : Color(0XFF000000),
  //                                             fontFamily: "Poppinsm"),),
  //                                       SizedBox(height: 5,),
  //                                       Row(children: [
  //                                         Text(orderModel.status.tr(),
  //                                             style: TextStyle(
  //                                                 color: isDarkMode(context)
  //                                                     ? Colors.grey.shade200
  //                                                     : Color(0XFF555353),
  //                                                 fontFamily: "Poppinsr")),
  //                                         SizedBox(width: 3),
  //                                         Image(image: AssetImage(
  //                                             "assets/images/verti_divider.png"),
  //                                           height: 10,
  //                                           width: 10,
  //                                           color: Color(0XFF555353),),
  //                                         Text(orderDate(orderModel.createdAt),
  //                                             style: TextStyle(
  //                                                 color: isDarkMode(context)
  //                                                     ? Colors.grey.shade200
  //                                                     : Color(0XFF555353),
  //                                                 fontFamily: "Poppinsr")),
  //                                       ],),
  //                                       SizedBox(height: 5),
  //                                       getPriceTotalText(
  //                                           orderModel.products[index])
  //                                     ]));
  //                           }),
  //                     ],)),
  //                 ],),
  //               SizedBox(height: 20),
  //             ])),));
  // }

  String? getPrice(OrderModel product, int index, CartProduct cartProduct) {
    /*double.parse(product.price)
        .toStringAsFixed(decimal)*/
    var subTotal;
    var price =
        cartProduct.extras_price == "" ||
                cartProduct.extras_price == null ||
                cartProduct.extras_price == "0.0"
            ? 0.0
            : cartProduct.extras_price;
    var tipValue =
        product.tipValue.toString() == "" || product.tipValue == null
            ? 0.0
            : product.tipValue.toString();
    var dCharge =
        product.deliveryCharge == null ||
                product.deliveryCharge.toString().isEmpty
            ? 0.0
            : double.parse(product.deliveryCharge.toString());
    var dis =
        product.discount.toString() == "" || product.discount == null
            ? 0.0
            : product.discount.toString();

    subTotal =
        double.parse(price.toString()) +
        double.parse(tipValue.toString()) +
        double.parse(dCharge.toString()) -
        double.parse(dis.toString());

    return subTotal.toString();
  }

  String? getPriceTotal(String price, int quantity) {
    double ans = double.parse(price) * double.parse(quantity.toString());
    return ans.toString();
  }

  getPriceTotalText(CartProduct s) {
    double total = 0.0;
    print("price $s");
    if (s.extras_price != null &&
        s.extras_price!.isNotEmpty &&
        double.parse(s.extras_price!) != 0.0) {
      total += s.quantity * double.parse(s.extras_price!);
    }
    total += s.quantity * double.parse(s.price);

    return Text(
      amountShow(amount: total.toString()),
      style: TextStyle(
        fontSize: 20,
        color:
            isDarkMode(context) ? Colors.grey.shade200 : Color(COLOR_PRIMARY),
        fontFamily: "Poppinssm",
      ),
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
