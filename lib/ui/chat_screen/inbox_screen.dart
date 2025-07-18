import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/model/inbox_model.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/chat_screen/chat_screen.dart';

import '../../constants.dart';
import '../../model/mail_setting.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
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

  Widget build(BuildContext context) {
    return Scaffold(
      body: PaginateFirestore(
        //item builder type is compulsory.
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, documentSnapshots, index) {
          final data = documentSnapshots[index].data() as Map<String, dynamic>?;
          InboxModel inboxModel = InboxModel.fromJson(data!);
          return InkWell(
            onTap: () async {
              await showProgress(context, "Please wait".tr(), false);

              User? customer = await FireStoreUtils.getCurrentUser(
                inboxModel.customerId.toString(),
              );
              User? restaurantUser = await FireStoreUtils.getCurrentUser(
                inboxModel.restaurantId.toString(),
              );
              VendorModel? vendorModel = await FireStoreUtils.getVendor(
                restaurantUser!.vendorID.toString(),
              );
              hideProgress();
              push(
                context,
                ChatScreens(
                  customerName:
                      '${customer!.firstName + " " + customer.lastName}',
                  restaurantName: vendorModel!.title,
                  orderId: inboxModel.orderId,
                  restaurantId: restaurantUser.userID,
                  customerId: customer.userID,
                  customerProfileImage: customer.profilePictureURL,
                  restaurantProfileImage: vendorModel.photo,
                  token: restaurantUser.fcmToken,
                  chatType: inboxModel.chatType,
                ),
              );
            },
            child: ListTile(
              leading: ClipOval(
                child: CachedNetworkImage(
                  width: 50,
                  height: 50,
                  imageUrl: inboxModel.restaurantProfileImage.toString(),
                  imageBuilder:
                      (context, imageProvider) => Container(
                        width: 50,
                        height: 50,
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
              title: Row(
                children: [
                  Expanded(child: Text(inboxModel.restaurantName.toString())),
                  Text(
                    DateFormat('MMM d, yyyy').format(
                      DateTime.fromMillisecondsSinceEpoch(
                        inboxModel.createdAt!.millisecondsSinceEpoch,
                      ),
                    ),
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              subtitle: Text(
                "Order Id :" + " #" + inboxModel.orderId.toString(),
              ),
            ),
          );
        },
        shrinkWrap: true,
        onEmpty: Center(child: Text("No Conversion found".tr())),
        // orderBy is compulsory to enable pagination
        query: FirebaseFirestore.instance
            .collection('chat_restaurant')
            .where("customerId", isEqualTo: MyAppState.currentUser!.userID)
            .orderBy('createdAt', descending: true),
        //Change types customerId
        itemBuilderType: PaginateBuilderType.listView,
        initialLoader: CircularProgressIndicator(),
        // to fetch real-time data
        isLive: true,
      ),
    );
  }
}
