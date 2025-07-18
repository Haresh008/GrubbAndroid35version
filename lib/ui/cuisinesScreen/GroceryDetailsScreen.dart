// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:foodie_customer/AppGlobal.dart';
// import 'package:foodie_customer/constants.dart';
// import 'package:foodie_customer/model/VendorCategoryModel.dart';
// import 'package:foodie_customer/model/VendorModel.dart';
// import 'package:foodie_customer/services/FirebaseHelper.dart';
// import 'package:foodie_customer/services/helper.dart';
// import 'package:foodie_customer/ui/dineInScreen/dine_in_restaurant_details_screen.dart';
// import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';
//
// import '../../model/mail_setting.dart';
//
// class GroceryDetailsScreen extends StatefulWidget {
//   final VendorCategoryModel category;
//   final bool isDineIn;
//
//   const GroceryDetailsScreen(
//       {Key? key, required this.category, required this.isDineIn})
//       : super(key: key);
//
//   @override
//   _GroceryDetailsScreenState createState() => _GroceryDetailsScreenState();
// }
//
// class _GroceryDetailsScreenState extends State<GroceryDetailsScreen> {
//   Stream<List<VendorModel>>? categoriesFuture;
//   final FireStoreUtils fireStoreUtils = FireStoreUtils();
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
//     categoriesFuture = fireStoreUtils.getVendorsByCuisineID(
//         widget.category.id.toString(),
//         isDinein: widget.isDineIn);
//     initializeFlutterFire();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppGlobal.buildSimpleAppBar(
//             context, widget.category.title.toString()),
//         body: StreamBuilder<List<VendorModel>>(
//           stream: categoriesFuture,
//           initialData: [],
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting)
//               return Container(
//                 child: Center(
//                   child: CircularProgressIndicator.adaptive(
//                     valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
//                   ),
//                 ),
//               );
//             if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
//               return Center(
//                 child: showEmptyState('No Grocery found'.tr(), context),
//               );
//             } else {
//               return ListView.builder(
//                 itemCount: snapshot.data!.length,
//                 itemBuilder: (context, index) =>
//                     buildVendorItem(snapshot.data![index]),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
//
//   buildVendorItem(VendorModel vendorModel) {
//     return vendorModel.commingsoon
//         ? GestureDetector(
//             onTap: () {
//               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                 content: Text(
//                     "Ah! I see you are already excited about the upcoming outlet on the platform. Stay tuned 😉"
//                         .tr()),
//               ));
//             },
//             child: Stack(
//               children: [
//                 ColorFiltered(
//                   colorFilter: ColorFilter.matrix(<double>[
//                     0.2126,
//                     0.7152,
//                     0.0722,
//                     0,
//                     0,
//                     0.2126,
//                     0.7152,
//                     0.0722,
//                     0,
//                     0,
//                     0.2126,
//                     0.7152,
//                     0.0722,
//                     0,
//                     0,
//                     0,
//                     0,
//                     0,
//                     1,
//                     0,
//                   ]),
//                   child: Card(
//                     elevation: 0.5,
//                     color: Color(DARK_GREY_TEXT_COLOR),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.all(
//                         Radius.circular(20),
//                       ),
//                     ),
//                     margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: Container(
//                       height: 200,
//                       child: Column(
//                         children: [
//                           Expanded(
//                             child: CachedNetworkImage(
//                               imageUrl: getImageVAlidUrl(vendorModel.photo),
//                               imageBuilder: (context, imageProvider) =>
//                                   Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(20),
//                                   image: DecorationImage(
//                                       image: imageProvider, fit: BoxFit.cover),
//                                 ),
//                               ),
//                               placeholder: (context, url) => Center(
//                                 child: CircularProgressIndicator.adaptive(
//                                   valueColor: AlwaysStoppedAnimation(
//                                       Color(COLOR_PRIMARY)),
//                                 ),
//                               ),
//                               errorWidget: (context, url, error) => ClipRRect(
//                                 borderRadius: BorderRadius.circular(20),
//                                 child: Image.network(
//                                   AppGlobal.placeHolderImage!,
//                                   fit: BoxFit.fitWidth,
//                                   width: MediaQuery.of(context).size.width,
//                                 ),
//                               ),
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                           ListTile(
//                             title: Text(
//                               vendorModel.title,
//                               maxLines: 1,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Color(0xff666666),
//                                 fontFamily: 'Poppinssb',
//                               ),
//                             ),
//                             subtitle: Text(
//                               vendorModel.location,
//                               maxLines: 1,
//                               style: TextStyle(
//                                   fontFamily: 'Poppinssm',
//                                   color: Color(0xff666666)),
//                             ),
//                             // trailing: Padding(
//                             //   padding: const EdgeInsets.only(top: 8.0),
//                             //   child: Column(
//                             //     mainAxisAlignment: MainAxisAlignment.start,
//                             //     children: [
//                             //       Wrap(
//                             //         spacing: 8,
//                             //         crossAxisAlignment: WrapCrossAlignment.center,
//                             //         children: <Widget>[
//                             //           Icon(
//                             //             Icons.star,
//                             //             size: 20,
//                             //             color:Color(0xff666666),
//                             //           ),
//                             //           Text(
//                             //             (vendorModel.reviewsSum > 0)
//                             //                 ? (vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)
//                             //                 : "",
//                             //             style: TextStyle(
//                             //               fontFamily: 'Poppinssb',color: Color(0xff666666)
//                             //             ),
//                             //           ),
//                             //           Visibility(
//                             //             visible: vendorModel.reviewsCount != 0,
//                             //             child: Text(
//                             //               "(${vendorModel.reviewsCount.toStringAsFixed(1)})",style: TextStyle(color: Color(0xff666666)),
//                             //             ),
//                             //           ),
//                             //         ],
//                             //       ),
//                             //     ],
//                             //   ),
//                             // ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   top: 25,
//                   right: 16,
//                   child: Container(
//                     padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
//                     alignment: Alignment.center,
//                     decoration: BoxDecoration(
//                         color: Colors.red,
//                         borderRadius: BorderRadius.only(
//                             topLeft: Radius.circular(8),
//                             bottomLeft: Radius.circular(8))),
//                     child: Text(
//                       'coming_soon'.tr(),
//                       style: TextStyle(
//                         fontFamily: "Poppinsm",
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         : GestureDetector(
//             onTap: () {
//               if (widget.isDineIn) {
//                 push(
//                   context,
//                   DineInRestaurantDetailsScreen(vendorModel: vendorModel),
//                 );
//               } else {
//                 push(
//                   context,
//                   NewVendorProductsScreen(vendorModel: vendorModel),
//                 );
//               }
//             },
//             child: Card(
//               elevation: 0.5,
//               color: isDarkMode(context) ? Colors.grey.shade900 : Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.all(
//                   Radius.circular(20),
//                 ),
//               ),
//               margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Container(
//                 height: 200,
//
//                 // padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 // margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                 child: Column(
//                   // mainAxisSize: MainAxisSize.max,
//                   // crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Expanded(
//                       child: CachedNetworkImage(
//                         imageUrl: getImageVAlidUrl(vendorModel.photo),
//                         imageBuilder: (context, imageProvider) => Container(
//                           decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(20),
//                               image: DecorationImage(
//                                   image: imageProvider, fit: BoxFit.cover)),
//                         ),
//                         placeholder: (context, url) => Center(
//                             child: CircularProgressIndicator.adaptive(
//                           valueColor:
//                               AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
//                         )),
//                         errorWidget: (context, url, error) => ClipRRect(
//                             borderRadius: BorderRadius.circular(20),
//                             child: Image.network(
//                               AppGlobal.placeHolderImage!,
//                               fit: BoxFit.fitWidth,
//                               width: MediaQuery.of(context).size.width,
//                             )),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                     // SizedBox(height: 8),
//                     ListTile(
//                       title: Text(vendorModel.title,
//                           maxLines: 1,
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: isDarkMode(context)
//                                 ? Colors.grey.shade400
//                                 : Colors.grey.shade800,
//                             fontFamily: 'Poppinssb',
//                           )),
//                       subtitle: Text(vendorModel.location,
//                           maxLines: 1,
//
//                           // filters.keys
//                           //     .where(
//                           //         (element) => vendorModel.filters[element] == 'Yes')
//                           //     .take(2)
//                           //     .join(', '),
//
//                           style: TextStyle(
//                             fontFamily: 'Poppinssm',
//                           )),
//                       trailing: Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           children: [
//                             Wrap(
//                                 spacing: 8,
//                                 crossAxisAlignment: WrapCrossAlignment.center,
//                                 children: <Widget>[
//                                   Icon(
//                                     Icons.star,
//                                     size: 20,
//                                     color: Color(COLOR_PRIMARY),
//                                   ),
//                                   Text(
//                                     (vendorModel.reviewsSum > 0)
//                                         ? (vendorModel.reviewsSum /
//                                                 vendorModel.reviewsCount)
//                                             .toStringAsFixed(1)
//                                         : "",
//                                     style: TextStyle(
//                                       fontFamily: 'Poppinssb',
//                                     ),
//                                   ),
//                                   Visibility(
//                                       visible: vendorModel.reviewsCount != 0,
//                                       child: Text(
//                                           "(${vendorModel.reviewsCount.toStringAsFixed(1)})")),
//                                 ]),
//                           ],
//                         ),
//                       ),
//                     ),
//                     // SizedBox(height: 4),
//
//                     // SizedBox(height: 4),
//                     // Visibility(
//                     //   visible: vendorModel.reviewsCount != 0,
//                     //   child: RichText(
//                     //     text: TextSpan(
//                     //       style: TextStyle(
//                     //           color: isDarkMode(context)
//                     //               ? Colors.grey.shade200
//                     //               : Colors.black),
//                     //       children: [
//                     //         TextSpan(
//                     //             text:
//                     //                 '${double.parse((vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(2))} '),
//                     //         WidgetSpan(
//                     //           child: Icon(
//                     //             Icons.star,
//                     //             size: 20,
//                     //             color: Color(COLOR_PRIMARY),
//                     //           ),
//                     //         ),
//                     //         TextSpan(text: ' (${vendorModel.reviewsCount})'),
//                     //       ],
//                     //     ),
//                     //   ),
//                     // ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//   }
// }
