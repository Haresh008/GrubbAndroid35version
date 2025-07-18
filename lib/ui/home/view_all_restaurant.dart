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
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/auth/AuthScreen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/mail_setting.dart';

class ViewAllRestaurant extends StatefulWidget {
  const ViewAllRestaurant({Key? key}) : super(key: key);

  @override
  State<ViewAllRestaurant> createState() => _ViewAllRestaurantState();
}

class _ViewAllRestaurantState extends State<ViewAllRestaurant> {
  List<VendorModel> vendors = [];

  bool isLoading = true;

  getProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if SharedPreferences has saved location data
    // double? savedLatitude =
    // prefs.getDouble('latitude');
    // double? savedLongitude = prefs.getDouble('longitude');
    double? savedLatitude =
        MyAppState.currentUser == null ||
                MyAppState.currentUser?.userID == null ||
                MyAppState.currentUser?.userID == ""
            ? MyAppState.selectedPosotion.latitude
            : MyAppState.currentUser?.location.latitude == 0.01
            ? MyAppState.selectedPosotion.latitude
            : double.parse(
              (MyAppState.currentUser?.location.latitude).toString(),
            );
    // prefs.getDouble('latitude');
    double? savedLongitude =
        MyAppState.currentUser == null ||
                MyAppState.currentUser?.userID == null ||
                MyAppState.currentUser?.userID == ""
            ? MyAppState.selectedPosotion.longitude
            : MyAppState.currentUser?.location.longitude == 0.01
            ? MyAppState.selectedPosotion.longitude
            : double.parse(
              (MyAppState.currentUser?.location.longitude).toString(),
            );
    print("savedLatitudesavedLatitude${savedLatitude}");
    setState(() {
      isLoading = true;
    });
    var collectionReference = FireStoreUtils.firestore.collection(VENDORS);

    GeoFirePoint center = GeoFlutterFire().point(
      latitude:
          savedLatitude == null
              ? MyAppState.selectedPosotion.latitude
              : savedLatitude,
      longitude:
          savedLongitude == null
              ? MyAppState.selectedPosotion.longitude
              : savedLongitude,
    );
    String field = 'g';
    print("centercenter${center.latitude}");
    print("centercenter${center.longitude}");
    print("centercenter${radiusValue}");
    print("centercenter${field}");
    Stream<List<DocumentSnapshot>> stream = GeoFlutterFire()
        .collection(collectionRef: collectionReference)
        .within(
          center: center,
          radius: radiusValue,
          field: field,
          strictMode: true,
        );
    stream.listen((documentList) {
      for (var document in documentList) {
        final data = document.data() as Map<String, dynamic>;
        setState(() {
          vendors.add(VendorModel.fromJson(data));
        });
      }
    });
    // Stream<List<DocumentSnapshot>> stream = collectionReference.snapshots().map((snapshot) => snapshot.docs);
    // stream.listen((documentList) {
    //   for (var document in documentList) {
    //     final data = document.data() as Map<String, dynamic>;
    //     setState(() {
    //       vendors.add(VendorModel.fromJson(data));
    //     });
    //   }
    // });
    setState(() {
      isLoading = false;
    });
  }

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

  List<String> lstFav = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGlobal.buildAppBar(context, "All Restaurant".tr()),
      body: Column(
        children: [
          // Expanded(
          //   child: vendors.isEmpty
          //       ? Center(
          //     child: const Text('No Data...').tr(),
          //   )
          //       : Builder(
          //     builder: (context) {
          //       // ✅ Sort vendors: Coming Soon vendors at the bottom
          //       List<VendorModel> sortedVendors = [...vendors];
          //       sortedVendors.sort((a, b) {
          //         if (a.commingsoon && !b.commingsoon) return 1;
          //         if (!a.commingsoon && b.commingsoon) return -1;
          //         return 0;
          //       });
          //
          //       return ListView.builder(
          //         shrinkWrap: true,
          //         scrollDirection: Axis.vertical,
          //         physics: const AlwaysScrollableScrollPhysics(),
          //         itemCount: sortedVendors.length,
          //         itemBuilder: (context, index) =>
          //             buildAllRestaurantsData(sortedVendors[index]),
          //       );
          //     },
          //   ),
          // ),

          // All working code
          Expanded(
            child:
                vendors.isEmpty
                    ? Center(child: const Text('No Data...').tr())
                    : buildSortedVendorListWidget(vendors, context),
            // ListView.builder(
            //         shrinkWrap: true,
            //         scrollDirection: Axis.vertical,
            //         physics: const AlwaysScrollableScrollPhysics(),
            //         itemCount: vendors.length,
            //         itemBuilder: (context, index) =>
            //             //buildVendorItem(vendors[index])
            //
            //             buildAllRestaurantsData(vendors[index]),
            //       ),
          ),
          isLoading ? const CircularProgressIndicator() : Container(),
        ],
      ),
    );
  }

  String getVendorStatus(VendorModel vendorModel) {
    final now = DateTime.now();
    final String today = DateFormat('EEEE').format(now); // e.g., Monday

    // આજે ના workingHours filter કરો
    final todayHours =
        vendorModel.workingHours
            .where((element) => element.day == today)
            .toList();

    if (todayHours.isEmpty ||
        todayHours[0].timeslot == null ||
        todayHours[0].timeslot!.isEmpty) {
      return 'Closed';
    }

    final currentTime = DateFormat("HH:mm").parse(
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
    );

    bool isOpen = false;

    for (var slot in todayHours[0].timeslot!) {
      if (slot.from == null || slot.to == null) continue;

      final fromTime = DateFormat("HH:mm").parse(slot.from!);
      final toTime = DateFormat("HH:mm").parse(slot.to!);

      if (currentTime.isAfter(fromTime) && currentTime.isBefore(toTime)) {
        isOpen = true;
        break;
      }
    }

    return isOpen ? 'Open' : 'Pre-order';
  }

  Widget buildSortedVendorListWidget(
    List<VendorModel> vendors,
    BuildContext context,
  ) {
    List<VendorModel> sortedVendors = [...vendors];

    sortedVendors.sort((a, b) {
      String statusA = getVendorStatus(a);
      String statusB = getVendorStatus(b);

      int weight(VendorModel vendor, String status) {
        if (vendor.commingsoon) return 3; // Coming Soon always last
        if (status == 'Open') return 0;
        if (status == 'Pre-order') return 1;
        return 2; // Closed
      }

      int weightA = weight(a, statusA);
      int weightB = weight(b, statusB);

      return weightA.compareTo(weightB);
    });

    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemCount: sortedVendors.length,
        itemBuilder: (context, index) {
          VendorModel vendorModel = sortedVendors[index];
          return buildAllRestaurantsData(vendorModel);
        },
      ),
    );
  }

  buildAllRestaurantsData(VendorModel vendorModel) {
    String vendorStatus = getVendorStatus(vendorModel);
    if (vendorModel.groceryandrestirant == "Restaurant") {
      // print("Vendor Type: ${vendorModel.groceryandrestirant}");
      print("Vendor Type: ${vendorModel.title}");
      return vendorModel.commingsoon
          ? GestureDetector(
            onTap: () {
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xff666666), width: 1),
                        color: const Color(DARK_GREY_TEXT_COLOR),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: getImageVAlidUrl(vendorModel.photo),
                                  height: 100,
                                  width: 100,
                                  imageBuilder:
                                      (context, imageProvider) => Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
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
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          AppGlobal.placeHolderImage!,
                                          fit: BoxFit.cover,
                                          cacheHeight: 100,
                                          cacheWidth: 100,
                                        ),
                                      ),
                                  fit: BoxFit.cover,
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          vendorModel.title,
                                          style: TextStyle(
                                            fontFamily: "Poppinsm",
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xff666666),
                                          ),
                                          maxLines: 1,
                                        ),
                                      ),
                                      // GestureDetector(
                                      //   onTap: () {
                                      //     if (MyAppState.currentUser == null) {
                                      //       push(context, AuthScreen());
                                      //     } else {
                                      //       setState(() {
                                      //         if (lstFav.contains(vendorModel.id) ==
                                      //             true) {
                                      //           FavouriteModel favouriteModel =
                                      //               FavouriteModel(
                                      //             restaurantId: vendorModel.id,
                                      //             userId: MyAppState
                                      //                 .currentUser!.userID,
                                      //           );
                                      //           lstFav.removeWhere(
                                      //             (item) => item == vendorModel.id,
                                      //           );
                                      //           FireStoreUtils()
                                      //               .removeFavouriteRestaurant(
                                      //             favouriteModel,
                                      //           );
                                      //         } else {
                                      //           FavouriteModel favouriteModel =
                                      //               FavouriteModel(
                                      //             restaurantId: vendorModel.id,
                                      //             userId: MyAppState
                                      //                 .currentUser!.userID,
                                      //           );
                                      //           FireStoreUtils()
                                      //               .setFavouriteRestaurant(
                                      //             favouriteModel,
                                      //           );
                                      //           lstFav.add(vendorModel.id);
                                      //         }
                                      //       });
                                      //     }
                                      //   },
                                      //   child:
                                      //       lstFav.contains(vendorModel.id) == true
                                      //           ? Icon(
                                      //               Icons.favorite,
                                      //               color: Color(COLOR_PRIMARY),
                                      //             )
                                      //           : Icon(
                                      //               Icons.favorite_border,
                                      //               color: isDarkMode(context)
                                      //                   ? Colors.white38
                                      //                   : Colors.black38,
                                      //             ),
                                      // )
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  // Row(
                                  //   children: [
                                  //     Icon(
                                  //       Icons.location_pin,
                                  //       size: 20,
                                  //       color: Color(0xff666666),
                                  //     ),
                                  //     Expanded(
                                  //       child: Text(
                                  //         vendorModel.location,
                                  //         maxLines: 1,
                                  //         style: TextStyle(
                                  //           fontFamily: "Poppinsm",
                                  //           color: Color(0xff666666),
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  // const SizedBox(
                                  //   height: 5,
                                  // ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 20,
                                        color: Color(0xff666666),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        vendorModel.reviewsCount != 0
                                            ? (vendorModel.reviewsSum /
                                                    vendorModel.reviewsCount)
                                                .toStringAsFixed(1)
                                            : 0.toString(),
                                        style: TextStyle(
                                          fontFamily: "Poppinsm",
                                          letterSpacing: 0.5,
                                          color: Color(0xff666666),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                                        style: TextStyle(
                                          fontFamily: "Poppinsm",
                                          letterSpacing: 0.5,
                                          color: Color(0xff666666),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                    ],
                                  ),
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
                  bottom: 25,
                  right: 10,
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
            onTap:
                () => push(
                  context,
                  NewVendorProductsScreen(vendorModel: vendorModel),
                ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: getImageVAlidUrl(vendorModel.photo),
                                height: 100,
                                width: 100,
                                imageBuilder:
                                    (context, imageProvider) => Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
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
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        AppGlobal.placeHolderImage!,
                                        fit: BoxFit.cover,
                                        cacheHeight: 100,
                                        cacheWidth: 100,
                                      ),
                                    ),
                                fit: BoxFit.cover,
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        vendorModel.title,
                                        style: TextStyle(
                                          fontFamily: "Poppinsm",
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (MyAppState.currentUser == null) {
                                          push(context, AuthScreen());
                                        } else {
                                          setState(() {
                                            if (lstFav.contains(
                                                  vendorModel.id,
                                                ) ==
                                                true) {
                                              FavouriteModel favouriteModel =
                                                  FavouriteModel(
                                                    restaurantId:
                                                        vendorModel.id,
                                                    userId:
                                                        MyAppState
                                                            .currentUser!
                                                            .userID,
                                                  );
                                              lstFav.removeWhere(
                                                (item) =>
                                                    item == vendorModel.id,
                                              );
                                              FireStoreUtils()
                                                  .removeFavouriteRestaurant(
                                                    favouriteModel,
                                                  );
                                            } else {
                                              FavouriteModel favouriteModel =
                                                  FavouriteModel(
                                                    restaurantId:
                                                        vendorModel.id,
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
                                          lstFav.contains(vendorModel.id) ==
                                                  true
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
                                  ],
                                ),
                                const SizedBox(height: 5),
                                // Text("Min".tr() + " ${discountAmountTempList.isNotEmpty ? discountAmountTempList.reduce(min).toStringAsFixed(0) : 0}% " + "off".tr(),
                                //     maxLines: 1,
                                //     style: TextStyle(
                                //       fontFamily: "Poppinsm",
                                //       letterSpacing: 0.5,
                                //       color: isDarkMode(context) ? Colors.white60 : const Color(0xff555353),
                                //     )),
                                // const SizedBox(
                                //   height: 10,
                                // ),
                                // Row(
                                //   children: [
                                //     Icon(
                                //       Icons.location_pin,
                                //       size: 20,
                                //       color: Color(COLOR_PRIMARY),
                                //     ),
                                //     Expanded(
                                //       child: Text(
                                //         vendorModel.location,
                                //         maxLines: 1,
                                //         style: TextStyle(
                                //           fontFamily: "Poppinsm",
                                //           color: isDarkMode(context)
                                //               ? Colors.white70
                                //               : const Color(0xff9091A4),
                                //         ),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                // const SizedBox(
                                //   height: 5,
                                // ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 20,
                                      color: Color(COLOR_PRIMARY),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      vendorModel.reviewsCount != 0
                                          ? (vendorModel.reviewsSum /
                                                  vendorModel.reviewsCount)
                                              .toStringAsFixed(1)
                                          : 0.toString(),
                                      style: TextStyle(
                                        fontFamily: "Poppinsm",
                                        letterSpacing: 0.5,
                                        color:
                                            isDarkMode(context)
                                                ? Colors.white
                                                : const Color(0xff000000),
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                                      style: TextStyle(
                                        fontFamily: "Poppinsm",
                                        letterSpacing: 0.5,
                                        color:
                                            isDarkMode(context)
                                                ? Colors.white60
                                                : const Color(0xff666666),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                ),
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
                      bottom: 25,
                      right: 10,
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
                Positioned(
                  top: 12,
                  right: 25,
                  child:
                      vendorStatus == 'Open'
                          ? Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Color(0XFF3dae7d),
                                size: 10,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Open".tr(),
                                style: const TextStyle(
                                  fontFamily: "Poppinsm",
                                  fontSize: 10,
                                  color: Color(0XFF3dae7d),
                                ),
                              ),
                            ],
                          )
                          : vendorStatus == 'Pre-order'
                          ? Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Color(0XFF3dae7d),
                                size: 10,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Pre-order".tr(),
                                style: const TextStyle(
                                  fontFamily: "Poppinsm",
                                  fontSize: 10,
                                  color: Color(0XFF3dae7d),
                                ),
                              ),
                            ],
                          )
                          : Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Colors.red,
                                size: 10,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Closed".tr(),
                                style: const TextStyle(
                                  fontFamily: "Poppinsm",
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  //   decoration: BoxDecoration(
                  //     color: vendorStatus == 'Open'
                  //         ? Colors.green
                  //         : vendorStatus == 'Pre-order'
                  //         ? Colors.orange
                  //         : Colors.red,
                  //     borderRadius: BorderRadius.circular(5),
                  //   ),
                  //   child: Text(
                  //     vendorStatus,
                  //     style: const TextStyle(
                  //       color: Colors.white,
                  //       fontSize: 13,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  // ),
                ),
              ],
            ),
          );
    } else {
      return Container();
    }
  }

  @override
  void initState() {
    super.initState();
    getRadius();
    getData();
    initializeFlutterFire();
  }

  getRadius() async {
    await FireStoreUtils().getRestaurantNearBy().then((value) {
      if (value != null) {
        getProducts();
      }
    });
  }
}
