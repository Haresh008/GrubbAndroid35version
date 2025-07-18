import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/CurrencyModel.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/Grocery/Groceryhome_page.dart';
import 'package:foodie_customer/ui/Language/language_choose_screen.dart';
import 'package:foodie_customer/ui/auth/AuthScreen.dart';
import 'package:foodie_customer/ui/cartScreen/CartScreen.dart';
import 'package:foodie_customer/ui/chat_screen/inbox_driver_screen.dart';
import 'package:foodie_customer/ui/chat_screen/inbox_screen.dart';
import 'package:foodie_customer/ui/cuisinesScreen/CuisinesScreen.dart';
import 'package:foodie_customer/ui/dineInScreen/dine_in_screen.dart';
import 'package:foodie_customer/ui/dineInScreen/my_booking_screen.dart';
import 'package:foodie_customer/ui/home/HomeScreen.dart';
import 'package:foodie_customer/ui/home/SaveAddressScreen.dart';
import 'package:foodie_customer/ui/home/favourite_item.dart';
import 'package:foodie_customer/ui/home/favourite_restaurant.dart';
import 'package:foodie_customer/ui/home/home_screen_two.dart';
import 'package:foodie_customer/ui/ordersScreen/OrdersScreen.dart';
import 'package:foodie_customer/ui/profile/ProfileScreen.dart';
import 'package:foodie_customer/ui/referral_screen/referral_screen.dart';
import 'package:foodie_customer/ui/searchScreen/SearchScreen.dart';
import 'package:foodie_customer/ui/wallet/walletScreen.dart';
import 'package:foodie_customer/userPrefrence.dart';
import 'package:foodie_customer/utils/DarkThemeProvider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/mail_setting.dart';
import '../contactUs/ContactUsScreen.dart';

enum DrawerSelection {
  Home,
  Wallet,
  dineIn,
  Search,
  Cuisines,
  Cart,
  Profile,
  Saveaddress,
  Orders,
  MyBooking,
  termsCondition,
  privacyPolicy,
  chooseLanguage,
  contactUs,
  referral,
  inbox,
  driver,
  Logout,
  LikedRestaurant,
  LikedProduct,
  Grocery,
}

class ContainerScreen extends StatefulWidget {
  final User? user;
  final Widget currentWidget;
  final String appBarTitle;
  final DrawerSelection drawerSelection;

  ContainerScreen({
    Key? key,
    required this.user,
    currentWidget,
    appBarTitle,
    this.drawerSelection = DrawerSelection.Home,
  }) : this.appBarTitle = appBarTitle ?? 'Home'.tr(),
       this.currentWidget =
           currentWidget ??
           ((homePageThem == "theme_2")
               ? HomeScreenTwo(user: MyAppState.currentUser)
               : HomeScreen(user: MyAppState.currentUser)),
       super(key: key);

  @override
  _ContainerScreen createState() {
    return _ContainerScreen();
  }
}

class _ContainerScreen extends State<ContainerScreen> {
  var key = GlobalKey<ScaffoldState>();

  late CartDatabase cartDatabase;
  late User user;
  late String _appBarTitle;
  final fireStoreUtils = FireStoreUtils();

  late Widget _currentWidget;
  late DrawerSelection _drawerSelection;

  int cartCount = 0;
  bool? isWalletEnable;

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

  Future<void> clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("All SharedPreferences data cleared!");
  }

  // bool isEnable = false;

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
      setState(() {
        isEnable = document.get('isEnable');
      });

      print('isEnable Status: $isEnable');
    } else {
      print('Document not found');
    }
  }

  // bool isEnable1 = false;

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Location service enable che ke nai e check karo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Permission check karo
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // Current position return karo
    return await Geolocator.getCurrentPosition();
  }

  Future<String> _getCityFromCoordinates(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks[0];
    return place.locality ?? 'Unknown City'; // City name return karse
  }

  Future<List<String>> getCities() async {
    // Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Settings document fetch karo
    DocumentSnapshot documentSnapshot =
        await firestore.collection('settings').doc('grubb_mart').get();

    // Check karo ke document ma data chhe ke nahi
    if (documentSnapshot.exists) {
      // Cities field fetch karo
      List<String> cities = List<String>.from(documentSnapshot.get('cities'));
      print("citiescities${cities}");
      return cities;
    } else {
      // Default empty list return karo jya data na male
      return [];
    }
  }

  void _getCit1() async {
    try {
      Position position = await _getCurrentLocation();
      String city = await _getCityFromCoordinates(position);
      print('Current City: $city');

      // Fetch the cities from Firestore
      List<String> cities = await getCities();

      // Check if the current city is in the list of cities
      if (cities.contains(city)) {
        setState(() {
          isEnable1 = true;
        });
        print(
          'Your current city "$city" is available in the Firestore cities.',
        );
      } else {
        print(
          'Your current city "$city" is not available in the Firestore cities.',
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<List<String>> getCities1() async {
    // Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch the settings document
    DocumentSnapshot documentSnapshot =
        await firestore.collection('settings').doc('grubb_mart').get();

    // Check if the document exists
    if (documentSnapshot.exists) {
      // Fetch the cities field
      List<String> cities = List<String>.from(documentSnapshot.get('cities'));
      print("Cities: $cities");
      return cities;
    } else {
      // Return an empty list if no data is found
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    getIsEnableStatus();
    setCurrency();
    // _getCit1();
    setState(() {
      isEnable;
      isEnable1;
      homedayanamic;
      homedayanamic1;
      print("fgfdgdfgdgdgdgddfg${isEnable}");
      print("fgfdgdfgdgdgdgddfg${isEnable1}");
      print("fgfdgdfgdgdgdgddfg${homedayanamic1}");
      print("fgfdgdfgdgdgdgddfg${homedayanamic}");
    });
    initializeFlutterFire();
    if (widget.user != null) {
      user = widget.user!;
    } else {
      user = new User();
    }
    _currentWidget = widget.currentWidget;
    _appBarTitle = widget.appBarTitle;
    _drawerSelection = widget.drawerSelection;
    //getKeyHash();
    /// On iOS, we request notification permissions, Does nothing and returns null on Android
    FireStoreUtils.firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    fireStoreUtils.getuserplaceholderimage().then((value) {
      AppGlobal.userprofileimage = value;
    });
  }

  setCurrency() async {
    await FirebaseFirestore.instance
        .collection(Setting)
        .doc("home_page_theme")
        .get()
        .then((value) {
          if (value.exists) {
            homePageThem = value.data()!["theme"];
          }
        });

    await FireStoreUtils().getCurrency().then((value) {
      if (value != null) {
        currencyModel = value;
      } else {
        currencyModel = CurrencyModel(
          id: "",
          code: "USD",
          decimal: 2,
          isactive: true,
          name: "US Dollar",
          symbol: "\$",
          symbolatright: false,
        );
      }
    });

    MyAppState.selectedPosotion = await getCurrentLocation();
    List<Placemark> placeMarks = await placemarkFromCoordinates(
      MyAppState.selectedPosotion.latitude,
      MyAppState.selectedPosotion.longitude,
      // MyAppState.currentUser == null ||
      //         MyAppState.currentUser?.userID == "" ||
      //         MyAppState.currentUser?.userID == null
      //     ? MyAppState.selectedPosotion.latitude
      //     : MyAppState.currentUser?.location.latitude == 0.01 ||
      //             MyAppState.currentUser?.location.latitude == null
      //         ? MyAppState.selectedPosotion.latitude
      //         : double.parse(
      //             (MyAppState.currentUser?.location.latitude).toString()),
      // MyAppState.currentUser == null ||
      //         MyAppState.currentUser?.userID == "" ||
      //         MyAppState.currentUser?.userID == null
      //     ? MyAppState.selectedPosotion.longitude
      //     : MyAppState.currentUser?.location.longitude == 0.01 ||
      //             MyAppState.currentUser?.location.longitude == null
      //         ? MyAppState.selectedPosotion.longitude
      //         : double.parse(
      //             (MyAppState.currentUser?.location.latitude).toString())
    );
    country = placeMarks.first.country;
    print("countrycountrycountry${country}");
    print(
      "live location shu ave che ${MyAppState.currentUser == null || MyAppState.currentUser?.userID == "" || MyAppState.currentUser?.userID == null
          ? MyAppState.selectedPosotion.latitude
          : MyAppState.currentUser?.location.latitude == 0.01 || MyAppState.currentUser?.location.latitude == null
          ? MyAppState.selectedPosotion.latitude
          : double.parse((MyAppState.currentUser?.location.latitude).toString())}",
    );
    await FireStoreUtils().getTaxList().then((value) {
      if (value != null) {
        taxList = value;
      }
    });

    await FireStoreUtils().getRazorPayDemo();
    await FireStoreUtils().gethometest();
    await FireStoreUtils.getPaypalSettingData();
    await FireStoreUtils.getStripeSettingData();
    await FireStoreUtils.getPayStackSettingData();
    await FireStoreUtils.getFlutterWaveSettingData();
    await FireStoreUtils.getPaytmSettingData();
    await FireStoreUtils.getWalletSettingData();
    await FireStoreUtils.getPayFastSettingData();
    await FireStoreUtils.getMercadoPagoSettingData();
    await FireStoreUtils.getReferralAmount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cartDatabase = Provider.of<CartDatabase>(context);
  }

  DateTime preBackpress = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (!(_currentWidget is HomeScreen)) {
          setState(() {
            _drawerSelection = DrawerSelection.Home;
            _appBarTitle = 'Restaurants'.tr();
            if (homePageThem == "theme_2") {
              print("HomeScreenTwoHomeScreenTwo");
              _currentWidget = HomeScreenTwo(user: MyAppState.currentUser);
            } else {
              print("HomeScreenHomeScreenHomeScreen");
              _currentWidget = HomeScreen(user: MyAppState.currentUser);
            }
          });
          return false;
        } else {
          final timegap = DateTime.now().difference(preBackpress);
          final cantExit = timegap >= Duration(seconds: 2);
          preBackpress = DateTime.now();
          if (cantExit) {
            final snack = SnackBar(
              content: Text(
                'Press Back button again to Exit'.tr(),
                style: TextStyle(color: Colors.white),
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.black,
            );
            ScaffoldMessenger.of(context).showSnackBar(snack);
            return false; // false will do nothing when back press
          } else {
            return true; // true will exit the app
          }
        }
      },
      child: ChangeNotifierProvider.value(
        value: user,
        child: Consumer<User>(
          builder: (context, user, _) {
            return Scaffold(
              extendBodyBehindAppBar:
                  _drawerSelection == DrawerSelection.Wallet ? true : false,
              key: key,
              drawer: Drawer(
                width: MediaQuery.of(context).size.width * 0.875,
                child: Container(
                  color: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : null,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            Consumer<User>(
                              builder: (context, user, _) {
                                return DrawerHeader(
                                  child: Column(
                                    // mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      displayCircleImage(
                                        user.profilePictureURL,
                                        65,
                                        false,
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.87,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            SizedBox(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.55,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                        ),
                                                    child: Text(
                                                      user.fullName(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 5.0,
                                                        ),
                                                    child: Text(
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      user.email,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                !themeChange.darkTheme
                                                    ? const Icon(
                                                      Icons.light_mode_sharp,
                                                    )
                                                    : const Icon(
                                                      Icons.nightlight,
                                                    ),
                                                Switch(
                                                  // thumb color (round icon)
                                                  splashRadius: 50.0,
                                                  inactiveThumbColor:
                                                      Colors.black,

                                                  // activeThumbImage: const AssetImage('https://lists.gnu.org/archive/html/emacs-devel/2015-10/pngR9b4lzUy39.png'),
                                                  // inactiveThumbImage: const AssetImage('http://wolfrosch.com/_img/works/goodies/icon/vim@2x'),
                                                  value: themeChange.darkTheme,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      themeChange.darkTheme =
                                                          value;
                                                    });

                                                    UserPreference.setLightDarkThemeData(
                                                      value,
                                                    );
                                                    themeChange.darkTheme =
                                                        value;
                                                    print(
                                                      "Switch Value ${value}",
                                                    );
                                                    UserPreference.getLightDarkThemeData();
                                                    print(
                                                      "Switch Value1 ${value}",
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(COLOR_PRIMARY),
                                  ),
                                );
                              },
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection == DrawerSelection.Home,
                                title: Text('Restaurants').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _drawerSelection = DrawerSelection.Home;
                                    _appBarTitle = 'Restaurants'.tr();
                                    if (homePageThem == "theme_2") {
                                      _currentWidget = HomeScreenTwo(
                                        user: MyAppState.currentUser,
                                      );
                                    } else {
                                      _currentWidget = HomeScreen(
                                        user: MyAppState.currentUser,
                                      );
                                    }
                                  });
                                },
                                leading: Icon(CupertinoIcons.home),
                              ),
                            ),
                            isEnable1 && isEnable
                                ? ListTileTheme(
                                  style: ListTileStyle.drawer,
                                  selectedColor: Color(COLOR_PRIMARY),
                                  child: ListTile(
                                    selected:
                                        _drawerSelection ==
                                        DrawerSelection.Grocery,
                                    title: Text('Grubb Mart').tr(),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _drawerSelection =
                                            DrawerSelection.Grocery;
                                        _appBarTitle = 'Grubb Mart'.tr();
                                        if (homePageThem == "theme_2") {
                                          _currentWidget = GroceryHome(
                                            user: MyAppState.currentUser,
                                            isPageCallFromHomeScreen: false,
                                          );
                                        } else {
                                          _currentWidget = GroceryHome(
                                            user: MyAppState.currentUser,
                                            isPageCallFromHomeScreen: false,
                                          );
                                        }
                                      });
                                    },
                                    leading: Icon(Icons.shopping_bag_outlined),
                                  ),
                                )
                                : Container(),
                            homedayanamic && homedayanamic1
                                ? ListTileTheme(
                                  style: ListTileStyle.drawer,
                                  selectedColor: Color(COLOR_PRIMARY),
                                  child: ListTile(
                                    selected:
                                        _drawerSelection ==
                                        DrawerSelection.Grocery,
                                    title: Text('Grubb Mart').tr(),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _drawerSelection =
                                            DrawerSelection.Grocery;
                                        _appBarTitle = 'Grubb Mart'.tr();
                                        if (homePageThem == "theme_2") {
                                          _currentWidget = GroceryHome(
                                            user: MyAppState.currentUser,
                                            isPageCallFromHomeScreen: false,
                                          );
                                        } else {
                                          _currentWidget = GroceryHome(
                                            user: MyAppState.currentUser,
                                            isPageCallFromHomeScreen: false,
                                          );
                                        }
                                      });
                                    },
                                    leading: Icon(Icons.shopping_bag_outlined),
                                  ),
                                )
                                : Container(),
                            resisEnable1 && resisEnable1
                                ? ListTileTheme(
                                  style: ListTileStyle.drawer,
                                  selectedColor: Color(COLOR_PRIMARY),
                                  child: ListTile(
                                    selected:
                                        _drawerSelection ==
                                        DrawerSelection.Cuisines,
                                    leading: Image.asset(
                                      'assets/images/cousion.png',
                                      color:
                                          _drawerSelection ==
                                                  DrawerSelection.Cuisines
                                              ? Color(COLOR_PRIMARY)
                                              : isDarkMode(context)
                                              ? Colors.grey.shade200
                                              : Colors.grey.shade600,
                                      width: 24,
                                      height: 24,
                                    ),
                                    title: Text('Cuisines').tr(),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _drawerSelection =
                                            DrawerSelection.Cuisines;
                                        _appBarTitle = 'Cuisines'.tr();
                                        _currentWidget = CuisinesScreen();
                                      });
                                    },
                                  ),
                                )
                                : Container(),
                            // !isDineInEnable
                            //     ? Container()
                            //     :
                            resisEnable1 && resisEnable1
                                ? ListTileTheme(
                                  style: ListTileStyle.drawer,
                                  selectedColor: Color(COLOR_PRIMARY),
                                  child: ListTile(
                                    selected:
                                        _drawerSelection ==
                                        DrawerSelection.dineIn,
                                    leading: Icon(Icons.restaurant),
                                    title: Text('Dine-in').tr(),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _drawerSelection =
                                            DrawerSelection.dineIn;
                                        _appBarTitle = 'Dine-In'.tr();
                                        _currentWidget = DineInScreen(
                                          user: MyAppState.currentUser,
                                        );
                                      });
                                    },
                                  ),
                                )
                                : Container(),
                            resisEnable1 && resisEnable1
                                ? ListTileTheme(
                                  style: ListTileStyle.drawer,
                                  selectedColor: Color(COLOR_PRIMARY),
                                  child: ListTile(
                                    selected:
                                        _drawerSelection ==
                                        DrawerSelection.Search,
                                    title: Text('Search').tr(),
                                    leading: Icon(Icons.search),
                                    onTap: () async {
                                      push(context, const SearchScreen());
                                    },
                                  ),
                                )
                                : Container(),
                            resisEnable1 && resisEnable1
                                ? ListTileTheme(
                                  style: ListTileStyle.drawer,
                                  selectedColor: Color(COLOR_PRIMARY),
                                  child: ListTile(
                                    selected:
                                        _drawerSelection ==
                                        DrawerSelection.LikedRestaurant,
                                    title: Text('Favourite Restaurants').tr(),
                                    onTap: () {
                                      if (MyAppState.currentUser == null) {
                                        Navigator.pop(context);
                                        push(context, AuthScreen());
                                      } else {
                                        Navigator.pop(context);
                                        setState(() {
                                          _drawerSelection =
                                              DrawerSelection.LikedRestaurant;
                                          _appBarTitle =
                                              'Favourite Restaurants'.tr();
                                          _currentWidget =
                                              FavouriteRestaurantScreen();
                                        });
                                      }
                                    },
                                    leading: Icon(CupertinoIcons.heart),
                                  ),
                                )
                                : Container(),
                            resisEnable1 && resisEnable1
                                ? ListTileTheme(
                                  style: ListTileStyle.drawer,
                                  selectedColor: Color(COLOR_PRIMARY),
                                  child: ListTile(
                                    selected:
                                        _drawerSelection ==
                                        DrawerSelection.LikedProduct,
                                    title: const Text('Favourite Items').tr(),
                                    onTap: () {
                                      Navigator.pop(context);
                                      if (MyAppState.currentUser == null) {
                                        push(context, AuthScreen());
                                      } else {
                                        setState(() {
                                          _drawerSelection =
                                              DrawerSelection.LikedProduct;
                                          _appBarTitle = 'Favourite Items'.tr();
                                          _currentWidget =
                                              const FavouriteItemScreen();
                                        });
                                      }
                                    },
                                    leading: const Icon(CupertinoIcons.heart),
                                  ),
                                )
                                : Container(),
                            Visibility(
                              visible: UserPreference.getWalletData() ?? false,
                              child: ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: Color(COLOR_PRIMARY),
                                child: ListTile(
                                  selected:
                                      _drawerSelection ==
                                      DrawerSelection.Wallet,
                                  leading: Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                  title: Text('Grubb Money').tr(),
                                  onTap: () {
                                    if (MyAppState.currentUser == null) {
                                      Navigator.pop(context);
                                      push(context, AuthScreen());
                                    } else {
                                      Navigator.pop(context);
                                      setState(() {
                                        _drawerSelection =
                                            DrawerSelection.Wallet;
                                        _appBarTitle = 'Grubb money'.tr();
                                        _currentWidget = WalletScreen();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection == DrawerSelection.Cart,
                                leading: Icon(CupertinoIcons.cart),
                                title: Text('Cart').tr(),
                                onTap: () {
                                  if (MyAppState.currentUser == null) {
                                    Navigator.pop(context);
                                    push(context, AuthScreen());
                                  } else {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.Cart;
                                      _appBarTitle = 'Your Cart'.tr();
                                      _currentWidget = CartScreen(
                                        fromContainer: true,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection == DrawerSelection.Profile,
                                leading: Icon(CupertinoIcons.person),
                                title: Text('Profile').tr(),
                                onTap: () {
                                  if (MyAppState.currentUser == null) {
                                    Navigator.pop(context);
                                    push(context, AuthScreen());
                                  } else {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection =
                                          DrawerSelection.Profile;
                                      _appBarTitle = 'My Profile'.tr();
                                      _currentWidget = ProfileScreen(
                                        user: user,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection ==
                                    DrawerSelection.Saveaddress,
                                leading: Icon(CupertinoIcons.location_circle),
                                title: Text('address_book').tr(),
                                onTap: () {
                                  if (MyAppState.currentUser == null) {
                                    Navigator.pop(context);
                                    push(context, SaveAddressScreen());
                                  } else {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection =
                                          DrawerSelection.Saveaddress;
                                      _appBarTitle = 'address_book'.tr();
                                      _currentWidget = SaveAddressScreen();
                                      print("_appBarTitle${_appBarTitle}");
                                    });
                                  }
                                },
                              ),
                            ),

                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection == DrawerSelection.Orders,
                                leading: Image.asset(
                                  'assets/images/truck.png',
                                  color:
                                      _drawerSelection == DrawerSelection.Orders
                                          ? Color(COLOR_PRIMARY)
                                          : isDarkMode(context)
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade600,
                                  width: 24,
                                  height: 24,
                                ),
                                title: Text('Orders').tr(),
                                onTap: () {
                                  if (MyAppState.currentUser == null) {
                                    Navigator.pop(context);
                                    push(context, AuthScreen());
                                  } else {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.Orders;
                                      _appBarTitle = 'Orders'.tr();
                                      _currentWidget = OrdersScreen();
                                    });
                                  }
                                },
                              ),
                            ),
                            !isDineInEnable
                                ? Container()
                                : ListTileTheme(
                                  style: ListTileStyle.drawer,
                                  selectedColor: Color(COLOR_PRIMARY),
                                  child: ListTile(
                                    selected:
                                        _drawerSelection ==
                                        DrawerSelection.MyBooking,
                                    leading: Image.asset(
                                      'assets/images/your_booking.png',
                                      color:
                                          _drawerSelection ==
                                                  DrawerSelection.MyBooking
                                              ? Color(COLOR_PRIMARY)
                                              : isDarkMode(context)
                                              ? Colors.grey.shade200
                                              : Colors.grey.shade600,
                                      width: 24,
                                      height: 24,
                                    ),
                                    title: Text('Dine-In Bookings').tr(),
                                    onTap: () {
                                      if (MyAppState.currentUser == null) {
                                        Navigator.pop(context);
                                        push(context, AuthScreen());
                                      } else {
                                        Navigator.pop(context);
                                        setState(() {
                                          _drawerSelection =
                                              DrawerSelection.MyBooking;
                                          _appBarTitle =
                                              'Dine-In Bookings'.tr();
                                          _currentWidget = MyBookingScreen();
                                        });
                                      }
                                    },
                                  ),
                                ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection ==
                                    DrawerSelection.referral,
                                leading: Image.asset(
                                  'assets/images/refer.png',
                                  width: 28,
                                  color: Colors.grey,
                                ),
                                title: const Text('Refer a friend').tr(),
                                onTap: () async {
                                  if (MyAppState.currentUser == null) {
                                    Navigator.pop(context);
                                    push(context, AuthScreen());
                                  } else {
                                    Navigator.pop(context);
                                    push(context, ReferralScreen());
                                  }
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection ==
                                    DrawerSelection.chooseLanguage,
                                leading: Icon(
                                  Icons.language,
                                  color:
                                      _drawerSelection ==
                                              DrawerSelection.chooseLanguage
                                          ? Color(COLOR_PRIMARY)
                                          : isDarkMode(context)
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade600,
                                ),
                                title: const Text('Language').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _drawerSelection =
                                        DrawerSelection.chooseLanguage;
                                    _appBarTitle = 'Language'.tr();
                                    _currentWidget = LanguageChooseScreen(
                                      isContainer: true,
                                    );
                                  });
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection ==
                                    DrawerSelection.contactUs,
                                leading: Icon(
                                  Icons.call,
                                  color:
                                      _drawerSelection ==
                                              DrawerSelection.contactUs
                                          ? Color(COLOR_PRIMARY)
                                          : isDarkMode(context)
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade600,
                                ),
                                title: const Text('Contact Us').tr(),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _drawerSelection =
                                        DrawerSelection.contactUs;
                                    _appBarTitle = 'Contact Us'.tr();
                                    _currentWidget = ContactUsScreen(
                                      // isContainer: true,
                                    );
                                  });
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection == DrawerSelection.inbox,
                                leading: Icon(
                                  CupertinoIcons.chat_bubble_2_fill,
                                ),
                                title: Text('Restaurant Inbox').tr(),
                                onTap: () {
                                  if (MyAppState.currentUser == null) {
                                    Navigator.pop(context);
                                    push(context, AuthScreen());
                                  } else {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.inbox;
                                      _appBarTitle = 'Restaurant Inbox'.tr();
                                      _currentWidget = InboxScreen();
                                    });
                                  }
                                },
                              ),
                            ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection == DrawerSelection.driver,
                                leading: Icon(
                                  CupertinoIcons.chat_bubble_2_fill,
                                ),
                                title: Text('Driver Inbox').tr(),
                                onTap: () {
                                  if (MyAppState.currentUser == null) {
                                    Navigator.pop(context);
                                    push(context, AuthScreen());
                                  } else {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.driver;
                                      _appBarTitle = 'Driver Inbox'.tr();
                                      _currentWidget = InboxDriverScreen();
                                    });
                                  }
                                },
                              ),
                            ),
                            // ListTileTheme(
                            //   style: ListTileStyle.drawer,
                            //   selectedColor: Color(COLOR_PRIMARY),
                            //   child: ListTile(
                            //     selected: _drawerSelection == DrawerSelection.termsCondition,
                            //     leading: const Icon(Icons.policy),
                            //     title: const Text('Terms and Condition').tr(),
                            //     onTap: () async {
                            //       push(context, const TermsAndCondition());
                            //     },
                            //   ),
                            // ),
                            // ListTileTheme(
                            //   style: ListTileStyle.drawer,
                            //   selectedColor: Color(COLOR_PRIMARY),
                            //   child: ListTile(
                            //     selected: _drawerSelection == DrawerSelection.privacyPolicy,
                            //     leading: const Icon(Icons.privacy_tip),
                            //     title: const Text('Privacy policy').tr(),
                            //     onTap: () async {
                            //       push(context, const PrivacyPolicyScreen());
                            //     },
                            //   ),
                            // ),
                            ListTileTheme(
                              style: ListTileStyle.drawer,
                              selectedColor: Color(COLOR_PRIMARY),
                              child: ListTile(
                                selected:
                                    _drawerSelection == DrawerSelection.Logout,
                                leading: Icon(Icons.logout),
                                title:
                                    Text(
                                      MyAppState.currentUser == null
                                          ? 'Login'
                                          : 'Log Out',
                                    ).tr(),
                                onTap: () async {
                                  if (MyAppState.currentUser == null) {
                                    pushAndRemoveUntil(
                                      context,
                                      AuthScreen(),
                                      false,
                                    );
                                  } else {
                                    Navigator.pop(context);
                                    //user.active = false;

                                    user.lastOnlineTimestamp = Timestamp.now();
                                    user.fcmToken = "";
                                    await FireStoreUtils.updateCurrentUser(
                                      user,
                                    );
                                    await auth.FirebaseAuth.instance.signOut();
                                    MyAppState.currentUser = null;
                                    MyAppState
                                        .selectedPosotion = Position.fromMap({
                                      'latitude': 0.0,
                                      'longitude': 0.0,
                                    });
                                    clearSharedPreferences();
                                    Provider.of<CartDatabase>(
                                      context,
                                      listen: false,
                                    ).deleteAllProducts();
                                    pushAndRemoveUntil(
                                      context,
                                      AuthScreen(),
                                      false,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("V : $appVersion"),
                      ),
                    ],
                  ),
                ),
              ),
              appBar: AppBar(
                elevation: 0,
                centerTitle:
                    _drawerSelection == DrawerSelection.Wallet ? true : false,
                backgroundColor:
                    _drawerSelection == DrawerSelection.Wallet
                        ? Colors.transparent
                        : isDarkMode(context)
                        ? Color(DARK_COLOR)
                        : _drawerSelection == DrawerSelection.Home
                        ? homePageThem == "theme_2"
                            ? Colors.white
                            : Colors.black
                        : Colors.white,
                //isDarkMode(context) ? Color(DARK_COLOR) : null,
                leading: IconButton(
                  visualDensity: VisualDensity(horizontal: -4),
                  padding: EdgeInsets.only(right: 5),
                  icon: Image(
                    image: AssetImage("assets/images/menu.png"),
                    width: 20,
                    color:
                        _drawerSelection == DrawerSelection.Wallet
                            ? Colors.white
                            : isDarkMode(context)
                            ? Colors.white
                            : homePageThem == "theme_2"
                            ? Colors.black
                            : _drawerSelection == DrawerSelection.Home
                            ? Colors.white
                            : Colors.black,
                  ),
                  onPressed: () {
                    key.currentState!.openDrawer();
                    setState(() {
                      homedayanamic;
                      homedayanamic1;
                      isEnable1;
                      isEnable;
                      resisEnable;
                      resisEnable1;
                    });
                  },
                ),
                // iconTheme: IconThemeData(color: Colors.blue),
                title: Text(
                  _appBarTitle,
                  style: TextStyle(
                    fontFamily: "Poppinsm",
                    color:
                        isDarkMode(context)
                            ? Colors.white
                            : homePageThem == "theme_2"
                            ? Colors.black
                            : _drawerSelection == DrawerSelection.Home
                            ? Colors.white
                            : Colors.black,
                    //isDarkMode(context) ? Colors.white : Colors.black,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                actions:
                    _drawerSelection == DrawerSelection.Wallet ||
                            _drawerSelection == DrawerSelection.MyBooking
                        ? []
                        : _drawerSelection == DrawerSelection.dineIn
                        ? [
                          // IconButton(
                          //     padding: const EdgeInsets.only(right: 20),
                          //     visualDensity: VisualDensity(horizontal: -4),
                          //     tooltip: 'QrCode'.tr(),
                          //     icon: Image(
                          //       image: AssetImage("assets/images/qrscan.png"),
                          //       width: 20,
                          //       color: isDarkMode(context)
                          //           ? Colors.white
                          //           : homePageThem == "theme_2"
                          //           ? Colors.black
                          //           : _drawerSelection == DrawerSelection.Home
                          //           ? Colors.white
                          //           : Colors.black,
                          //     ),
                          //     onPressed: () {
                          //       push(
                          //         context,
                          //         QrCodeScanner(),
                          //       );
                          //     }),
                          IconButton(
                            visualDensity: const VisualDensity(horizontal: -4),
                            padding: EdgeInsets.only(right: 10),
                            icon: Image(
                              image: AssetImage("assets/images/search.png"),
                              width: 20,
                              color:
                                  isDarkMode(context)
                                      ? Colors.white
                                      : homePageThem == "theme_2"
                                      ? Colors.black
                                      : _drawerSelection == DrawerSelection.Home
                                      ? Colors.white
                                      : Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                push(context, const SearchScreen());
                              });
                            },
                          ),
                          // if (!(_currentWidget is CartScreen) || !(_currentWidget is ProfileScreen))
                          //   IconButton(
                          //     visualDensity: VisualDensity(horizontal: -4),
                          //     padding: EdgeInsets.only(right: 10),
                          //     icon: Image(
                          //       image: AssetImage("assets/images/map.png"),
                          //       width: 20,
                          //       color: isDarkMode(context)
                          //           ? Colors.white
                          //           : homePageThem == "theme_2"
                          //           ? Colors.black
                          //           : _drawerSelection == DrawerSelection.Home
                          //           ? Colors.white
                          //           : Colors.black,
                          //     ),
                          //     onPressed: () => push(
                          //       context,
                          //       MapViewScreen(),
                          //     ),
                          //   )
                        ]
                        : [
                          // IconButton(
                          //     padding: const EdgeInsets.only(right: 20),
                          //     visualDensity: VisualDensity(horizontal: -4),
                          //     tooltip: 'QrCode'.tr(),
                          //     icon: Stack(
                          //       clipBehavior: Clip.none,
                          //       children: [
                          //         Image(
                          //           image: AssetImage("assets/images/qrscan.png"),
                          //           width: 20,
                          //           color: isDarkMode(context)
                          //               ? Colors.white
                          //               : homePageThem == "theme_2"
                          //               ? Colors.black
                          //               : _drawerSelection == DrawerSelection.Home
                          //               ? Colors.white
                          //               : Colors.black,
                          //         ),
                          //       ],
                          //     ),
                          //     onPressed: () {
                          //       push(
                          //         context,
                          //         QrCodeScanner(),
                          //       );
                          //     }),
                          IconButton(
                            visualDensity: const VisualDensity(horizontal: -4),
                            padding: EdgeInsets.only(right: 10),
                            icon: Image(
                              image: AssetImage("assets/images/search.png"),
                              width: 20,
                              color:
                                  isDarkMode(context)
                                      ? Colors.white
                                      : homePageThem == "theme_2"
                                      ? Colors.black
                                      : _drawerSelection == DrawerSelection.Home
                                      ? Colors.white
                                      : Colors.black,
                            ),
                            onPressed: () {
                              push(context, const SearchScreen());
                            },
                          ),
                          // if (!(_currentWidget is CartScreen) || !(_currentWidget is ProfileScreen))
                          //   IconButton(
                          //     visualDensity: VisualDensity(horizontal: -4),
                          //     padding: EdgeInsets.only(right: 10),
                          //     icon: Image(
                          //       image: AssetImage("assets/images/map.png"),
                          //       width: 20,
                          //       color: isDarkMode(context)
                          //           ? Colors.white
                          //           : homePageThem == "theme_2"
                          //           ? Colors.black
                          //           : _drawerSelection == DrawerSelection.Home
                          //           ? Colors.white
                          //           : Colors.black,
                          //     ),
                          //     onPressed: () => push(
                          //       context,
                          //       MapViewScreen(),
                          //     ),
                          //   ),
                          // if (!(_currentWidget is CartScreen) || !(_currentWidget is ProfileScreen))
                          //   IconButton(
                          //       padding: EdgeInsets.only(right: 20),
                          //       visualDensity: VisualDensity(horizontal: -4),
                          //       tooltip: 'Cart'.tr(),
                          //       icon: Stack(
                          //         clipBehavior: Clip.none,
                          //         children: [
                          //           Image(
                          //             image: AssetImage("assets/images/cart.png"),
                          //             width: 20,
                          //             color: isDarkMode(context)
                          //                 ? Colors.white
                          //                 : homePageThem == "theme_2"
                          //                 ? Colors.black
                          //                 : _drawerSelection == DrawerSelection.Home
                          //                 ? Colors.white
                          //                 : Colors.black,
                          //           ),
                          //           StreamBuilder<List<CartProduct>>(
                          //             stream: cartDatabase.watchProducts,
                          //             builder: (context, snapshot) {
                          //               cartCount = 0;
                          //               if (snapshot.hasData) {
                          //                 snapshot.data!.forEach((element) {
                          //                   cartCount += element.quantity;
                          //                 });
                          //               }
                          //               return Visibility(
                          //                 visible: cartCount >= 1,
                          //                 child: Positioned(
                          //                   right: -6,
                          //                   top: -8,
                          //                   child: Container(
                          //                     padding: EdgeInsets.all(4),
                          //                     decoration: BoxDecoration(
                          //                       shape: BoxShape.circle,
                          //                       color: Color(COLOR_PRIMARY),
                          //                     ),
                          //                     constraints: BoxConstraints(
                          //                       minWidth: 12,
                          //                       minHeight: 12,
                          //                     ),
                          //                     child: Center(
                          //                       child: new Text(
                          //                         cartCount <= 99 ? '$cartCount' : '+99',
                          //                         style: new TextStyle(
                          //                           color: Colors.white,
                          //                           // fontSize: 10,
                          //                         ),
                          //                         textAlign: TextAlign.center,
                          //                       ),
                          //                     ),
                          //                   ),
                          //                 ),
                          //               );
                          //             },
                          //           )
                          //         ],
                          //       ),
                          //       onPressed: () {
                          //         if (MyAppState.currentUser == null) {
                          //           Navigator.pop(context);
                          //           push(context, AuthScreen());
                          //         } else {
                          //           setState(() {
                          //             _drawerSelection = DrawerSelection.Cart;
                          //             _appBarTitle = 'Your Cart'.tr();
                          //             _currentWidget = CartScreen(
                          //               fromContainer: true,
                          //             );
                          //           });
                          //         }
                          //       }),
                        ],
              ),
              body: _currentWidget,
            );
          },
        ),
      ),
    );
  }
}
