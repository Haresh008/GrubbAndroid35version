import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/model/ProductModel.dart';
import 'package:foodie_customer/model/Ratingmodel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';

import '../../constants.dart';
import '../../model/mail_setting.dart';

// ignore: must_be_immutable
class Review extends StatefulWidget {
  ProductModel productModel;

  Review({Key? key, required this.productModel}) : super(key: key);

  @override
  _ReviewState createState() => _ReviewState();
}

class _ReviewState extends State<Review> {
  List<RatingModel> reviewList = [];

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
    getReview();
    initializeFlutterFire();
  }

  getReview() async {
    await FireStoreUtils().getReviewList(widget.productModel.id).then((value) {
      setState(() {
        reviewList = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppGlobal.buildSimpleAppBar(
          context,
          'Reviews -('.tr() +
              widget.productModel.reviewsCount.toString() +
              " Reviews)",
        ),
        body: Padding(
          padding: const EdgeInsets.all(4.0),
          child: ListView.builder(
            itemCount: reviewList.length,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      10,
                    ), //border corner radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5), //color of shadow
                        spreadRadius: 3, //spread radius
                        blurRadius: 7, // blur radius
                        offset: const Offset(
                          0,
                          2,
                        ), // changes position of shadow
                        //first paramerter of offset is left-right
                        //second parameter is top to down
                      ),
                      //you can set more BoxShadow() here
                    ],
                  ), // Change this
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              height: 45,
                              width: 45,
                              imageUrl: getImageVAlidUrl(
                                reviewList[index].profile.toString(),
                              ),
                              imageBuilder:
                                  (context, imageProvider) => Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(35),
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
                                    borderRadius: BorderRadius.circular(35),
                                    child: Image.network(
                                      placeholderImage,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reviewList[index].uname.toString(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                      fontSize: 16,
                                    ),
                                  ),
                                  RatingBar.builder(
                                    ignoreGestures: true,
                                    initialRating:
                                        reviewList[index].rating ?? 0.0,
                                    minRating: 1,
                                    itemSize: 22,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemPadding: const EdgeInsets.only(
                                      top: 5.0,
                                    ),
                                    itemBuilder:
                                        (context, _) => Icon(
                                          Icons.star,
                                          color: Color(COLOR_PRIMARY),
                                        ),
                                    onRatingUpdate: (double rate) {
                                      // ratings = rate;
                                      // print(ratings);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              orderDate(reviewList[index].createdAt),
                              style: TextStyle(
                                color:
                                    isDarkMode(context)
                                        ? Colors.grey.shade200
                                        : const Color(0XFF555353),
                                fontFamily: "Poppinsr",
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(thickness: 2),
                        ),
                        Text(
                          reviewList[index].comment.toString(),
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.70),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        reviewList[index].photos!.isNotEmpty
                            ? SizedBox(
                              height: 75,
                              child: ListView.builder(
                                itemCount: reviewList[index].photos!.length,
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index1) {
                                  return Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: CachedNetworkImage(
                                      height: 65,
                                      width: 65,
                                      imageUrl: getImageVAlidUrl(
                                        reviewList[index].photos![index1],
                                      ),
                                      imageBuilder:
                                          (context, imageProvider) => Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                              10,
                                            ),
                                            child: Image.network(
                                              placeholderImage,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  //   getcount(RatingModel ratingModel,length){
  //    var count=0;
  //   if (length<count){
  //      rating = ratingModel.rating +rating;
  //      count++;
  //   }
  //  print(count);
  //     vendor.reviewsCount =length;
  //     vendor.reviewsSum =rating;
  //     // fireStoreUtils.
  //     count == length? FireStoreUtils.updateVendor(vendor):
  //   null;
  //   return Center();
  //     // print(length);
  //     // return Center();
  //   }
}
