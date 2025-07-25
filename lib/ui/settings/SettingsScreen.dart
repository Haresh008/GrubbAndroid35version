import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/cartScreen/CartScreen.dart';
import 'package:foodie_customer/ui/mapView/MapViewScreen.dart';
import 'package:provider/provider.dart';

import '../../model/mail_setting.dart';

class SettingsScreen extends StatefulWidget {
  final User user;

  const SettingsScreen({Key? key, required this.user}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late User user;

  late CartDatabase cartDatabase;

  late bool pushNewMessages, orderUpdates, newArrivals, promotions;
  int cartCount = 0;

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
    user = widget.user;
    pushNewMessages = user.settings.pushNewMessages;
    orderUpdates = user.settings.orderUpdates;
    newArrivals = user.settings.newArrivals;
    promotions = user.settings.promotions;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cartDatabase = Provider.of<CartDatabase>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(
              'settings',
              style: TextStyle(
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
            ).tr(),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.map, color: Color(COLOR_PRIMARY)),
            onPressed: () => push(context, MapViewScreen()),
          ),
          IconButton(
            tooltip: 'Cart'.tr(),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(CupertinoIcons.cart, color: Color(COLOR_PRIMARY)),
                StreamBuilder<List<CartProduct>>(
                  stream: cartDatabase.watchProducts,
                  builder: (context, snapshot) {
                    cartCount = 0;
                    if (snapshot.hasData) {
                      snapshot.data!.forEach((element) {
                        cartCount += element.quantity;
                      });
                    }
                    return Visibility(
                      visible: cartCount >= 1,
                      child: Positioned(
                        right: 0,
                        top: -6,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: new BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Center(
                            child: new Text(
                              cartCount <= 99 ? '$cartCount' : '+99',
                              style: new TextStyle(
                                color: Colors.white,
                                // fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onPressed: () => push(context, CartScreen(fromContainer: false)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Builder(
          builder:
              (buildContext) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 16.0,
                      left: 16,
                      top: 16,
                      bottom: 8,
                    ),
                    child:
                        Text(
                          'Push Notifications',
                          style: TextStyle(
                            color:
                                isDarkMode(context)
                                    ? Colors.white54
                                    : Colors.black54,
                            fontSize: 18,
                          ),
                        ).tr(),
                  ),
                  Material(
                    elevation: 2,
                    color: isDarkMode(context) ? Colors.black12 : Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // SwitchListTile.adaptive(
                        //     activeColor: Color(COLOR_ACCENT),
                        //     title: Text(
                        //       'Allow Push Notifications',
                        //       style: TextStyle(
                        //         fontSize: 16,
                        //         color: isDarkMode(context) ? Colors.white : Colors.black,
                        //       ),
                        //     ).tr(),
                        //     value: pushNewMessages,
                        //     onChanged: (bool newValue) {
                        //       pushNewMessages = newValue;
                        //       setState(() {});
                        //     }),
                        SwitchListTile.adaptive(
                          activeColor: Color(COLOR_ACCENT),
                          title:
                              Text(
                                'Order Updates',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ).tr(),
                          value: orderUpdates,
                          onChanged: (bool newValue) {
                            orderUpdates = newValue;
                            setState(() {});
                          },
                        ),
                        // SwitchListTile.adaptive(
                        //     activeColor: Color(COLOR_ACCENT),
                        //     title: Text(
                        //       'New Arrivals',
                        //       style: TextStyle(
                        //          fontSize: 16,
                        //         color: isDarkMode(context)
                        //             ? Colors.white
                        //             : Colors.black,
                        //       ),
                        //     ).tr(),
                        //     value: newArrivals,
                        //     onChanged: (bool newValue) {
                        //       newArrivals = newValue;
                        //       setState(() {});
                        //     }),
                        SwitchListTile.adaptive(
                          activeColor: Color(COLOR_ACCENT),
                          title:
                              Text(
                                'Promotions',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ).tr(),
                          value: promotions,
                          onChanged: (bool newValue) {
                            promotions = newValue;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0, bottom: 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: double.infinity,
                      ),
                      child: Material(
                        elevation: 2,
                        color:
                            isDarkMode(context) ? Colors.black12 : Colors.white,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(12.0),
                          onPressed: () async {
                            showProgress(
                              context,
                              'Saving changes...'.tr(),
                              true,
                            );
                            user.settings.pushNewMessages = pushNewMessages;
                            user.settings.orderUpdates = orderUpdates;
                            user.settings.newArrivals = newArrivals;
                            user.settings.promotions = promotions;
                            User? updateUser =
                                await FireStoreUtils.updateCurrentUser(user);
                            hideProgress();
                            if (updateUser != null) {
                              this.user = updateUser;
                              MyAppState.currentUser = user;
                              ScaffoldMessenger.of(buildContext).showSnackBar(
                                SnackBar(
                                  duration: Duration(seconds: 3),
                                  content:
                                      Text(
                                        'Settings saved successfully',
                                        style: TextStyle(fontSize: 17),
                                      ).tr(),
                                ),
                              );
                            }
                          },
                          child:
                              Text(
                                'save',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(COLOR_PRIMARY),
                                ),
                              ).tr(),
                          color:
                              isDarkMode(context)
                                  ? Colors.black12
                                  : Colors.white,
                        ),
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
