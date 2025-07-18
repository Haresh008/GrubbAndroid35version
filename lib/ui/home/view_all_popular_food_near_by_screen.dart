import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/src/public_ext.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/model/ProductModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../AppGlobal.dart';
import '../../constants.dart';
import '../../model/mail_setting.dart';
import '../vendorProductsScreen/NewVendorProductsScreen.dart';

class ViewAllPopularFoodNearByScreen extends StatefulWidget {
  const ViewAllPopularFoodNearByScreen({Key? key}) : super(key: key);

  @override
  _ViewAllPopularFoodNearByScreenState createState() =>
      _ViewAllPopularFoodNearByScreenState();
}

class _ViewAllPopularFoodNearByScreenState
    extends State<ViewAllPopularFoodNearByScreen> {
  late Stream<List<VendorModel>> vendorsFuture;
  final fireStoreUtils = FireStoreUtils();
  Stream<List<VendorModel>>? lstAllStore;
  late Future<List<ProductModel>> productsFuture;
  List<ProductModel> lstNearByFood = [];
  List<VendorModel> vendors = [];
  bool showLoader = true;
  String? selctedOrderTypeValue = "Delivery";
  VendorModel? popularNearFoodVendorModel;
  int totItem = 0;

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
    getFoodType();
    initializeFlutterFire();
    fireStoreUtils.getRestaurantNearBy().whenComplete(() {
      lstAllStore = fireStoreUtils.getAllRestaurants().asBroadcastStream();
      lstAllStore!.listen((event) {
        print(event.toString() + "==={}{}===");
        vendors.clear();
        vendors.addAll(event);
      });
      if (selctedOrderTypeValue == "Delivery") {
        productsFuture = fireStoreUtils.getAllDelevryProducts();
      } else {
        productsFuture = fireStoreUtils.getAllTakeAWayProducts();
      }

      productsFuture.then((value) {
        lstNearByFood.addAll(value);
        setState(() {
          showLoader = false;
        });
      });
    });
  }

  getFoodType() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    setState(() {
      selctedOrderTypeValue =
          sp.getString("foodType") == "" || sp.getString("foodType") == null
              ? "Delivery".tr()
              : sp.getString("foodType");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGlobal.buildAppBar(
        context,
        "See what your neighbors are ordering".tr(),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
        child:
            showLoader
                ? Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  ),
                )
                : lstNearByFood.isEmpty
                ? showEmptyState('No Item found'.tr(), context)
                : ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  itemCount: lstNearByFood.length,
                  itemBuilder: (context, index) {
                    if (vendors.isNotEmpty) {
                      print("item name ${lstNearByFood[index].name}");
                      popularNearFoodVendorModel = null;
                      for (int a = 0; a < vendors.length; a++) {
                        print(
                          vendors[a].id.toString() +
                              "===<><><><==" +
                              lstNearByFood[index].vendorID,
                        );
                        if (vendors[a].id == lstNearByFood[index].vendorID) {
                          popularNearFoodVendorModel = vendors[a];
                        }
                      }
                    }
                    return popularNearFoodVendorModel == null
                        ? (totItem == 0 && index == (lstNearByFood.length - 1))
                            ? showEmptyState(
                              'No top selling found'.tr(),
                              context,
                            )
                            : Container()
                        : buildVendorItemData(
                          context,
                          index,
                          popularNearFoodVendorModel!,
                        );
                  },
                ),
      ),
    );
  }

  Widget buildVendorItemData(
    BuildContext context,
    int index,
    VendorModel popularNearFoodVendorModel,
  ) {
    totItem++;
    return GestureDetector(
      onTap: () {
        print(
          popularNearFoodVendorModel.id.toString() +
              " *** " +
              popularNearFoodVendorModel.title.toString(),
        );
        push(
          context,
          NewVendorProductsScreen(vendorModel: popularNearFoodVendorModel),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        width: MediaQuery.of(context).size.width * 0.8,
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: getImageVAlidUrl(lstNearByFood[index].photo),
                height: 100,
                width: 100,
                imageBuilder:
                    (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                placeholder:
                    (context, url) => Center(
                      child: CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation(
                          Color(COLOR_PRIMARY),
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        AppGlobal.placeHolderImage!,
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                      ),
                    ),
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lstNearByFood[index].name,
                    style: const TextStyle(
                      fontFamily: "Poppinsm",
                      fontSize: 18,
                      color: Color(0xff000000),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    lstNearByFood[index].description,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: "Poppinsm",
                      fontSize: 16,
                      color: Color(0xff9091A4),
                    ),
                  ),
                  const SizedBox(height: 5),
                  lstNearByFood[index].disPrice == "" ||
                          lstNearByFood[index].disPrice == "0"
                      ? Text(
                        amountShow(amount: lstNearByFood[index].price),
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: "Poppinsm",
                          letterSpacing: 0.5,
                          color: Color(COLOR_PRIMARY),
                        ),
                      )
                      : Row(
                        children: [
                          Text(
                            "${amountShow(amount: lstNearByFood[index].disPrice)}",
                            style: TextStyle(
                              fontFamily: "Poppinsm",
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(COLOR_PRIMARY),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${amountShow(amount: lstNearByFood[index].price)}',
                            style: const TextStyle(
                              fontFamily: "Poppinsm",
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
