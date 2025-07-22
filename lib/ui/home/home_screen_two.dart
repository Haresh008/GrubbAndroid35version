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
import 'package:foodie_customer/ui/cuisinesScreen/CuisinesScreen.dart';
import 'package:foodie_customer/ui/home/CurrentAddressChangeScreen.dart';
import 'package:foodie_customer/ui/home/HomeScreen.dart';
import 'package:foodie_customer/ui/home/view_all_offer_screen.dart';
import 'package:foodie_customer/ui/home/view_all_restaurant.dart';
import 'package:foodie_customer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:foodie_customer/ui/searchScreen/SearchScreen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/NewVendorProductsScreen.dart';
import 'package:foodie_customer/widget/gradiant_text.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story_view/story_view.dart';
// import 'package:story_view/story_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/mail_setting.dart';
import '../Grocery/Groceryhome_page.dart';
import '../categoryDetailsScreen/CategoryDetailsScreen.dart';

bool homedayanamic = false;
bool homedayanamic1 = false;
bool homeresisEnable = true;
bool homeresisEnable1 = true;

class HomeScreenTwo extends StatefulWidget {
  final User? user;

  const HomeScreenTwo({super.key, this.user});

  @override
  State<HomeScreenTwo> createState() => _HomeScreenTwoState();
}

class _HomeScreenTwoState extends State<HomeScreenTwo> {
  final fireStoreUtils = FireStoreUtils();

  late Future<List<ProductModel>> productsFuture;

  // PageController _controller =
  //     PageController(viewportFraction: 0.8, keepPage: true);
  late PageController _controller;
  late Timer _timer;
  int currentPage = 0;
  List<VendorModel> vendors = [];
  List<VendorModel> offerVendorList = [];
  List<OfferModel> offersList = [];
  Stream<List<VendorModel>>? lstAllRestaurant;
  List<ProductModel> lstNearByFood = [];

  late Future<List<FavouriteModel>> lstFavourites;
  List<String> lstFav = [];

  String? name = "";

  String? currentLocation = "";

  String? selctedOrderTypeValue = "Delivery".tr();

  bool isLocationPermissionAllowed = false;

  // bool isEnable = false;
  loc.Location location = loc.Location();

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
        homedayanamic = documentSnapshot.get('isEnable');
      });
      List<String> cities = List<String>.from(documentSnapshot.get('cities'));
      print("citiescities${cities}");

      return cities;
    } else {
      // Default empty list return karo jya data na male
      return [];
    }
  }

  Future<List<String>> getresturantcities() async {
    print('athata che');
    getImageUrl();
    // Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Settings document fetch karo
    DocumentSnapshot documentSnapshot =
        await firestore.collection('settings').doc('grubb_restau').get();

    // Check karo ke document ma data chhe ke nahi
    if (documentSnapshot.exists) {
      // Cities field fetch karo
      setState(() {
        homedayanamic = documentSnapshot.get('isEnable');
      });
      List<String> cities = List<String>.from(documentSnapshot.get('cities'));
      print("citiescitiedfdsfsdfsfsfsdfdsffs${cities}");

      return cities;
    } else {
      // Default empty list return karo jya data na male
      return [];
    }
  }

  Future<String?> getImageUrl() async {
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
      print('Error: $e');
      return null;
    }
  }

  Future<void> getIsEnableStatus() async {
    print('isEnable Status: ');
    // Firestore instance banavo
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Document nu reference lidhu, jema 'grubb_mart' collection ane tamaru document name che
    DocumentSnapshot document =
        await firestore.collection('settings').doc('grubb_mart').get();

    if (document.exists) {
      print('isEnable Status: ');
      // isEnable field check kari ne fetch karo
      // isEnable = document.get('isEnable');
      setState(() {
        homedayanamic = document.get('isEnable');
        print("setState ini${homedayanamic}");
      });
      print('shu ave che  $homedayanamic');
    } else {
      print('Document not found');
    }
  }

  Future<void> getCityFromCoordinates(double latitude, double longitude) async {
    String? city;
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
        getBanner(city);
        List<String> cities = await getCities();
        if (cities.contains(city)) {
          setState(() {
            homedayanamic = true;
            homedayanamic1 = true;
          });

          print(
            'Your current city "$city" is available in the Firestore cities.',
          );
        } else {
          setState(() {
            homedayanamic = false;
            homedayanamic1 = false;
            gethometest(city.toString());
            print(
              'Your current city "$city" is available in the Firestore cities.',
            );
          });
          print(
            'Your current city "$city" is not available in the Firestore cities.',
          );
        }
      } else {
        print('No location found for the given coordinates.');
        gethometest(city.toString());
      }
    } catch (e) {
      print('Error: $e');
      gethometest(city.toString());
    }
  }

  Future<void> updateUserLocation(
    String userId,
    double latitude,
    double longitude,
  ) async {
    try {
      // FirebaseFirestore નો રેફરન્સ મેળવો
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // latitude અને longitude અપડેટ કરો
      await docRef.update({
        'location': {'latitude': latitude, 'longitude': longitude},
      });

      print('Location updated successfully!');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  // resturant valu che
  Future<void> getCityrestaurantcity(double latitude, double longitude) async {
    getImageUrl();
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
        });
        print('egegfdgdffgddfgdgdgdfgCity: $city');
        List<String> cities = await getresturantcities();
        if (cities.contains(city)) {
          setState(() {
            homeresisEnable = true;
            homeresisEnable = true;
            resisEnable = true;
            resisEnable1 = true;
          });

          print(
            'restaurant valu ave che  "$city" is available in the Firestore cities.',
          );
        } else {
          setState(() {
            homeresisEnable = false;
            homeresisEnable = false;
            resisEnable = false;
            resisEnable1 = false;
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

  HomeTextDayanamicModal? homeTextdayanamicmodal;

  // Future<HomeTextDayanamicModal?> gethometest(String city) async {
  //   print("a call tha che ke nay${city}");
  //   await FirebaseFirestore.instance
  //       .collection("app_home_cms_city_wise")
  //       .doc(city)
  //       .get()
  //       .then((value) {
  //     if (value.exists) {
  //       setState(() {
  //         homeTextdayanamicmodal = HomeTextDayanamicModal.fromJson(value.data()!);
  //       });
  //       print("homeTextdayanamicmodalhomeTextdayanamicmodalhomeTextdayanamicmodal${homeTextdayanamicmodal?.grubMartTitle.toString()}");
  //       return homeTextdayanamicmodal;
  //     }
  //     else{
  //       fetchHomeData();
  //     }
  //   });
  // }
  Future<HomeTextDayanamicModal?> gethometest(String city) async {
    if (city.isEmpty) {
      print("Error: City name is empty");
      return null;
    }

    print("API Call: $city");

    try {
      DocumentSnapshot value =
          await FirebaseFirestore.instance
              .collection("app_home_cms_city_wise")
              .doc(city)
              .get();

      if (value.exists && value.data() != null) {
        final data = value.data() as Map<String, dynamic>; // ✅ Type Casting

        setState(() {
          homeTextdayanamicmodal = HomeTextDayanamicModal.fromJson(data);
        });

        print("Data fetched: ${homeTextdayanamicmodal?.grubMartTitle}");
        return homeTextdayanamicmodal;
      } else {
        fetchHomeData();
        return null;
      }
    } catch (e) {
      print("Firestore Error: $e");
      return null;
    }
  }

  // Database db;
  void fetchHomeData() async {
    homeTextdayanamicmodal = await FireStoreUtils().gethometest();
    if (homeTextdayanamicmodal != null) {
      debugPrint("Modal Data: $homeTextdayanamicmodal");
    } else {
      debugPrint("No data found in modal.");
    }
  }

  @override
  void initState() {
    super.initState();
    // fetchHomeData();
    // getLocationData();
    initializeFlutterFire();
    getImageUrl();
    // getIsEnableStatus();
    fireStoreUtils.getplaceholderimage().then((value) {
      AppGlobal.placeHolderImage = value;
    });
    // getData();
    checkAndFetchLocation();
  }

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
      homeresisEnable = false;
      homeresisEnable = false;
      resisEnable = false;
      resisEnable1 = false;
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

  List<VendorCategoryModel> categoryWiseProductList = [];

  List<BannerModel> bannerTopHome = [];
  List<BannerModel> bannerMiddleHome = [];

  bool isHomeBannerLoading = true;
  bool isHomeBannerMiddleLoading = true;
  List<OfferModel> offerList = [];
  bool? storyEnable = false;

  getBanner(city) async {
    await fireStoreUtils.getHomeTopBanner(city).then((value) {
      setState(() {
        bannerTopHome = value;
        print("bannerTopHomebannerTopHomebannerTopHome${bannerTopHome}");
        isHomeBannerLoading = false;
        isLoading = false;
      });
    });

    await fireStoreUtils.getHomePageShowCategory().then((value) {
      if (mounted)
        setState(() {
          categoryWiseProductList = value;
        });
    });

    await fireStoreUtils.getHomeMiddleBanner(city).then((value) {
      setState(() {
        bannerMiddleHome = value;
        isHomeBannerMiddleLoading = false;
      });
    });
    await FireStoreUtils().getPublicCoupons(city).then((value) {
      setState(() {
        offerList = value;
      });
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:
            isDarkMode(context)
                ? const Color(DARK_BG_COLOR)
                : const Color(0xffFAFAFA),
        body:
            isLoading == true
                ? Center(child: CircularProgressIndicator())
                : (MyAppState.selectedPosotion.latitude == 0 &&
                    MyAppState.selectedPosotion.longitude == 0)
                ? Center(
                  child: Column(
                    children: [
                      Image.asset("assets/images/loctio.png"),
                      SizedBox(height: 20),
                      showEmptyState(
                        "Hold on! We are locating you".tr(),
                        context,
                        description:
                            "Set your location to start searching for restaurants in your area."
                                .tr(),
                        action: () async {
                          // LocationResult result = await Navigator.of(context)
                          //     .push(MaterialPageRoute(
                          //         builder: (context) =>
                          //             PlacePicker(GOOGLE_API_KEY)));
                          //
                          // setState(() {
                          //   MyAppState.selectedPosotion = Position.fromMap({
                          //     'latitude': result.latLng!.latitude,
                          //     'longitude': result.latLng!.longitude
                          //   });
                          //
                          //   currentLocation = result.formattedAddress;
                          //   getData();
                          // });
                          Navigator.of(context)
                              .push(
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const CurrentAddressChangeScreen(),
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
                        },
                        buttonTitle: 'Select'.tr(),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color:
                            isDarkMode(context)
                                ? const Color(DarkContainerColor)
                                : Colors.white,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 5,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 18),
                                  Expanded(
                                    child: InkWell(
                                      onTap:
                                          MyAppState.currentUser == null ||
                                                  MyAppState
                                                          .currentUser
                                                          ?.userID ==
                                                      null ||
                                                  MyAppState
                                                          .currentUser
                                                          ?.userID ==
                                                      ""
                                              ? () {
                                                final snackBar = SnackBar(
                                                  backgroundColor:
                                                      !isDarkMode(context)
                                                          ? Colors.white
                                                          : Color(
                                                            DARK_BG_COLOR,
                                                          ),
                                                  content: Text(
                                                    'Please login Change Your Address',
                                                    style: TextStyle(
                                                      color:
                                                          !isDarkMode(context)
                                                              ? Colors.red
                                                              : Colors.white,
                                                    ),
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(snackBar);
                                              }
                                              : () {
                                                getPermission();
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
                                                      if (value != null &&
                                                          mounted) {
                                                        setState(() {
                                                          currentLocation =
                                                              value;
                                                          getData();
                                                        });
                                                      }
                                                    });
                                              },
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child:
                                                Text(
                                                  currentLocation.toString(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: "Poppinsr",
                                                  ),
                                                ).tr(),
                                          ),
                                          Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 80),
                                  // DropdownButton(
                                  //   value: selctedOrderTypeValue,
                                  //   isDense: true,
                                  //   onChanged: (newValue) async {
                                  //     int cartProd = 0;
                                  //     await Provider.of<CartDatabase>(
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
                                  //         builder: (BuildContext context) =>
                                  //             ShowDialogToDismiss(
                                  //           title: '',
                                  //           content:
                                  //               "Do you really want to change the delivery option?"
                                  //                       .tr() +
                                  //                   "Your cart will be empty"
                                  //                       .tr(),
                                  //           buttonText: 'CLOSE'.tr(),
                                  //           secondaryButtonText: 'OK'.tr(),
                                  //           action: () {
                                  //             Navigator.of(context).pop();
                                  //             Provider.of<CartDatabase>(
                                  //                     context,
                                  //                     listen: false)
                                  //                 .deleteAllProducts();
                                  //             setState(() {
                                  //               selctedOrderTypeValue =
                                  //                   newValue.toString();
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
                                  //   ),
                                  //   items: [
                                  //     'Delivery'.tr(),
                                  //     // 'Takeaway'.tr(),
                                  //   ].map((location) {
                                  //     return DropdownMenuItem(
                                  //       child: Text(location),
                                  //       value: location,
                                  //     );
                                  //   }).toList(),
                                  // ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            homeresisEnable && homeresisEnable
                                ? InkWell(
                                  onTap: () {
                                    push(context, const SearchScreen());
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: TextFormField(
                                      textInputAction: TextInputAction.next,
                                      onChanged: (value) {},
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search menu, restaurant or etc...'
                                                .tr(),
                                        fillColor: Color(0XFFF2F2F2),
                                        filled: true,
                                        enabled: false,
                                        contentPadding: const EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                          top: 10,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search,
                                          color: Colors.black,
                                        ),
                                        hintStyle: const TextStyle(
                                          color: Color(0XFF8A8989),
                                          fontFamily: 'Poppinsr',
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30.0,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(COLOR_PRIMARY),
                                            width: 2.0,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30.0,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30.0,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30.0,
                                          ),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                : Container(),
                            Divider(thickness: 1),
                            homeresisEnable && homeresisEnable
                                ? Visibility(
                                  visible: bannerTopHome.isNotEmpty,
                                  child: Padding(
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
                                                  0.18,
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
                                                //     itemCount:
                                                //         bannerTopHome.length,
                                                //     scrollDirection:
                                                //         Axis.horizontal,
                                                //     controller: _controller,
                                                //     itemBuilder:
                                                //         (context, index) =>
                                                //             buildBestDealPage(
                                                //                 bannerTopHome[
                                                //                     index])),
                                              ),
                                            ),
                                  ),
                                )
                                : Container(),
                          ],
                        ),
                      ),
                      homeresisEnable && homeresisEnable
                          ? Column(
                            children: [
                              SizedBox(height: 10),
                              homedayanamic && homedayanamic1
                                  ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkMode(context)
                                                ? const Color(
                                                  DarkContainerColor,
                                                )
                                                : Colors.white,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(20),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  homeTextdayanamicmodal
                                                          ?.grubMartTitle ??
                                                      "",
                                                  // "Mart Categories",
                                                  style: TextStyle(
                                                    color:
                                                        isDarkMode(context)
                                                            ? Colors.white
                                                            : const Color(
                                                              0xFF000000,
                                                            ),
                                                    fontFamily: "Poppinsm",
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    push(
                                                      context,
                                                      GroceryHome(
                                                        isPageCallFromHomeScreen:
                                                            true,
                                                        user:
                                                            MyAppState
                                                                .currentUser,
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'View All'.tr(),
                                                    style: TextStyle(
                                                      color: Color(
                                                        COLOR_PRIMARY,
                                                      ),
                                                      fontFamily: "Poppinsm",
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            GradientText(
                                              homeTextdayanamicmodal
                                                      ?.grubmartsubtitle ??
                                                  "",
                                              // 'Best Servings Groceries',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontFamily: 'Inter Tight',
                                                fontWeight: FontWeight.w800,
                                              ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF3961F1),
                                                  Color(0xFF11D0EA),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            FutureBuilder<
                                              List<VendorCategoryModel>
                                            >(
                                              future:
                                                  fireStoreUtils.getCuisines1(),
                                              initialData: [],
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Center(
                                                    child: CircularProgressIndicator.adaptive(
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                            Color(
                                                              COLOR_PRIMARY,
                                                            ),
                                                          ),
                                                    ),
                                                  );
                                                }
                                                if ((snapshot.hasData ||
                                                        (snapshot
                                                                .data
                                                                ?.isNotEmpty ??
                                                            false)) &&
                                                    mounted) {
                                                  return GridView.builder(
                                                    gridDelegate:
                                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 4,
                                                          crossAxisSpacing: 5,
                                                          childAspectRatio:
                                                              5 / 6,
                                                        ),
                                                    itemCount:
                                                        snapshot.data!.length >=
                                                                8
                                                            ? 8
                                                            : snapshot
                                                                .data!
                                                                .length,
                                                    physics:
                                                        NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      VendorCategoryModel
                                                      vendorCategoryModel =
                                                          snapshot.data![index];
                                                      return GestureDetector(
                                                        onTap: () {
                                                          push(
                                                            context,
                                                            CategoryDetailsScreen(
                                                              category:
                                                                  vendorCategoryModel,
                                                              isDineIn: false,
                                                              grubbmart: true,
                                                            ),
                                                          );
                                                        },
                                                        child: Column(
                                                          children: [
                                                            ClipOval(
                                                              child: CachedNetworkImage(
                                                                width: 60,
                                                                height: 60,
                                                                imageUrl: getImageVAlidUrl(
                                                                  vendorCategoryModel
                                                                      .photo
                                                                      .toString(),
                                                                ),
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                                placeholder:
                                                                    (
                                                                      context,
                                                                      url,
                                                                    ) => ClipOval(
                                                                      child: Image.network(
                                                                        AppGlobal
                                                                            .placeHolderImage!,
                                                                        fit:
                                                                            BoxFit.cover,
                                                                      ),
                                                                    ),
                                                                errorWidget:
                                                                    (
                                                                      context,
                                                                      url,
                                                                      error,
                                                                    ) => ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            20,
                                                                          ),
                                                                      child: Image.network(
                                                                        AppGlobal
                                                                            .placeHolderImage!,
                                                                        fit:
                                                                            BoxFit.cover,
                                                                      ),
                                                                    ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 5,
                                                                  ),
                                                              child: Center(
                                                                child:
                                                                    Text(
                                                                      vendorCategoryModel
                                                                          .title
                                                                          .toString(),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: TextStyle(
                                                                        color:
                                                                            isDarkMode(
                                                                                  context,
                                                                                )
                                                                                ? Colors.white
                                                                                : const Color(
                                                                                  0xFF000000,
                                                                                ),
                                                                        fontFamily:
                                                                            "Poppinsr",
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ).tr(),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  return showEmptyState(
                                                    'No Categories'.tr(),
                                                    context,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  : Container(),
                              SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isDarkMode(context)
                                            ? const Color(DarkContainerColor)
                                            : Colors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              homeTextdayanamicmodal
                                                      ?.foodCategoriesTitle ??
                                                  "",
                                              // "Our Categories",
                                              style: TextStyle(
                                                color:
                                                    isDarkMode(context)
                                                        ? Colors.white
                                                        : const Color(
                                                          0xFF000000,
                                                        ),
                                                fontFamily: "Poppinsm",
                                                fontSize: 18,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                push(
                                                  context,
                                                  const CuisinesScreen(
                                                    isPageCallFromHomeScreen:
                                                        true,
                                                  ),
                                                );
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
                                        GradientText(
                                          homeTextdayanamicmodal
                                                  ?.foodcategoriessubtitle ??
                                              "",
                                          // 'Best Servings Food',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontFamily: 'Inter Tight',
                                            fontWeight: FontWeight.w800,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF3961F1),
                                              Color(0xFF11D0EA),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        FutureBuilder<
                                          List<VendorCategoryModel>
                                        >(
                                          future: fireStoreUtils.getCuisines(),
                                          initialData: [],
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Center(
                                                child:
                                                    CircularProgressIndicator.adaptive(
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                            Color(
                                                              COLOR_PRIMARY,
                                                            ),
                                                          ),
                                                    ),
                                              );
                                            }
                                            if ((snapshot.hasData ||
                                                    (snapshot
                                                            .data
                                                            ?.isNotEmpty ??
                                                        false)) &&
                                                mounted) {
                                              return GridView.builder(
                                                gridDelegate:
                                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 4,
                                                      crossAxisSpacing: 5,
                                                      childAspectRatio: 5 / 6,
                                                    ),
                                                itemCount:
                                                    snapshot.data!.length >= 8
                                                        ? 8
                                                        : snapshot.data!.length,
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemBuilder: (context, index) {
                                                  VendorCategoryModel
                                                  vendorCategoryModel =
                                                      snapshot.data![index];
                                                  return GestureDetector(
                                                    onTap: () {
                                                      push(
                                                        context,
                                                        CategoryDetailsScreen(
                                                          category:
                                                              vendorCategoryModel,
                                                          isDineIn: false,
                                                          grubbmart: false,
                                                        ),
                                                      );
                                                    },
                                                    child: Column(
                                                      children: [
                                                        ClipOval(
                                                          child: CachedNetworkImage(
                                                            width: 60,
                                                            height: 60,
                                                            imageUrl: getImageVAlidUrl(
                                                              vendorCategoryModel
                                                                  .photo
                                                                  .toString(),
                                                            ),
                                                            fit: BoxFit.cover,
                                                            placeholder:
                                                                (
                                                                  context,
                                                                  url,
                                                                ) => ClipOval(
                                                                  child: Image.network(
                                                                    AppGlobal
                                                                        .placeHolderImage!,
                                                                    fit:
                                                                        BoxFit
                                                                            .cover,
                                                                  ),
                                                                ),
                                                            errorWidget:
                                                                (
                                                                  context,
                                                                  url,
                                                                  error,
                                                                ) => ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        20,
                                                                      ),
                                                                  child: Image.network(
                                                                    AppGlobal
                                                                        .placeHolderImage!,
                                                                    fit:
                                                                        BoxFit
                                                                            .cover,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 5,
                                                              ),
                                                          child: Center(
                                                            child:
                                                                Text(
                                                                  vendorCategoryModel
                                                                      .title
                                                                      .toString(),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: TextStyle(
                                                                    color:
                                                                        isDarkMode(
                                                                              context,
                                                                            )
                                                                            ? Colors.white
                                                                            : const Color(
                                                                              0xFF000000,
                                                                            ),
                                                                    fontFamily:
                                                                        "Poppinsr",
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ).tr(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              homeresisEnable && homeresisEnable
                                  ? Visibility(
                                    visible: bannerMiddleHome.isNotEmpty,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
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
                                                    0.18,
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
                                                  //         bannerTopHome.length,
                                                  //     scrollDirection:
                                                  //         Axis.horizontal,
                                                  //     controller: _controller,
                                                  //     itemBuilder:
                                                  //         (context, index) =>
                                                  //             buildBestDealPage(
                                                  //                 bannerTopHome[
                                                  //                     index])),
                                                ),
                                              ),
                                    ),
                                  )
                                  : Container(),
                              SizedBox(height: 10),
                              offerVendorList.isEmpty
                                  ? Container()
                                  : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkMode(context)
                                                ? const Color(
                                                  DarkContainerColor,
                                                )
                                                : Colors.white,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(20),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  homeTextdayanamicmodal
                                                          ?.offerForYouTitle ??
                                                      "",
                                                  // "Large Discounts",
                                                  style: TextStyle(
                                                    color:
                                                        isDarkMode(context)
                                                            ? Colors.white
                                                            : const Color(
                                                              0xFF000000,
                                                            ),
                                                    fontFamily: "Poppinsm",
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    push(
                                                      context,
                                                      OffersScreen(
                                                        vendors: vendors,
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'View All'.tr(),
                                                    style: TextStyle(
                                                      color: Color(
                                                        COLOR_PRIMARY,
                                                      ),
                                                      fontFamily: "Poppinsm",
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            GradientText(
                                              homeTextdayanamicmodal
                                                      ?.offer_for_you_sub_title ??
                                                  "",
                                              // 'Save Upto 50% Off',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontFamily: 'Inter Tight',
                                                fontWeight: FontWeight.w800,
                                              ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF39F1C5),
                                                  Color(0xFF97EA11),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width,
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.35,
                                              child:
                                              // ListView.builder(
                                              //     shrinkWrap: true,
                                              //     scrollDirection:
                                              //         Axis.horizontal,
                                              //     physics:
                                              //         const BouncingScrollPhysics(),
                                              //     itemCount: offerVendorList
                                              //                 .length >=
                                              //             15
                                              //         ? 15
                                              //         : offerVendorList
                                              //             .length,
                                              //     itemBuilder:
                                              //         (context,
                                              //             index) {
                                              //       return buildCouponsForYouItem(
                                              //           context,
                                              //           offerVendorList[
                                              //               index],
                                              //           offersList[
                                              //               index]);
                                              //     })
                                              ListView.builder(
                                                shrinkWrap: true,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                itemCount:
                                                    offerVendorList.length >= 15
                                                        ? 15
                                                        : offerVendorList
                                                            .length,
                                                itemBuilder: (context, index) {
                                                  print(
                                                    "Building index: $index",
                                                  );
                                                  return buildCouponsForYouItem(
                                                    context,
                                                    offerVendorList[index],
                                                    offersList[index],
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              SizedBox(height: storyEnable == true ? 5 : 20),
                              Visibility(
                                visible: storyEnable == true,
                                child: storyWidget(),
                              ),
                              SizedBox(height: storyEnable == true ? 5 : 20),
                              Container(
                                color:
                                    isDarkMode(context) ? null : Colors.white,
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            homeTextdayanamicmodal
                                                    ?.allRestaurantTitle ??
                                                "",
                                            // "Best Restaurants",
                                            style: TextStyle(
                                              color:
                                                  isDarkMode(context)
                                                      ? Colors.white
                                                      : const Color(0xFF000000),
                                              fontFamily: "Poppinsm",
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // vendors.isEmpty
                                    //     ? showEmptyState(
                                    //         homeTextdayanamicmodal
                                    //                 ?.allRestaurantEmptyMsg ??
                                    //             "",
                                    //         context,
                                    //       )
                                    //     : Container(
                                    //         width: MediaQuery.of(context)
                                    //             .size
                                    //             .width,
                                    //         margin:
                                    //             const EdgeInsets.fromLTRB(
                                    //                 10, 0, 0, 10),
                                    //         child: ListView.builder(
                                    //           shrinkWrap: true,
                                    //           scrollDirection:
                                    //               Axis.vertical,
                                    //           physics:
                                    //               const BouncingScrollPhysics(),
                                    //
                                    //           // ✅ Sort and limit the vendors before the builder
                                    //           itemCount: vendors
                                    //               .where((v) =>
                                    //                   v.groceryandrestirant ==
                                    //                   "Restaurant") // Optional filter
                                    //               .toList()
                                    //               .length
                                    //               .clamp(0, 15),
                                    //           // Limit to 15 max
                                    //           itemBuilder:
                                    //               (context, index) {
                                    //             // ✅ Sort vendors: Coming Soon last
                                    //             List<VendorModel>
                                    //                 sortedVendors = [
                                    //               ...vendors
                                    //             ];
                                    //             sortedVendors
                                    //                 .sort((a, b) {
                                    //               if (a.commingsoon &&
                                    //                   !b.commingsoon)
                                    //                 return 1;
                                    //               if (!a.commingsoon &&
                                    //                   b.commingsoon)
                                    //                 return -1;
                                    //               return 0;
                                    //             });
                                    //
                                    //             // ✅ Optional: filter only Restaurant-type vendors (if needed)
                                    //             sortedVendors = sortedVendors
                                    //                 .where((v) =>
                                    //                     v.groceryandrestirant ==
                                    //                     "Restaurant")
                                    //                 .toList();
                                    //
                                    //             // ✅ Limit to 15 vendors after sorting
                                    //             List<VendorModel>
                                    //                 limitedVendors =
                                    //                 sortedVendors
                                    //                     .take(15)
                                    //                     .toList();
                                    //
                                    //             VendorModel vendorModel =
                                    //                 limitedVendors[index];
                                    //             return buildAllRestaurantsData(
                                    //                 vendorModel);
                                    //           },
                                    //         ),
                                    //       )

                                    // All working code **************
                                    vendors.isEmpty
                                        ? showEmptyState(
                                          homeTextdayanamicmodal
                                                  ?.allRestaurantEmptyMsg ??
                                              "",
                                          // 'No Vendors'.tr(),
                                          context,
                                        )
                                        : Container(
                                          width:
                                              MediaQuery.of(context).size.width,
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
                                        ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 5),
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
                                            'See all Restaurants'.tr(),
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
                      SizedBox(height: 5),
                    ],
                  ),
                ),
      ),
    );
  }

  // final StoryController controller = StoryController();

  Widget storyWidget() {
    return storyList.isEmpty
        ? Container()
        : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              // image: DecorationImage(
              //     image: AssetImage("assets/images/story_bg.png"),
              //     fit: BoxFit.cover)
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    homeTextdayanamicmodal?.stories_title ?? "",
                    // "Stories",
                    style: TextStyle(
                      color: isDarkMode(context) ? Colors.white : Colors.black,
                      fontFamily: "Poppinsm",
                      fontSize: 18,
                    ),
                  ),
                  GradientText(
                    homeTextdayanamicmodal?.stories_sub_title ?? "",
                    // / 'Best Food Stories Ever',
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Inter Tight',
                      fontWeight: FontWeight.w800,
                    ),
                    gradient: LinearGradient(
                      colors: [Color(0xFFF1C839), Color(0xFFEA1111)],
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
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
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              child: Container(
                                height: 180,
                                width: 130,
                                child: Stack(
                                  children: [
                                    Stack(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl:
                                              storyList[index].videoThumbnail
                                                  .toString(),
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            15,
                                                          ),
                                                      image: DecorationImage(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                          errorWidget:
                                              (
                                                context,
                                                url,
                                                error,
                                              ) => ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                child: Image.network(
                                                  AppGlobal.placeHolderImage!,
                                                  fit: BoxFit.cover,
                                                  width:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width,
                                                  height:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height,
                                                ),
                                              ),
                                        ),
                                        Container(
                                          color: Colors.black.withOpacity(0.30),
                                        ),
                                      ],
                                    ),
                                    FutureBuilder(
                                      future: FireStoreUtils()
                                          .getVendorByVendorID(
                                            storyList[index].vendorID
                                                .toString(),
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
                                              child: Text(
                                                'Error: ${snapshot.error}',
                                              ),
                                            );
                                          else {
                                            return Positioned(
                                              top: 4,
                                              left: 2,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                            Radius.circular(30),
                                                          ),
                                                    ),
                                                    child: ClipOval(
                                                      child: CachedNetworkImage(
                                                        width: 32,
                                                        height: 32,
                                                        imageUrl:
                                                            getImageVAlidUrl(
                                                              snapshot
                                                                  .data!
                                                                  .photo
                                                                  .toString(),
                                                            ),
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (
                                                              context,
                                                              url,
                                                            ) => ClipOval(
                                                              child: Image.network(
                                                                AppGlobal
                                                                    .placeHolderImage!,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                              ),
                                                            ),
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) => ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                              child: Image.network(
                                                                AppGlobal
                                                                    .placeHolderImage!,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 5),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        snapshot.data != null
                                                            ? snapshot
                                                                .data!
                                                                .title
                                                                .toString()
                                                            : "cdc",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontFamily:
                                                              'Inter Tight',
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          height: 1.67,
                                                        ),
                                                      ),
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.star,
                                                            size: 14,
                                                            color: Colors.amber,
                                                          ),
                                                          SizedBox(width: 2),
                                                          Text(
                                                            "${snapshot.data!.reviewsCount != 0 ? '${(snapshot.data!.reviewsSum / snapshot.data!.reviewsCount).toStringAsFixed(1)}' : 0.toString()} reviews",
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  "Poppinssr",
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 10,
                                                              color:
                                                                  isDarkMode(
                                                                        context,
                                                                      )
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
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
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
  }

  // Widget buildSortedVendorListWidget(List<VendorModel> vendors, BuildContext context) {
  //   List<VendorModel> sortedVendors = [...vendors];
  //
  //   sortedVendors.sort((a, b) {
  //     String statusA = getVendorStatus(a);
  //     String statusB = getVendorStatus(b);
  //
  //     int weight(String status) {
  //       if (status == 'Open') return 0;
  //       if (status == 'Pre-order') return 1;
  //       return 2;
  //     }
  //
  //     return weight(statusA).compareTo(weight(statusB));
  //   });
  //
  //   return Container(
  //     width: MediaQuery.of(context).size.width,
  //     margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
  //     child: ListView.builder(
  //       shrinkWrap: true,
  //       scrollDirection: Axis.vertical,
  //       physics: const BouncingScrollPhysics(),
  //       itemCount: sortedVendors.length > 15 ? 15 : sortedVendors.length,
  //       itemBuilder: (context, index) {
  //         VendorModel vendorModel = sortedVendors[index];
  //         return buildAllRestaurantsData(vendorModel);
  //       },
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

  Widget buildAllRestaurantsData(VendorModel vendorModel) {
    String vendorStatus = getVendorStatus(vendorModel);

    List<OfferModel> tempList = [];
    List<double> discountAmountTempList = [];
    offerList.forEach((element) {
      if (vendorModel.id == element.restaurantId &&
          element.expireOfferDate!.toDate().isAfter(DateTime.now())) {
        tempList.add(element);

        discountAmountTempList.add(double.parse(element.discount.toString()));
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

                  debugPrint(
                    "vendor====>>>>>>${vendorModel.workingHours.length}",
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
                          color:
                              Colors
                                  .grey
                                  .shade300, // Grey tone for the container
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        Colors.grey.shade400,
                                        // Apply grey tone to the image
                                        BlendMode.saturation,
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: vendorModel.photo,
                                        height: 120,
                                        width: 108,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                        errorWidget:
                                            (context, url, error) => ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                height: 120,
                                                width: 90,
                                                AppGlobal.placeHolderImage!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 120,
                                    width: 108,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.30),
                                      borderRadius: BorderRadius.circular(10),
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
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  Colors
                                                      .grey
                                                      .shade800, // Adjusted for grey tone
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
                                    //       color: Colors.grey.shade600, // Adjusted for grey tone
                                    //     ),
                                    //     Expanded(
                                    //       child: Text(
                                    //         vendorModel.location,
                                    //         maxLines: 1,
                                    //         style: TextStyle(
                                    //           fontFamily: "Poppinsm",
                                    //           color: Colors.grey.shade600, // Adjusted for grey tone
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
                                          color:
                                              Colors
                                                  .grey
                                                  .shade600, // Adjusted for grey tone
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
                                                Colors
                                                    .grey
                                                    .shade800, // Adjusted for grey tone
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                                          style: TextStyle(
                                            fontFamily: "Poppinsm",
                                            letterSpacing: 0.5,
                                            color:
                                                Colors
                                                    .grey
                                                    .shade600, // Adjusted for grey tone
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
                        bottom: 5, // Aligns the tag at the bottom
                        right: 5, // Aligns the tag to the right
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
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
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: vendorModel.photo,
                                          height: 120,
                                          width: 108,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget:
                                              (
                                                context,
                                                url,
                                                error,
                                              ) => ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  height: 120,
                                                  width: 90,
                                                  AppGlobal.placeHolderImage!,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                        ),
                                        Container(
                                          height: 120,
                                          width: 108,
                                          color: Colors.black.withOpacity(0.30),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 1,
                                    // right: 5,
                                    left: 3,
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
                                  if (discountAmountTempList.isNotEmpty)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Save Upto',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontFamily: 'Inter Tight',
                                              fontWeight: FontWeight.w700,
                                              height: 1.20,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              // "30 %",
                                              discountAmountTempList
                                                      .reduce(min)
                                                      .toStringAsFixed(
                                                        currencyModel!.decimal,
                                                      ) +
                                                  "%".tr(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
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
                                          vendorModel.reviewsCount != 0
                                              ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
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
                      vendorModel.freeDelivery == true
                          ? Positioned(
                            bottom: 5, // Aligns the tag at the bottom
                            right: 5, // Aligns the tag to the right
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'Free Delivery',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          : Container(),
                      // Positioned(
                      //   top: 1,
                      //   right: 5,
                      //   child: vendorStatus == 'Open'?Row(children: [
                      //     const Icon(
                      //       Icons.circle,
                      //       color: Color(0XFF3dae7d),
                      //       size: 10,
                      //     ),
                      //     const SizedBox(
                      //       width: 5,
                      //     ),
                      //     Text("Open".tr(),
                      //         style: const TextStyle(
                      //             fontFamily: "Poppinsm",
                      //             fontSize: 10,
                      //             color: Color(0XFF3dae7d)))
                      //   ]):vendorStatus == 'Pre-order'?Row(
                      //       children: [
                      //         const Icon(
                      //           Icons.circle,
                      //           color: Color(0XFF3dae7d),
                      //           size: 10,
                      //         ),
                      //         const SizedBox(
                      //           width: 5,
                      //         ),
                      //         Text("Pre-order".tr(),
                      //             style: const TextStyle(
                      //                 fontFamily: "Poppinsm",
                      //                 fontSize: 10,
                      //                 color: Color(0XFF3dae7d)))
                      //       ]):Row(children: [
                      //     const Icon(
                      //       Icons.circle,
                      //       color: Colors.red,
                      //       size: 10,
                      //     ),
                      //     const SizedBox(
                      //       width: 5,
                      //     ),
                      //     Text("Closed".tr(),
                      //         style: const TextStyle(
                      //             fontFamily: "Poppinsm",
                      //             fontSize: 10,
                      //             letterSpacing: 0.5,
                      //             color: Colors.red))
                      //   ]),
                      //   // Container(
                      //   //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      //   //   decoration: BoxDecoration(
                      //   //     color: vendorStatus == 'Open'
                      //   //         ? Colors.green
                      //   //         : vendorStatus == 'Pre-order'
                      //   //         ? Colors.orange
                      //   //         : Colors.red,
                      //   //     borderRadius: BorderRadius.circular(5),
                      //   //   ),
                      //   //   child: Text(
                      //   //     vendorStatus,
                      //   //     style: const TextStyle(
                      //   //       color: Colors.white,
                      //   //       fontSize: 13,
                      //   //       fontWeight: FontWeight.bold,
                      //   //     ),
                      //   //   ),
                      //   // ),
                      // ),
                    ],
                  ),
        ),
      );
    } else {
      return Container();
    }
  }

  // Widget buildAllRestaurantsData(VendorModel vendorModel) {
  //   String vendorStatus = getVendorStatus(vendorModel);
  //
  //   return GestureDetector(
  //     onTap: vendorStatus == 'Closed'
  //         ? () {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("This vendor is currently closed")),
  //       );
  //     }
  //         : () {
  //       push(context, NewVendorProductsScreen(vendorModel: vendorModel));
  //     },
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
  //       child: Stack(
  //         children: [
  //           Container(
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             child: Padding(
  //               padding: const EdgeInsets.all(8.0),
  //               child: Row(
  //                 children: [
  //                   Stack(
  //                     children: [
  //                       ClipRRect(
  //                         borderRadius: BorderRadius.circular(10),
  //                         child: CachedNetworkImage(
  //                           imageUrl: vendorModel.photo,
  //                           height: 120,
  //                           width: 108,
  //                           fit: BoxFit.cover,
  //                           placeholder: (context, url) =>
  //                               Center(child: CircularProgressIndicator()),
  //                           errorWidget: (context, url, error) => ClipRRect(
  //                             borderRadius: BorderRadius.circular(10),
  //                             child: Image.network(
  //                               height: 120,
  //                               width: 90,
  //                               AppGlobal.placeHolderImage!,
  //                               fit: BoxFit.cover,
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                       Container(
  //                         height: 120,
  //                         width: 108,
  //                         color: Colors.black.withOpacity(0.3),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(width: 10),
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           vendorModel.title,
  //                           style: TextStyle(
  //                             fontFamily: "Poppinsm",
  //                             fontSize: 18,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                           maxLines: 1,
  //                         ),
  //                         const SizedBox(height: 5),
  //                         Row(
  //                           children: [
  //                             Icon(Icons.star, size: 20, color: Colors.orange),
  //                             const SizedBox(width: 3),
  //                             Text(
  //                               vendorModel.reviewsCount != 0
  //                                   ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
  //                                   : '0',
  //                               style: TextStyle(
  //                                 fontFamily: "Poppinsm",
  //                                 color: Colors.black,
  //                               ),
  //                             ),
  //                             const SizedBox(width: 3),
  //                             Text(
  //                               '(${vendorModel.reviewsCount.toStringAsFixed(1)})',
  //                               style: TextStyle(
  //                                 fontFamily: "Poppinsm",
  //                                 color: Colors.grey,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //           Positioned(
  //             bottom: 5,
  //             right: 5,
  //             child: Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //               decoration: BoxDecoration(
  //                 color: vendorStatus == 'Open'
  //                     ? Colors.green
  //                     : vendorStatus == 'Pre-order'
  //                     ? Colors.orange
  //                     : Colors.red,
  //                 borderRadius: BorderRadius.circular(5),
  //               ),
  //               child: Text(
  //                 vendorStatus,
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  String getVendorStatus(VendorModel vendorModel) {
    // If temporarily closed, always return 'Closed'
    if (vendorModel.isTempClose == true) {
      return 'Closed';
    }

    final now = DateTime.now();
    final String today = DateFormat('EEEE').format(now); // e.g., Monday

    // આજના workingHours filter કરો
    final todayHours = vendorModel.workingHours
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

  // String getVendorStatus(VendorModel vendorModel) {
  //   final now = DateTime.now();
  //   final String today = DateFormat('EEEE').format(now); // e.g., Monday
  //
  //   // આજે ના workingHours filter કરો
  //   final todayHours =
  //       vendorModel.workingHours
  //           .where((element) => element.day == today)
  //           .toList();
  //
  //   if (todayHours.isEmpty ||
  //       todayHours[0].timeslot == null ||
  //       todayHours[0].timeslot!.isEmpty) {
  //     return 'Closed';
  //   }
  //
  //   final currentTime = DateFormat("HH:mm").parse(
  //     "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
  //   );
  //
  //   bool isOpen = false;
  //
  //   for (var slot in todayHours[0].timeslot!) {
  //     if (slot.from == null || slot.to == null) continue;
  //
  //     final fromTime = DateFormat("HH:mm").parse(slot.from!);
  //     final toTime = DateFormat("HH:mm").parse(slot.to!);
  //
  //     if (currentTime.isAfter(fromTime) && currentTime.isBefore(toTime)) {
  //       isOpen = true;
  //       break;
  //     }
  //   }
  //
  //   return isOpen ? 'Open' : 'Pre-order';
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
        if (categoriesModel.redirect_type == "store") {
          VendorModel? vendorModel = await FireStoreUtils.getVendor(
            categoriesModel.redirect_id.toString(),
          );
          push(context, NewVendorProductsScreen(vendorModel: vendorModel!));
        } else if (categoriesModel.redirect_type == "product") {
          ProductModel? productModel = await fireStoreUtils
              .getProductByProductID(categoriesModel.redirect_id.toString());
          VendorModel? vendorModel = await FireStoreUtils.getVendor(
            productModel.vendorID,
          );

          if (vendorModel != null) {
            push(
              context,
              ProductDetailsScreen(
                vendorModel: vendorModel,
                productModel: productModel,
              ),
            );
          }
        } else if (categoriesModel.redirect_type == "external_link") {
          final uri = Uri.parse(categoriesModel.redirect_id.toString());
          if (await canLaunchUrl(uri)) {
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
                    width: MediaQuery.of(context).size.width * 0.75,
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
                        " ${offerModel.discountType == "Fix Price" ? "${currencyModel!.symbol}" : ""}${offerModel.discount} ${offerModel.discountType == "Percentage" ? "%".tr() : "".tr()} ",
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

  Widget buildCouponsForYouItem(
    BuildContext context1,
    VendorModel? vendorModel,
    OfferModel offerModel,
  ) {
    if (vendorModel?.groceryandrestirant == "Restaurant") {
      return vendorModel == null
          ? Container()
          : Container(
            // margin: const EdgeInsets.symmetric(horizontal: 5),
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
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: vendorModel.photo,
                            height: 134,
                            width: 130,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                            errorWidget:
                                (context, url, error) => ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    height: 120,
                                    width: 90,
                                    AppGlobal.placeHolderImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                          ),
                          Container(
                            height: 134,
                            width: 130,
                            color: Colors.black.withOpacity(0.30),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vendorModel.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Inter Tight',
                              fontWeight: FontWeight.w700,
                              height: 1.20,
                            ),
                          ),
                          SizedBox(height: 5),
                          Container(
                            decoration: ShapeDecoration(
                              color: Color(0xFF356FDC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2000),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(
                                " ${offerModel.discountType == "Fix Price" ? "${currencyModel!.symbol}" : ""}${offerModel.discount} ${offerModel.discountType == "Percent" ? "% OFF".tr() : "OFF".tr()} ",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.7,
                                ),
                              ),
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

  bool isLoading = false;

  // getLocationData() async {
  //   await getCurrentLocation().then((value) {
  //     setState(() {
  //       MyAppState.selectedPosotion = value;
  //     });
  //     getData();
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }).onError((error, stackTrace) {
  //     getPermission();
  //   });
  //
  //   await placemarkFromCoordinates(MyAppState.selectedPosotion.latitude,
  //           MyAppState.selectedPosotion.longitude)
  //       .then((value) {
  //     Placemark placeMark = value[0];
  //
  //     setState(() {
  //       currentLocation =
  //           "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
  //     });
  //   }).catchError((error) {
  //     debugPrint("------>${error.toString()}");
  //   });
  //
  //   setState(() {
  //     isLoading = false;
  //   });
  // }
  Position? previousLocation;

  // Future<void> getLocationData() async {
  //
  //   print('Kaa MAMA');
  //   setState(() {
  //     isLoading = true;
  //   });
  //   try {
  //     print('Ki He');
  //
  //     final position = await getCurrentLocation();
  //     print('previousLocation : ${previousLocation}');
  //     if (previousLocation == null ||
  //         position.latitude != previousLocation!.latitude ||
  //         position.longitude != previousLocation!.longitude) {
  //       setState(() {
  //         MyAppState.selectedPosotion = position;
  //         previousLocation = position;
  //         print("position${position}");
  //       });
  //
  //       // Save new location to SharedPreferences
  //       // await prefs.setDouble('latitude', position.latitude);
  //       // await prefs.setDouble('longitude', position.longitude);
  //
  //       final placemarks = await placemarkFromCoordinates(
  //           // MyAppState.currentUser==null||MyAppState.currentUser?.userID==""||MyAppState.currentUser?.userID==null?MyAppState.selectedPosotion.latitude:MyAppState.currentUser?.location.latitude==0.01||MyAppState.currentUser?.location.latitude==null?MyAppState.selectedPosotion.latitude:double.parse((MyAppState.currentUser?.location.latitude).toString()),
  //           // MyAppState.currentUser==null||MyAppState.currentUser?.userID==""||MyAppState.currentUser?.userID==null?MyAppState.selectedPosotion.longitude:MyAppState.currentUser?.location.longitude==0.01||MyAppState.currentUser?.location.longitude==null?MyAppState.selectedPosotion.longitude:double.parse((MyAppState.currentUser?.location.latitude).toString())
  //           MyAppState.selectedPosotion.latitude,
  //           MyAppState.selectedPosotion.longitude
  //       );
  //       print("placemarks${placemarks}");
  //       print("latitu${MyAppState.selectedPosotion.latitude}");
  //       print("longi${MyAppState.selectedPosotion.longitude}");
  //
  //       if (placemarks.isNotEmpty) {
  //         final placeMark = placemarks[0];
  //         setState(() {
  //           currentLocation =
  //           "${MyAppState.currentUser==null||MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?placeMark.name:MyAppState.currentUser?.shippingAddress.line1==""?placeMark.name:MyAppState.currentUser?.shippingAddress.line1}, ${MyAppState.currentUser==null||MyAppState.currentUser==null||MyAppState.currentUser==""?placeMark.subLocality:MyAppState.currentUser?.shippingAddress.line2==null||MyAppState.currentUser?.shippingAddress.line2==""?placeMark.subLocality:MyAppState.currentUser?.shippingAddress.line2}, ${MyAppState.currentUser==null||MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?placeMark.locality:MyAppState.currentUser?.shippingAddress.city==null||MyAppState.currentUser?.shippingAddress.city==""?placeMark.locality:MyAppState.currentUser?.shippingAddress.city}, ${MyAppState.currentUser==null||MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?placeMark.postalCode:MyAppState.currentUser?.shippingAddress.postalCode==null||MyAppState.currentUser?.shippingAddress.postalCode==""?placeMark.postalCode:MyAppState.currentUser?.shippingAddress.postalCode}, ${MyAppState.currentUser==null||MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?placeMark.country:MyAppState.currentUser?.shippingAddress.country==null||MyAppState.currentUser?.shippingAddress.country==""?placeMark.country:MyAppState.currentUser?.shippingAddress.country}";
  //           print('Allhuva Location : ${currentLocation}');
  //           // isLoading = false;
  //           MyAppState.currentUser!.shippingAddress.country =
  //               placeMark.country ?? '';
  //           MyAppState.currentUser!.shippingAddress.line1 =
  //               placeMark.name ?? '';
  //           MyAppState.currentUser!.shippingAddress.line2 =
  //               placeMark.subLocality ?? '';
  //           MyAppState.currentUser!.shippingAddress.city =
  //               placeMark.locality ?? '';
  //           MyAppState.currentUser!.shippingAddress.postalCode =
  //               placeMark.postalCode ?? '';
  //         });
  //       }
  //
  //       await getData();
  //       setState(() {
  //         isLoading = false;
  //       });
  //     } else {
  //       print("Location has not changed.");
  //       await getData();
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   } catch (error) {
  //     debugPrint("------>${error.toString()}");
  //     await getPermission();
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  //   // SharedPreferences prefs = await SharedPreferences.getInstance();
  //   //
  //   // // Check if SharedPreferences has saved location data
  //   // double? savedLatitude = prefs.getDouble('latitude');
  //   // double? savedLongitude = prefs.getDouble('longitude');
  //   // addrss=prefs.getBool('address_state') ?? false;
  //   //
  //   // print('savedLatitude : ${savedLongitude}');
  //   // print('prefs.getBool : ${prefs.getBool('address_state')}${addrss}');
  //   // if (savedLatitude != null && savedLongitude != null) {
  //   //   // Load location from SharedPreferences
  //   //   MyAppState.selectedPosotion = Position(
  //   //     latitude: savedLatitude,
  //   //     longitude: savedLongitude,
  //   //     timestamp: DateTime.now(),
  //   //     accuracy: 0,
  //   //     altitude: 0,
  //   //     heading: 0,
  //   //     speed: 0,
  //   //     speedAccuracy: 0,
  //   //     altitudeAccuracy: 0,
  //   //     headingAccuracy: 0,
  //   //     floor: 0,
  //   //     isMocked: true,
  //   //   );
  //   //   previousLocation = MyAppState.selectedPosotion;
  //   //
  //   //   final placemarks =
  //   //   await placemarkFromCoordinates(savedLatitude, savedLongitude);
  //   //   if (placemarks.isNotEmpty) {
  //   //     final placeMark = placemarks[0];
  //   //     print("placeMark.country${placeMark.country}");
  //   //     setState(() {
  //   //       currentLocation =
  //   //       "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.postalCode}, ${placeMark.country}";
  //   //       isLoading = false;
  //   //       MyAppState.currentUser?.userID==null|| MyAppState.currentUser?.userID==""?print("a call nay thay ho")   :MyAppState.currentUser?.shippingAddress.country =
  //   //           placeMark.country ?? '';
  //   //       MyAppState.currentUser?.userID==null|| MyAppState.currentUser?.userID==""?print("a call nay thay ho") :  MyAppState.currentUser?.shippingAddress.line1 = placeMark.name ?? '';
  //   //       MyAppState.currentUser?.userID==null|| MyAppState.currentUser?.userID==""?print("a call nay thay ho") :  MyAppState.currentUser?.shippingAddress.line2 =
  //   //           placeMark.subLocality ?? '';
  //   //       MyAppState.currentUser?.userID==null|| MyAppState.currentUser?.userID==""?print("a call nay thay ho") :MyAppState.currentUser!.shippingAddress.city =
  //   //           placeMark.locality ?? '';
  //   //       MyAppState.currentUser?.userID==null|| MyAppState.currentUser?.userID==""?print("a call nay thay ho") :MyAppState.currentUser!.shippingAddress.postalCode =
  //   //           placeMark.postalCode ?? '';
  //   //     });
  //   //   }
  //   //   await getData();
  //   //   setState(() {
  //   //     isLoading = false;
  //   //   });
  //   // } else {
  //   //   // If no saved location, get live location
  //   //   print('Kaa MAMA');
  //   //   setState(() {
  //   //     isLoading = true;
  //   //   });
  //   //   try {
  //   //     print('Ki He');
  //   //
  //   //     final position = await getCurrentLocation();
  //   //     print('previousLocation : ${previousLocation}');
  //   //     if (previousLocation == null ||
  //   //         position.latitude != previousLocation!.latitude ||
  //   //         position.longitude != previousLocation!.longitude) {
  //   //       setState(() {
  //   //         MyAppState.selectedPosotion = position;
  //   //         previousLocation = position;
  //   //         print("position${position}");
  //   //       });
  //   //
  //   //       // Save new location to SharedPreferences
  //   //       await prefs.setDouble('latitude', position.latitude);
  //   //       await prefs.setDouble('longitude', position.longitude);
  //   //
  //   //       final placemarks = await placemarkFromCoordinates(
  //   //           MyAppState.selectedPosotion.latitude,
  //   //           MyAppState.selectedPosotion.longitude);
  //   //       print("placemarks${placemarks}");
  //   //       print("latitu${MyAppState.selectedPosotion.latitude}");
  //   //       print("longi${MyAppState.selectedPosotion.longitude}");
  //   //
  //   //       if (placemarks.isNotEmpty) {
  //   //         final placeMark = placemarks[0];
  //   //         setState(() {
  //   //           currentLocation =
  //   //           "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.postalCode}, ${placeMark.country}";
  //   //           print('Allhuva Location : ${currentLocation}');
  //   //           // isLoading = false;
  //   //           MyAppState.currentUser!.shippingAddress.country =
  //   //               placeMark.country ?? '';
  //   //           MyAppState.currentUser!.shippingAddress.line1 =
  //   //               placeMark.name ?? '';
  //   //           MyAppState.currentUser!.shippingAddress.line2 =
  //   //               placeMark.subLocality ?? '';
  //   //           MyAppState.currentUser!.shippingAddress.city =
  //   //               placeMark.locality ?? '';
  //   //           MyAppState.currentUser!.shippingAddress.postalCode =
  //   //               placeMark.postalCode ?? '';
  //   //         });
  //   //       }
  //   //
  //   //       await getData();
  //   //       setState(() {
  //   //         isLoading = false;
  //   //       });
  //   //     } else {
  //   //       print("Location has not changed.");
  //   //       await getData();
  //   //       setState(() {
  //   //         isLoading = false;
  //   //       });
  //   //     }
  //   //   } catch (error) {
  //   //     debugPrint("------>${error.toString()}");
  //   //     await getPermission();
  //   //   } finally {
  //   //     setState(() {
  //   //       isLoading = false;
  //   //     });
  //   //   }
  //   // }
  // }
  Future<void> getLocationData() async {
    double? savedLatitude;
    double? savedLongitude;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    MyAppState.selectedPosotion = await getCurrentLocation();
    print(
      "MyAppState.currentUser?.location.latitude${MyAppState.currentUser?.location.latitude}",
    );
    print(
      "MyAppState.currentUser?.location.latitude${MyAppState.selectedPosotion.latitude}",
    );
    // Check if SharedPreferences has saved location data
    setState(() {
      savedLatitude =
          MyAppState.currentUser?.location.latitude == 0.01
              ? MyAppState.selectedPosotion.latitude
              : MyAppState.currentUser?.location.latitude;
      // prefs.getDouble('latitude');
      savedLongitude =
          MyAppState.currentUser?.location.latitude == 0.01
              ? MyAppState.selectedPosotion.longitude
              : MyAppState.currentUser?.location.longitude;
    });
    // prefs.getDouble('longitude');
    addrss = prefs.getBool('address_state') ?? false;
    print('savedLatitude : ${savedLongitude}');
    if (savedLatitude != null && savedLongitude != null) {
      // Load location from SharedPreferences
      MyAppState.selectedPosotion = Position(
        latitude: double.parse(savedLatitude.toString()),
        longitude: double.parse(savedLongitude.toString()),
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
        double.parse(savedLatitude.toString()),
        double.parse(savedLongitude.toString()),
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

  // getPermission() async {
  //   setState(() {
  //     isLoading = false;
  //   });
  //   PermissionStatus _permissionGranted = await location.hasPermission();
  //   if (_permissionGranted == PermissionStatus.denied) {
  //     _permissionGranted = await location.requestPermission();
  //     if (_permissionGranted != PermissionStatus.granted) {
  //       getData();
  //     }
  //   }
  //   setState(() {
  //     isLoading = false;
  //   });
  // }
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
      // getCityFromCoordinates(MyAppState.selectedPosotion.latitude,MyAppState.selectedPosotion.longitude);
      //  MyAppState.currentUser?.userID==null|| MyAppState.currentUser?.userID==""?print("a call nay thay"):updateUserLocation(MyAppState.currentUser?.userID ?? "",double.parse(MyAppState.selectedPosotion.latitude.toString()),double.parse(MyAppState.selectedPosotion.longitude.toString()));
      // MyAppState.currentUser?.location = UserLocation(
      //   latitude: MyAppState.selectedPosotion.latitude,
      //   longitude: MyAppState.selectedPosotion.longitude,
      // );
      // getCityrestaurantcity(MyAppState.selectedPosotion.latitude,MyAppState.selectedPosotion.longitude);
      getCityFromCoordinates(
        MyAppState.currentUser?.userID == null ||
                MyAppState.currentUser?.userID == ""
            ? MyAppState.selectedPosotion.latitude
            : MyAppState.currentUser?.location.latitude == null ||
                MyAppState.currentUser?.location.latitude == 0.01
            ? MyAppState.selectedPosotion.latitude
            : double.parse(
              (MyAppState.currentUser?.location.latitude).toString(),
            ),
        MyAppState.currentUser?.userID == null ||
                MyAppState.currentUser?.userID == ""
            ? MyAppState.selectedPosotion.longitude
            : MyAppState.currentUser?.location.longitude == null ||
                MyAppState.currentUser?.location.longitude == 0.01
            ? MyAppState.selectedPosotion.longitude
            : double.parse(
              (MyAppState.currentUser?.location.longitude).toString(),
            ),
      );
      getCityrestaurantcity(
        MyAppState.currentUser?.userID == null ||
                MyAppState.currentUser?.userID == ""
            ? MyAppState.selectedPosotion.latitude
            : MyAppState.currentUser?.location.latitude == null ||
                MyAppState.currentUser?.location.latitude == 0.01
            ? MyAppState.selectedPosotion.latitude
            : double.parse(
              (MyAppState.currentUser?.location.latitude).toString(),
            ),
        MyAppState.currentUser?.userID == null ||
                MyAppState.currentUser?.userID == ""
            ? MyAppState.selectedPosotion.longitude
            : MyAppState.currentUser?.location.longitude == null ||
                MyAppState.currentUser?.location.longitude == 0.01
            ? MyAppState.selectedPosotion.longitude
            : double.parse(
              (MyAppState.currentUser?.location.longitude).toString(),
            ),
      );
      MyAppState.currentUser?.location = UserLocation(
        // latitude: MyAppState.selectedPosotion.latitude,
        // longitude: MyAppState.selectedPosotion.longitude,
        latitude:
            MyAppState.currentUser?.userID == null ||
                    MyAppState.currentUser?.userID == ""
                ? MyAppState.selectedPosotion.latitude
                : MyAppState.currentUser?.location.latitude == null ||
                    MyAppState.currentUser?.location.latitude == 0.01
                ? MyAppState.selectedPosotion.latitude
                : double.parse(
                  (MyAppState.currentUser?.location.latitude).toString(),
                ),
        longitude:
            MyAppState.currentUser?.userID == null ||
                    MyAppState.currentUser?.userID == ""
                ? MyAppState.selectedPosotion.longitude
                : MyAppState.currentUser?.location.longitude == null ||
                    MyAppState.currentUser?.location.longitude == 0.01
                ? MyAppState.selectedPosotion.longitude
                : double.parse(
                  (MyAppState.currentUser?.location.longitude).toString(),
                ),
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

  // Future<void> getData() async {
  //
  //   getFoodType();
  //   lstNearByFood.clear();
  //   fireStoreUtils.getRestaurantNearBy().whenComplete(() async {
  //     lstAllRestaurant = fireStoreUtils.getAllRestaurants().asBroadcastStream();
  //     print("current location ave cave che ${MyAppState.selectedPosotion.latitude  ?? ""}");
  //     print("current location ave cave che ${MyAppState.selectedPosotion.longitude  ?? ""}");
  //     getCityFromCoordinates(MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?MyAppState.selectedPosotion.latitude:MyAppState.currentUser?.location.latitude==null||MyAppState.currentUser?.location.latitude==0.01?MyAppState.selectedPosotion.latitude:double.parse((MyAppState.currentUser?.location.latitude).toString()),MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?MyAppState.selectedPosotion.longitude:MyAppState.currentUser?.location.longitude==null||MyAppState.currentUser?.location.longitude==0.01?MyAppState.selectedPosotion.longitude:double.parse((MyAppState.currentUser?.location.longitude).toString()));
  //     getCityrestaurantcity(MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?MyAppState.selectedPosotion.latitude:MyAppState.currentUser?.location.latitude==null||MyAppState.currentUser?.location.latitude==0.01?MyAppState.selectedPosotion.latitude:double.parse((MyAppState.currentUser?.location.latitude).toString()),MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?MyAppState.selectedPosotion.longitude:MyAppState.currentUser?.location.longitude==null||MyAppState.currentUser?.location.longitude==0.01?MyAppState.selectedPosotion.longitude:double.parse((MyAppState.currentUser?.location.longitude).toString()));
  //     MyAppState.currentUser?.location = UserLocation(
  //       // latitude: MyAppState.selectedPosotion.latitude,
  //       // longitude: MyAppState.selectedPosotion.longitude,
  //       latitude: MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?MyAppState.selectedPosotion.latitude:MyAppState.currentUser?.location.latitude==null||MyAppState.currentUser?.location.latitude==0.01?MyAppState.selectedPosotion.latitude:double.parse((MyAppState.currentUser?.location.latitude).toString()),
  //   longitude: MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?MyAppState.selectedPosotion.longitude:MyAppState.currentUser?.location.longitude==null||MyAppState.currentUser?.location.longitude==0.01?MyAppState.selectedPosotion.longitude:double.parse((MyAppState.currentUser?.location.longitude).toString()),
  //     );
  //     MyAppState.currentUser?.userID==null||MyAppState.currentUser?.userID==""?print("a call nay thay"): updateUserLocation(MyAppState.currentUser?.userID ?? "",MyAppState.currentUser?.location.latitude==null||MyAppState.currentUser?.location.latitude==0.01?MyAppState.selectedPosotion.latitude:double.parse((MyAppState.currentUser?.location.latitude).toString()),MyAppState.currentUser?.location.latitude==null||MyAppState.currentUser?.location.latitude==0.01?MyAppState.selectedPosotion.longitude:double.parse((MyAppState.currentUser?.location.longitude).toString()));
  //     if (MyAppState.currentUser != null) {
  //       lstFavourites = fireStoreUtils
  //           .getFavouriteRestaurant(MyAppState.currentUser!.userID);
  //       lstFavourites.then((event) {
  //         lstFav.clear();
  //         for (int a = 0; a < event.length; a++) {
  //           lstFav.add(event[a].restaurantId!);
  //         }
  //       });
  //       name = toBeginningOfSentenceCase(widget.user!.firstName);
  //     }
  //
  //     lstAllRestaurant!.listen((event) {
  //       vendors.clear();
  //       vendors.addAll(event);
  //       allstoreList.clear();
  //       allstoreList.addAll(event);
  //       productsFuture.then((value) {
  //         for (int a = 0; a < event.length; a++) {
  //           for (int d = 0; d < (value.length > 20 ? 20 : value.length); d++) {
  //             if (event[a].id == value[d].vendorID &&
  //                 !lstNearByFood.contains(value[d])) {
  //               lstNearByFood.add(value[d]);
  //             }
  //           }
  //         }
  //       });
  //
  //       FireStoreUtils().getPublicCoupons(city).then((value) {
  //         offersList.clear();
  //         offerVendorList.clear();
  //         value.forEach((element1) {
  //           event.forEach((element) {
  //             if (element1.restaurantId == element.id &&
  //                 element1.expireOfferDate!.toDate().isAfter(DateTime.now())) {
  //               offersList.add(element1);
  //               offerVendorList.add(element);
  //             }
  //           });
  //         });
  //         setState(() {});
  //       });
  //       FireStoreUtils().getStory().then((value) {
  //         storyList.clear();
  //         value.forEach((element1) {
  //           vendors.forEach((element) {
  //             if (element1.vendorID == element.id) {
  //               storyList.add(element1);
  //             }
  //           });
  //         });
  //         setState(() {
  //           isLoading = false;
  //         });
  //       });
  //     });
  //
  //     setState(() {
  //       isLoading = false;
  //     });
  //   });
  // }
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
              Text(
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
    // storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return
    //   Scaffold(
    //     body: Stack(
    //   children: [
    //     // StoryView(
    //     //     storyItems: List.generate(
    //     //       widget.storyList[widget.index].videoUrl.length,
    //     //       (i) {
    //     //         return StoryItem.pageVideo(
    //     //           widget.storyList[widget.index].videoUrl[i],
    //     //           controller: storyController,
    //     //         );
    //     //       },
    //     //     ).toList(),
    //     //     onStoryShow: (s) {
    //     //       debugPrint("Showing a story");
    //     //     },
    //     //     onComplete: () {
    //     //       debugPrint("--------->");
    //     //       debugPrint(widget.storyList.length.toString());
    //     //       debugPrint(widget.index.toString());
    //     //       if (widget.storyList.length - 1 != widget.index) {
    //     //         // Navigator.pop(context);
    //     //         // Navigator.of(context).push(MaterialPageRoute(
    //     //         //     builder: (context) => MoreStories(
    //     //         //       storyList: widget.storyList,
    //     //         //       index: widget.index + 1,
    //     //         //     )));
    //     //
    //     //         setState(() {
    //     //           widget.index = widget.index + 1;
    //     //         });
    //     //       } else {
    //     //         Navigator.pop(context);
    //     //       }
    //     //     },
    //     //     progressPosition: ProgressPosition.top,
    //     //     repeat: true,
    //     //     controller: storyController,
    //     //     onVerticalSwipeComplete: (direction) {
    //     //       if (direction == Direction.down) {
    //     //         Navigator.pop(context);
    //     //       }
    //     //     }),
    //     FutureBuilder(
    //       future: FireStoreUtils().getVendorByVendorID(
    //           widget.storyList[widget.index].vendorID.toString()),
    //       builder: (context, snapshot) {
    //         if (snapshot.connectionState == ConnectionState.waiting) {
    //           return Center(child: Container());
    //         } else {
    //           if (snapshot.hasError) {
    //             return Center(
    //                 child: Text("Error".tr() + ": ${snapshot.error}"));
    //           } else {
    //             VendorModel? vendorModel = snapshot.data;
    //             double distanceInMeters = Geolocator.distanceBetween(
    //                 vendorModel!.latitude,
    //                 vendorModel.longitude,
    //                 MyAppState.selectedPosotion.latitude,
    //                 MyAppState.selectedPosotion.longitude);
    //             double kilometer = distanceInMeters / 1000;
    //             return Positioned(
    //               top: 55,
    //               child: InkWell(
    //                 onTap: () {
    //                   push(
    //                     context,
    //                     NewVendorProductsScreen(vendorModel: vendorModel),
    //                   );
    //                 },
    //                 child: Padding(
    //                   padding: const EdgeInsets.symmetric(horizontal: 10),
    //                   child: Row(
    //                     children: [
    //                       ClipRRect(
    //                         borderRadius: BorderRadius.circular(30),
    //                         child: CachedNetworkImage(
    //                           imageUrl: vendorModel.photo,
    //                           height: 50,
    //                           width: 50,
    //                           imageBuilder: (context, imageProvider) =>
    //                               Container(
    //                             decoration: BoxDecoration(
    //                               borderRadius: BorderRadius.circular(30),
    //                               image: DecorationImage(
    //                                   image: imageProvider, fit: BoxFit.cover),
    //                             ),
    //                           ),
    //                           placeholder: (context, url) => Center(
    //                               child: CircularProgressIndicator.adaptive(
    //                             valueColor: AlwaysStoppedAnimation(
    //                                 Color(COLOR_PRIMARY)),
    //                           )),
    //                           errorWidget: (context, url, error) => ClipRRect(
    //                               borderRadius: BorderRadius.circular(30),
    //                               child: Image.network(
    //                                 AppGlobal.placeHolderImage!,
    //                                 fit: BoxFit.cover,
    //                                 width: MediaQuery.of(context).size.width,
    //                                 height: MediaQuery.of(context).size.height,
    //                               )),
    //                           fit: BoxFit.cover,
    //                         ),
    //                       ),
    //                       SizedBox(
    //                         width: 10,
    //                       ),
    //                       Column(
    //                         crossAxisAlignment: CrossAxisAlignment.start,
    //                         children: [
    //                           Text(vendorModel.title.toString(),
    //                               style: TextStyle(
    //                                   fontSize: 16,
    //                                   color: Colors.white,
    //                                   fontWeight: FontWeight.bold)),
    //                           SizedBox(
    //                             height: 5,
    //                           ),
    //                           Row(
    //                             crossAxisAlignment: CrossAxisAlignment.center,
    //                             children: [
    //                               Container(
    //                                 decoration: BoxDecoration(
    //                                   color: Colors.green,
    //                                   borderRadius: BorderRadius.circular(5),
    //                                 ),
    //                                 child: Padding(
    //                                   padding: const EdgeInsets.symmetric(
    //                                       horizontal: 5, vertical: 2),
    //                                   child: Row(
    //                                     mainAxisSize: MainAxisSize.min,
    //                                     children: [
    //                                       Text(
    //                                           vendorModel.reviewsCount != 0
    //                                               ? (vendorModel.reviewsSum /
    //                                                       vendorModel
    //                                                           .reviewsCount)
    //                                                   .toStringAsFixed(1)
    //                                               : 0.toString(),
    //                                           style: const TextStyle(
    //                                             fontFamily: "Poppinsm",
    //                                             letterSpacing: 0.5,
    //                                             fontSize: 12,
    //                                             color: Colors.white,
    //                                           )),
    //                                       const SizedBox(width: 3),
    //                                       const Icon(
    //                                         Icons.star,
    //                                         size: 16,
    //                                         color: Colors.white,
    //                                       ),
    //                                     ],
    //                                   ),
    //                                 ),
    //                               ),
    //                               SizedBox(
    //                                 width: 5,
    //                               ),
    //                               Icon(
    //                                 Icons.location_pin,
    //                                 size: 16,
    //                                 color: Color(COLOR_PRIMARY),
    //                               ),
    //                               SizedBox(
    //                                 width: 3,
    //                               ),
    //                               Text(
    //                                   "${kilometer.toDouble().toStringAsFixed(currencyModel!.decimal)} KM",
    //                                   style: TextStyle(
    //                                       color: Colors.white,
    //                                       fontFamily: "Poppinsr")),
    //                               SizedBox(
    //                                 width: 5,
    //                               ),
    //                               Container(
    //                                 height: 15,
    //                                 child: VerticalDivider(
    //                                   color: Colors.white,
    //                                   thickness: 2,
    //                                 ),
    //                               ),
    //                               SizedBox(
    //                                 width: 5,
    //                               ),
    //                               Text(
    //                                   DateTime.now()
    //                                               .difference(widget
    //                                                   .storyList[widget.index]
    //                                                   .createdAt!
    //                                                   .toDate())
    //                                               .inDays ==
    //                                           0
    //                                       ? 'Today'.tr()
    //                                       : "${DateTime.now().difference(widget.storyList[widget.index].createdAt!.toDate()).inDays.toString()} d",
    //                                   style: TextStyle(
    //                                       color: Colors.white,
    //                                       fontFamily: "Poppinsr")),
    //                             ],
    //                           ),
    //                         ],
    //                       )
    //                     ],
    //                   ),
    //                 ),
    //               ),
    //             );
    //           }
    //         }
    //       },
    //     )
    //   ],
    // ));
    Scaffold(
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
