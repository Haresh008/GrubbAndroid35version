import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/FavouriteModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constants.dart';
import '../../model/mail_setting.dart';

class FavouriteRestaurantScreen extends StatefulWidget {
  const FavouriteRestaurantScreen({Key? key}) : super(key: key);

  @override
  _FavouriteRestaurantScreenState createState() =>
      _FavouriteRestaurantScreenState();
}

class _FavouriteRestaurantScreenState extends State<FavouriteRestaurantScreen> {
  late Future<List<VendorModel>> vendorFuture;
  final fireStoreUtils = FireStoreUtils();
  List<VendorModel> storeAllLst = [];
  List<FavouriteModel> lstFavourite = [];
  var position = const LatLng(23.12, 70.22);
  bool showLoader = true;
  String placeHolderImage = "";
  VendorModel? vendorModel;

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
    initializeFlutterFire();
    fireStoreUtils.getplaceholderimage().then((value) {
      placeHolderImage = value!;
    });
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          showLoader
              ? Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                ),
              )
              : lstFavourite.isEmpty
              ? showEmptyState('No Favourite Restaurant'.tr(), context)
              : ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                itemCount: lstFavourite.length,
                itemBuilder: (context, index) {
                  if (storeAllLst.isNotEmpty) {
                    for (int a = 0; a < storeAllLst.length; a++) {
                      if (storeAllLst[a].id ==
                          lstFavourite[index].restaurantId) {
                        vendorModel = storeAllLst[a];
                      } else {}
                    }
                  }
                  return vendorModel == null
                      ? Container()
                      : buildAllStoreData(vendorModel!, index);
                },
              ),
    );
  }

  Widget buildAllStoreData(VendorModel vendorModel, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: GestureDetector(
        onTap:
            () => push(
              context,
              NewVendorProductsScreen(vendorModel: vendorModel),
            ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              isDarkMode(context)
                  ? const BoxShadow()
                  : BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                  ),
            ],
          ),
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: getImageVAlidUrl(vendorModel.photo),
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
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          placeHolderImage,
                          fit: BoxFit.cover,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendorModel.title,
                            style: const TextStyle(
                              fontFamily: "Poppinsm",
                              fontSize: 18,
                              color: Color(0xff000000),
                            ),
                            maxLines: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              FavouriteModel favouriteModel = FavouriteModel(
                                restaurantId: vendorModel.id,
                                userId: MyAppState.currentUser!.userID,
                              );
                              lstFavourite.removeWhere(
                                (item) => item.restaurantId == vendorModel.id,
                              );
                              fireStoreUtils.removeFavouriteRestaurant(
                                favouriteModel,
                              );
                            });
                          },
                          child: Icon(
                            Icons.favorite,
                            color: Color(COLOR_PRIMARY),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      vendorModel.location,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: "Poppinsm",
                        fontSize: 16,
                        color: Color(0xff9091A4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 20, color: Color(COLOR_PRIMARY)),
                        const SizedBox(width: 3),
                        Text(
                          vendorModel.reviewsCount != 0
                              ? (vendorModel.reviewsSum /
                                      vendorModel.reviewsCount)
                                  .toStringAsFixed(1)
                              : 0.toString(),
                          style: const TextStyle(
                            fontFamily: "Poppinsm",
                            letterSpacing: 0.5,
                            color: Color(0xff000000),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                          style: const TextStyle(
                            fontFamily: "Poppinsm",
                            letterSpacing: 0.5,
                            color: Color(0xff666666),
                          ),
                        ),
                        const SizedBox(width: 12),
                        vendorModel.freeDelivery == true
                            ? Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 10,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Free Delivery'.tr(),
                                style: TextStyle(
                                  fontFamily: "Poppinsm",
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            : Container(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void getData() {
    fireStoreUtils.getFavouriteRestaurant(MyAppState.currentUser!.userID).then((
      value,
    ) {
      setState(() {
        lstFavourite.clear();
        lstFavourite.addAll(value);
      });
    });
    vendorFuture = fireStoreUtils.getVendors();

    vendorFuture.then((value) {
      setState(() {
        storeAllLst.clear();
        storeAllLst.addAll(value);
        showLoader = false;
      });
    });
  }
}
