import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/BannerModel.dart';
import 'package:foodie_customer/model/FavouriteModel.dart';
import 'package:foodie_customer/model/HomeTextDayanamicModal.dart';
import 'package:foodie_customer/model/ProductModel.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/model/VendorCategoryModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/model/offer_model.dart';
import 'package:foodie_customer/model/story_model.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/Grocery/Groceryhome_page.dart';
import 'package:foodie_customer/ui/categoryDetailsScreen/CategoryDetailsScreen.dart';
import 'package:foodie_customer/ui/cuisinesScreen/CuisinesScreen.dart';
import 'package:foodie_customer/ui/home/CurrentAddressChangeScreen.dart';
import 'package:foodie_customer/ui/home/view_all_category_product_screen.dart';
import 'package:foodie_customer/ui/home/view_all_new_arrival_restaurant_screen.dart';
import 'package:foodie_customer/ui/home/view_all_offer_screen.dart';
import 'package:foodie_customer/ui/home/view_all_popular_food_near_by_screen.dart';
import 'package:foodie_customer/ui/home/view_all_popular_restaurant_screen.dart';
import 'package:foodie_customer/ui/home/view_all_restaurant.dart';
import 'package:foodie_customer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story_view/story_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/mail_setting.dart';
import '../GetAccessTokan/getAccessTokan.dart';

bool isEnable1 = false;
bool isEnable = false;
String? city;
bool resisEnable = true;
bool resisEnable1 = true;

class HomeScreen extends StatefulWidget {
  final User? user;
  final String vendorId;
  String? address;

  HomeScreen({Key? key, required this.user, vendorId, this.address})
    : vendorId = vendorId ?? "",
      super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class KnownLanguages {
  String image;
  String name;

  KnownLanguages({required this.image, required this.name});
}

class _HomeScreenState extends State<HomeScreen> {
  final fireStoreUtils = FireStoreUtils();
  Timer? _timer;
  late Future<List<ProductModel>> productsFuture;

  // final PageController _controller =
  //     PageController(viewportFraction: 0.8, keepPage: true);
  late PageController _controller;
  List<VendorModel> vendors = [];
  List<VendorModel> popularRestaurantLst = [];
  List<VendorModel> newArrivalLst = [];
  List<VendorModel> offerVendorList = [];
  List<OfferModel> offersList = [];
  Stream<List<VendorModel>>? lstAllRestaurant;
  List<ProductModel> lstNearByFood = [];

  late Future<List<FavouriteModel>> lstFavourites;
  List<String> lstFav = [];

  // bool isEnable1 = false;
  String? name = "";

  String? currentLocation = "";

  String? selctedOrderTypeValue = "Delivery".tr();

  bool isLocationPermissionAllowed = false;
  loc.Location location = loc.Location();
  Timer? _timer1;

  // bool isEnable = false;

  // Database db;
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

  Future<List<String>> getCities() async {
    print('athata che');
    // Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Settings document fetch karo
    DocumentSnapshot documentSnapshot =
        await firestore.collection('settings').doc('grubb_mart').get();

    // Check karo ke document ma data chhe ke nahi
    if (documentSnapshot.exists) {
      // Cities field fetch karo
      setState(() {
        isEnable = documentSnapshot.get('isEnable');
      });
      List<String> cities = List<String>.from(documentSnapshot.get('cities'));
      print("citiescities${cities}");

      return cities;
    } else {
      // Default empty list return karo jya data na male
      return [];
    }
  }

  Future<String?> getImageUrl() async {
    print("a call thay cheke nay e mare chek karvu che ");
    try {
      // 'settings' collection માંથી ખાસ document get કરો
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('refServiceScreen') // તમારી document ID મૂકો
              .get();

      if (snapshot.exists) {
        // image field check કરો અને return કરો
        setState(() {
          imageurl = snapshot.get('image');
          print("imageurlimageurlimageurlimageurl${imageurl}");
        });
      } else {
        print('Document does not exist');
        return null;
      }
    } catch (e) {
      print('Error fggdfgdfgdfggdfg: $e');
      return null;
    }
  }

  Future<List<String>> getresturantcities() async {
    print('athata che');

    // Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Settings document fetch karo
    DocumentSnapshot documentSnapshot =
        await firestore.collection('settings').doc('grubb_restau').get();

    // Check karo ke document ma data chhe ke nahi
    if (documentSnapshot.exists) {
      // Cities field fetch karo
      setState(() {
        isEnable = documentSnapshot.get('isEnable');
      });
      List<String> cities = List<String>.from(documentSnapshot.get('cities'));
      print("citiescitiedfdsfsdfsfsfsdfdsffs${cities}");

      return cities;
    } else {
      // Default empty list return karo jya data na male
      return [];
    }
  }

  Future<void> getCityFromCoordinates(double latitude, double longitude) async {
    try {
      // Latitude ane longitude thi location details melvo
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          city = place.locality ?? 'City not found';
        }); // City nu naam melvo
        print('egegfdgdffgddfgdgdgdfgCity: $city');
        gethometest(city.toString());
        getBanner(city.toString());
        List<String> cities = await getCities();
        if (cities.contains(city)) {
          setState(() {
            isEnable = true;
            isEnable1 = true;
          });

          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool('isEnable', isEnable);
          prefs.setBool('isEnable1', isEnable1);
          print("jdksfhsdkfhsdfkhsdkfsdjfk${isEnable}");
          print("jdksfhsdkfhsdfkhsdkfsdjfk${isEnable1}");
          print(
            'Your current city "$city" is available in the Firestore cities.',
          );
        } else {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          setState(() {
            isEnable = false;
            isEnable1 = false;
            prefs.setBool('isEnable', isEnable);
            prefs.setBool('isEnable1', isEnable1);
            print("jdksfhsdkfhsdfkhsdkfsdjfk${isEnable}");
            print("jdksfhsdkfhsdfkhsdkfsdjfk${isEnable1}");
            print(
              'Your current city "$city" is available in the Firestore cities.',
            );
          });
          gethometest(city.toString());
          print(
            'Your current city "$city" is not available in the Firestore cities.',
          );
        }
      } else {
        gethometest(city.toString());
        print('No location found for the given coordinates.');
      }
    } catch (e) {
      print('Error: $e');
      gethometest(city.toString());
    }
  }

  Future<void> getCityrestaurantcity(double latitude, double longitude) async {
    try {
      // Latitude ane longitude thi location details melvo
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality ?? 'City not found'; // City nu naam melvo
        print('egegfdgdffgddfgdgdgdfgCity: $city');
        List<String> cities = await getresturantcities();
        if (cities.contains(city)) {
          setState(() {
            resisEnable1 = true;
            resisEnable1 = true;
          });
          print(
            'restaurant valu ave che  "$city" is available in the Firestore cities.',
          );
        } else {
          setState(() {
            resisEnable1 = false;
            resisEnable = false;
          });
          print(
            'restaurant valu ave che "$city" is not available in the Firestore cities.',
          );
        }
      } else {
        print('No location found for the given coordinates.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String serverToken = '';
  HomeTextDayanamicModal? homeTextdayanamicmodal;

  void getToken() async {
    GetServerToken Getservertoken = GetServerToken();
    serverToken = await Getservertoken.getAccessToken();
    print('serverToken : $serverToken');
  }

  Future<HomeTextDayanamicModal?> gethometest(String city) async {
    await FirebaseFirestore.instance
        .collection("app_home_cms_city_wise")
        .doc(city)
        .get()
        .then((value) {
          if (value.exists) {
            setState(() {
              homeTextdayanamicmodal = HomeTextDayanamicModal.fromJson(
                value.data()!,
              );
            });
            print(
              "homeTextdayanamicmodalhomeTextdayanamicmodalhomeTextdayanamicmodal${homeTextdayanamicmodal?.grubMartTitle.toString()}",
            );
            return homeTextdayanamicmodal;
          } else {
            fetchHomeData();
          }
        });
  }

  void fetchHomeData() async {
    homeTextdayanamicmodal = await FireStoreUtils().gethometest();
    if (homeTextdayanamicmodal != null) {
      debugPrint("Modal Data: $homeTextdayanamicmodal");
    } else {
      debugPrint("No data found in modal.");
    }
  }

  int _currentPage = 0;

  @override
  void initState() {
    initializeFlutterFire();
    // // getIsEnableStatus();
    // getCities();
    getImageUrl();

    setState(() {
      isLoading = true;
      print("setState ini${isLoading}");
    });
    print("isLoading ini${isLoading}");
    super.initState();
    setState(() {
      isLoading = true;
      print("setState ini${isLoading}");
    });
    checkAndFetchLocation();
  }

  List<VendorCategoryModel> categoryWiseProductList = [];

  List<BannerModel> bannerTopHome = [];
  List<BannerModel> bannerMiddleHome = [];

  bool isHomeBannerLoading = true;
  bool isHomeBannerMiddleLoading = true;
  List<OfferModel> offerList = [];
  bool? storyEnable = false;

  getBanner(String city) async {
    fireStoreUtils.getplaceholderimage().then((value) {
      AppGlobal.placeHolderImage = value;
    });
    await fireStoreUtils.getHomeTopBanner(city).then((value) {
      setState(() {
        bannerTopHome = value;
        isHomeBannerLoading = false;
      });
    });
    // getHomeTopBanner(city);

    await fireStoreUtils.getHomePageShowCategory().then((value) {
      setState(() {
        categoryWiseProductList = value;
      });
    });

    fireStoreUtils.getHomeMiddleBanner(city).then((value) {
      if (mounted) {
        setState(() {
          bannerMiddleHome = value;
          isHomeBannerMiddleLoading = false;
        });
      }
    });

    await FireStoreUtils().getPublicCoupons(city).then((value) {
      if (mounted) {
        setState(() {
          offerList = value;
        });
      }
    });

    await FirebaseFirestore.instance
        .collection(Setting)
        .doc('story')
        .get()
        .then((value) {
          setState(() {
            storyEnable = value.data()!['isEnabled'];
          });
        });
  }

  // Future<List<BannerModel>> getHomeTopBanner(String userCity) async {
  //
  //
  //   QuerySnapshot<Map<String, dynamic>> bannerHomeQuery = await FirebaseFirestore.instance
  //       .collection(MENU_ITEM)
  //       .where("is_grocery_banner", isEqualTo: false)
  //       .where("is_publish", isEqualTo: true)
  //       .where("position", isEqualTo: "top")
  //       .where("cities", arrayContains: userCity) // cities એરેમાં city match કરવું
  //       .orderBy("set_order", descending: false)
  //       .get();
  //
  //   for (var document in bannerHomeQuery.docs) {
  //     try {
  //       bannerTopHome.add(BannerModel.fromJson(document.data()));
  //     } catch (e) {
  //       debugPrint('FireStoreUtils.getHomeTopBanner Parse error $e');
  //     }
  //   }
  //   setState(() {
  //     isHomeBannerLoading = false;
  //   });
  //   return bannerTopHome;
  // }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:
            isDarkMode(context)
                ? const Color(DARK_BG_COLOR)
                : const Color(0xffFFFFFF),
        body:
            isLoading
                ? Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  ),
                )
                : SingleChildScrollView(
                  child: Container(
                    color:
                        isDarkMode(context)
                            ? const Color(DARK_COLOR)
                            : const Color(0xffFFFFFF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            color: Colors.black,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child:
                                            Text(
                                              currentLocation.toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: "Poppinsr",
                                              ),
                                            ).tr(),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          getPermission();
                                          // sendMail(body: "hello",subject: "cddcdc",recipients: ['rma4005@gmail.com']);
                                          Navigator.of(context)
                                              .push(
                                                PageRouteBuilder(
                                                  pageBuilder:
                                                      (
                                                        context,
                                                        animation,
                                                        secondaryAnimation,
                                                      ) =>
                                                          const CurrentAddressChangeScreen(),
                                                  transitionsBuilder: (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child,
                                                  ) {
                                                    return child;
                                                  },
                                                ),
                                              )
                                              .then((value) {
                                                if (value != null && mounted) {
                                                  setState(() {
                                                    currentLocation = value;
                                                    getData();
                                                  });
                                                }
                                              });
                                          getData();
                                        },
                                        child: Text("Change".tr()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Color(COLOR_PRIMARY),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          elevation: 4.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    bottom: 5,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child:
                                            Text(
                                              homeTextdayanamicmodal
                                                      ?.findRestaurantTitle ??
                                                  "",
                                              // "Find your Restaurant"
                                              //     .tr(),
                                              style: TextStyle(
                                                fontSize: 22,
                                                color: Colors.white,
                                                fontFamily: "Poppinssb",
                                              ),
                                            ).tr(),
                                      ),
                                      // DropdownButton(
                                      //   // Not necessary for Option 1
                                      //   value: selctedOrderTypeValue,
                                      //   isDense: true,
                                      //   dropdownColor: Colors.black,
                                      //   onChanged: (newValue) async {
                                      //     int cartProd = 0;
                                      //     await Provider.of<
                                      //                 CartDatabase>(
                                      //             context,
                                      //             listen: false)
                                      //         .allCartProducts
                                      //         .then((value) {
                                      //       cartProd = value.length;
                                      //     });
                                      //
                                      //     if (cartProd > 0) {
                                      //       showDialog(
                                      //         context: context,
                                      //         builder: (BuildContext
                                      //                 context) =>
                                      //             ShowDialogToDismiss(
                                      //           title: '',
                                      //           content:
                                      //               "Do you really want to change the delivery option?"
                                      //                       .tr() +
                                      //                   "Your cart will be empty"
                                      //                       .tr(),
                                      //           buttonText:
                                      //               'CLOSE'.tr(),
                                      //           secondaryButtonText:
                                      //               'OK'.tr(),
                                      //           action: () {
                                      //             Navigator.of(context)
                                      //                 .pop();
                                      //             Provider.of<CartDatabase>(
                                      //                     context,
                                      //                     listen: false)
                                      //                 .deleteAllProducts();
                                      //             setState(() {
                                      //               selctedOrderTypeValue =
                                      //                   newValue
                                      //                       .toString();
                                      //               saveFoodTypeValue();
                                      //               getData();
                                      //             });
                                      //           },
                                      //         ),
                                      //       );
                                      //     } else {
                                      //       setState(() {
                                      //         selctedOrderTypeValue =
                                      //             newValue.toString();
                                      //
                                      //         saveFoodTypeValue();
                                      //         getData();
                                      //       });
                                      //     }
                                      //   },
                                      //   icon: const Icon(
                                      //     Icons.keyboard_arrow_down,
                                      //     color: Colors.white,
                                      //   ),
                                      //   items: [
                                      //     'Delivery'.tr(),
                                      //     // 'Takeaway'.tr(),
                                      //   ].map((location) {
                                      //     return DropdownMenuItem(
                                      //       child: Text(location,
                                      //           style: TextStyle(
                                      //               color:
                                      //                   Colors.white)),
                                      //       value: location,
                                      //     );
                                      //   }).toList(),
                                      // )
                                    ],
                                  ),
                                ),
                                resisEnable1 && resisEnable1
                                    ? Visibility(
                                      visible: storyEnable == true,
                                      child: storyWidget(),
                                    )
                                    : Container(),
                              ],
                            ),
                          ),
                        ),

                        // isEnable && isEnable1
                        //     ? Container(
                        //         color: isDarkMode(context)
                        //             ? const Color(DARK_COLOR)
                        //             : const Color(0xffFFFFFF),
                        //         child: FutureBuilder<
                        //                 List<VendorCategoryModel>>(
                        //             future: fireStoreUtils.getCuisines1(),
                        //             initialData: const [],
                        //             builder: (context, snapshot) {
                        //               if (snapshot.connectionState ==
                        //                   ConnectionState.waiting) {
                        //                 return Center(
                        //                   child: CircularProgressIndicator
                        //                       .adaptive(
                        //                     valueColor:
                        //                         AlwaysStoppedAnimation(
                        //                             Color(COLOR_PRIMARY)),
                        //                   ),
                        //                 );
                        //               }
                        //
                        //               if ((snapshot.hasData ||
                        //                       (snapshot.data?.isNotEmpty ??
                        //                           false)) &&
                        //                   mounted) {
                        //                 return Container(
                        //                     padding: const EdgeInsets.only(
                        //                         left: 10),
                        //                     height: 150,
                        //                     child: ListView.builder(
                        //                       scrollDirection:
                        //                           Axis.horizontal,
                        //                       itemCount: snapshot
                        //                                   .data!.length >=
                        //                               15
                        //                           ? 15
                        //                           : snapshot.data!.length,
                        //                       itemBuilder:
                        //                           (context, index) {
                        //                         return buildGrocerygo(
                        //                             snapshot.data![index]);
                        //                       },
                        //                     ));
                        //               } else {
                        //                 return showEmptyState(
                        //                     'No Categories'.tr(), context);
                        //               }
                        //             }),
                        //       )
                        //     : Container(
                        //   alignment: Alignment.center,
                        //
                        //     height: 200,
                        //     child:
                        // Image(
                        //   image: AssetImage("assets/images/oops.png"),
                        //   width: 500,
                        //   color: isDarkMode(context) ? Colors.white : null,
                        // )
                        // ),
                        resisEnable1 && resisEnable1
                            ? Column(
                              children: [
                                isEnable && isEnable1
                                    ? buildTitleRow(
                                      titleValue:
                                          homeTextdayanamicmodal
                                              ?.grubMartTitle ??
                                          "",
                                      // "Grubb Mart",
                                      onClick: () {
                                        push(
                                          context,
                                          GroceryHome(
                                            isPageCallFromHomeScreen: true,
                                            user: MyAppState.currentUser,
                                          ),
                                        );
                                      },
                                    )
                                    : Container(),
                                isEnable && isEnable1
                                    ? Container(
                                      color:
                                          isDarkMode(context)
                                              ? const Color(DARK_COLOR)
                                              : const Color(0xffFFFFFF),
                                      child: FutureBuilder<
                                        List<VendorCategoryModel>
                                      >(
                                        future: fireStoreUtils.getCuisines1(),
                                        initialData: const [],
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                              child:
                                                  CircularProgressIndicator.adaptive(
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                          Color(COLOR_PRIMARY),
                                                        ),
                                                  ),
                                            );
                                          }

                                          if ((snapshot.hasData ||
                                                  (snapshot.data?.isNotEmpty ??
                                                      false)) &&
                                              mounted) {
                                            return Container(
                                              padding: const EdgeInsets.only(
                                                left: 10,
                                              ),
                                              height: 150,
                                              child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount:
                                                    snapshot.data!.length >= 15
                                                        ? 15
                                                        : snapshot.data!.length,
                                                itemBuilder: (context, index) {
                                                  return buildGrocerygo(
                                                    snapshot.data![index],
                                                  );
                                                },
                                              ),
                                            );
                                          } else {
                                            return showEmptyState(
                                              homeTextdayanamicmodal
                                                      ?.foodCategoriesEmptyMsg ??
                                                  "",
                                              // 'No Categories'.tr(),
                                              context,
                                            );
                                          }
                                        },
                                      ),
                                    )
                                    : Container(),
                                buildTitleRow(
                                  titleValue:
                                      homeTextdayanamicmodal
                                          ?.foodCategoriesTitle ??
                                      "",
                                  // "Food Categories".tr(),
                                  onClick: () {
                                    push(
                                      context,
                                      const CuisinesScreen(
                                        isPageCallFromHomeScreen: true,
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  color:
                                      isDarkMode(context)
                                          ? const Color(DARK_COLOR)
                                          : const Color(0xffFFFFFF),
                                  child: FutureBuilder<
                                    List<VendorCategoryModel>
                                  >(
                                    future: fireStoreUtils.getCuisines(),
                                    initialData: const [],
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                          child:
                                              CircularProgressIndicator.adaptive(
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      Color(COLOR_PRIMARY),
                                                    ),
                                              ),
                                        );
                                      }

                                      if ((snapshot.hasData ||
                                              (snapshot.data?.isNotEmpty ??
                                                  false)) &&
                                          mounted) {
                                        return Container(
                                          padding: const EdgeInsets.only(
                                            left: 10,
                                          ),
                                          height: 150,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount:
                                                snapshot.data!.length >= 15
                                                    ? 15
                                                    : snapshot.data!.length,
                                            itemBuilder: (context, index) {
                                              return buildCategoryItem(
                                                snapshot.data![index],
                                              );
                                            },
                                          ),
                                        );
                                      } else {
                                        return showEmptyState(
                                          homeTextdayanamicmodal
                                                  ?.foodCategoriesEmptyMsg ??
                                              "",
                                          // 'No Categories'.tr(),
                                          context,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Visibility(
                                  visible: bannerTopHome.isNotEmpty,
                                  child: Container(
                                    color:
                                        isDarkMode(context)
                                            ? const Color(DARK_COLOR)
                                            : const Color(0xffFFFFFF),
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child:
                                        isHomeBannerLoading
                                            ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : SizedBox(
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.23,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                child: CarouselSlider(
                                                  options: CarouselOptions(
                                                    height: 200.0,
                                                    // તમારી જરૂર મુજબ ઊંચાઇ
                                                    autoPlay: true,
                                                    enlargeFactor: 0.001,
                                                    // ઓટોપ્લે સ્લાઇડિંગ
                                                    enlargeCenterPage: true,
                                                    // મધ્યમાં મોટી ઇમેજ દેખાશે
                                                    viewportFraction:
                                                        0.85, // એક સાથે કેટલાં બેનર દેખાશે
                                                  ),
                                                  items:
                                                      bannerTopHome.map((item) {
                                                        return buildBestDealPage(
                                                          item,
                                                        );
                                                      }).toList(),
                                                ),
                                                // PageView.builder(
                                                //     padEnds: false,
                                                //     itemCount: bannerTopHome.length,
                                                //     scrollDirection:
                                                //     Axis.horizontal,
                                                //     controller: _controller,
                                                //     itemBuilder: (context, index) =>
                                                //         buildBestDealPage(
                                                //             bannerTopHome[index])),
                                              ),
                                            ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    buildTitleRow(
                                      titleValue:
                                          homeTextdayanamicmodal
                                              ?.seeNeighborsBorderingTitle ??
                                          "",
                                      // "See what your neighbors are ordering"
                                      //     .tr(),
                                      onClick: () {
                                        push(
                                          context,
                                          const ViewAllPopularFoodNearByScreen(),
                                        );
                                      },
                                    ),
                                    SizedBox(
                                      height: 120,
                                      child:
                                          lstNearByFood.isEmpty
                                              ? showEmptyState(
                                                homeTextdayanamicmodal
                                                        ?.seeNeighborsBorderingEmptyMsg ??
                                                    "",
                                                // 'No popular Item found'.tr(),
                                                context,
                                              )
                                              : ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount:
                                                    lstNearByFood.length >= 15
                                                        ? 15
                                                        : lstNearByFood.length,
                                                itemBuilder: (context, index) {
                                                  VendorModel?
                                                  popularNearFoodVendorModel;
                                                  if (vendors.isNotEmpty) {
                                                    for (
                                                      int a = 0;
                                                      a < vendors.length;
                                                      a++
                                                    ) {
                                                      if (vendors[a].id ==
                                                          lstNearByFood[index]
                                                              .vendorID) {
                                                        popularNearFoodVendorModel =
                                                            vendors[a];
                                                      }
                                                    }
                                                  }
                                                  return popularNearFoodVendorModel ==
                                                          null
                                                      ? Container()
                                                      : popularFoodItem(
                                                        context,
                                                        lstNearByFood[index],
                                                        popularNearFoodVendorModel,
                                                      );
                                                },
                                              ),
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    buildTitleRow(
                                      titleValue:
                                          homeTextdayanamicmodal
                                              ?.newArrivalsTitle ??
                                          "",
                                      // "New Arrivals".tr(),
                                      onClick: () {
                                        push(
                                          context,
                                          const ViewAllNewArrivalRestaurantScreen(),
                                        );
                                      },
                                    ),
                                    StreamBuilder<List<VendorModel>>(
                                      stream:
                                          fireStoreUtils
                                              .getVendorsForNewArrival()
                                              .asBroadcastStream(),
                                      initialData: const [],
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child:
                                                CircularProgressIndicator.adaptive(
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                        Color(COLOR_PRIMARY),
                                                      ),
                                                ),
                                          );
                                        }

                                        if ((snapshot.hasData ||
                                                (snapshot.data?.isNotEmpty ??
                                                    false)) &&
                                            mounted) {
                                          newArrivalLst = snapshot.data!;

                                          return newArrivalLst.isEmpty
                                              ? showEmptyState(
                                                homeTextdayanamicmodal
                                                        ?.newArrivalsEmptyMsg ??
                                                    "",
                                                // 'No Vendors'.tr(),
                                                context,
                                              )
                                              : Container(
                                                width:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width,
                                                height: 260,
                                                margin:
                                                    const EdgeInsets.fromLTRB(
                                                      10,
                                                      0,
                                                      0,
                                                      10,
                                                    ),
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  itemCount:
                                                      newArrivalLst.length >= 15
                                                          ? 15
                                                          : newArrivalLst
                                                              .length,
                                                  itemBuilder:
                                                      (
                                                        context,
                                                        index,
                                                      ) => buildNewArrivalItem(
                                                        newArrivalLst[index],
                                                      ),
                                                ),
                                              );
                                        } else {
                                          return showEmptyState(
                                            homeTextdayanamicmodal
                                                    ?.newArrivalsEmptyMsg ??
                                                "",
                                            // 'No Vendors'.tr(),
                                            context,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                buildTitleRow(
                                  titleValue:
                                      homeTextdayanamicmodal
                                          ?.offerForYouTitle ??
                                      "",
                                  // "Offers For You".tr(),
                                  onClick: () {
                                    push(
                                      context,
                                      OffersScreen(vendors: vendors),
                                    );
                                  },
                                ),
                                offerVendorList.isEmpty
                                    ? showEmptyState(
                                      homeTextdayanamicmodal
                                              ?.offerForYouEmptyMsg ??
                                          "",
                                      // 'No Offers Found'.tr(),
                                      context,
                                    )
                                    : Container(
                                      width: MediaQuery.of(context).size.width,
                                      height: 300,
                                      margin: const EdgeInsets.fromLTRB(
                                        10,
                                        0,
                                        0,
                                        10,
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount:
                                            offerVendorList.length >= 15
                                                ? 15
                                                : offerVendorList.length,
                                        itemBuilder: (context, index) {
                                          return buildCouponsForYouItem(
                                            context,
                                            offerVendorList[index],
                                            offersList[index],
                                          );
                                        },
                                      ),
                                    ),
                                Visibility(
                                  visible: bannerMiddleHome.isNotEmpty,
                                  child: Container(
                                    color:
                                        isDarkMode(context)
                                            ? const Color(DARK_COLOR)
                                            : const Color(0xffFFFFFF),
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child:
                                        isHomeBannerMiddleLoading
                                            ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : SizedBox(
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.23,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                child: CarouselSlider(
                                                  options: CarouselOptions(
                                                    height: 200.0,
                                                    // તમારી જરૂર મુજબ ઊંચાઇ
                                                    autoPlay: true,
                                                    enlargeFactor: 0.001,
                                                    // ઓટોપ્લે સ્લાઇડિંગ
                                                    enlargeCenterPage: true,
                                                    // મધ્યમાં મોટી ઇમેજ દેખાશે
                                                    viewportFraction:
                                                        0.85, // એક સાથે કેટલાં બેનર દેખાશે
                                                  ),
                                                  items:
                                                      bannerMiddleHome.map((
                                                        item,
                                                      ) {
                                                        return buildBestDealPage(
                                                          item,
                                                        );
                                                      }).toList(),
                                                ),
                                                // PageView.builder(
                                                //     padEnds: false,
                                                //     itemCount:
                                                //     bannerMiddleHome.length,
                                                //     scrollDirection:
                                                //     Axis.horizontal,
                                                //     controller: _controller,
                                                //     itemBuilder: (context, index) =>
                                                //         buildBestDealPage(
                                                //             bannerMiddleHome[
                                                //             index])),
                                              ),
                                            ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    buildTitleRow(
                                      titleValue:
                                          homeTextdayanamicmodal
                                              ?.popularRestaurantTitle ??
                                          "",
                                      // "Popular Restaurant".tr(),
                                      onClick: () {
                                        push(
                                          context,
                                          const ViewAllPopularRestaurantScreen(),
                                        );
                                      },
                                    ),
                                    popularRestaurantLst.isEmpty
                                        ? showEmptyState(
                                          homeTextdayanamicmodal
                                                  ?.popularRestaurantEmptyMsg ??
                                              "",
                                          // 'No Popular restaurant'.tr(),
                                          context,
                                        )
                                        : Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: 260,
                                          margin: const EdgeInsets.fromLTRB(
                                            10,
                                            0,
                                            0,
                                            10,
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.horizontal,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount:
                                                popularRestaurantLst.length >= 5
                                                    ? 5
                                                    : popularRestaurantLst
                                                        .length,
                                            itemBuilder:
                                                (
                                                  context,
                                                  index,
                                                ) => buildPopularsItem(
                                                  popularRestaurantLst[index],
                                                ),
                                          ),
                                        ),
                                  ],
                                ),
                                ListView.builder(
                                  itemCount: categoryWiseProductList.length,
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context, index) {
                                    return StreamBuilder<List<VendorModel>>(
                                      stream: FireStoreUtils()
                                          .getCategoryRestaurants(
                                            categoryWiseProductList[index].id
                                                .toString(),
                                          ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child:
                                                CircularProgressIndicator.adaptive(
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                        Color(COLOR_PRIMARY),
                                                      ),
                                                ),
                                          );
                                        }
                                        if ((snapshot.hasData ||
                                                (snapshot.data?.isNotEmpty ??
                                                    false)) &&
                                            mounted) {
                                          return snapshot.data!.isEmpty
                                              ? Container()
                                              : Column(
                                                children: [
                                                  buildTitleRow(
                                                    titleValue:
                                                        categoryWiseProductList[index]
                                                            .title
                                                            .toString(),
                                                    onClick: () {
                                                      push(
                                                        context,
                                                        ViewAllCategoryProductScreen(
                                                          vendorCategoryModel:
                                                              categoryWiseProductList[index],
                                                        ),
                                                      );
                                                    },
                                                    isViewAll: false,
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width,
                                                    height:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.height *
                                                        0.28,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                          ),
                                                      child: ListView.builder(
                                                        shrinkWrap: true,
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        physics:
                                                            const BouncingScrollPhysics(),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        itemCount:
                                                            snapshot
                                                                .data!
                                                                .length,
                                                        itemBuilder: (
                                                          context,
                                                          index,
                                                        ) {
                                                          VendorModel
                                                          vendorModel =
                                                              snapshot
                                                                  .data![index];
                                                          double
                                                          distanceInMeters =
                                                              Geolocator.distanceBetween(
                                                                vendorModel
                                                                    .latitude,
                                                                vendorModel
                                                                    .longitude,
                                                                MyAppState
                                                                    .selectedPosotion
                                                                    .latitude,
                                                                MyAppState
                                                                    .selectedPosotion
                                                                    .longitude,
                                                              );
                                                          double kilometer =
                                                              distanceInMeters /
                                                              1000;
                                                          double minutes = 1.2;
                                                          double value =
                                                              minutes *
                                                              kilometer;
                                                          final int hour =
                                                              value ~/ 60;
                                                          final double minute =
                                                              value % 60;
                                                          return Container(
                                                            margin:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 8,
                                                                ),
                                                            child:
                                                                vendorModel
                                                                        .commingsoon
                                                                    ? GestureDetector(
                                                                      onTap: () {
                                                                        ScaffoldMessenger.of(
                                                                          context,
                                                                        ).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text(
                                                                              "Ah! I see you are already excited about the upcoming outlet on the platform. Stay tuned 😉".tr(),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: Stack(
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                MediaQuery.of(
                                                                                  context,
                                                                                ).size.width *
                                                                                0.65,
                                                                            child: ColorFiltered(
                                                                              colorFilter: ColorFilter.matrix(
                                                                                <
                                                                                  double
                                                                                >[
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
                                                                                ],
                                                                              ),
                                                                              child: Container(
                                                                                decoration: BoxDecoration(
                                                                                  borderRadius: BorderRadius.circular(
                                                                                    20,
                                                                                  ),
                                                                                  border: Border.all(
                                                                                    color: Color(
                                                                                      0xff666666,
                                                                                    ),
                                                                                    width:
                                                                                        1,
                                                                                  ),
                                                                                  color: Color(
                                                                                    DARK_GREY_TEXT_COLOR,
                                                                                  ),
                                                                                  boxShadow: [
                                                                                    BoxShadow(
                                                                                      color: Colors.grey.withOpacity(
                                                                                        0.5,
                                                                                      ),
                                                                                      blurRadius:
                                                                                          5,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                                child: Column(
                                                                                  crossAxisAlignment:
                                                                                      CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Expanded(
                                                                                      child: Stack(
                                                                                        children: [
                                                                                          CachedNetworkImage(
                                                                                            imageUrl: getImageVAlidUrl(
                                                                                              vendorModel.photo,
                                                                                            ),
                                                                                            imageBuilder:
                                                                                                (
                                                                                                  context,
                                                                                                  imageProvider,
                                                                                                ) => Container(
                                                                                                  decoration: BoxDecoration(
                                                                                                    borderRadius: BorderRadius.only(
                                                                                                      topLeft: Radius.circular(
                                                                                                        20,
                                                                                                      ),
                                                                                                      topRight: Radius.circular(
                                                                                                        20,
                                                                                                      ),
                                                                                                    ),
                                                                                                    image: DecorationImage(
                                                                                                      image:
                                                                                                          imageProvider,
                                                                                                      fit:
                                                                                                          BoxFit.cover,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                            placeholder:
                                                                                                (
                                                                                                  context,
                                                                                                  url,
                                                                                                ) => Center(
                                                                                                  child: CircularProgressIndicator.adaptive(
                                                                                                    valueColor: AlwaysStoppedAnimation(
                                                                                                      Color(
                                                                                                        COLOR_PRIMARY,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                            errorWidget:
                                                                                                (
                                                                                                  context,
                                                                                                  url,
                                                                                                  error,
                                                                                                ) => ClipRRect(
                                                                                                  borderRadius: BorderRadius.only(
                                                                                                    topLeft: Radius.circular(
                                                                                                      20,
                                                                                                    ),
                                                                                                    topRight: Radius.circular(
                                                                                                      20,
                                                                                                    ),
                                                                                                  ),
                                                                                                  child: Image.network(
                                                                                                    AppGlobal.placeHolderImage!,
                                                                                                    width:
                                                                                                        MediaQuery.of(
                                                                                                          context,
                                                                                                        ).size.width *
                                                                                                        0.75,
                                                                                                    fit:
                                                                                                        BoxFit.contain,
                                                                                                  ),
                                                                                                ),
                                                                                            fit:
                                                                                                BoxFit.cover,
                                                                                          ),
                                                                                          // Positioned(
                                                                                          //   bottom: 10,
                                                                                          //   right: 10,
                                                                                          //   child: Container(
                                                                                          //     decoration: BoxDecoration(
                                                                                          //       color: Colors.green,
                                                                                          //       borderRadius: BorderRadius.circular(5),
                                                                                          //     ),
                                                                                          //     child: Padding(
                                                                                          //       padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                                                          //       child: Row(
                                                                                          //         mainAxisSize: MainAxisSize.min,
                                                                                          //         children: [
                                                                                          //           Text(
                                                                                          //             vendorModel.reviewsSum > 0 ? (vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1) : "",
                                                                                          //             style: const TextStyle(
                                                                                          //               fontFamily: "Poppinsm",
                                                                                          //               letterSpacing: 0.5,
                                                                                          //               fontSize: 12,
                                                                                          //               color: Colors.white,
                                                                                          //             ),
                                                                                          //           ),
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
                                                                                    const SizedBox(
                                                                                      height:
                                                                                          5,
                                                                                    ),
                                                                                    Padding(
                                                                                      padding: const EdgeInsets.symmetric(
                                                                                        horizontal:
                                                                                            5,
                                                                                      ),
                                                                                      child: Column(
                                                                                        crossAxisAlignment:
                                                                                            CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          Text(
                                                                                            vendorModel.title,
                                                                                            maxLines:
                                                                                                1,
                                                                                            style: TextStyle(
                                                                                              fontFamily:
                                                                                                  "Poppinsm",
                                                                                              fontSize:
                                                                                                  16,
                                                                                              color: Color(
                                                                                                0xff666666,
                                                                                              ),
                                                                                              fontWeight:
                                                                                                  FontWeight.w700,
                                                                                              letterSpacing:
                                                                                                  0.2,
                                                                                            ),
                                                                                          ).tr(),
                                                                                          const SizedBox(
                                                                                            height:
                                                                                                5,
                                                                                          ),
                                                                                          Row(
                                                                                            children: [
                                                                                              Icon(
                                                                                                Icons.location_pin,
                                                                                                color: Color(
                                                                                                  COLOR_PRIMARY,
                                                                                                ),
                                                                                                size:
                                                                                                    20,
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width:
                                                                                                    5,
                                                                                              ),
                                                                                              Expanded(
                                                                                                child:
                                                                                                    Text(
                                                                                                      vendorModel.location,
                                                                                                      maxLines:
                                                                                                          1,
                                                                                                      style: TextStyle(
                                                                                                        fontFamily:
                                                                                                            "Poppinsm",
                                                                                                        color: Color(
                                                                                                          0xff666666,
                                                                                                        ),
                                                                                                      ),
                                                                                                    ).tr(),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          const SizedBox(
                                                                                            height:
                                                                                                5,
                                                                                          ),
                                                                                          Row(
                                                                                            children: [
                                                                                              Icon(
                                                                                                Icons.timer_sharp,
                                                                                                color: Color(
                                                                                                  COLOR_PRIMARY,
                                                                                                ),
                                                                                                size:
                                                                                                    20,
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width:
                                                                                                    5,
                                                                                              ),
                                                                                              Text(
                                                                                                '${hour.toString().padLeft(2, "0")}h ${minute.toStringAsFixed(0).padLeft(2, "0")}m',
                                                                                                style: TextStyle(
                                                                                                  fontFamily:
                                                                                                      "Poppinsm",
                                                                                                  letterSpacing:
                                                                                                      0.5,
                                                                                                  color: Color(
                                                                                                    0xff666666,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width:
                                                                                                    10,
                                                                                              ),
                                                                                              Icon(
                                                                                                Icons.my_location_sharp,
                                                                                                color: Color(
                                                                                                  COLOR_PRIMARY,
                                                                                                ),
                                                                                                size:
                                                                                                    20,
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width:
                                                                                                    10,
                                                                                              ),
                                                                                              Text(
                                                                                                "${kilometer.toDouble().toStringAsFixed(currencyModel!.decimal)} km",
                                                                                                style: TextStyle(
                                                                                                  fontFamily:
                                                                                                      "Poppinsm",
                                                                                                  letterSpacing:
                                                                                                      0.5,
                                                                                                  color: Color(
                                                                                                    0xff666666,
                                                                                                  ),
                                                                                                ),
                                                                                              ).tr(),
                                                                                            ],
                                                                                          ),
                                                                                          SizedBox(
                                                                                            height:
                                                                                                5,
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Positioned(
                                                                            top:
                                                                                17,
                                                                            right:
                                                                                -5,
                                                                            child: Container(
                                                                              padding: EdgeInsets.symmetric(
                                                                                vertical:
                                                                                    5,
                                                                                horizontal:
                                                                                    15,
                                                                              ),
                                                                              alignment:
                                                                                  Alignment.center,
                                                                              decoration: BoxDecoration(
                                                                                color:
                                                                                    Colors.red,
                                                                                borderRadius: BorderRadius.circular(
                                                                                  8,
                                                                                ),
                                                                              ),
                                                                              child: Text(
                                                                                'coming_soon'.tr(),
                                                                                style: TextStyle(
                                                                                  fontFamily:
                                                                                      "Poppinsm",
                                                                                  color:
                                                                                      Colors.white,
                                                                                  fontWeight:
                                                                                      FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    )
                                                                    : GestureDetector(
                                                                      onTap: () async {
                                                                        push(
                                                                          context,
                                                                          NewVendorProductsScreen(
                                                                            vendorModel:
                                                                                vendorModel,
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: Stack(
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                MediaQuery.of(
                                                                                  context,
                                                                                ).size.width *
                                                                                0.65,
                                                                            child: Container(
                                                                              decoration: BoxDecoration(
                                                                                borderRadius: BorderRadius.circular(
                                                                                  20,
                                                                                ),
                                                                                border: Border.all(
                                                                                  color:
                                                                                      isDarkMode(
                                                                                            context,
                                                                                          )
                                                                                          ? const Color(
                                                                                            DarkContainerBorderColor,
                                                                                          )
                                                                                          : Colors.grey.shade100,
                                                                                  width:
                                                                                      1,
                                                                                ),
                                                                                color:
                                                                                    isDarkMode(
                                                                                          context,
                                                                                        )
                                                                                        ? const Color(
                                                                                          DarkContainerColor,
                                                                                        )
                                                                                        : Colors.white,
                                                                                boxShadow: [
                                                                                  isDarkMode(
                                                                                        context,
                                                                                      )
                                                                                      ? const BoxShadow()
                                                                                      : BoxShadow(
                                                                                        color: Colors.grey.withOpacity(
                                                                                          0.5,
                                                                                        ),
                                                                                        blurRadius:
                                                                                            5,
                                                                                      ),
                                                                                ],
                                                                              ),
                                                                              child: Column(
                                                                                crossAxisAlignment:
                                                                                    CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Expanded(
                                                                                    child: Stack(
                                                                                      children: [
                                                                                        CachedNetworkImage(
                                                                                          imageUrl: getImageVAlidUrl(
                                                                                            vendorModel.photo,
                                                                                          ),
                                                                                          imageBuilder:
                                                                                              (
                                                                                                context,
                                                                                                imageProvider,
                                                                                              ) => Container(
                                                                                                decoration: BoxDecoration(
                                                                                                  borderRadius: BorderRadius.only(
                                                                                                    topLeft: Radius.circular(
                                                                                                      20,
                                                                                                    ),
                                                                                                    topRight: Radius.circular(
                                                                                                      20,
                                                                                                    ),
                                                                                                  ),
                                                                                                  image: DecorationImage(
                                                                                                    image:
                                                                                                        imageProvider,
                                                                                                    fit:
                                                                                                        BoxFit.cover,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                          placeholder:
                                                                                              (
                                                                                                context,
                                                                                                url,
                                                                                              ) => Center(
                                                                                                child: CircularProgressIndicator.adaptive(
                                                                                                  valueColor: AlwaysStoppedAnimation(
                                                                                                    Color(
                                                                                                      COLOR_PRIMARY,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                          errorWidget:
                                                                                              (
                                                                                                context,
                                                                                                url,
                                                                                                error,
                                                                                              ) => ClipRRect(
                                                                                                borderRadius: BorderRadius.only(
                                                                                                  topLeft: Radius.circular(
                                                                                                    20,
                                                                                                  ),
                                                                                                  topRight: Radius.circular(
                                                                                                    20,
                                                                                                  ),
                                                                                                ),
                                                                                                child: Image.network(
                                                                                                  AppGlobal.placeHolderImage!,
                                                                                                  width:
                                                                                                      MediaQuery.of(
                                                                                                        context,
                                                                                                      ).size.width *
                                                                                                      0.75,
                                                                                                  fit:
                                                                                                      BoxFit.contain,
                                                                                                ),
                                                                                              ),
                                                                                          fit:
                                                                                              BoxFit.cover,
                                                                                        ),
                                                                                        Positioned(
                                                                                          bottom:
                                                                                              10,
                                                                                          right:
                                                                                              10,
                                                                                          child: Container(
                                                                                            decoration: BoxDecoration(
                                                                                              color:
                                                                                                  Colors.green,
                                                                                              borderRadius: BorderRadius.circular(
                                                                                                5,
                                                                                              ),
                                                                                            ),
                                                                                            child: Padding(
                                                                                              padding: const EdgeInsets.symmetric(
                                                                                                horizontal:
                                                                                                    5,
                                                                                                vertical:
                                                                                                    2,
                                                                                              ),
                                                                                              child: Row(
                                                                                                mainAxisSize:
                                                                                                    MainAxisSize.min,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    vendorModel.reviewsSum >
                                                                                                            0
                                                                                                        ? (vendorModel.reviewsSum /
                                                                                                                vendorModel.reviewsCount)
                                                                                                            .toStringAsFixed(
                                                                                                              1,
                                                                                                            )
                                                                                                        : "",
                                                                                                    style: const TextStyle(
                                                                                                      fontFamily:
                                                                                                          "Poppinsm",
                                                                                                      letterSpacing:
                                                                                                          0.5,
                                                                                                      fontSize:
                                                                                                          12,
                                                                                                      color:
                                                                                                          Colors.white,
                                                                                                    ),
                                                                                                  ),
                                                                                                  const SizedBox(
                                                                                                    width:
                                                                                                        3,
                                                                                                  ),
                                                                                                  const Icon(
                                                                                                    Icons.star,
                                                                                                    size:
                                                                                                        16,
                                                                                                    color:
                                                                                                        Colors.white,
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(
                                                                                    height:
                                                                                        5,
                                                                                  ),
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.symmetric(
                                                                                      horizontal:
                                                                                          5,
                                                                                    ),
                                                                                    child: Column(
                                                                                      crossAxisAlignment:
                                                                                          CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Text(
                                                                                          vendorModel.title,
                                                                                          maxLines:
                                                                                              1,
                                                                                          style: TextStyle(
                                                                                            fontFamily:
                                                                                                "Poppinsm",
                                                                                            fontSize:
                                                                                                16,
                                                                                            fontWeight:
                                                                                                FontWeight.w700,
                                                                                            letterSpacing:
                                                                                                0.2,
                                                                                          ),
                                                                                        ).tr(),
                                                                                        const SizedBox(
                                                                                          height:
                                                                                              5,
                                                                                        ),
                                                                                        Row(
                                                                                          children: [
                                                                                            Icon(
                                                                                              Icons.location_pin,
                                                                                              color: Color(
                                                                                                COLOR_PRIMARY,
                                                                                              ),
                                                                                              size:
                                                                                                  20,
                                                                                            ),
                                                                                            SizedBox(
                                                                                              width:
                                                                                                  5,
                                                                                            ),
                                                                                            Expanded(
                                                                                              child:
                                                                                                  Text(
                                                                                                    vendorModel.location,
                                                                                                    maxLines:
                                                                                                        1,
                                                                                                    style: TextStyle(
                                                                                                      fontFamily:
                                                                                                          "Poppinsm",
                                                                                                      color:
                                                                                                          isDarkMode(
                                                                                                                context,
                                                                                                              )
                                                                                                              ? Colors.white
                                                                                                              : Colors.black.withOpacity(
                                                                                                                0.60,
                                                                                                              ),
                                                                                                    ),
                                                                                                  ).tr(),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                        const SizedBox(
                                                                                          height:
                                                                                              5,
                                                                                        ),
                                                                                        Row(
                                                                                          children: [
                                                                                            Icon(
                                                                                              Icons.timer_sharp,
                                                                                              color: Color(
                                                                                                COLOR_PRIMARY,
                                                                                              ),
                                                                                              size:
                                                                                                  20,
                                                                                            ),
                                                                                            SizedBox(
                                                                                              width:
                                                                                                  5,
                                                                                            ),
                                                                                            Text(
                                                                                              '${hour.toString().padLeft(2, "0")}h ${minute.toStringAsFixed(0).padLeft(2, "0")}m',
                                                                                              style: TextStyle(
                                                                                                fontFamily:
                                                                                                    "Poppinsm",
                                                                                                letterSpacing:
                                                                                                    0.5,
                                                                                                color:
                                                                                                    isDarkMode(
                                                                                                          context,
                                                                                                        )
                                                                                                        ? Colors.white
                                                                                                        : Colors.black.withOpacity(
                                                                                                          0.60,
                                                                                                        ),
                                                                                              ),
                                                                                            ),
                                                                                            SizedBox(
                                                                                              width:
                                                                                                  10,
                                                                                            ),
                                                                                            Icon(
                                                                                              Icons.my_location_sharp,
                                                                                              color: Color(
                                                                                                COLOR_PRIMARY,
                                                                                              ),
                                                                                              size:
                                                                                                  20,
                                                                                            ),
                                                                                            SizedBox(
                                                                                              width:
                                                                                                  10,
                                                                                            ),
                                                                                            Text(
                                                                                              "${kilometer.toDouble().toStringAsFixed(currencyModel!.decimal)} km",
                                                                                              style: TextStyle(
                                                                                                fontFamily:
                                                                                                    "Poppinsm",
                                                                                                letterSpacing:
                                                                                                    0.5,
                                                                                                color:
                                                                                                    isDarkMode(
                                                                                                          context,
                                                                                                        )
                                                                                                        ? Colors.white
                                                                                                        : Colors.black.withOpacity(
                                                                                                          0.60,
                                                                                                        ),
                                                                                              ),
                                                                                            ).tr(),
                                                                                          ],
                                                                                        ),
                                                                                        SizedBox(
                                                                                          height:
                                                                                              5,
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          vendorModel.freeDelivery ==
                                                                                  true
                                                                              ? Positioned(
                                                                                top:
                                                                                    17,
                                                                                right:
                                                                                    -5,
                                                                                child: Container(
                                                                                  padding: EdgeInsets.symmetric(
                                                                                    vertical:
                                                                                        5,
                                                                                    horizontal:
                                                                                        15,
                                                                                  ),
                                                                                  alignment:
                                                                                      Alignment.center,
                                                                                  decoration: BoxDecoration(
                                                                                    color:
                                                                                        Colors.red,
                                                                                    borderRadius: BorderRadius.circular(
                                                                                      8,
                                                                                    ),
                                                                                  ),
                                                                                  child: Text(
                                                                                    'Free Delivery'.tr(),
                                                                                    style: TextStyle(
                                                                                      fontFamily:
                                                                                          "Poppinsm",
                                                                                      color:
                                                                                          Colors.white,
                                                                                      fontWeight:
                                                                                          FontWeight.bold,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              )
                                                                              : Container(),
                                                                        ],
                                                                      ),
                                                                    ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                        } else {
                                          return Container();
                                        }
                                      },
                                    );
                                  },
                                ),
                                buildTitleRow(
                                  titleValue:
                                      homeTextdayanamicmodal
                                          ?.allRestaurantTitle ??
                                      "",
                                  // "All Restaurant".tr(),
                                  onClick: () {},
                                  isViewAll: true,
                                ),
                                // vendors.isEmpty
                                //     ? showEmptyState(
                                //   homeTextdayanamicmodal?.allRestaurantEmptyMsg ?? "",
                                //   context,
                                // )
                                //     :
                                // Container(
                                //   width: MediaQuery.of(context).size.width,
                                //   margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                                //   child: ListView.builder(
                                //     shrinkWrap: true,
                                //     scrollDirection: Axis.vertical,
                                //     physics: const BouncingScrollPhysics(),
                                //
                                //     // ✅ Sort and limit the vendors before the builder
                                //     itemCount: vendors
                                //         .where((v) => v.groceryandrestirant == "Restaurant") // Optional filter
                                //         .toList()
                                //         .length
                                //         .clamp(0, 15), // Limit to 15 max
                                //     itemBuilder: (context, index) {
                                //       // ✅ Sort vendors: Coming Soon last
                                //       List<VendorModel> sortedVendors = [...vendors];
                                //       sortedVendors.sort((a, b) {
                                //         if (a.commingsoon && !b.commingsoon) return 1;
                                //         if (!a.commingsoon && b.commingsoon) return -1;
                                //         return 0;
                                //       });
                                //
                                //       // ✅ Optional: filter only Restaurant-type vendors (if needed)
                                //       sortedVendors = sortedVendors
                                //           .where((v) => v.groceryandrestirant == "Restaurant")
                                //           .toList();
                                //
                                //       // ✅ Limit to 15 vendors after sorting
                                //       List<VendorModel> limitedVendors = sortedVendors.take(15).toList();
                                //
                                //       VendorModel vendorModel = limitedVendors[index];
                                //       return buildAllRestaurantsData(vendorModel);
                                //     },
                                //   ),
                                // ),

                                //   // All working code **************
                                vendors.isEmpty
                                    ? showEmptyState(
                                      homeTextdayanamicmodal
                                              ?.allRestaurantEmptyMsg ??
                                          "",
                                      // 'No Vendors'.tr(),
                                      context,
                                    )
                                    : Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.fromLTRB(
                                        10,
                                        0,
                                        0,
                                        10,
                                      ),
                                      child: buildSortedVendorListWidget(
                                        vendors,
                                        context,
                                      ),
                                      // ListView.builder(
                                      //   shrinkWrap: true,
                                      //   scrollDirection: Axis.vertical,
                                      //   physics:
                                      //       const BouncingScrollPhysics(),
                                      //   itemCount: vendors.length > 15
                                      //       ? 15
                                      //       : vendors.length,
                                      //   itemBuilder: (context, index) {
                                      //     VendorModel vendorModel =
                                      //         vendors[index];
                                      //     return buildAllRestaurantsData(
                                      //         vendorModel);
                                      //   },
                                      // ),
                                    ),

                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.06,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(COLOR_PRIMARY),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.0,
                                            ),
                                            side: BorderSide(
                                              color: Color(COLOR_PRIMARY),
                                            ),
                                          ),
                                        ),
                                        child:
                                            Text(
                                              'See All restaurant around you'
                                                  .tr(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ).tr(),
                                        onPressed: () {
                                          push(
                                            context,
                                            const ViewAllRestaurant(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                            : Container(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                              child: Image.network(imageurl, fit: BoxFit.fill),
                              // Image(
                              //   image:
                              //   AssetImage("assets/images/oops.png"),
                              //
                              //   fit: BoxFit.fill,
                              // )
                            ),
                        // Container(
                        //     width: MediaQuery.of(context).size.width,
                        //
                        //
                        //     height: MediaQuery.of(context).size.height,
                        //     child:
                        //     Image(
                        //       image: AssetImage("assets/images/oops.png"),
                        //
                        //       fit: BoxFit.fill,
                        //     )
                        // ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  final StoryController controller = StoryController();

  Widget storyWidget() {
    return storyList.isEmpty
        ? Container()
        : Container(
          height: 190,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ListView.builder(
              itemCount: storyList.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => MoreStories(
                                storyList: storyList,
                                index: index,
                              ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      child: Container(
                        height: 180,
                        width: 130,
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl:
                                  storyList[index].videoThumbnail.toString(),
                              imageBuilder:
                                  (context, imageProvider) => Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
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
                                      height:
                                          MediaQuery.of(context).size.height,
                                    ),
                                  ),
                            ),
                            FutureBuilder(
                              future: FireStoreUtils().getVendorByVendorID(
                                storyList[index].vendorID.toString(),
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else {
                                  if (snapshot.hasError)
                                    return Center(
                                      child: Text('Error: ${snapshot.error}'),
                                    );
                                  else
                                    return Positioned(
                                      bottom: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8,
                                          right: 10,
                                          bottom: 10,
                                          top: 10,
                                        ),
                                        child: Text(
                                          snapshot.data != null
                                              ? snapshot.data!.title.toString()
                                              : "cdc",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
  }

  Widget buildVendorItemData(BuildContext context, ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      width: MediaQuery.of(context).size.width * 0.8,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: getImageVAlidUrl(product.photo),
              height: 100,
              width: 100,
              memCacheHeight: 100,
              memCacheWidth: 100,
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
                      valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(AppGlobal.placeHolderImage!),
                  ),
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: "Poppinsm",
                    fontSize: 18,
                    color: Color(0xff000000),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 10),
                Text(
                  product.description,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: "Poppinsm",
                    fontSize: 16,
                    color: Color(0xff9091A4),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${amountShow(amount: product.price)}",
                  style: TextStyle(
                    fontFamily: "Poppinsm",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(COLOR_PRIMARY),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// new jay only restaurant
  Widget popularFoodItem(
    BuildContext context,
    ProductModel product,
    VendorModel popularNearFoodVendorModel,
  ) {
    if (popularNearFoodVendorModel.groceryandrestirant != "Grubb Mart") {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          VendorModel? vendorModel = await FireStoreUtils.getVendor(
            product.vendorID,
          );
          if (vendorModel != null) {
            push(
              context,
              ProductDetailsScreen(
                vendorModel: vendorModel,
                productModel: product,
              ),
            );
          }
        },
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
          width: MediaQuery.of(context).size.width * 0.70,
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: getImageVAlidUrl(product.photo),
                  height: 100,
                  width: 100,
                  memCacheHeight: 100,
                  memCacheWidth: 100,
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
                          AppGlobal.placeHolderImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontFamily: "Poppinsm",
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode(context) ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_pin,
                          size: 20,
                          color: Color(COLOR_PRIMARY),
                        ),
                        Expanded(
                          child: Text(
                            popularNearFoodVendorModel.location,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: "Poppinsm",
                              color:
                                  isDarkMode(context)
                                      ? Colors.white70
                                      : const Color(0xff9091A4),
                            ),
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
    } else {
      return SizedBox(); // Return an empty widget if the condition is not met
    }
  }

  /// old haresh bhai
  // Widget popularFoodItem(
  //   BuildContext context,
  //   ProductModel product,
  //   VendorModel popularNearFoodVendorModel,
  // ) {
  //   return GestureDetector(
  //     behavior: HitTestBehavior.translucent,
  //     onTap: () async {
  //       VendorModel? vendorModel =
  //           await FireStoreUtils.getVendor(product.vendorID);
  //       if (vendorModel != null) {
  //         push(
  //           context,
  //           ProductDetailsScreen(
  //             vendorModel: vendorModel,
  //             productModel: product,
  //           ),
  //         );
  //       }
  //     },
  //     // onTap: () => push(
  //     //   context,
  //     //   NewVendorProductsScreen(vendorModel: popularNearFoodVendorModel),
  //     // ),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(20),
  //         border: Border.all(
  //             color: isDarkMode(context)
  //                 ? const Color(DarkContainerBorderColor)
  //                 : Colors.grey.shade100,
  //             width: 1),
  //         color: isDarkMode(context)
  //             ? const Color(DarkContainerColor)
  //             : Colors.white,
  //         boxShadow: [
  //           isDarkMode(context)
  //               ? const BoxShadow()
  //               : BoxShadow(
  //                   color: Colors.grey.withOpacity(0.5),
  //                   blurRadius: 5,
  //                 ),
  //         ],
  //       ),
  //       width: MediaQuery.of(context).size.width * 0.70,
  //       margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
  //       padding: const EdgeInsets.all(5),
  //       child: Row(
  //         children: [
  //           ClipRRect(
  //             borderRadius: BorderRadius.circular(20),
  //             child: CachedNetworkImage(
  //               imageUrl: getImageVAlidUrl(product.photo),
  //               height: 100,
  //               width: 100,
  //               memCacheHeight: 100,
  //               memCacheWidth: 100,
  //               imageBuilder: (context, imageProvider) => Container(
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(20),
  //                   image: DecorationImage(
  //                       image: imageProvider, fit: BoxFit.cover),
  //                 ),
  //               ),
  //               placeholder: (context, url) => Center(
  //                   child: CircularProgressIndicator.adaptive(
  //                 valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
  //               )),
  //               errorWidget: (context, url, error) => ClipRRect(
  //                   borderRadius: BorderRadius.circular(20),
  //                   child: Image.network(
  //                     AppGlobal.placeHolderImage!,
  //                     fit: BoxFit.cover,
  //                   )),
  //               fit: BoxFit.cover,
  //             ),
  //           ),
  //           const SizedBox(
  //             width: 10,
  //           ),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 SizedBox(
  //                   width: MediaQuery.of(context).size.width * 0.50,
  //                   child: Text(
  //                     product.name,
  //                     style: TextStyle(
  //                       fontFamily: "Poppinsm",
  //                       fontSize: 18,
  //                       color:
  //                           isDarkMode(context) ? Colors.white : Colors.black,
  //                     ),
  //                     maxLines: 1,
  //                   ),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 SizedBox(
  //                   width: MediaQuery.of(context).size.width * 0.50,
  //                   child: Text(
  //                     product.description,
  //                     maxLines: 1,
  //                     style: const TextStyle(
  //                       fontFamily: "Poppinsm",
  //                       fontSize: 16,
  //                       color: Color(0xff9091A4),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(
  //                   height: 5,
  //                 ),
  //                 product.disPrice == "" || product.disPrice == "0"
  //                     ? Text(
  //                         amountShow(amount: product.price),
  //                         style: TextStyle(
  //                             fontSize: 16,
  //                             fontFamily: "Poppinsm",
  //                             letterSpacing: 0.5,
  //                             color: Color(COLOR_PRIMARY)),
  //                       )
  //                     : Row(
  //                         children: [
  //                           Text(
  //                             "${amountShow(amount: product.disPrice)}",
  //                             style: TextStyle(
  //                               fontFamily: "Poppinsm",
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.bold,
  //                               color: Color(COLOR_PRIMARY),
  //                             ),
  //                           ),
  //                           const SizedBox(
  //                             width: 5,
  //                           ),
  //                           Text(
  //                             '${amountShow(amount: product.price)}',
  //                             style: const TextStyle(
  //                                 fontFamily: "Poppinsm",
  //                                 fontWeight: FontWeight.bold,
  //                                 color: Colors.grey,
  //                                 decoration: TextDecoration.lineThrough),
  //                           ),
  //                         ],
  //                       ),
  //               ],
  //             ),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }
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
        itemCount: sortedVendors.length > 15 ? 15 : sortedVendors.length,
        itemBuilder: (context, index) {
          VendorModel vendorModel = sortedVendors[index];
          return buildAllRestaurantsData(vendorModel);
        },
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

  buildAllRestaurantsData(VendorModel vendorModel) {
    String vendorStatus = getVendorStatus(vendorModel);
    print("sdfsdfsdfdf");
    print('Kaaaa ${vendorModel.groceryandrestirant}');

    print("App Live check");
    debugPrint(vendorModel.photo);
    List<OfferModel> tempList = [];
    List<double> discountAmountTempList = [];
    List<String> discountAmountTempList1 = [];
    offerList.forEach((element) {
      if (vendorModel.id == element.restaurantId &&
          element.expireOfferDate!.toDate().isAfter(DateTime.now())) {
        tempList.add(element);
        discountAmountTempList.add(double.parse(element.discount.toString()));
        discountAmountTempList1.add((element.discountType).toString());
      }
    });
    if (vendorModel.groceryandrestirant == "Restaurant") {
      return GestureDetector(
        onTap:
            vendorModel.commingsoon
                ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Ah! I see you are already excited about the upcoming outlet on the platform. Stay tuned 😉"
                            .tr(),
                      ),
                    ),
                  );
                }
                : () => push(
                  context,
                  NewVendorProductsScreen(vendorModel: vendorModel),
                ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child:
              vendorModel.commingsoon
                  ? Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xff666666),
                            width: 1,
                          ),
                          color: const Color(DARK_GREY_TEXT_COLOR),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: ColorFiltered(
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
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: vendorModel.photo,
                                    height: 80,
                                    width: 80,
                                    color: const Color(0xff666666),
                                    fit: BoxFit.cover,
                                    colorBlendMode: BlendMode.hardLight,
                                    placeholder:
                                        (context, url) => Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget:
                                        (context, url, error) => ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.network(
                                            AppGlobal.placeHolderImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                color: const Color(0xff666666),
                                              ),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
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
                                      //           color: const Color(0xff666666),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),
                                      // const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 20,
                                            color: Color(COLOR_PRIMARY),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            vendorModel.reviewsSum > 0
                                                ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                                : "",
                                            style: TextStyle(
                                              fontFamily: "Poppinsm",
                                              letterSpacing: 0.5,
                                              color: const Color(0xff666666),
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                                            style: TextStyle(
                                              fontFamily: "Poppinsm",
                                              letterSpacing: 0.5,
                                              color: const Color(0xff666666),
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
                      Positioned(
                        bottom: 0,
                        right: -5,
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
                              bottomRight: Radius.circular(20),
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
                  )
                  : Stack(
                    children: [
                      Container(
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    // child: Image.network(height: 80,
                                    //     width: 80,vendorModel.photo),
                                    child: CachedNetworkImage(
                                      imageUrl: vendorModel.photo,
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      errorWidget:
                                          (context, url, error) => ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.network(
                                              AppGlobal.placeHolderImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                    ),
                                  ),
                                  if (discountAmountTempList.isNotEmpty)
                                    Positioned(
                                      bottom: -6,
                                      left: -1,
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              'assets/images/offer_badge.png',
                                            ),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            discountAmountTempList
                                                    .reduce(min)
                                                    .toStringAsFixed(
                                                      currencyModel!.decimal,
                                                    )
                                                    .substring(
                                                      0,
                                                      discountAmountTempList
                                                              .reduce(min)
                                                              .toStringAsFixed(
                                                                currencyModel!
                                                                    .decimal,
                                                              )
                                                              .length -
                                                          3,
                                                    ) +
                                                "%".tr(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
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
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  isDarkMode(context)
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
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
                                          vendorModel.reviewsSum > 0
                                              ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                              : "",
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
                      Positioned(
                        top: 1,
                        right: 5,
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
                      vendorModel.freeDelivery == true
                          ? Positioned(
                            bottom: 0,
                            right: -5,
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
                                  bottomRight: Radius.circular(20),
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
        ),
      );
    } else {
      return Container();
    }
  }

  Widget buildAvailableVendor(
    VendorModel vendorModel,
    List<double> discountAmountTempList,
  ) {
    return Container(
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
              : BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // buildVendorImage(vendorModel, discountAmountTempList),
            // const SizedBox(width: 10),
            // buildVendorInfo(vendorModel),
          ],
        ),
      ),
    );
  }

  buildCategoryItem(VendorCategoryModel model) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          push(
            context,
            CategoryDetailsScreen(
              category: model,
              isDineIn: false,
              grubbmart: false,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(
              imageUrl: getImageVAlidUrl(model.photo.toString()),
              imageBuilder:
                  (context, imageProvider) => Container(
                    height: MediaQuery.of(context).size.height * 0.11,
                    width: MediaQuery.of(context).size.width * 0.23,
                    decoration: BoxDecoration(
                      border: Border.all(width: 6, color: Color(COLOR_PRIMARY)),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      // height: 80,width: 80,
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
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
              memCacheHeight:
                  (MediaQuery.of(context).size.height * 0.11).toInt(),
              memCacheWidth: (MediaQuery.of(context).size.width * 0.23).toInt(),
              placeholder:
                  (context, url) => ClipOval(
                    child: Container(
                      // padding: EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(75 / 1),
                        ),
                        border: Border.all(
                          color: Color(COLOR_PRIMARY),
                          style: BorderStyle.solid,
                          width: 2.0,
                        ),
                      ),
                      width: 75,
                      height: 75,
                      child: Icon(Icons.fastfood, color: Color(COLOR_PRIMARY)),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      AppGlobal.placeHolderImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
            ),
            // displayCircleImage(model.photo, 90, false),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child:
                    Text(
                      model.title.toString(),
                      style: TextStyle(
                        color:
                            isDarkMode(context)
                                ? Colors.white
                                : const Color(0xFF000000),
                        fontFamily: "Poppinsr",
                      ),
                    ).tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildGrocerygo(VendorCategoryModel model) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          push(
            context,
            CategoryDetailsScreen(
              category: model,
              isDineIn: false,
              grubbmart: true,
            ),
          );
          // push(
          //   context,
          //   Grocery_Products(
          //     categoryName: model.title,
          //     categoryId: model.id,
          //   ),
          // );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(
              imageUrl: getImageVAlidUrl(model.photo.toString()),
              imageBuilder:
                  (context, imageProvider) => Container(
                    height: MediaQuery.of(context).size.height * 0.11,
                    width: MediaQuery.of(context).size.width * 0.23,
                    decoration: BoxDecoration(
                      border: Border.all(width: 6, color: Color(COLOR_PRIMARY)),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      // height: 80,width: 80,
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
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
              memCacheHeight:
                  (MediaQuery.of(context).size.height * 0.11).toInt(),
              memCacheWidth: (MediaQuery.of(context).size.width * 0.23).toInt(),
              placeholder:
                  (context, url) => ClipOval(
                    child: Container(
                      // padding: EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(75 / 1),
                        ),
                        border: Border.all(
                          color: Color(COLOR_PRIMARY),
                          style: BorderStyle.solid,
                          width: 2.0,
                        ),
                      ),
                      width: 75,
                      height: 75,
                      child: Icon(Icons.fastfood, color: Color(COLOR_PRIMARY)),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      AppGlobal.placeHolderImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
            ),
            // displayCircleImage(model.photo, 90, false),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child:
                    Text(
                      model.title.toString(),
                      style: TextStyle(
                        color:
                            isDarkMode(context)
                                ? Colors.white
                                : const Color(0xFF000000),
                        fontFamily: "Poppinsr",
                      ),
                    ).tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // buildCategoryItem1(VendorCategoryModel model) {
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: GestureDetector(
  //       onTap: () {
  //         push(
  //           context,
  //           GroceryDetailsScreen(
  //             category: model,
  //             isDineIn: false,
  //           ),
  //         );
  //       },
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           CachedNetworkImage(
  //             imageUrl: getImageVAlidUrl(model.photo.toString()),
  //             imageBuilder: (context, imageProvider) => Container(
  //               height: MediaQuery.of(context).size.height * 0.11,
  //               width: MediaQuery.of(context).size.width * 0.23,
  //               decoration: BoxDecoration(
  //                   border: Border.all(width: 6, color: Color(COLOR_PRIMARY)),
  //                   borderRadius: BorderRadius.circular(30)),
  //               child: Container(
  //                 // height: 80,width: 80,
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(20),
  //                   border: Border.all(
  //                       color: isDarkMode(context)
  //                           ? const Color(DarkContainerBorderColor)
  //                           : Colors.grey.shade100,
  //                       width: 1),
  //                   color: isDarkMode(context)
  //                       ? const Color(DarkContainerColor)
  //                       : Colors.white,
  //                   boxShadow: [
  //                     isDarkMode(context)
  //                         ? const BoxShadow()
  //                         : BoxShadow(
  //                             color: Colors.grey.withOpacity(0.5),
  //                             blurRadius: 5,
  //                           ),
  //                   ],
  //                 ),
  //                 child: Container(
  //                   width: 60,
  //                   height: 60,
  //                   decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(20),
  //                       image: DecorationImage(
  //                         image: imageProvider,
  //                         fit: BoxFit.cover,
  //                       )),
  //                 ),
  //               ),
  //             ),
  //             memCacheHeight:
  //                 (MediaQuery.of(context).size.height * 0.11).toInt(),
  //             memCacheWidth: (MediaQuery.of(context).size.width * 0.23).toInt(),
  //             placeholder: (context, url) => ClipOval(
  //               child: Container(
  //                 // padding: EdgeInsets.only(top: 10),
  //                 decoration: BoxDecoration(
  //                   borderRadius:
  //                       const BorderRadius.all(Radius.circular(75 / 1)),
  //                   border: Border.all(
  //                     color: Color(COLOR_PRIMARY),
  //                     style: BorderStyle.solid,
  //                     width: 2.0,
  //                   ),
  //                 ),
  //                 width: 75,
  //                 height: 75,
  //                 child: Icon(
  //                   Icons.fastfood,
  //                   color: Color(COLOR_PRIMARY),
  //                 ),
  //               ),
  //             ),
  //             errorWidget: (context, url, error) => ClipRRect(
  //                 borderRadius: BorderRadius.circular(20),
  //                 child: Image.network(
  //                   AppGlobal.placeHolderImage!,
  //                   fit: BoxFit.cover,
  //                 )),
  //           ),
  //           // displayCircleImage(model.photo, 90, false),
  //           Padding(
  //             padding: const EdgeInsets.only(top: 10),
  //             child: Center(
  //                 child: Text(model.title.toString(),
  //                     style: TextStyle(
  //                       color: isDarkMode(context)
  //                           ? Colors.white
  //                           : const Color(0xFF000000),
  //                       fontFamily: "Poppinsr",
  //                     )).tr()),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    fireStoreUtils.closeVendorStream();
    fireStoreUtils.closeNewArrivalStream();
    super.dispose();
  }

  Widget buildBestDealPage(BannerModel categoriesModel) {
    return InkWell(
      onTap: () async {
        print("gsjhdg");
        print(categoriesModel.redirect_id);

        if (categoriesModel.redirect_type == "store") {
          VendorModel? vendorModel = await FireStoreUtils.getVendor(
            categoriesModel.redirect_id.toString(),
          );
          push(context, NewVendorProductsScreen(vendorModel: vendorModel!));
        } else if (categoriesModel.redirect_type == "product") {
          print("gsjhdg2");
          print(categoriesModel.redirect_id);
          ProductModel? productModel = await fireStoreUtils
              .getProductByProductID(categoriesModel.redirect_id.toString());
          VendorModel? vendorModel = await FireStoreUtils.getVendor(
            productModel.vendorID,
          );

          if (vendorModel != null) {
            print("gsjhdg3");

            push(
              context,
              ProductDetailsScreen(
                vendorModel: vendorModel,
                productModel: productModel,
              ),
            );
          }
        } else if (categoriesModel.redirect_type == "external_link") {
          print("gsjhd4");

          final uri = Uri.parse(categoriesModel.redirect_id.toString());
          if (await launchUrl(uri)) {
            await launchUrl(uri);
          } else {
            throw "Could not launch".tr() +
                " ${categoriesModel.redirect_id.toString()}";
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          child: CachedNetworkImage(
            imageUrl: getImageVAlidUrl(categoriesModel.photo.toString()),
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
            color: Colors.black.withOpacity(0.5),
            placeholder:
                (context, url) => Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  ),
                ),
            errorWidget:
                (context, url, error) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    AppGlobal.placeHolderImage!,
                    width: MediaQuery.of(context).size.width * 0.66,
                    fit: BoxFit.fitWidth,
                  ),
                ),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  openCouponCode(BuildContext context, OfferModel offerModel) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 40, right: 40),
            padding: const EdgeInsets.only(left: 50, right: 50),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/offer_code_bg.png"),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                offerModel.offerCode!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              FlutterClipboard.copy(offerModel.offerCode!).then((value) {
                final SnackBar snackBar = SnackBar(
                  content: Text(
                    "Coupon code copied".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.black38,
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                return Navigator.pop(context);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 30, bottom: 30),
              child: Text(
                "COPY CODE".tr(),
                style: TextStyle(
                  color: Color(COLOR_PRIMARY),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            child: RichText(
              text: TextSpan(
                text: "Use code".tr(),
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                  fontWeight: FontWeight.w700,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: offerModel.offerCode,
                    style: TextStyle(
                      color: Color(COLOR_PRIMARY),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                  TextSpan(
                    text:
                        " & get".tr() +
                        " ${offerModel.discountType == "Fix Price" ? "${currencyModel!.symbol}" : ""}${offerModel.discount} ${offerModel.discountType == "Percent" ? "%".tr() : "".tr()} ",
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                      fontWeight: FontWeight.w700,
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

  Widget buildNewArrivalItem(VendorModel vendorModel) {
    if (vendorModel.groceryandrestirant == "Restaurant") {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap:
              vendorModel.commingsoon
                  ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Ah! I see you are already excited about the upcoming outlet on the platform. Stay tuned 😉"
                              .tr(),
                        ),
                      ),
                    );
                  }
                  : () => push(
                    context,
                    NewVendorProductsScreen(vendorModel: vendorModel),
                  ),
          child:
              vendorModel.commingsoon
                  ? Stack(
                    children: [
                      SizedBox(
                        // margin: EdgeInsets.all(5),
                        width: MediaQuery.of(context).size.width * 0.65,
                        child: ColorFiltered(
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
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xff666666),
                                width: 1,
                              ),
                              color: const Color(DARK_GREY_TEXT_COLOR),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: CachedNetworkImage(
                                    imageUrl: getImageVAlidUrl(
                                      vendorModel.photo,
                                    ),
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                    memCacheWidth:
                                        (MediaQuery.of(context).size.width *
                                                0.75)
                                            .toInt(),
                                    imageBuilder:
                                        (context, imageProvider) => Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Image.network(
                                            AppGlobal.placeHolderImage!,
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.75,
                                            fit: BoxFit.fitWidth,
                                          ),
                                        ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  margin: const EdgeInsets.fromLTRB(
                                    15,
                                    0,
                                    5,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vendorModel.title,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontFamily: "Poppinsm",
                                          letterSpacing: 0.5,
                                          color: const Color(0xff666666),
                                        ),
                                      ).tr(),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ImageIcon(
                                            const AssetImage(
                                              'assets/images/location3x.png',
                                            ),
                                            size: 15,
                                            color: Color(COLOR_PRIMARY),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              vendorModel.location,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: "Poppinsm",
                                                letterSpacing: 0.5,
                                                color: const Color(0xff666666),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                          bottom: 10,
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
                                                const SizedBox(width: 3),
                                                Text(
                                                  vendorModel.reviewsSum > 0
                                                      ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                                      : "",
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
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 17,
                        right: -5,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 15,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
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
                  )
                  : Stack(
                    children: [
                      SizedBox(
                        // margin: EdgeInsets.all(5),
                        width: MediaQuery.of(context).size.width * 0.65,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: getImageVAlidUrl(vendorModel.photo),
                                  width:
                                      MediaQuery.of(context).size.width * 0.75,
                                  memCacheWidth:
                                      (MediaQuery.of(context).size.width * 0.75)
                                          .toInt(),
                                  imageBuilder:
                                      (context, imageProvider) => Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
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
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          AppGlobal.placeHolderImage!,
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.75,
                                          fit: BoxFit.fitWidth,
                                        ),
                                      ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                margin: const EdgeInsets.fromLTRB(15, 0, 5, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendorModel.title,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily: "Poppinsm",
                                        letterSpacing: 0.5,
                                        color:
                                            isDarkMode(context)
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ).tr(),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ImageIcon(
                                          const AssetImage(
                                            'assets/images/location3x.png',
                                          ),
                                          size: 15,
                                          color: Color(COLOR_PRIMARY),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            vendorModel.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: "Poppinsm",
                                              letterSpacing: 0.5,
                                              color:
                                                  isDarkMode(context)
                                                      ? Colors.white60
                                                      : const Color(0xff555353),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8.0,
                                        bottom: 10,
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
                                              const SizedBox(width: 3),
                                              Text(
                                                vendorModel.reviewsSum > 0
                                                    ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                                    : "",
                                                style: TextStyle(
                                                  fontFamily: "Poppinsm",
                                                  letterSpacing: 0.5,
                                                  color:
                                                      isDarkMode(context)
                                                          ? Colors.white
                                                          : const Color(
                                                            0xff000000,
                                                          ),
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
                                                          ? Colors.white70
                                                          : const Color(
                                                            0xff666666,
                                                          ),
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
                            ],
                          ),
                        ),
                      ),
                      vendorModel.freeDelivery == true
                          ? Positioned(
                            top: 17,
                            right: -5,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 15,
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          : Container(),
                    ],
                  ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget buildPopularsItem(VendorModel vendorModel) {
    if (!mounted) {
      return Container();
    }
    if (vendorModel.groceryandrestirant == "Restaurant") {
      return vendorModel.commingsoon
          ? Container(
            color: const Color(0xff666666),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.of(context).size.width * 0.68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xff666666), width: 1),
                  color: const Color(0xff666666),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.saturation,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: getImageVAlidUrl(vendorModel.photo),
                          memCacheWidth:
                              (MediaQuery.of(context).size.width * 0.75)
                                  .toInt(),
                          memCacheHeight: 250,
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
                                  AppGlobal.placeHolderImage!,
                                  width:
                                      MediaQuery.of(context).size.width * 0.75,
                                  fit: BoxFit.fitHeight,
                                ),
                              ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      color: const Color(0xff666666),
                      margin: const EdgeInsets.fromLTRB(15, 0, 5, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendorModel.title,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: "Poppinsm",
                              letterSpacing: 0.5,
                              color:
                                  isDarkMode(context)
                                      ? Colors.white
                                      : const Color(0xff000000),
                            ),
                          ).tr(),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ImageIcon(
                                const AssetImage(
                                  'assets/images/location3x.png',
                                ),
                                size: 15,
                                color: Color(COLOR_PRIMARY),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  vendorModel.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: "Poppinsm",
                                    letterSpacing: 0.5,
                                    color:
                                        isDarkMode(context)
                                            ? Colors.white70
                                            : const Color(0xff555353),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 10,
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
                                    const SizedBox(width: 3),
                                    Text(
                                      vendorModel.reviewsCount != 0
                                          ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                          : 0.toString(),
                                      style: TextStyle(
                                        fontFamily: "Poppinsm",
                                        letterSpacing: 0.5,
                                        color:
                                            isDarkMode(context)
                                                ? Colors.white70
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
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          : Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap:
                  () => push(
                    context,
                    NewVendorProductsScreen(vendorModel: vendorModel),
                  ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.68,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: getImageVAlidUrl(vendorModel.photo),
                        memCacheWidth:
                            (MediaQuery.of(context).size.width * 0.75).toInt(),
                        memCacheHeight: 250,
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
                                AppGlobal.placeHolderImage!,
                                width: MediaQuery.of(context).size.width * 0.75,
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.fromLTRB(15, 0, 5, 0),
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
                              color:
                                  isDarkMode(context)
                                      ? Colors.white
                                      : const Color(0xff000000),
                            ),
                          ).tr(),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ImageIcon(
                                const AssetImage(
                                  'assets/images/location3x.png',
                                ),
                                size: 15,
                                color: Color(COLOR_PRIMARY),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  vendorModel.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: "Poppinsm",
                                    letterSpacing: 0.5,
                                    color:
                                        isDarkMode(context)
                                            ? Colors.white70
                                            : const Color(0xff555353),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 10,
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
                                    const SizedBox(width: 3),
                                    Text(
                                      vendorModel.reviewsCount != 0
                                          ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                          : 0.toString(),
                                      style: TextStyle(
                                        fontFamily: "Poppinsm",
                                        letterSpacing: 0.5,
                                        color:
                                            isDarkMode(context)
                                                ? Colors.white70
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
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
    } else {
      return Container();
    }
  }

  Widget buildCouponsForYouItem(
    BuildContext context1,
    VendorModel? vendorModel,
    OfferModel offerModel,
  ) {
    if (vendorModel?.groceryandrestirant == "Restaurant") {
      return vendorModel == null
          ? Container()
          : Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: GestureDetector(
              onTap: () {
                if (vendorModel.id.toString() ==
                    offerModel.restaurantId.toString()) {
                  push(
                    context,
                    NewVendorProductsScreen(vendorModel: vendorModel),
                  );
                } else {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    isDismissible: true,
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    backgroundColor: Colors.transparent,
                    enableDrag: true,
                    builder: (context) => openCouponCode(context, offerModel),
                  );
                }
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  alignment: AlignmentDirectional.bottomStart,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade100,
                          width: 0.1,
                        ),
                        boxShadow: [
                          isDarkMode(context)
                              ? const BoxShadow()
                              : BoxShadow(
                                color: Colors.grey.shade400,
                                blurRadius: 8.0,
                                spreadRadius: 1.2,
                                offset: const Offset(0.2, 0.2),
                              ),
                        ],
                        color:
                            isDarkMode(context)
                                ? const Color(DARK_BG_COLOR)
                                : Colors.white,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: CachedNetworkImage(
                              imageUrl: getImageVAlidUrl(
                                offerModel.imageOffer!,
                              ),
                              memCacheWidth:
                                  (MediaQuery.of(context).size.width * 0.75)
                                      .toInt(),
                              memCacheHeight:
                                  MediaQuery.of(context).size.width.toInt(),
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
                                      AppGlobal.placeHolderImage!,
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.75,
                                      fit: BoxFit.fitHeight,
                                    ),
                                  ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          vendorModel.id.toString() ==
                                  offerModel.restaurantId.toString()
                              ? Container(
                                margin: const EdgeInsets.fromLTRB(15, 0, 5, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendorModel.title,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily: "Poppinsm",
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color:
                                            isDarkMode(context)
                                                ? Colors.white
                                                : const Color(0xff000000),
                                      ),
                                    ).tr(),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ImageIcon(
                                          const AssetImage(
                                            'assets/images/location3x.png',
                                          ),
                                          size: 15,
                                          color: Color(COLOR_PRIMARY),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            vendorModel.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: "Poppinsm",
                                              letterSpacing: 0.5,
                                              color:
                                                  isDarkMode(context)
                                                      ? Colors.white70
                                                      : const Color(0xff555353),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8.0,
                                        bottom: 10,
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                offerModel.offerCode!,
                                                style: TextStyle(
                                                  fontFamily: "Poppinsm",
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(COLOR_PRIMARY),
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    size: 20,
                                                    color: Color(COLOR_PRIMARY),
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    vendorModel.reviewsCount !=
                                                            0
                                                        ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                                        : 0.toString(),
                                                    style: TextStyle(
                                                      fontFamily: "Poppinsm",
                                                      letterSpacing: 0.5,
                                                      color:
                                                          isDarkMode(context)
                                                              ? Colors.white
                                                              : const Color(
                                                                0xff000000,
                                                              ),
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
                                                              : const Color(
                                                                0xff666666,
                                                              ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Container(
                                margin: const EdgeInsets.fromLTRB(15, 0, 5, 8),
                                width: MediaQuery.of(context).size.width,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Grubb's Offer".tr(),
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Poppinsm",
                                        letterSpacing: 0.5,
                                        color: Color(0xff000000),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Apply Offer".tr(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: "Poppinsm",
                                        letterSpacing: 0.5,
                                        color: Color(0xff555353),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () {
                                        FlutterClipboard.copy(
                                          offerModel.offerCode!,
                                        ).then((value) => print('copied'.tr()));
                                      },
                                      child: Text(
                                        offerModel.offerCode!,
                                        style: TextStyle(
                                          fontFamily: "Poppinsm",
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(COLOR_PRIMARY),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                    /* vendorModel.id.toString()==offerModel.restaurantId.toString()?*/
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        margin: const EdgeInsets.only(top: 150),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Container(
                                  width: 105,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: const Image(
                                    image: AssetImage(
                                      "assets/images/offer_badge.png",
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    "${offerModel.discountType == "Fix Price" ? "${currencyModel!.symbol}" : ""}${offerModel.discount}${offerModel.discountType == "Percent" ? "%".tr() : "".tr()} ",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ) /*:Container()*/,
                  ],
                ),
              ),
            ),
          );
    } else {
      return Container();
    }
  }

  Widget buildVendorItem(VendorModel vendorModel) {
    return GestureDetector(
      onTap:
          () =>
              push(context, NewVendorProductsScreen(vendorModel: vendorModel)),
      child: Container(
        height: 120,
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                : BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: getImageVAlidUrl(vendorModel.photo),
                memCacheWidth: (MediaQuery.of(context).size.width).toInt(),
                memCacheHeight: 120,
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
                      child: Image.network(AppGlobal.placeHolderImage!),
                    ),
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title:
                  Text(
                    vendorModel.title,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: "Poppinsm",
                      letterSpacing: 0.5,
                      color: Color(0xff000000),
                    ),
                  ).tr(),
              subtitle: Row(
                children: [
                  ImageIcon(
                    AssetImage('assets/images/location3x.png'),
                    size: 15,
                    color: Color(COLOR_PRIMARY),
                  ),
                  SizedBox(
                    width: 200,
                    child: Text(
                      vendorModel.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: "Poppinsm",
                        letterSpacing: 0.5,
                        color: Color(0xff555353),
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 20, color: Color(COLOR_PRIMARY)),
                        const SizedBox(width: 3),
                        Text(
                          vendorModel.reviewsCount != 0
                              ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveFoodTypeValue() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString('foodType', selctedOrderTypeValue!);
  }

  getFoodType() async {
    // setState(() {
    //   isLoading = false;
    // });
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        selctedOrderTypeValue =
            sp.getString("foodType") == "" || sp.getString("foodType") == null
                ? "Delivery"
                : sp.getString("foodType");
      });
    }
    if (selctedOrderTypeValue == "Takeaway") {
      productsFuture = fireStoreUtils.getAllTakeAWayProducts();
    } else {
      productsFuture = fireStoreUtils.getAllDelevryProducts();
    }
  }

  bool isLoading = true;
  Position? previousLocation;

  Future<void> checkAndFetchLocation() async {
    setState(() {
      isLoading = true;
      print("checkAndFetchLocation ini${isLoading}");
    });
    PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied ||
        _permissionGranted == PermissionStatus.deniedForever) {
      // setState(() {
      //   isLoading = false;
      // });
      _permissionGranted = await location.requestPermission();
      isEnable1 = false;
      isEnable = false;

      resisEnable = true;
      resisEnable1 = true;
      fetchHomeData();
    } else {
      setState(() {
        isLoading = false;
      });
    }

    if (_permissionGranted == PermissionStatus.granted) {
      setState(() {
        isLoading = true;
        print("PermissionStatus ini${isLoading}");
      });
      MyAppState.currentUser?.userID == null ||
              MyAppState.currentUser?.userID == "" ||
              MyAppState.currentUser == null ||
              MyAppState.currentUser == ""
          ? await withoutuser()
          : await getLocationData();
      await getData();
    } else {
      setState(() {
        isLoading = false;
      });
      // Handle permission denied scenario
    }
  }

  Future<void> withoutuser() async {
    print('with out user a call thay che ho');
    setState(() {
      isLoading = true;
    });
    try {
      print('Ki He');

      final position = await getCurrentLocation();
      print('previousLocation : ${previousLocation}');
      if (previousLocation == null ||
          position.latitude != previousLocation!.latitude ||
          position.longitude != previousLocation!.longitude) {
        setState(() {
          MyAppState.selectedPosotion = position;
          previousLocation = position;
          print("position${position}");
        });

        // Save new location to SharedPreferences
        // await prefs.setDouble('latitude', position.latitude);
        // await prefs.setDouble('longitude', position.longitude);

        final placemarks = await placemarkFromCoordinates(
          MyAppState.selectedPosotion.latitude,
          MyAppState.selectedPosotion.longitude,
        );
        print("placemarks${placemarks}");
        print("latitu${MyAppState.selectedPosotion.latitude}");
        print("longi${MyAppState.selectedPosotion.longitude}");

        if (placemarks.isNotEmpty) {
          final placeMark = placemarks[0];
          setState(() {
            currentLocation =
                "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.postalCode}, ${placeMark.country}";
            print('Allhuva Location : ${currentLocation}');
            // isLoading = false;
            MyAppState.currentUser!.shippingAddress.country =
                placeMark.country ?? '';
            MyAppState.currentUser!.shippingAddress.line1 =
                placeMark.name ?? '';
            MyAppState.currentUser!.shippingAddress.line2 =
                placeMark.subLocality ?? '';
            MyAppState.currentUser!.shippingAddress.city =
                placeMark.locality ?? '';
            MyAppState.currentUser!.shippingAddress.postalCode =
                placeMark.postalCode ?? '';
          });
        }

        await getData();
        setState(() {
          isLoading = false;
        });
      } else {
        print("Location has not changed.");
        await getData();
      }
    } catch (error) {
      debugPrint("------>${error.toString()}");
      await getPermission();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getLocationData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    MyAppState.selectedPosotion = await getCurrentLocation();
    // Check if SharedPreferences has saved location data
    double? savedLatitude =
        MyAppState.currentUser?.location.latitude == 0.01
            ? MyAppState.selectedPosotion.latitude
            : MyAppState.currentUser?.location.latitude;
    // prefs.getDouble('latitude');
    double? savedLongitude =
        MyAppState.currentUser?.location.latitude == 0.01
            ? MyAppState.selectedPosotion.longitude
            : MyAppState.currentUser?.location.longitude;
    // prefs.getDouble('longitude');
    addrss = prefs.getBool('address_state') ?? false;
    print('savedLatitude : ${savedLongitude}');
    if (savedLatitude != null && savedLongitude != null) {
      // Load location from SharedPreferences
      MyAppState.selectedPosotion = Position(
        latitude: savedLatitude,
        longitude: savedLongitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
        floor: 0,
        isMocked: true,
      );
      previousLocation = MyAppState.selectedPosotion;

      final placemarks = await placemarkFromCoordinates(
        savedLatitude,
        savedLongitude,
      );
      if (placemarks.isNotEmpty) {
        final placeMark = placemarks[0];
        setState(() {
          currentLocation =
              "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.postalCode}, ${placeMark.country}";
          isLoading = false;
          MyAppState.currentUser?.shippingAddress.country =
              placeMark.country ?? '';
          MyAppState.currentUser?.shippingAddress.line1 = placeMark.name ?? '';
          MyAppState.currentUser?.shippingAddress.line2 =
              placeMark.subLocality ?? '';
          MyAppState.currentUser?.shippingAddress.city =
              placeMark.locality ?? '';
          MyAppState.currentUser?.shippingAddress.postalCode =
              placeMark.postalCode ?? '';
        });
      }
      await getData();
      setState(() {
        isLoading = false;
      });
    } else {
      // If no saved location, get live location
      print('Kaa MAMA');
      setState(() {
        isLoading = true;
      });
      try {
        print('Ki He');

        final position = await getCurrentLocation();
        print('previousLocation : ${previousLocation}');
        if (previousLocation == null ||
            position.latitude != previousLocation!.latitude ||
            position.longitude != previousLocation!.longitude) {
          setState(() {
            MyAppState.selectedPosotion = position;
            previousLocation = position;
            print("position${position}");
          });

          // Save new location to SharedPreferences
          await prefs.setDouble('latitude', position.latitude);
          await prefs.setDouble('longitude', position.longitude);

          final placemarks = await placemarkFromCoordinates(
            double.parse(
              (MyAppState.currentUser?.location.latitude).toString(),
            ),
            double.parse(
              (MyAppState.currentUser?.location.longitude).toString(),
            ),
            // MyAppState.selectedPosotion.longitude)
          );
          print("placemarks${placemarks}");
          print("latitu${MyAppState.selectedPosotion.latitude}");
          print("longi${MyAppState.selectedPosotion.longitude}");

          if (placemarks.isNotEmpty) {
            final placeMark = placemarks[0];
            setState(() {
              currentLocation =
                  "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.postalCode}, ${placeMark.country}";
              print('Allhuva Location : ${currentLocation}');
              // isLoading = false;
              MyAppState.currentUser!.shippingAddress.country =
                  placeMark.country ?? '';
              MyAppState.currentUser!.shippingAddress.line1 =
                  placeMark.name ?? '';
              MyAppState.currentUser!.shippingAddress.line2 =
                  placeMark.subLocality ?? '';
              MyAppState.currentUser!.shippingAddress.city =
                  placeMark.locality ?? '';
              MyAppState.currentUser!.shippingAddress.postalCode =
                  placeMark.postalCode ?? '';
            });
          }

          await getData();
        } else {
          print("Location has not changed.");
          await getData();
        }
      } catch (error) {
        debugPrint("------>${error.toString()}");
        await getPermission();
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getPermission() async {
    setState(() {
      isLoading = true;
    });

    PermissionStatus _permissionGranted = await location.hasPermission();
    print("_permissionGranted${_permissionGranted}");
    if (_permissionGranted == PermissionStatus.denied) {
      print("PermissionStatus${PermissionStatus}");
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        setState(() {
          isLoading = true;
        });
        await getData();
      }
      setState(() {
        isLoading = false;
      });
      print("isLoading flase${isLoading}");
    }
  }

  Future<void> getData() async {
    print('Kaaaaaa');
    setState(() {
      isLoading = true;
    });
    // _initializeCities();
    getFoodType();
    lstNearByFood.clear();
    fireStoreUtils.getRestaurantNearBy().whenComplete(() async {
      lstAllRestaurant = fireStoreUtils.getAllRestaurants().asBroadcastStream();
      print(
        "current location ave cave che ${MyAppState.selectedPosotion.latitude ?? ""}",
      );
      print(
        "current location ave cave che ${MyAppState.selectedPosotion.longitude ?? ""}",
      );
      getCityFromCoordinates(
        MyAppState.selectedPosotion.latitude,
        MyAppState.selectedPosotion.longitude,
      );
      // MyAppState.currentUser?.userID==null|| MyAppState.currentUser?.userID==""?print("a call nay thay"):updateUserLocation(MyAppState.currentUser?.userID ?? "",double.parse(MyAppState.selectedPosotion.latitude.toString()),double.parse(MyAppState.selectedPosotion.longitude.toString()));
      MyAppState.currentUser?.location = UserLocation(
        latitude: MyAppState.selectedPosotion.latitude,
        longitude: MyAppState.selectedPosotion.longitude,
      );
      getCityrestaurantcity(
        MyAppState.selectedPosotion.latitude,
        MyAppState.selectedPosotion.longitude,
      );
      if (MyAppState.currentUser != null) {
        lstFavourites = fireStoreUtils.getFavouriteRestaurant(
          MyAppState.currentUser!.userID,
        );
        lstFavourites.then((event) {
          lstFav.clear();
          for (int a = 0; a < event.length; a++) {
            lstFav.add(event[a].restaurantId!);
          }
        });
        name = toBeginningOfSentenceCase(widget.user!.firstName);
      }

      lstAllRestaurant!.listen((event) {
        vendors.clear();
        vendors.addAll(event);
        allstoreList.clear();
        allstoreList.addAll(event);
        productsFuture.then((value) {
          for (int a = 0; a < event.length; a++) {
            for (int d = 0; d < (value.length > 20 ? 20 : value.length); d++) {
              if (event[a].id == value[d].vendorID &&
                  !lstNearByFood.contains(value[d])) {
                lstNearByFood.add(value[d]);
              }
            }
          }
        });

        popularRestaurantLst.addAll(event);
        List<VendorModel> temp5 =
            popularRestaurantLst
                .where(
                  (element) =>
                      num.parse(
                        (element.reviewsSum / element.reviewsCount).toString(),
                      ) ==
                      5,
                )
                .toList();
        List<VendorModel> temp5_ =
            popularRestaurantLst
                .where(
                  (element) =>
                      num.parse(
                            (element.reviewsSum / element.reviewsCount)
                                .toString(),
                          ) >
                          4 &&
                      num.parse(
                            (element.reviewsSum / element.reviewsCount)
                                .toString(),
                          ) <
                          5,
                )
                .toList();
        List<VendorModel> temp4 =
            popularRestaurantLst
                .where(
                  (element) =>
                      num.parse(
                            (element.reviewsSum / element.reviewsCount)
                                .toString(),
                          ) >
                          3 &&
                      num.parse(
                            (element.reviewsSum / element.reviewsCount)
                                .toString(),
                          ) <
                          4,
                )
                .toList();
        List<VendorModel> temp3 =
            popularRestaurantLst
                .where(
                  (element) =>
                      num.parse(
                            (element.reviewsSum / element.reviewsCount)
                                .toString(),
                          ) >
                          2 &&
                      num.parse(
                            (element.reviewsSum / element.reviewsCount)
                                .toString(),
                          ) <
                          3,
                )
                .toList();
        List<VendorModel> temp2 =
            popularRestaurantLst
                .where(
                  (element) =>
                      num.parse(
                            (element.reviewsSum / element.reviewsCount)
                                .toString(),
                          ) >
                          1 &&
                      num.parse(
                            (element.reviewsSum / element.reviewsCount)
                                .toString(),
                          ) <
                          2,
                )
                .toList();
        List<VendorModel> temp1 =
            popularRestaurantLst
                .where(
                  (element) =>
                      num.parse(
                        (element.reviewsSum / element.reviewsCount).toString(),
                      ) ==
                      1,
                )
                .toList();
        List<VendorModel> temp0 =
            popularRestaurantLst
                .where(
                  (element) =>
                      num.parse(
                        (element.reviewsSum / element.reviewsCount).toString(),
                      ) ==
                      0,
                )
                .toList();
        List<VendorModel> temp0_ =
            popularRestaurantLst
                .where(
                  (element) =>
                      element.reviewsSum == 0 && element.reviewsCount == 0,
                )
                .toList();

        popularRestaurantLst.clear();
        popularRestaurantLst.addAll(temp5);
        popularRestaurantLst.addAll(temp5_);
        popularRestaurantLst.addAll(temp4);
        popularRestaurantLst.addAll(temp3);
        popularRestaurantLst.addAll(temp2);
        popularRestaurantLst.addAll(temp1);
        popularRestaurantLst.addAll(temp0);
        popularRestaurantLst.addAll(temp0_);

        FireStoreUtils().getPublicCoupons(city).then((value) {
          offersList.clear();
          offerVendorList.clear();
          value.forEach((element1) {
            event.forEach((element) {
              if (element1.restaurantId == element.id &&
                  element1.expireOfferDate!.toDate().isAfter(DateTime.now())) {
                offersList.add(element1);
                offerVendorList.add(element);
              }
            });
          });
        });

        FireStoreUtils()
            .getStory()
            .then((value) {
              storyList.clear();
              value.forEach((element1) {
                vendors.forEach((element) {
                  if (element1.vendorID == element.id) {
                    storyList.add(element1);
                  }
                });
              });
              setState(() {});
            })
            .whenComplete(() {
              setState(() {
                isLoading = false;
              });
            });
      });
      setState(() {
        isLoading = false;
      });
    });
  }

  List<StoryModel> storyList = [];
}

// ignore: camel_case_types
class buildTitleRow extends StatelessWidget {
  final String titleValue;
  final Function? onClick;
  final bool? isViewAll;

  const buildTitleRow({
    Key? key,
    required this.titleValue,
    this.onClick,
    this.isViewAll = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color:
          isDarkMode(context)
              ? const Color(DARK_COLOR)
              : const Color(0xffFFFFFF),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titleValue.tr(),
                  style: TextStyle(
                    color:
                        isDarkMode(context)
                            ? Colors.white
                            : const Color(0xFF000000),
                    fontFamily: "Poppinsm",
                    fontSize: 18,
                  ),
                ),
              ),
              isViewAll!
                  ? Container()
                  : GestureDetector(
                    onTap: () {
                      onClick!.call();
                    },
                    child: Text(
                      'View All'.tr(),
                      style: TextStyle(
                        color: Color(COLOR_PRIMARY),
                        fontFamily: "Poppinsm",
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class MoreStories extends StatefulWidget {
  List<StoryModel> storyList = [];
  int index;

  MoreStories({Key? key, required this.index, required this.storyList})
    : super(key: key);

  @override
  _MoreStoriesState createState() => _MoreStoriesState();
}

class _MoreStoriesState extends State<MoreStories> {
  final storyController = StoryController();

  @override
  void dispose() {
    storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StoryView(
            storyItems:
                List.generate(widget.storyList[widget.index].videoUrl.length, (
                  i,
                ) {
                  return StoryItem.pageVideo(
                    widget.storyList[widget.index].videoUrl[i],
                    controller: storyController,
                  );
                }).toList(),
            onStoryShow: (storyItem, index) {
              debugPrint("Showing a story");
            },
            onComplete: () {
              debugPrint("--------->");
              debugPrint(widget.storyList.length.toString());
              debugPrint(widget.index.toString());
              if (widget.storyList.length - 1 != widget.index) {
                // Navigator.pop(context);
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (context) => MoreStories(
                //       storyList: widget.storyList,
                //       index: widget.index + 1,
                //     )));

                setState(() {
                  widget.index = widget.index + 1;
                });
              } else {
                Navigator.pop(context);
              }
            },
            progressPosition: ProgressPosition.top,
            repeat: true,
            controller: storyController,
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Navigator.pop(context);
              }
            },
          ),
          Positioned(
            top: 45,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          FutureBuilder(
            future: FireStoreUtils().getVendorByVendorID(
              widget.storyList[widget.index].vendorID.toString(),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Container());
              } else {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error".tr() + ": ${snapshot.error}"),
                  );
                } else {
                  VendorModel? vendorModel = snapshot.data;
                  double distanceInMeters = Geolocator.distanceBetween(
                    vendorModel!.latitude,
                    vendorModel.longitude,
                    MyAppState.selectedPosotion.latitude,
                    MyAppState.selectedPosotion.longitude,
                  );
                  double kilometer = distanceInMeters / 1000;
                  return Positioned(
                    top: 55,
                    child: InkWell(
                      onTap: () {
                        push(
                          context,
                          NewVendorProductsScreen(vendorModel: vendorModel),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: CachedNetworkImage(
                                imageUrl: vendorModel.photo,
                                height: 50,
                                width: 50,
                                imageBuilder:
                                    (context, imageProvider) => Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
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
                                      borderRadius: BorderRadius.circular(30),
                                      child: Image.network(
                                        AppGlobal.placeHolderImage!,
                                        fit: BoxFit.cover,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height:
                                            MediaQuery.of(context).size.height,
                                      ),
                                    ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendorModel.title.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
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
                                                          vendorModel
                                                              .reviewsCount)
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
                                    SizedBox(width: 5),
                                    Icon(
                                      Icons.location_pin,
                                      size: 16,
                                      color: Color(COLOR_PRIMARY),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      "${kilometer.toDouble().toStringAsFixed(currencyModel!.decimal)} KM",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "Poppinsr",
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Container(
                                      height: 15,
                                      child: VerticalDivider(
                                        color: Colors.white,
                                        thickness: 2,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      DateTime.now()
                                                  .difference(
                                                    widget
                                                        .storyList[widget.index]
                                                        .createdAt!
                                                        .toDate(),
                                                  )
                                                  .inDays ==
                                              0
                                          ? 'Today'.tr()
                                          : "${DateTime.now().difference(widget.storyList[widget.index].createdAt!.toDate()).inDays.toString()} d",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "Poppinsr",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
