// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:foodie_customer/AppGlobal.dart';
// import 'package:foodie_customer/constants.dart';
// import 'package:foodie_customer/model/VendorCategoryModel.dart';
// import 'package:foodie_customer/services/FirebaseHelper.dart';
// import 'package:foodie_customer/services/helper.dart';
// import 'package:foodie_customer/ui/Grocery/GroceryDetailsScreen.dart';
//
// import '../../model/mail_setting.dart';
//
// class CuisinesScreen1 extends StatefulWidget {
//   const CuisinesScreen1(
//       {Key? key,
//       this.isPageCallFromHomeScreen = false,
//       this.isPageCallForDineIn = false})
//       : super(key: key);
//
//   @override
//   _CuisinesScreen1State createState() => _CuisinesScreen1State();
//   final bool? isPageCallFromHomeScreen;
//   final bool? isPageCallForDineIn;
// }
//
// class _CuisinesScreen1State extends State<CuisinesScreen1> {
//   final fireStoreUtils = FireStoreUtils();
//   late Future<List<VendorCategoryModel>> categoriesFuture;
//
//   void initializeFlutterFire() async {
//     try {
//       await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
//
//       final FlutterExceptionHandler? originalOnError = FlutterError.onError;
//       FlutterError.onError = (FlutterErrorDetails errorDetails) async {
//         await FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
//         originalOnError!(errorDetails);
//         // Forward to original handler.
//       };
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("globalSettings")
//           .get()
//           .then((dineinresult) {
//         if (dineinresult.exists &&
//             dineinresult.data() != null &&
//             dineinresult.data()!.containsKey("website_color")) {
//           COLOR_PRIMARY = int.parse(
//               dineinresult.data()!["website_color"].replaceFirst("#", "0xff"));
//         }
//       });
//
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("DineinForRestaurant")
//           .get()
//           .then((dineinresult) {
//         if (dineinresult.exists) {
//           isDineInEnable = dineinresult.data()!["isEnabledForCustomer"];
//         }
//       });
//
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("emailSetting")
//           .get()
//           .then((value) {
//         if (value.exists) {
//           mailSettings = MailSettings.fromJson(value.data()!);
//         }
//       });
//
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("home_page_theme")
//           .get()
//           .then((value) {
//         if (value.exists) {
//           homePageThem = value.data()!["theme"];
//         }
//       });
//
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("Version")
//           .get()
//           .then((value) {
//         debugPrint(value.data().toString());
//         appVersion = value.data()!['app_version'].toString();
//       });
//
//       await FirebaseFirestore.instance
//           .collection(Setting)
//           .doc("googleMapKey")
//           .get()
//           .then((value) {
//         print(value.data());
//         GOOGLE_API_KEY = value.data()!['key'].toString();
//       });
//     } catch (e) {
//       debugPrint(e.toString());
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     initializeFlutterFire();
//     categoriesFuture = fireStoreUtils.getCuisines1();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : null,
//         appBar: widget.isPageCallFromHomeScreen!
//             ? AppGlobal1.buildAppBar1(context, "Categories")
//             : null,
//         body: FutureBuilder<List<VendorCategoryModel>>(
//             future: categoriesFuture,
//             initialData: [],
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting)
//                 return Center(
//                   child: CircularProgressIndicator.adaptive(
//                     valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
//                   ),
//                 );
//
//               if (snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) {
//                 return ListView.builder(
//                     padding: EdgeInsets.all(10),
//                     itemCount: snapshot.data!.length,
//                     itemBuilder: (context, index) {
//                       return snapshot.data != null
//                           ? buildCuisineCell(snapshot.data![index])
//                           : showEmptyState('No Categories'.tr(), context,
//                               description: "add-categories".tr());
//                     });
//               }
//               return CircularProgressIndicator();
//             }));
//   }
//
//   Widget buildCuisineCell(VendorCategoryModel cuisineModel) {
//     return Padding(
//         padding: EdgeInsets.only(bottom: 12),
//         child: GestureDetector(
//           onTap: () => push(
//             context,
//             GroceryDetailsScreen(
//               category: cuisineModel,
//               isDineIn: widget.isPageCallForDineIn!,
//             ),
//           ),
//           child: Container(
//             height: 140,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(23),
//               image: DecorationImage(
//                 image: NetworkImage(cuisineModel.photo.toString()),
//                 fit: BoxFit.cover,
//                 colorFilter: ColorFilter.mode(
//                     Colors.black.withOpacity(0.5), BlendMode.darken),
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 cuisineModel.title.toString(),
//                 style: TextStyle(
//                     color: Colors.white, fontFamily: "Poppinsm", fontSize: 27),
//               ).tr(),
//             ),
//           ),
//         ));
//   }
// }
