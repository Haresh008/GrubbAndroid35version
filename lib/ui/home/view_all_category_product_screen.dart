import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/FavouriteModel.dart';
import 'package:foodie_customer/model/VendorCategoryModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/auth/AuthScreen.dart';
import 'package:geolocator/geolocator.dart';

import '../../model/mail_setting.dart';
import '../vendorProductsScreen/newVendorProductsScreen.dart';

class ViewAllCategoryProductScreen extends StatefulWidget {
  VendorCategoryModel? vendorCategoryModel;

  ViewAllCategoryProductScreen({Key? key, this.vendorCategoryModel})
    : super(key: key);

  @override
  State<ViewAllCategoryProductScreen> createState() =>
      _ViewAllCategoryProductScreenState();
}

class _ViewAllCategoryProductScreenState
    extends State<ViewAllCategoryProductScreen> {
  List<VendorModel> productList = [];
  bool showLoader = true;

  List<String> lstFav = [];
  late Future<List<FavouriteModel>> lstFavourites;

  getData() {
    if (MyAppState.currentUser != null) {
      lstFavourites = FireStoreUtils().getFavouriteRestaurant(
        MyAppState.currentUser!.userID,
      );
      lstFavourites.then((event) {
        lstFav.clear();
        for (int a = 0; a < event.length; a++) {
          lstFav.add(event[a].restaurantId!);
        }
      });
      setState(() {});
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
    getProductByCategoryId();
    initializeFlutterFire();
  }

  getProductByCategoryId() async {
    FireStoreUtils()
        .getCategoryRestaurants(widget.vendorCategoryModel!.id.toString())
        .asBroadcastStream()
        .listen((event) {
          setState(() {
            productList = event;
          });
        });

    setState(() {
      showLoader = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGlobal.buildAppBar(
        context,
        widget.vendorCategoryModel!.title.toString(),
      ),
      body:
          showLoader
              ? Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                ),
              )
              : productList.isEmpty
              ? showEmptyState("No Item found".tr(), context)
              : ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  return buildVendorItemData(context, productList[index]);
                },
              ),
    );
  }

  Widget buildVendorItemData(BuildContext context, VendorModel vendorModel) {
    double distanceInMeters = Geolocator.distanceBetween(
      vendorModel.latitude,
      vendorModel.longitude,
      MyAppState.selectedPosotion.latitude,
      MyAppState.selectedPosotion.longitude,
    );
    double kilometer = distanceInMeters / 1000;
    double minutes = 1.2;
    double value = minutes * kilometer;
    final int hour = value ~/ 60;
    final double minute = value % 60;
    return vendorModel.commingsoon
        ? GestureDetector(
          onTap: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Ah! I see you are already excited about the upcoming outlet on the platform. Stay tuned 😉"
                      .tr(),
                ),
              ),
            );
          },
          child: Stack(
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.matrix(<double>[
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xff666666), width: 1),
                        color: const Color(DARK_GREY_TEXT_COLOR),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: getImageVAlidUrl(vendorModel.photo),
                                  imageBuilder:
                                      (context, imageProvider) => Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          ),
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                  placeholder:
                                      (context, url) => Center(
                                        child:
                                            CircularProgressIndicator.adaptive(
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    Color(COLOR_PRIMARY),
                                                  ),
                                            ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                        child: Image.network(
                                          AppGlobal.placeHolderImage!,
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.75,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                  fit: BoxFit.cover,
                                ),
                                //                          Positioned(
                                //   bottom: 10,
                                //   right: 10,
                                //   child: Container(
                                //     decoration: BoxDecoration(
                                //       color: Colors.green,
                                //       borderRadius: BorderRadius.circular(5),
                                //     ),
                                //     child: Padding(
                                //       padding: const EdgeInsets.symmetric(
                                //           horizontal: 5, vertical: 2),
                                //       child: Row(
                                //         mainAxisSize: MainAxisSize.min,
                                //         children: [
                                //           Text(
                                //               vendorModel.reviewsCount != 0
                                //                   ? (vendorModel.reviewsSum /
                                //                           vendorModel.reviewsCount)
                                //                       .toStringAsFixed(1)
                                //                   : 0.toString(),
                                //               style: const TextStyle(
                                //                 fontFamily: "Poppinsm",
                                //                 letterSpacing: 0.5,
                                //                 fontSize: 12,
                                //                 color: Colors.white,
                                //               )),
                                //           const SizedBox(width: 3),
                                //           const Icon(
                                //             Icons.star,
                                //             size: 16,
                                //             color: Colors.white,
                                //           ),
                                //         ],
                                //       ),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendorModel.title,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: "Poppinsm",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff666666),
                                    letterSpacing: 0.2,
                                  ),
                                ).tr(),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_pin,
                                      color: Color(0xff666666),
                                      size: 20,
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child:
                                          Text(
                                            vendorModel.location,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontFamily: "Poppinsm",
                                              color: Color(0xff666666),
                                            ),
                                          ).tr(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_sharp,
                                      color: Color(0xff666666),
                                      size: 20,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '${hour.toString().padLeft(2, "0")}h ${minute.toStringAsFixed(0).padLeft(2, "0")}m',
                                      style: TextStyle(
                                        fontFamily: "Poppinsm",
                                        letterSpacing: 0.5,
                                        color: Color(0xff666666),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(
                                      Icons.my_location_sharp,
                                      color: Color(0xff666666),
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "${kilometer.toDouble().toStringAsFixed(currencyModel!.decimal)} km",
                                      style: TextStyle(
                                        fontFamily: "Poppinsm",
                                        letterSpacing: 0.5,
                                        color: Color(0xff666666),
                                      ),
                                    ).tr(),
                                  ],
                                ),
                                SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 26,
                right: 8.5,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'coming_soon'.tr(),
                    style: TextStyle(
                      fontFamily: "Poppinsm",
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        : GestureDetector(
          onTap: () async {
            print('Naa');
            push(context, NewVendorProductsScreen(vendorModel: vendorModel));
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: getImageVAlidUrl(vendorModel.photo),
                                imageBuilder:
                                    (context, imageProvider) => Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
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
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                      child: Image.network(
                                        AppGlobal.placeHolderImage!,
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.75,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () {
                                    if (MyAppState.currentUser == null) {
                                      push(context, AuthScreen());
                                    } else {
                                      setState(() {
                                        if (lstFav.contains(vendorModel.id) ==
                                            true) {
                                          FavouriteModel favouriteModel =
                                              FavouriteModel(
                                                restaurantId: vendorModel.id,
                                                userId:
                                                    MyAppState
                                                        .currentUser!
                                                        .userID,
                                              );
                                          lstFav.removeWhere(
                                            (item) => item == vendorModel.id,
                                          );
                                          FireStoreUtils()
                                              .removeFavouriteRestaurant(
                                                favouriteModel,
                                              );
                                        } else {
                                          FavouriteModel favouriteModel =
                                              FavouriteModel(
                                                restaurantId: vendorModel.id,
                                                userId:
                                                    MyAppState
                                                        .currentUser!
                                                        .userID,
                                              );
                                          FireStoreUtils()
                                              .setFavouriteRestaurant(
                                                favouriteModel,
                                              );
                                          lstFav.add(vendorModel.id);
                                        }
                                      });
                                    }
                                  },
                                  child:
                                      lstFav.contains(vendorModel.id) == true
                                          ? Icon(
                                            Icons.favorite,
                                            color: Color(COLOR_PRIMARY),
                                          )
                                          : Icon(
                                            Icons.favorite_border,
                                            color:
                                                isDarkMode(context)
                                                    ? Colors.white38
                                                    : Colors.black38,
                                          ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          vendorModel.reviewsCount != 0
                                              ? (vendorModel.reviewsSum /
                                                      vendorModel.reviewsCount)
                                                  .toStringAsFixed(1)
                                              : 0.toString(),
                                          style: const TextStyle(
                                            fontFamily: "Poppinsm",
                                            letterSpacing: 0.5,
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        const Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendorModel.title,
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: "Poppinsm",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ).tr(),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_pin,
                                    color: Color(COLOR_PRIMARY),
                                    size: 20,
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child:
                                        Text(
                                          vendorModel.location,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontFamily: "Poppinsm",
                                            color:
                                                isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black.withOpacity(
                                                      0.60,
                                                    ),
                                          ),
                                        ).tr(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_sharp,
                                    color: Color(COLOR_PRIMARY),
                                    size: 20,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    '${hour.toString().padLeft(2, "0")}h ${minute.toStringAsFixed(0).padLeft(2, "0")}m',
                                    style: TextStyle(
                                      fontFamily: "Poppinsm",
                                      letterSpacing: 0.5,
                                      color:
                                          isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black.withOpacity(0.60),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.my_location_sharp,
                                    color: Color(COLOR_PRIMARY),
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "${kilometer.toDouble().toStringAsFixed(currencyModel!.decimal)} km",
                                    style: TextStyle(
                                      fontFamily: "Poppinsm",
                                      letterSpacing: 0.5,
                                      color:
                                          isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black.withOpacity(0.60),
                                    ),
                                  ).tr(),
                                ],
                              ),
                              SizedBox(height: 5),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              vendorModel.freeDelivery == true
                  ? Positioned(
                    top: 26,
                    right: 8.5,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 15,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Free Delivery'.tr(),
                        style: TextStyle(
                          fontFamily: "Poppinsm",
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  : Container(),
            ],
          ),
        );
  }
}
