import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/BookTableModel.dart';
import 'package:foodie_customer/model/Ratingmodel.dart';
import 'package:foodie_customer/model/SpecialDiscountModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/model/offer_model.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/auth/AuthScreen.dart';
import 'package:foodie_customer/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/photos.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/mail_setting.dart';

class DineInRestaurantDetailsScreen extends StatefulWidget {
  final VendorModel vendorModel;

  const DineInRestaurantDetailsScreen({Key? key, required this.vendorModel})
    : super(key: key);

  @override
  State<DineInRestaurantDetailsScreen> createState() =>
      _DineInRestaurantDetailsScreenState();
}

class _DineInRestaurantDetailsScreenState
    extends State<DineInRestaurantDetailsScreen> {
  final fireStoreUtils = FireStoreUtils();

  String? placeHolderImage = "";
  String _selectedOccasion = "";
  bool? isFirstTime = false;
  TextEditingController reqController = TextEditingController(text: '');

  String userDisFName = '',
      userDisLName = '',
      userDisPhone = '',
      userDisEmail = '';

  var position = LatLng(23.12, 70.22);
  late Future<List<RatingModel>> ratingproduct;

  Stream<List<OfferModel>>? lstOfferData;
  var tags = [];
  List occasionList = ["Birthday", "Anniversary"];
  List<DateModel> dateList = [];
  List<TimeModel> timeSlotList = [];
  DateTime startTime = DateTime.now().add(Duration(hours: 9));
  DateTime endTime = DateTime.now().add(Duration(hours: 21));
  String selectedTimeSlot = '6:00 PM';
  String selectedTimeDiscount = '0';
  String selectedTimeDiscountType = '';

  void _getUserLocation() async {
    setState(() {
      position = LatLng(
        MyAppState.selectedPosotion.latitude,
        MyAppState.selectedPosotion.longitude,
      );
    });
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

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    initializeFlutterFire();

    // for (int i = 0; i < 7; i++) {
    //   final now = DateTime.now().add(Duration(days: i));
    //   var day = DateFormat('EEEE').format(now);
    //   if (widget.vendorModel.specialDiscount.isNotEmpty &&
    //       widget.vendorModel.specialDiscountEnable) {
    //     widget.vendorModel.specialDiscount.forEach((element) {
    //       if (day == element.day.toString()) {
    //         if (element.timeslot!.isNotEmpty) {
    //           Timeslot employeeWithMaxSalary = element.timeslot!.reduce(
    //               (item1, item2) => double.parse(item1.discount.toString()) >
    //                       double.parse(item2.discount.toString())
    //                   ? item1
    //                   : item2);
    //           if (employeeWithMaxSalary.discountType == "dinein") {
    //             DateModel model = new DateModel(
    //                 date: Timestamp.fromDate(now),
    //                 discountPer: employeeWithMaxSalary.discount.toString());
    //             dateList.add(model);
    //           } else {
    //             DateModel model = new DateModel(
    //                 date: Timestamp.fromDate(now), discountPer: "0");
    //             dateList.add(model);
    //           }
    //         } else {
    //           DateModel model = new DateModel(
    //               date: Timestamp.fromDate(now), discountPer: "0");
    //           dateList.add(model);
    //         }
    //       }
    //     });
    //   } else {
    //     DateModel model =
    //         new DateModel(date: Timestamp.fromDate(now), discountPer: "0");
    //     dateList.add(model);
    //   }
    // }
    for (int i = 0; i < 7; i++) {
      final now = DateTime.now().add(Duration(days: i));
      var day = DateFormat('EEEE').format(now);
      print("Processing day: $day");

      if (widget.vendorModel.specialDiscount.isNotEmpty &&
          widget.vendorModel.specialDiscountEnable) {
        widget.vendorModel.specialDiscount.forEach((element) {
          print("Checking element for day: ${element.day}");
          if (day == element.day.toString()) {
            print(
              "Matched day: $day with special discount day: ${element.day}",
            );
            if (element.timeslot!.isNotEmpty) {
              Timeslot employeeWithMaxSalary = element.timeslot!.reduce(
                (item1, item2) =>
                    double.parse(item1.discount.toString()) >
                            double.parse(item2.discount.toString())
                        ? item1
                        : item2,
              );
              print(
                "Max discount: ${employeeWithMaxSalary.discount}, type: ${employeeWithMaxSalary.discountType}",
              );
              if (employeeWithMaxSalary.discountType == "dinein") {
                DateModel model = new DateModel(
                  date: Timestamp.fromDate(now),
                  discountPer: employeeWithMaxSalary.discount.toString(),
                );
                dateList.add(model);
              } else {
                DateModel model = new DateModel(
                  date: Timestamp.fromDate(now),
                  discountPer: "0",
                );
                dateList.add(model);
              }
            } else {
              print("No timeslot available for day: $day");
              DateModel model = new DateModel(
                date: Timestamp.fromDate(now),
                discountPer: "0",
              );
              dateList.add(model);
            }
          }
        });
      } else {
        print("No special discount or specialDiscountEnable is false.");
        DateModel model = new DateModel(
          date: Timestamp.fromDate(now),
          discountPer: "0",
        );
        dateList.add(model);
      }
    }

    selectedDate = dateList.first.date;

    if (widget.vendorModel.openDineTime.isNotEmpty) {
      startTime =
          startTime = stringToDate(
            widget.vendorModel.openDineTime,
          ); // Default value if null

      print(
        "widget.vendorModel.openDineTimewidget.vendorModel.openDineTime${widget.vendorModel.openDineTime}",
      );
    }

    if (widget.vendorModel.closeDineTime.isNotEmpty) {
      endTime =
          endTime = stringToDate(
            widget.vendorModel.closeDineTime,
          ); // Default value if null

      print(
        "widget.vendorModel.closeDineTime${widget.vendorModel.closeDineTime}",
      );
    }

    timeSet(selectedDate!);
    if (timeSlotList.isNotEmpty) {
      selectedTimeSlot = DateFormat('hh:mm a').format(timeSlotList[0].time!);
    }

    ratingproduct = fireStoreUtils.getReviewsbyVendorID(widget.vendorModel.id);
    fireStoreUtils.getVendorCusions(widget.vendorModel.id).then((value) {
      tags.addAll(value);
      setState(() {});
    });
    if (MyAppState.currentUser != null) {
      userDisFName = MyAppState.currentUser!.firstName;
      userDisLName = MyAppState.currentUser!.lastName;
      userDisEmail = MyAppState.currentUser!.email;
      userDisPhone = MyAppState.currentUser!.phoneNumber;
    }
  }

  //   timeSet(Timestamp selectedDate) {
  //     timeSlotList.clear();
  // print("qaq call tha che ho");
  //     for (DateTime time = startTime;
  //         time.isBefore(endTime);
  //         time = time.add(Duration(minutes: 30))) {
  //       final now = DateTime.parse(selectedDate.toDate().toString());
  //       var day = DateFormat('EEEE').format(now);
  //       var date = DateFormat('dd-MM-yyyy').format(now);
  //       if (widget.vendorModel.specialDiscount.isNotEmpty &&
  //           widget.vendorModel.specialDiscountEnable) {
  //         widget.vendorModel.specialDiscount.forEach((element) {
  //           if (day == element.day.toString()) {
  //             if (element.timeslot!.isNotEmpty) {
  //               element.timeslot!.forEach((element) {
  //                 if (element.discountType == "dinein") {
  //                   var start = DateFormat("dd-MM-yyyy HH:mm a")
  //                       .parse(date + " " + element.from.toString());
  //                   var end = DateFormat("dd-MM-yyyy HH:mm a")
  //                       .parse(date + " " + element.to.toString());
  //                   var selected = DateFormat("dd-MM-yyyy HH:mm a")
  //                       .parse(date + " " + DateFormat.Hm().format(time));
  //
  //                   if (isCurrentDateInRange(start, end, selected)) {
  //                     var contains =
  //                         timeSlotList.where((element) => element.time == time);
  //                     if (contains.isNotEmpty) {
  //                       var index = timeSlotList
  //                           .indexWhere((element) => element.time == time);
  //                       if (timeSlotList[index].discountPer == "0") {
  //                         timeSlotList.removeAt(index);
  //                         TimeModel model = new TimeModel(
  //                             time: time,
  //                             discountPer: element.discount,
  //                             discountType: element.type);
  //                         timeSlotList.insert(index == 0 ? 0 : index, model);
  //                       }
  //                     } else {
  //                       TimeModel model = new TimeModel(
  //                           time: time,
  //                           discountPer: element.discount,
  //                           discountType: element.type);
  //                       timeSlotList.add(model);
  //                     }
  //                   } else {
  //                     var contains =
  //                         timeSlotList.where((element) => element.time == time);
  //                     if (contains.isEmpty) {
  //                       TimeModel model = new TimeModel(
  //                           time: time, discountPer: "0", discountType: "amount");
  //                       timeSlotList.add(model);
  //                     }
  //                   }
  //                 }
  //               });
  //             } else {
  //               TimeModel model = new TimeModel(
  //                   time: time, discountPer: "0", discountType: "amount");
  //               timeSlotList.add(model);
  //             }
  //           }
  //         });
  //       } else {
  //         TimeModel model =
  //             new TimeModel(time: time, discountPer: "0", discountType: "amount");
  //         timeSlotList.add(model);
  //       }
  //     }
  //   }

  void timeSet(Timestamp selectedDate) {
    timeSlotList.clear();

    // Parse the start and end times from the vendor model
    startTime = stringToDate(
      widget.vendorModel.openDineTime,
    ); // Default value if null
    endTime = stringToDate(
      widget.vendorModel.closeDineTime,
    ); // Default value if null

    print(
      "Function timeSet called with selectedDate: ${selectedDate.toDate()}",
    );
    print("Start Time: $startTime, End Time: $endTime");

    // Check if start and end times are valid
    if (startTime == null || endTime == null) {
      print("Error: One of the times is null.");
      return;
    }

    // Check if start time is before end time
    if (startTime.isAfter(endTime)) {
      print("Error: StartTime is after EndTime.");
      return;
    }

    for (
      DateTime time = startTime;
      time.isBefore(endTime);
      time = time.add(Duration(minutes: 30))
    ) {
      print("Loop Time: $time");
      final now = selectedDate.toDate();
      var day = DateFormat('EEEE').format(now);
      var date = DateFormat('dd-MM-yyyy').format(now);

      print("Day: $day, Date: $date");

      if (widget.vendorModel.specialDiscount.isNotEmpty &&
          widget.vendorModel.specialDiscountEnable) {
        print("Special Discount Enabled for Vendor");

        widget.vendorModel.specialDiscount.forEach((element) {
          print("Discount Element: $element");

          if (day == element.day.toString()) {
            print("Matching Day Found: $day");

            if (element.timeslot!.isNotEmpty) {
              element.timeslot!.forEach((timeslot) {
                print("Timeslot Element: $timeslot");

                if (timeslot.discountType == "dinein") {
                  print("Processing Dine-in Discount");

                  var start = DateFormat(
                    "dd-MM-yyyy hh:mm a",
                  ).parse("$date ${timeslot.from}");
                  var end = DateFormat(
                    "dd-MM-yyyy hh:mm a",
                  ).parse("$date ${timeslot.to}");
                  var selected = DateFormat(
                    "dd-MM-yyyy hh:mm a",
                  ).parse("$date ${DateFormat('hh:mm a').format(time)}");

                  print(
                    "Start Time: $start, End Time: $end, Selected: $selected",
                  );

                  if (isCurrentDateInRange(start, end, selected)) {
                    print("Time is within range");
                    var contains = timeSlotList.where((e) => e.time == time);

                    if (contains.isNotEmpty) {
                      print("Existing Timeslot Found");

                      var index = timeSlotList.indexWhere(
                        (e) => e.time == time,
                      );

                      if (timeSlotList[index].discountPer == "0") {
                        print("Updating Existing Timeslot at Index: $index");
                        timeSlotList.removeAt(index);

                        TimeModel model = TimeModel(
                          time: time,
                          discountPer: timeslot.discount,
                          discountType: timeslot.type,
                        );

                        timeSlotList.insert(index, model);
                      }
                    } else {
                      print("Adding New Timeslot with Discount");
                      TimeModel model = TimeModel(
                        time: time,
                        discountPer: timeslot.discount,
                        discountType: timeslot.type,
                      );
                      timeSlotList.add(model);
                    }
                  } else {
                    print("Time is outside range");

                    var contains = timeSlotList.where((e) => e.time == time);

                    if (contains.isEmpty) {
                      print("Adding New Timeslot without Discount");
                      TimeModel model = TimeModel(
                        time: time,
                        discountPer: "0",
                        discountType: "amount",
                      );
                      timeSlotList.add(model);
                    }
                  }
                }
              });
            } else {
              print("No Timeslots Found for Discount");
              TimeModel model = TimeModel(
                time: time,
                discountPer: "0",
                discountType: "amount",
              );
              timeSlotList.add(model);
            }
          }
        });
      } else {
        print("Special Discount Not Enabled or Empty");

        TimeModel model = TimeModel(
          time: time,
          discountPer: "0",
          discountType: "amount",
        );
        timeSlotList.add(model);
      }
    }

    // Print Final Timeslot List
    print("Final Timeslot List:");
    timeSlotList.forEach((slot) {
      print(
        "Time: ${slot.time}, Discount: ${slot.discountPer}, Type: ${slot.discountType}",
      );
    });
  }

  // Helper function to check if selected time is within range
  bool isCurrentDateInRange(DateTime start, DateTime end, DateTime selected) {
    print("Checking Range: Start=$start, End=$end, Selected=$selected");
    return selected.isAfter(start) && selected.isBefore(end);
  }

  // bool isCurrentDateInRange(
  //     DateTime startDate, DateTime endDate, DateTime selected) {
  //   return selected.isAtSameMomentAs(startDate) ||
  //       selected.isAtSameMomentAs(endDate) ||
  //       selected.isAfter(startDate) && selected.isBefore(endDate);
  // }

  @override
  Widget build(BuildContext context) {
    double distanceInMeters = Geolocator.distanceBetween(
      widget.vendorModel.latitude,
      widget.vendorModel.longitude,
      position.latitude,
      position.longitude,
    );
    double kilometer = distanceInMeters / 1000;
    double minutes = 1.2;
    double value = minutes * kilometer;
    final int hour = value ~/ 60;
    final double minute = value % 60;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: isDarkMode(context) ? Color(DARK_COLOR) : Color(0xffFFFFFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.3,
                    decoration: BoxDecoration(
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color:
                              isDarkMode(context)
                                  ? Colors.black38
                                  : Colors.white38,
                          blurRadius: 25.0,
                          offset: Offset(0.0, 0.75),
                        ),
                      ],
                    ),
                    width: MediaQuery.of(context).size.width * 1,
                    child: CachedNetworkImage(
                      imageUrl: getImageVAlidUrl(widget.vendorModel.photo),
                      imageBuilder:
                          (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(0),
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
                          (context, url, error) => Image.network(
                            placeHolderImage!,
                            fit: BoxFit.fitWidth,
                          ),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    top: MediaQuery.of(context).size.height * 0.033,
                    start: MediaQuery.of(context).size.width * 0.03,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 20,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    bottom: MediaQuery.of(context).size.height * 0.009,
                    end: MediaQuery.of(context).size.width * 0.03,
                    child: IconButton(
                      icon: Image(
                        image: AssetImage("assets/images/img.png"),
                        height: 35,
                      ),
                      onPressed: () {
                        push(
                          context,
                          RestaurantPhotos(vendorModel: widget.vendorModel),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Text(
                            widget.vendorModel.title,
                            maxLines: 2,
                            style: TextStyle(
                              fontFamily: "Poppinsm",
                              fontSize: 18,
                              letterSpacing: 0.5,
                              color:
                                  isDarkMode(context)
                                      ? Color(0xffFFFFFF)
                                      : Color(0xff2A2A2A),
                            ),
                          ),
                        ),
                        resttiming(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      top: 3.0,
                      right: 10,
                    ),
                    child: Row(
                      children: [
                        ImageIcon(
                          AssetImage('assets/images/location3x.png'),
                          size: 18,
                          color: Color(0xff9091A4),
                        ),
                        SizedBox(width: 5),
                        Container(
                          constraints: BoxConstraints(maxWidth: 230),
                          child: Text(
                            widget.vendorModel.location,
                            maxLines: 2,
                            style: TextStyle(
                              fontFamily: "Poppinsr",
                              letterSpacing: 0.5,
                              color: Color(0xFF9091A4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20.0,
                      left: 10,
                      right: 10,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
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
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                            blurRadius: 3.0,
                            spreadRadius: 0.6,
                            offset: Offset(0.1, 0.5),
                          ),
                        ],
                        color:
                            isDarkMode(context)
                                ? Color(DARK_CARD_BG_COLOR)
                                : Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Image(
                                  image: AssetImage(
                                    "assets/images/location.png",
                                  ),
                                  height: 25,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "${kilometer.toDouble().toStringAsFixed(2)} km",
                                  style: TextStyle(
                                    fontFamily: "Poppinssr",
                                    letterSpacing: 0.5,
                                    color:
                                        isDarkMode(context)
                                            ? Colors.white60
                                            : Color(0xff565764),
                                  ),
                                ).tr(),
                              ],
                            ),
                            Column(
                              children: [
                                Image(
                                  image: AssetImage("assets/images/price.png"),
                                  height: 25,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  widget.vendorModel.restaurantCost == 0
                                      ? ""
                                      : '${amountShow(amount: widget.vendorModel.restaurantCost.toString())} for two',
                                  // "${minute.toDouble()} min",
                                  style: TextStyle(
                                    fontFamily: "Poppinssm",
                                    letterSpacing: 0.5,
                                    color:
                                        isDarkMode(context)
                                            ? Colors.white60
                                            : Color(0xff565764),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Image(
                                  image: AssetImage("assets/images/rate.png"),
                                  height: 25,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  widget.vendorModel.reviewsCount == 0
                                      ? '0' + " " + 'Rate'.tr()
                                      : ' ${double.parse((widget.vendorModel.reviewsSum / widget.vendorModel.reviewsCount).toStringAsFixed(1))}' +
                                          ' Rate'.tr(),
                                  style: TextStyle(
                                    fontFamily: "Poppinssr",
                                    letterSpacing: 0.5,
                                    color:
                                        isDarkMode(context)
                                            ? Colors.white60
                                            : Color(0xff565764),
                                  ),
                                ).tr(),
                              ],
                            ),
                            // InkWell(
                            //     onTap: () async {
                            //       Share.share("${widget.vendorModel.title}\n${widget.vendorModel.location}\n\n${widget.vendorModel.photo}");
                            //     },
                            //     child: Column(children: [
                            //       Image(
                            //         image: AssetImage("assets/images/share.png"),
                            //         height: 25,
                            //       ),
                            //       SizedBox(
                            //         height: 10,
                            //       ),
                            //       Text(
                            //         "Share".tr(),
                            //         style: TextStyle(fontFamily: "Poppinssr", letterSpacing: 0.5, color: isDarkMode(context) ? Colors.white60 : Color(0xff565764)),
                            //       ).tr()
                            //     ])),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      FutureBuilder<List<RatingModel>>(
                        future: ratingproduct,
                        builder: (BuildContext context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return Center(
                              child: CircularProgressIndicator.adaptive(
                                valueColor: AlwaysStoppedAnimation(
                                  Color(COLOR_PRIMARY),
                                ),
                              ),
                            );
                          if (snapshot.hasData) {
                            return InkWell(
                              // onTap: () => push(
                              //   context,
                              //   Review(
                              //     vendorModel: widget.vendorModel,
                              //     reviewlength: snapshot.data!.length.toString(),
                              //   ),
                              // ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
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
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300,
                                      blurRadius: 3.0,
                                      spreadRadius: 0.6,
                                      offset: Offset(0.1, 0.5),
                                    ),
                                  ],
                                  color:
                                      isDarkMode(context)
                                          ? Color(DARK_CARD_BG_COLOR)
                                          : Colors.white,
                                ),
                                width: MediaQuery.of(context).size.width / 2.3,
                                margin: EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      snapshot.data!.length.toString() +
                                          " " +
                                          "reviews".tr(),
                                      style: TextStyle(
                                        fontFamily: "Poppinsr",
                                        letterSpacing: 0.5,
                                        color:
                                            isDarkMode(context)
                                                ? Colors.white60
                                                : Color(0XFF676771),
                                      ),
                                    ),
                                    Image(
                                      image: AssetImage(
                                        "assets/images/review.png",
                                      ),
                                      width: 20,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else
                            return CircularProgressIndicator();
                        },
                      ),
                      InkWell(
                        onTap:
                            () => showModalBottomSheet(
                              isScrollControlled: true,
                              isDismissible: true,
                              context: context,
                              backgroundColor: Colors.transparent,
                              enableDrag: true,
                              builder:
                                  (context) => ServicesScreen(
                                    vendorModel: widget.vendorModel,
                                  ),
                            ),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2.3,
                          margin: EdgeInsets.only(top: 10),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
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
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                blurRadius: 3.0,
                                spreadRadius: 0.6,
                                offset: Offset(0.1, 0.5),
                              ),
                            ],
                            color:
                                isDarkMode(context)
                                    ? Color(DARK_CARD_BG_COLOR)
                                    : Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                child:
                                    Text(
                                      "Services",
                                      style: TextStyle(
                                        fontFamily: "Poppinsr",
                                        letterSpacing: 0.5,
                                        color:
                                            isDarkMode(context)
                                                ? Colors.white60
                                                : Color(0XFF676771),
                                      ),
                                    ).tr(),
                              ),
                              Container(
                                child: Image(
                                  image: AssetImage(
                                    "assets/images/services.png",
                                  ),
                                  height: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Card(
                    elevation: 2,
                    color:
                        isDarkMode(context)
                            ? Color(DARK_CARD_BG_COLOR)
                            : Color(0XFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.black12, width: 1),
                    ),
                    margin: EdgeInsets.only(
                      left: 15,
                      right: 15,
                      bottom: 10,
                      top: 15,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 15,
                        right: 15,
                        bottom: 10,
                      ),
                      child: Row(
                        children: [
                          Image(
                            image: AssetImage(
                              "assets/images/food_delivery.png",
                            ),
                            height: 32,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 15,
                                right: 15,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Available food delivery",
                                    style: TextStyle(
                                      fontFamily: "Poppinsr",
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ).tr(),
                                  Text(
                                    "In ${hour.toString().padLeft(2, "0")}h ${minute.toStringAsFixed(0).padLeft(2, "0")}" +
                                        "minute".tr(),
                                    style: TextStyle(fontFamily: "Poppinsr"),
                                  ).tr(),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              push(
                                context,
                                NewVendorProductsScreen(
                                  vendorModel: widget.vendorModel,
                                ),
                              );
                            },
                            child: new Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                padding: EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    width: 1,
                                    color:
                                        isDarkMode(context)
                                            ? Color(COLOR_PRIMARY)
                                            : Colors.black54,
                                  ),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_right,
                                  color:
                                      isDarkMode(context)
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    color:
                        isDarkMode(context)
                            ? Color(DARK_CARD_BG_COLOR)
                            : Color(0XFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.black12, width: 1),
                    ),
                    margin: EdgeInsets.only(left: 15, right: 15),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 15,
                        right: 15,
                        bottom: 10,
                      ),
                      child: Row(
                        children: [
                          Image(
                            image: AssetImage("assets/images/book_table.png"),
                            height: 32,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 15,
                                right: 15,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Book a Table",
                                    style: TextStyle(
                                      fontFamily: "Poppinsr",
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ).tr(),
                                  Text(
                                    "Get instant Confirmation",
                                    style: TextStyle(
                                      fontFamily: "Poppinsr",
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ).tr(),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (MyAppState.currentUser == null) {
                                push(context, AuthScreen());
                              } else {
                                bookTableSheet();
                              }
                            },
                            child: new Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                padding: EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    width: 1,
                                    color:
                                        isDarkMode(context)
                                            ? Color(COLOR_PRIMARY)
                                            : Colors.black54,
                                  ),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_right,
                                  color:
                                      isDarkMode(context)
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Menus".tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Poppinsm",
                                ),
                              ),
                              widget.vendorModel.restaurantMenuPhotos.length ==
                                      0
                                  ? Container()
                                  : GestureDetector(
                                    onTap: () {
                                      push(
                                        context,
                                        RestaurantMenuPhoto(
                                          restaurantMenuPhotos:
                                              widget
                                                  .vendorModel
                                                  .restaurantMenuPhotos,
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
                        ),
                        widget.vendorModel.restaurantMenuPhotos.length == 0
                            ? showEmptyState('No Menu Photos'.tr(), context)
                            : Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.12,
                                child: ListView.builder(
                                  itemCount:
                                      widget
                                          .vendorModel
                                          .restaurantMenuPhotos
                                          .length,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      onTap: () {
                                        push(
                                          context,
                                          FullScreenImageViewer(
                                            imageUrl:
                                                widget
                                                    .vendorModel
                                                    .restaurantMenuPhotos[index],
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              new BorderRadius.circular(10),
                                          child: CachedNetworkImage(
                                            height: 80,
                                            width: 80,
                                            imageUrl: getImageVAlidUrl(
                                              widget
                                                  .vendorModel
                                                  .restaurantMenuPhotos[index],
                                            ),
                                            imageBuilder:
                                                (
                                                  context,
                                                  imageProvider,
                                                ) => Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
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
                                                  child: CircularProgressIndicator.adaptive(
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                          Color(COLOR_PRIMARY),
                                                        ),
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      child: Image.network(
                                                        placeHolderImage!,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      left: 10,
                      right: 10,
                    ),
                    child: Divider(color: Colors.black26),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 15, left: 15, right: 15),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image(
                              image: AssetImage("assets/images/time.png"),
                              height: 24,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 15,
                                right: 15,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Timings",
                                    style: TextStyle(
                                      fontFamily: "Poppinsr",
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ).tr(),
                                  Text(
                                    "${widget.vendorModel.openDineTime == '' ? "10:00 AM" : widget.vendorModel.openDineTime.toString()} " +
                                        "To".tr() +
                                        " ${widget.vendorModel.closeDineTime == '' ? "10:00 PM" : widget.vendorModel.closeDineTime.toString()}",
                                    style: TextStyle(fontFamily: "Poppinsr"),
                                  ).tr(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image(
                                image: AssetImage("assets/images/price.png"),
                                height: 24,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 15,
                                  right: 15,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Cost",
                                      style: TextStyle(
                                        fontFamily: "Poppinsr",
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ).tr(),
                                    Text(
                                      widget.vendorModel.restaurantCost == 0
                                          ? "Approx cost is not added".tr()
                                          : "Cost for two".tr() +
                                              " - ${amountShow(amount: widget.vendorModel.restaurantCost.toString())} " +
                                              "(Approx)".tr(),
                                      style: TextStyle(fontFamily: "Poppinssm"),
                                    ).tr(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image(
                                image: AssetImage("assets/images/location.png"),
                                height: 24,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 15,
                                    right: 15,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Location",
                                        style: TextStyle(
                                          fontFamily: "Poppinsr",
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ).tr(),
                                      Text(
                                        widget.vendorModel.location,
                                        style: TextStyle(
                                          fontFamily: "Poppinsr",
                                        ),
                                      ).tr(),
                                    ],
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  launchUrl(
                                    createCoordinatesUrl(
                                      widget.vendorModel.latitude,
                                      widget.vendorModel.longitude,
                                      widget.vendorModel.title,
                                    ),
                                  );
                                },
                                child:
                                    Text(
                                      "Direction",
                                      style: TextStyle(
                                        fontFamily: "Poppinsr",
                                        color: Color(COLOR_PRIMARY),
                                      ),
                                    ).tr(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      left: 10,
                      right: 10,
                    ),
                    child: Divider(color: Colors.black26),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Cuisines".tr(),
                                style: TextStyle(
                                  color:
                                      isDarkMode(context)
                                          ? Colors.white
                                          : Color(0xFF000000),
                                  fontSize: 16,
                                  fontFamily: "Poppinsm",
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 10,
                            left: 8,
                            right: 8,
                          ),
                          child: Wrap(
                            spacing: 5.0,
                            runSpacing: 3.0,
                            children: <Widget>[
                              ...tags
                                  .map(
                                    (tag) => FilterChip(
                                      labelStyle: TextStyle(
                                        color: Color(COLOR_PRIMARY),
                                      ),
                                      label: Text("$tag".tr()),
                                      onSelected: (bool value) {},
                                    ),
                                  )
                                  .toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  resttiming() {
    if (widget.vendorModel.reststatus == true) {
      return Container(
        height: 35,
        decoration: BoxDecoration(
          color:
              isDarkMode(context)
                  ? Color(DARK_CARD_BG_COLOR)
                  : Color(0XFFF1F4F7),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          ),
        ),
        padding: EdgeInsets.only(right: 36, left: 10),
        child: Row(
          children: [
            Icon(Icons.circle, color: Color(0XFF3dae7d), size: 13),
            SizedBox(width: 10),
            Text(
              "Open".tr(),
              style: TextStyle(
                fontFamily: "Poppinssm",
                fontSize: 16,
                color: Color(0XFF3dae7d),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 35,
        decoration: BoxDecoration(
          color: Color(0XFFF1F4F7),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          ),
        ),
        padding: EdgeInsets.only(right: 40, left: 10),
        child: Row(
          children: [
            Icon(Icons.circle, color: Colors.redAccent, size: 13),
            SizedBox(width: 10),
            Text(
              "Close".tr(),
              style: TextStyle(
                fontFamily: "Poppinssm",
                fontSize: 16,
                letterSpacing: 0.5,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      );
    }
  }

  buildOfferItem() {
    return Container(
      margin: EdgeInsets.fromLTRB(7, 10, 7, 10),
      height: 85,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: Radius.circular(2),
        padding: EdgeInsets.all(2),
        color: Color(COUPON_DASH_COLOR),
        strokeWidth: 2,
        dashPattern: [5],
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Container(
            decoration: new BoxDecoration(
              borderRadius: new BorderRadius.circular(2),
            ),
            margin: EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image(
                      image: AssetImage('assets/images/offer_icon.png'),
                      height: 25,
                      width: 25,
                    ),
                    SizedBox(width: 10),
                    Container(
                      margin: EdgeInsets.only(top: 3),
                      child: Text(
                        "${"Fix Price" == "Fix Price" ? "${currencyModel!.symbol}" : ""}${100} ${"Percentage" == "Percentage" ? "% OFF".tr() : "OFF".tr()}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "USE100",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 15, right: 15, top: 3),
                      height: 15,
                      width: 1,
                      color: Color(COUPON_DASH_COLOR),
                    ),
                    Text(
                      "valid till".tr() + " Nov 31,2022",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bookTableSheet() {
    final size = MediaQuery.of(context).size;
    return showModalBottomSheet(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      context: context,
      constraints: BoxConstraints(maxHeight: size.height * 0.8),
      isScrollControlled: true,
      builder: (context) {
        return Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Text(
                          "Book A Table".tr(),
                          style: TextStyle(
                            fontFamily: "Poppinssb",
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Card(
                          elevation: 0,
                          color:
                              isDarkMode(context)
                                  ? Color(DARK_VIEWBG_COLOR)
                                  : Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.vendorModel.title,
                                  style: TextStyle(
                                    fontFamily: "Poppinssb",
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Opacity(
                                  opacity: 0.7,
                                  child: Text(
                                    widget.vendorModel.location,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: "Poppinsm",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 10.0,
                                top: 8,
                                right: 10,
                              ),
                              child: Text(
                                'Select Day'.tr(),
                                style: TextStyle(fontFamily: "Poppinsm"),
                              ),
                            ),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                physics: BouncingScrollPhysics(),
                                itemCount: dateList.length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  bool isSelected =
                                      selectedDate == dateList[index].date
                                          ? true
                                          : false;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0,
                                      vertical: 8,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedDate = dateList[index].date;
                                          timeSet(dateList[index].date);
                                        });
                                      },
                                      child: Card(
                                        elevation: 5,
                                        color:
                                            isSelected
                                                ? Color(COLOR_PRIMARY)
                                                : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: SizedBox(
                                          width: 120,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Text(
                                                  calculateDifference(
                                                            dateList[index].date
                                                                .toDate(),
                                                          ) ==
                                                          0
                                                      ? "Today".tr()
                                                      : calculateDifference(
                                                            dateList[index].date
                                                                .toDate(),
                                                          ) ==
                                                          1
                                                      ? "Tomorrow".tr()
                                                      : DateFormat(
                                                        'EEE',
                                                      ).format(
                                                        dateList[index].date
                                                            .toDate(),
                                                      ),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.black38,
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat('d MMM')
                                                      .format(
                                                        dateList[index].date
                                                            .toDate(),
                                                      )
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontFamily: "Poppinssb",
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.black54,
                                                  ),
                                                ),
                                                Text(
                                                  dateList[index].discountPer +
                                                      "%",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontFamily: "Poppinssb",
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 10.0,
                                top: 8,
                                right: 10,
                              ),
                              child: Text(
                                'How Many People?'.tr(),
                                style: TextStyle(fontFamily: "Poppinsm"),
                              ),
                            ),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                physics: BouncingScrollPhysics(),
                                itemCount: noOfPeople.length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  bool isSelected =
                                      selectedPeople == noOfPeople[index]
                                          ? true
                                          : false;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0,
                                      vertical: 8,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedPeople = noOfPeople[index];
                                        });
                                      },
                                      child: Card(
                                        elevation: 5,
                                        color:
                                            isSelected
                                                ? Color(COLOR_PRIMARY)
                                                : isDarkMode(context)
                                                ? Colors.black38
                                                : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: SizedBox(
                                          height: 50,
                                          width: 70,
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                noOfPeople[index],
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: "Poppinsm",
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : isDarkMode(context)
                                                          ? Colors.white54
                                                          : Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 10.0,
                                top: 8,
                                right: 10,
                              ),
                              child: Text(
                                'What Time?'.tr(),
                                style: TextStyle(fontFamily: "Poppinsm"),
                              ),
                            ),
                            SizedBox(
                              height: 84,
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                physics: BouncingScrollPhysics(),
                                itemCount: timeSlotList.length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  log(
                                    "timeSlotList.lengthtimeSlotList.length${timeSlotList.length}",
                                  );

                                  bool isSelected =
                                      selectedTimeSlot ==
                                              DateFormat('hh:mm a').format(
                                                timeSlotList[index].time!,
                                              )
                                          ? true
                                          : false;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0,
                                      vertical: 5,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedTimeSlot = DateFormat(
                                            'hh:mm a',
                                          ).format(timeSlotList[index].time!);
                                          selectedTimeDiscount =
                                              timeSlotList[index].discountPer!;
                                          selectedTimeDiscountType =
                                              timeSlotList[index].discountType!;
                                        });
                                      },
                                      child: Card(
                                        elevation: 5,
                                        color:
                                            isSelected
                                                ? Color(COLOR_PRIMARY)
                                                : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: SizedBox(
                                          width: 90,
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    DateFormat(
                                                      'hh:mm a',
                                                    ).format(
                                                      timeSlotList[index].time!,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                              : Colors.black54,
                                                    ),
                                                  ),
                                                  timeSlotList[index]
                                                              .discountType ==
                                                          "amount"
                                                      ? Text(
                                                        amountShow(
                                                          amount:
                                                              timeSlotList[index]
                                                                  .discountPer!,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                              isSelected
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black54,
                                                        ),
                                                      )
                                                      : Text(
                                                        timeSlotList[index]
                                                                .discountPer! +
                                                            "%",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                              isSelected
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black54,
                                                        ),
                                                      ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Card(
                          color:
                              isDarkMode(context)
                                  ? Colors.black38
                                  : Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4.0,
                                      ),
                                      child: Text(
                                        "Personal Details".tr(),
                                        style: TextStyle(
                                          fontFamily: "Poppinssb",
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Opacity(
                                      opacity: 0.7,
                                      child: Text(
                                        "$userDisFName $userDisLName",
                                        style: TextStyle(
                                          fontFamily: "Poppinsr",
                                        ),
                                      ),
                                    ),
                                    Opacity(
                                      opacity: 0.7,
                                      child: Text(
                                        "$userDisPhone",
                                        style: TextStyle(
                                          fontFamily: "Poppinsr",
                                        ),
                                      ),
                                    ),
                                    Opacity(
                                      opacity: 0.7,
                                      child: Text(
                                        "$userDisEmail",
                                        style: TextStyle(
                                          fontFamily: "Poppinsr",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () {
                                    showCustomDialog(
                                      context,
                                      userDisFName,
                                      userDisLName,
                                      userDisPhone,
                                      userDisEmail,
                                      () {
                                        setState(() {});
                                      },
                                    );
                                  },
                                  child: Text(
                                    "CHANGE".tr(),
                                    style: TextStyle(
                                      color: Color(COLOR_PRIMARY),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          top: 8,
                          right: 10,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          child: Text(
                            'Special Occasion'.tr(),
                            style: TextStyle(fontFamily: "Poppinsm"),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                      Column(
                        children: <Widget>[
                          for (int i = 0; i < occasionList.length; i++)
                            ListTile(
                              title: Text(
                                '${occasionList[i]}'.tr(),
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color:
                                      i == 5
                                          ? isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black38
                                          : isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ),
                              leading: Radio<String>(
                                value: occasionList[i],
                                groupValue: _selectedOccasion,
                                activeColor: Color(COLOR_PRIMARY),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedOccasion = occasionList[i];
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0, right: 8),
                        child: CheckboxListTile(
                          title: Text("Is this your first visit?".tr()),
                          value: isFirstTime,
                          onChanged: (newValue) {
                            setState(() {
                              isFirstTime = newValue;
                            });
                          },
                          controlAffinity:
                              ListTileControlAffinity
                                  .leading, //  <-- leading Checkbox
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          top: 8,
                          right: 10,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          child: Text(
                            'Additional Requests'.tr(),
                            style: TextStyle(fontFamily: "Poppinsm"),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          top: 8,
                          right: 10,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          child: Container(
                            padding: EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 20,
                              bottom: 20,
                            ),
                            color:
                                isDarkMode(context)
                                    ? Color(0XFF0e0b08)
                                    : Color(0XFFF1F4F7),
                            // height: 120,
                            alignment: Alignment.center,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              controller: reqController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Write Any Additional Requests'.tr(),
                                hintStyle: TextStyle(color: Color(0XFF9091A4)),
                                labelStyle: TextStyle(color: Color(0XFF333333)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                          vertical: 20,
                        ),
                        child: MaterialButton(
                          minWidth: size.width * 0.95,
                          height: 50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          color: Color(COLOR_PRIMARY),
                          onPressed: () async {
                            if (selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Select Day"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            DateTime dt = selectedDate!.toDate();
                            String hour = DateFormat("kk:mm").format(
                              DateFormat('hh:mm a').parse(
                                (Intl.getCurrentLocale() == "en_US")
                                    ? selectedTimeSlot
                                    : selectedTimeSlot.toLowerCase(),
                              ),
                            );
                            dt = DateTime(
                              dt.year,
                              dt.month,
                              dt.day,
                              int.parse(hour.split(":")[0]),
                              int.parse(hour.split(":")[1]),
                              dt.second,
                              dt.millisecond,
                              dt.microsecond,
                            );
                            selectedDate = Timestamp.fromDate(dt);
                            FireStoreUtils fireStoreUtils = FireStoreUtils();
                            showProgress(
                              context,
                              'Sending Table Request...'.tr(),
                              false,
                            );
                            VendorModel vendorModel = await fireStoreUtils
                                .getVendorByVendorID(widget.vendorModel.id);
                            BookTableModel bookTablemodel = BookTableModel(
                              author: MyAppState.currentUser,
                              authorID: MyAppState.currentUser!.userID,
                              createdAt: Timestamp.now(),
                              date: selectedDate,
                              status: ORDER_STATUS_PLACED,
                              vendor: vendorModel,
                              specialRequest:
                                  reqController.text.isEmpty
                                      ? ""
                                      : reqController.text,
                              vendorID: widget.vendorModel.id,
                              guestEmail: userDisEmail,
                              guestFirstName: userDisFName,
                              guestLastName: userDisLName,
                              guestPhone: userDisPhone,
                              occasion: _selectedOccasion,
                              discount: selectedTimeDiscount,
                              discountType: selectedTimeDiscountType,
                              totalGuest: int.parse(selectedPeople),
                              firstVisit: isFirstTime!,
                            );

                            await fireStoreUtils.bookTable(bookTablemodel);
                            await FireStoreUtils.sendOneNotification(
                              type: dineInPlaced,
                              token: widget.vendorModel.fcmToken,
                            );
                            await FireStoreUtils.sendFcmMessage(
                              dineInPlaced,
                              widget.vendorModel.fcmToken,
                            );
                            log("||||{}" + bookTablemodel.toJson().toString());
                            reqController.text = "";
                            _selectedOccasion = "";
                            selectedPeople = "2";
                            selectedTimeSlot = DateFormat(
                              'hh:mm a',
                            ).format(timeSlotList[0].time!);
                            selectedDate = null;
                            isFirstTime = false;
                            hideProgress();
                            Navigator.pop(context);
                          },
                          child: Text(
                            "BOOK NOW".tr(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  int calculateDifference(DateTime date) {
    DateTime now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Timestamp? selectedDate;

  String selectedPeople = "2";
  List noOfPeople = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
  ];

  // List timeSlotList = [
  //   '6:00 PM',
  //   '6:30 PM',
  //   '7:00 PM',
  //   '7:30 PM',
  //   '8:00 PM',
  //   '8:30 PM',
  //   '9:00 PM',
  //   '9:30 PM',
  //   '10:00 PM',
  // ];

  void showCustomDialog(
    BuildContext context,
    String firstName,
    String lastName,
    String phoneNumber,
    String email,
    VoidCallback? action,
  ) {
    GlobalKey<FormState> _key = GlobalKey();
    AutovalidateMode _validate = AutovalidateMode.disabled;
    showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) {
        return Container(
          margin: EdgeInsets.only(left: 10, right: 10),
          child: Form(
            key: _key,
            autovalidateMode: _validate,
            child: Center(
              child: Material(
                child: Padding(
                  padding: MediaQuery.of(context).padding,
                  child: ListView(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children:
                        ListTile.divideTiles(
                          context: context,
                          tiles: [
                            ListTile(
                              title:
                                  Text(
                                    'First Name',
                                    style: TextStyle(
                                      color:
                                          isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ).tr(),
                              trailing: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 100),
                                child: TextFormField(
                                  onSaved: (String? val) {
                                    userDisFName = val!;
                                  },
                                  validator: validateName,
                                  textInputAction: TextInputAction.next,
                                  textAlign: TextAlign.end,
                                  initialValue: firstName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  cursorColor: Color(COLOR_ACCENT),
                                  textCapitalization: TextCapitalization.words,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'First Name'.tr(),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ListTile(
                              title:
                                  Text(
                                    'Last Name',
                                    style: TextStyle(
                                      color:
                                          isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ).tr(),
                              trailing: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 100),
                                child: TextFormField(
                                  onSaved: (String? val) {
                                    userDisLName = val!;
                                  },
                                  validator: validateName,
                                  textInputAction: TextInputAction.next,
                                  textAlign: TextAlign.end,
                                  initialValue: lastName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  cursorColor: Color(COLOR_ACCENT),
                                  textCapitalization: TextCapitalization.words,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Last Name'.tr(),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ListTile(
                              title:
                                  Text(
                                    'Email Address',
                                    style: TextStyle(
                                      color:
                                          isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ).tr(),
                              trailing: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 200),
                                child: TextFormField(
                                  onSaved: (String? val) {
                                    userDisEmail = val!;
                                  },
                                  validator: validateEmail,
                                  textInputAction: TextInputAction.next,
                                  initialValue: email,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  cursorColor: Color(COLOR_ACCENT),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Email Address'.tr(),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ListTile(
                              title:
                                  Text(
                                    'Phone Number',
                                    style: TextStyle(
                                      color:
                                          isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ).tr(),
                              trailing: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 150),
                                child: TextFormField(
                                  onSaved: (String? val) {
                                    userDisPhone = val!;
                                  },
                                  validator: validateMobile,
                                  textInputAction: TextInputAction.done,
                                  initialValue: phoneNumber,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  cursorColor: Color(COLOR_ACCENT),
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Phone Number'.tr(),
                                    contentPadding: EdgeInsets.only(bottom: 2),
                                  ),
                                ),
                              ),
                            ),
                            MaterialButton(
                              minWidth:
                                  MediaQuery.of(context).size.width * 0.95,
                              height: 50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onPressed: () async {
                                if (_key.currentState?.validate() ?? false) {
                                  _key.currentState!.save();
                                  action!.call();
                                  setState(() {});
                                } else {
                                  action!.call();
                                  setState(() {
                                    _validate =
                                        AutovalidateMode.onUserInteraction;
                                  });
                                }
                                Navigator.pop(context);
                              },
                              child: Text(
                                "CHANGE".tr(),
                                style: TextStyle(color: Color(COLOR_PRIMARY)),
                              ),
                            ),
                          ],
                        ).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        Tween<Offset> tween;
        if (anim.status == AnimationStatus.reverse) {
          tween = Tween(begin: Offset(0, 1), end: Offset.zero);
        } else {
          tween = Tween(begin: Offset(0, -1), end: Offset.zero);
        }

        return SlideTransition(
          position: tween.animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  DateTime stringToDate(String openDineTime) {
    return DateFormat('HH:mm').parse(
      DateFormat('HH:mm').format(
        DateFormat("hh:mm a").parse(
          (Intl.getCurrentLocale() == "en_US")
              ? openDineTime
              : openDineTime.toLowerCase(),
        ),
      ),
    );
  }
}

class DateModel {
  late Timestamp date;
  late String discountPer;

  DateModel({required this.date, required this.discountPer});
}

class TimeModel {
  DateTime? time;
  String? discountPer;
  String? discountType;

  TimeModel({
    required this.time,
    required this.discountPer,
    required this.discountType,
  });
}
