import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/public_ext.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/dineInScreen/dine_in_restaurant_details_screen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constants.dart';
import '../../model/mail_setting.dart';

class ViewAllNewArrivalRestaurantScreen extends StatefulWidget {
  const ViewAllNewArrivalRestaurantScreen({
    Key? key,
    this.isPageCallForDineIn = false,
  }) : super(key: key);

  @override
  _ViewAllNewArrivalRestaurantScreenState createState() =>
      _ViewAllNewArrivalRestaurantScreenState();

  final bool? isPageCallForDineIn;
}

class _ViewAllNewArrivalRestaurantScreenState
    extends State<ViewAllNewArrivalRestaurantScreen> {
  Stream<List<VendorModel>>? vendorsFuture;
  final fireStoreUtils = FireStoreUtils();
  Stream<List<VendorModel>>? lstNewArrivalRestaurant;
  var position = LatLng(23.12, 70.22);
  bool showLoader = true;
  List<VendorModel> newArrivalLst = [];

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
    super.initState();
    _getUserLocation();
    initializeFlutterFire();
    fireStoreUtils.getRestaurantNearBy().whenComplete(() {
      setState(() {
        if (widget.isPageCallForDineIn!) {
          lstNewArrivalRestaurant =
              fireStoreUtils
                  .getVendorsForNewArrival(path: "isDineIn")
                  .asBroadcastStream();
        } else {
          lstNewArrivalRestaurant =
              fireStoreUtils.getVendorsForNewArrival().asBroadcastStream();
        }
        showLoader = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGlobal.buildAppBar(context, "New Arrival Restaurants"),
      body: Container(
        color: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : Colors.white,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: StreamBuilder<List<VendorModel>>(
          stream: lstNewArrivalRestaurant,
          initialData: [],
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                ),
              );

            if (snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) {
              newArrivalLst = snapshot.data!;

              return Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                child:
                    showLoader
                        ? Center(
                          child: CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation(
                              Color(COLOR_PRIMARY),
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          physics: BouncingScrollPhysics(),
                          itemCount: newArrivalLst.length,
                          itemBuilder:
                              (context, index) =>
                                  buildPopularsItem(newArrivalLst[index]),
                        ),
              );
            } else {
              return showEmptyState('No Restaurant found'.tr(), context);
            }
          },
        ),
      ),
    );
  }

  Widget buildPopularsItem(VendorModel vendorModel) {
    if (vendorModel.groceryandrestirant == "Restaurant") {
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
                  child: Container(
                    height: 260,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDarkMode(context)
                                ? Colors.grey.shade900
                                : Colors.grey.shade100,
                        width: 0.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDarkMode(context)
                                  ? Colors.black38
                                  : Colors.grey.shade400,
                          blurRadius: 8.0,
                          spreadRadius: 1.2,
                          offset: Offset(0.2, 0.2),
                        ),
                      ],
                      color: Color(DARK_GREY_TEXT_COLOR),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: getImageVAlidUrl(vendorModel.photo),
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
                        SizedBox(height: 8),
                        Container(
                          margin: EdgeInsets.fromLTRB(15, 0, 5, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        Text(
                                          vendorModel.title,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontFamily: "Poppinssm",
                                            letterSpacing: 0.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff666666),
                                          ),
                                        ).tr(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8.0,
                                      bottom: 0,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 20,
                                              color: Color(COLOR_PRIMARY),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              vendorModel.reviewsCount != 0
                                                  ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                                  : 0.toString(),
                                              style: TextStyle(
                                                fontFamily: "Poppinssr",
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff666666),
                                              ),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              "(${vendorModel.reviewsCount})",
                                              style: TextStyle(
                                                fontFamily: "Poppinssr",
                                                letterSpacing: 0.5,
                                                color: Color(0xff666666),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ImageIcon(
                                    AssetImage('assets/images/location3x.png'),
                                    size: 15,
                                    color: Color(0xff555353),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 5,
                                        right: 5,
                                      ),
                                      child: Text(
                                        vendorModel.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: "Poppinssr",
                                          letterSpacing: 0.5,
                                          color: Color(0xff666666),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 5,
                                          width: 5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xff666666),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 10,
                                            right: 10,
                                          ),
                                          child: Text(
                                            getKm(
                                                  vendorModel.latitude,
                                                  vendorModel.longitude,
                                                )! +
                                                " km",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: "Poppinssr",
                                              color: Color(0xff666666),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 25,
                  right: 16.5,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        topLeft: Radius.circular(8),
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
            onTap: () {
              if (widget.isPageCallForDineIn == true) {
                push(
                  context,
                  DineInRestaurantDetailsScreen(vendorModel: vendorModel),
                );
              } else {
                push(
                  context,
                  NewVendorProductsScreen(vendorModel: vendorModel),
                );
              }
            },
            child: Stack(
              children: [
                Container(
                  height: 260,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isDarkMode(context)
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                      width: 0.1,
                    ),
                    boxShadow: [
                      isDarkMode(context)
                          ? BoxShadow()
                          : BoxShadow(
                            color:
                                isDarkMode(context)
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                            blurRadius: 8.0,
                            spreadRadius: 1.2,
                            offset: Offset(0.2, 0.2),
                          ),
                    ],
                    color:
                        isDarkMode(context)
                            ? Color(DARK_CARD_BG_COLOR)
                            : Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: CachedNetworkImage(
                          imageUrl: getImageVAlidUrl(vendorModel.photo),
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
                      SizedBox(height: 8),
                      Container(
                        margin: EdgeInsets.fromLTRB(15, 0, 5, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      Text(
                                        vendorModel.title,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontFamily: "Poppinssm",
                                          letterSpacing: 0.5,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDarkMode(context)
                                                  ? Colors.white
                                                  : Color(0xff000000),
                                        ),
                                      ).tr(),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    bottom: 0,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 20,
                                            color: Color(COLOR_PRIMARY),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            vendorModel.reviewsCount != 0
                                                ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                                : 0.toString(),
                                            style: TextStyle(
                                              fontFamily: "Poppinssr",
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isDarkMode(context)
                                                      ? Color(
                                                        DARK_GREY_TEXT_COLOR,
                                                      )
                                                      : Color(0xff666666),
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            "(${vendorModel.reviewsCount})",
                                            style: TextStyle(
                                              fontFamily: "Poppinssr",
                                              letterSpacing: 0.5,
                                              color:
                                                  isDarkMode(context)
                                                      ? Color(
                                                        DARK_GREY_TEXT_COLOR,
                                                      )
                                                      : Color(0xff666666),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ImageIcon(
                                  AssetImage('assets/images/location3x.png'),
                                  size: 15,
                                  color: Color(0xff555353),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 5,
                                      right: 5,
                                    ),
                                    child: Text(
                                      vendorModel.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: "Poppinssr",
                                        letterSpacing: 0.5,
                                        color:
                                            isDarkMode(context)
                                                ? Color(DARK_GREY_TEXT_COLOR)
                                                : Color(0xff555353),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 5,
                                        width: 5,
                                        decoration: new BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              isDarkMode(context)
                                                  ? Color(DARK_GREY_TEXT_COLOR)
                                                  : Color(0xff555353),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                        ),
                                        child: Text(
                                          getKm(
                                                vendorModel.latitude,
                                                vendorModel.longitude,
                                              )! +
                                              " km",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: "Poppinssr",
                                            color:
                                                isDarkMode(context)
                                                    ? Color(
                                                      DARK_GREY_TEXT_COLOR,
                                                    )
                                                    : Color(0xff555353),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                vendorModel.freeDelivery == true
                    ? Positioned(
                      top: 25,
                      right: 16.5,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 15,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            topLeft: Radius.circular(8),
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
    } else {
      // Handle the UI for non-restaurants if needed
      return Container(); // Return an appropriate widget here for other cases
    }
  }

  void _getUserLocation() async {
    setState(() {
      position = LatLng(
        MyAppState.selectedPosotion.latitude,
        MyAppState.selectedPosotion.longitude,
      );
    });
  }

  @override
  void dispose() {
    fireStoreUtils.closeNewArrivalStream();
    super.dispose();
  }

  String? getKm(double latitude, double longitude) {
    double distanceInMeters = Geolocator.distanceBetween(
      latitude,
      longitude,
      position.latitude,
      position.longitude,
    );
    double kilometer = distanceInMeters / 1000;
    print("KiloMeter$kilometer");

    double minutes = 1.2;
    double value = minutes * kilometer;
    final int hour = value ~/ 60;
    final double minute = value % 60;
    print(
      '${hour.toString().padLeft(2, "0")}:${minute.toStringAsFixed(0).padLeft(2, "0")}',
    );
    return kilometer.toStringAsFixed(2).toString();
  }
}
