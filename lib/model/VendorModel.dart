import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodie_customer/model/DeliveryChargeModel.dart';
import 'package:foodie_customer/model/SpecialDiscountModel.dart';

import '../constants.dart';
import 'WorkingHoursModel.dart';

class VendorModel {
  String author;

  // String speedCashLevel;
  String speedCashId;
  String razorpayBankAcno;
  String razorpayBankAcname;
  String authorName;
  String groceryandrestirant;
  String authorProfilePic;
  String categoryID;
  String fcmToken;
  String categoryPhoto;
  String categoryTitle;
  Timestamp? createdAt;
  String description;
  String customAdminCommissionType;
  String phonenumber;
  Map<String, dynamic> filters;
  String id;
  double latitude;
  double longitude;
  String photo;
  List<dynamic> photos;
  List<dynamic> restaurantMenuPhotos;
  String location;
  num reviewsCount, restaurantCost;
  num reviewsSum;
  num walletAmount;
  num auto_apply_discount;
  num freeDeliveryWallet;
  num customAdminCommissionValue;
  GeoFireData geoFireData;
  String title;
  String auto_apply_coupon_id;
  String opentime, openDineTime;
  String closetime, closeDineTime;
  bool hidephotos;
  bool commingsoon;
  bool reststatus;
  bool auto_apply;
  bool freeDelivery;
  bool customAdminCommission;
  DeliveryChargeModel? deliveryCharge;
  List<SpecialDiscountModel> specialDiscount;
  bool specialDiscountEnable;
  List<WorkingHoursModel> workingHours;
  List<CategoryModel> category;
  bool isScheduled;
  bool codWallet;
  bool isLiveandScheduled;
  bool isTempClose;

  VendorModel({
    this.author = '',
    this.razorpayBankAcno = '',
    // this.speedCashLevel = '',
    this.speedCashId = '',
    this.razorpayBankAcname = '',
    this.hidephotos = false,
    this.commingsoon = false,
    this.authorName = '',
    this.groceryandrestirant = '',
    this.authorProfilePic = '',
    this.categoryID = '',
    this.categoryPhoto = '',
    this.categoryTitle = '',
    this.category = const [],
    this.createdAt,
    this.filters = const {},
    this.description = '',
    this.customAdminCommissionType = '',
    this.phonenumber = '',
    this.fcmToken = '',
    this.auto_apply_coupon_id = '',
    this.id = '',
    this.latitude = 0.1,
    this.longitude = 0.1,
    this.photo = '',
    this.isTempClose = false,
    this.photos = const [],
    this.restaurantMenuPhotos = const [],
    this.specialDiscount = const [],
    this.workingHours = const [],
    this.specialDiscountEnable = false,
    this.location = '',
    this.reviewsCount = 0,
    this.reviewsSum = 0,
    this.walletAmount = 0,
    this.auto_apply_discount = 0,
    this.freeDeliveryWallet = 0,
    this.customAdminCommissionValue = 0,
    this.restaurantCost = 0,
    this.closetime = '',
    this.opentime = '',
    this.closeDineTime = '',
    this.openDineTime = '',
    this.title = '',
    this.reststatus = false,
    this.auto_apply = false,
    this.freeDelivery = false,
    this.customAdminCommission = false,
    this.isScheduled = false,
    this.codWallet = true,
    this.isLiveandScheduled = false,
    geoFireData,
    deliveryCharge,
  }) : this.deliveryCharge = deliveryCharge ?? null,
       this.geoFireData =
           geoFireData ??
           GeoFireData(geohash: "", geoPoint: GeoPoint(0.0, 0.0));

  factory VendorModel.fromJson(Map<String, dynamic> parsedJson) {
    num restCost = 0;
    if (parsedJson.containsKey("restaurantCost")) {
      if (parsedJson['restaurantCost'] == null ||
          parsedJson['restaurantCost'].toString().isEmpty) {
        restCost = 0;
      } else if (parsedJson['restaurantCost'] is String) {
        restCost = num.parse(parsedJson['restaurantCost']);
      } else if (parsedJson['restaurantCost'] is num) {
        restCost = parsedJson['restaurantCost'];
      }
    }

    List<SpecialDiscountModel> specialDiscount =
        parsedJson.containsKey('specialDiscount')
            ? List<SpecialDiscountModel>.from(
              (parsedJson['specialDiscount'] as List<dynamic>).map(
                (e) => SpecialDiscountModel.fromJson(e),
              ),
            ).toList()
            : [].cast<SpecialDiscountModel>();

    List<WorkingHoursModel> workingHours =
        parsedJson.containsKey('workingHours')
            ? List<WorkingHoursModel>.from(
              (parsedJson['workingHours'] as List<dynamic>).map(
                (e) => WorkingHoursModel.fromJson(e),
              ),
            ).toList()
            : [].cast<WorkingHoursModel>();

    List<CategoryModel> category =
        parsedJson.containsKey('category')
            ? List<CategoryModel>.from(
              (parsedJson['category'] as List<dynamic>).map(
                (e) => CategoryModel.fromJson(e),
              ),
            ).toList()
            : [].cast<CategoryModel>();

    return VendorModel(
      author: parsedJson['author'] ?? '',
      razorpayBankAcno: parsedJson['razorpayBankAcno'] ?? '',
      // speedCashLevel: parsedJson['speedCashLevel'] ?? '',
      speedCashId: parsedJson['speedCashId'] ?? '',
      razorpayBankAcname: parsedJson['razorpayBankAcname'] ?? '',
      hidephotos: parsedJson['hidephotos'] ?? false,
      commingsoon: parsedJson['comming_soon'] ?? false,
      authorName: parsedJson['authorName'] ?? '',
      groceryandrestirant: parsedJson['groceryandrestirant'] ?? '',
      authorProfilePic: parsedJson['authorProfilePic'] ?? '',
      categoryPhoto: parsedJson['categoryPhoto'] ?? '',
      category: category,
      createdAt: parsedJson['createdAt'],
      deliveryCharge:
          (parsedJson.containsKey('DeliveryCharge') &&
                  parsedJson['DeliveryCharge'] != null)
              ? DeliveryChargeModel.fromJson(parsedJson['DeliveryCharge'])
              : null,
      description: parsedJson['description'] ?? '',
      customAdminCommissionType: parsedJson['customAdminCommissionType'] ?? '',
      phonenumber: parsedJson['phonenumber'] ?? '',
      filters: parsedJson['filters'] ?? {},
      id: parsedJson['id'] ?? '',
      geoFireData:
          parsedJson.containsKey('g')
              ? GeoFireData.fromJson(parsedJson['g'])
              : GeoFireData(geohash: "", geoPoint: GeoPoint(0.0, 0.0)),
      latitude: getDoubleVal(parsedJson['latitude']),
      longitude: getDoubleVal(parsedJson['longitude']),
      photo: parsedJson['photo'] ?? placeholderImage,
      photos: parsedJson['photos'] ?? [],
      isTempClose: parsedJson['isTempClose'] ?? false,
      restaurantMenuPhotos: parsedJson['restaurantMenuPhotos'] ?? [],
      location: parsedJson['location'] ?? '',
      fcmToken: parsedJson['fcmToken'] ?? '',
      auto_apply_coupon_id: parsedJson['auto_apply_coupon_id'] ?? '',
      reviewsCount: parsedJson['reviewsCount'] ?? 0,
      restaurantCost: restCost,
      reviewsSum: parsedJson['reviewsSum'] ?? 0,
      walletAmount: parsedJson['walletAmount'] ?? 0,
      // auto_apply_discount: parsedJson['auto_apply_discount'] ?? 0,
      auto_apply_discount:
          (parsedJson['auto_apply_discount'] is num)
              ? parsedJson['auto_apply_discount']
              : num.tryParse(parsedJson['auto_apply_discount'].toString()) ?? 0,
      freeDeliveryWallet:
          (parsedJson['freeDeliveryWallet'] is num)
              ? parsedJson['freeDeliveryWallet']
              : num.tryParse(parsedJson['freeDeliveryWallet'].toString()) ?? 0,

      customAdminCommissionValue: parsedJson['customAdminCommissionValue'] ?? 0,
      title: parsedJson['title'] ?? '',
      closetime: parsedJson['closetime'] ?? '',
      opentime: parsedJson['opentime'] ?? '',
      closeDineTime: parsedJson['closeDineTime'] ?? '',
      openDineTime: parsedJson['openDineTime'] ?? '',
      specialDiscountEnable: parsedJson['specialDiscountEnable'] ?? false,
      specialDiscount: specialDiscount,
      workingHours: workingHours,
      reststatus: parsedJson['reststatus'] ?? false,
      auto_apply: parsedJson['auto_apply'] ?? false,
      freeDelivery: parsedJson['freeDelivery'] ?? false,
      customAdminCommission: parsedJson['customAdminCommission'] ?? false,
      isScheduled: parsedJson['isScheduled'] ?? false,
      codWallet: parsedJson['codWallet'] ?? true,
      isLiveandScheduled: parsedJson['isLiveandScheduled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'author': this.author,
      'razorpayBankAcno': this.razorpayBankAcno,
      // 'speedCashLevel': this.speedCashLevel,
      'speedCashId': this.speedCashId,
      'razorpayBankAcname': this.razorpayBankAcname,
      'hidephotos': this.hidephotos,
      'comming_soon ': this.commingsoon,
      'authorName': this.authorName,
      'groceryandrestirant': this.groceryandrestirant,
      'authorProfilePic': this.authorProfilePic,
      'categoryPhoto': this.categoryPhoto,
      'category': this.category.map((e) => e.toJson()).toList(),
      'createdAt': this.createdAt,
      'description': this.description,
      'customAdminCommissionType': this.customAdminCommissionType,
      'phonenumber': this.phonenumber,
      'filters': this.filters,
      'restaurantCost': this.restaurantCost,
      'id': this.id,
      "g": this.geoFireData.toJson(),
      'latitude': this.latitude,
      'longitude': this.longitude,
      'photo': this.photo,
      'photos': this.photos,
      'restaurantMenuPhotos': this.restaurantMenuPhotos,
      'location': this.location,
      'fcmToken': this.fcmToken,
      'auto_apply_coupon_id': this.auto_apply_coupon_id,
      'reviewsCount': this.reviewsCount,
      'reviewsSum': this.reviewsSum,
      'walletAmount': this.walletAmount,
      'auto_apply_discount': this.auto_apply_discount,
      'freeDeliveryWallet': this.freeDeliveryWallet,
      'customAdminCommissionValue': this.customAdminCommissionValue,
      'title': this.title,
      'opentime': this.opentime,
      'closetime': this.closetime,
      'openDineTime': this.openDineTime,
      'closeDineTime': this.closeDineTime,
      'reststatus': this.reststatus,
      'auto_apply': this.auto_apply,
      'freeDelivery': this.freeDelivery,
      'customAdminCommission': this.customAdminCommission,
      'specialDiscount': this.specialDiscount.map((e) => e.toJson()).toList(),
      'specialDiscountEnable': this.specialDiscountEnable,
      'workingHours': this.workingHours.map((e) => e.toJson()).toList(),
      'isTempClose': this.isTempClose,
      'isScheduled': this.isScheduled,
      'codWallet': this.codWallet,
      'isLiveandScheduled': this.isLiveandScheduled,
    };
    if (deliveryCharge != null) {
      json.addAll({'DeliveryCharge': this.deliveryCharge!.toJson()});
    }
    return json;
  }
}

class GeoFireData {
  String? geohash;
  GeoPoint? geoPoint;

  GeoFireData({this.geohash, this.geoPoint});

  factory GeoFireData.fromJson(Map<dynamic, dynamic> parsedJson) {
    return GeoFireData(
      geohash: parsedJson['geohash'] ?? '',
      geoPoint: parsedJson['geopoint'] ?? GeoPoint(0.0, 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {'geohash': this.geohash, 'geopoint': this.geoPoint};
  }
}

class Filters {
  String cuisine;

  String wifi;

  String breakfast;

  String dinner;

  String lunch;

  String seating;

  String vegan;

  String reservation;

  String music;

  String price;

  Filters({
    required this.cuisine,
    this.seating = '',
    this.price = '',
    this.breakfast = '',
    this.dinner = '',
    this.lunch = '',
    this.music = '',
    this.reservation = '',
    this.vegan = '',
    this.wifi = '',
  });

  factory Filters.fromJson(Map<dynamic, dynamic> parsedJson) {
    return new Filters(
      cuisine: parsedJson["Cuisine"] ?? '',
      wifi: parsedJson["Free Wi-Fi"] ?? 'No',
      breakfast: parsedJson["Good for Breakfast"] ?? 'No',
      dinner: parsedJson["Good for Dinner"] ?? 'No',
      lunch: parsedJson["Good for Lunch"] ?? 'No',
      music: parsedJson["Live Music"] ?? 'No',
      price: parsedJson["Price"],
      reservation: parsedJson["Takes Reservations"] ?? 'No',
      vegan: parsedJson["Vegetarian Friendly"] ?? 'No',
      seating: parsedJson["Outdoor Seating"] ?? 'No',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Cuisine': this.cuisine,
      'Free Wi-Fi': this.wifi,
      'Good for Breakfast': this.breakfast,
      'Good for Dinner': this.dinner,
      'Good for Lunch': this.lunch,
      'Live Music': this.music,
      'Price': this.price,
      'Takes Reservations': this.reservation,
      'Vegetarian Friendly': this.vegan,
      'Outdoor Seating': this.seating,
    };
  }
}

///old Code
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:foodie_customer/model/DeliveryChargeModel.dart';
// import 'package:foodie_customer/model/SpecialDiscountModel.dart';
//
// import '../constants.dart';
// import 'WorkingHoursModel.dart';
//
// class VendorModel {
//   String author;
//   // String speedCashLevel;
//   String speedCashId;
//   String razorpayBankAcno;
//   String razorpayBankAcname;
//   String authorName;
//   String groceryandrestirant;
//   String authorProfilePic;
//   String categoryID;
//   String fcmToken;
//   String categoryPhoto;
//   String categoryTitle;
//   Timestamp? createdAt;
//   String description;
//   String customAdminCommissionType;
//   String phonenumber;
//   Map<String, dynamic> filters;
//   String id;
//   double latitude;
//   double longitude;
//   String photo;
//   List<dynamic> photos;
//   List<dynamic> restaurantMenuPhotos;
//   String location;
//   num reviewsCount, restaurantCost;
//   num reviewsSum;
//   num walletAmount;
//   num auto_apply_discount;
//   num customAdminCommissionValue;
//   GeoFireData geoFireData;
//   String title;
//   String auto_apply_coupon_id;
//   String opentime, openDineTime;
//   String closetime, closeDineTime;
//   bool hidephotos;
//   bool commingsoon;
//   bool reststatus;
//   bool auto_apply;
//   bool customAdminCommission;
//   DeliveryChargeModel? deliveryCharge;
//   List<SpecialDiscountModel> specialDiscount;
//   bool specialDiscountEnable;
//   List<WorkingHoursModel> workingHours;
//   List<CategoryModel> category;
//   bool isScheduled;
//   bool codWallet;
//   bool isLiveandScheduled;
//   bool isTempClose;
//
//   VendorModel({
//     this.author = '',
//     this.razorpayBankAcno = '',
//     // this.speedCashLevel = '',
//     this.speedCashId = '',
//     this.razorpayBankAcname = '',
//     this.hidephotos = false,
//     this.commingsoon = false,
//     this.authorName = '',
//     this.groceryandrestirant = '',
//     this.authorProfilePic = '',
//     this.categoryID = '',
//     this.categoryPhoto = '',
//     this.categoryTitle = '',
//     this.category = const [],
//     this.createdAt,
//     this.filters = const {},
//     this.description = '',
//     this.customAdminCommissionType = '',
//     this.phonenumber = '',
//     this.fcmToken = '',
//     this.auto_apply_coupon_id = '',
//     this.id = '',
//     this.latitude = 0.1,
//     this.longitude = 0.1,
//     this.photo = '',
//     this.isTempClose = false,
//     this.photos = const [],
//     this.restaurantMenuPhotos = const [],
//     this.specialDiscount = const [],
//     this.workingHours = const [],
//     this.specialDiscountEnable = false,
//     this.location = '',
//     this.reviewsCount = 0,
//     this.reviewsSum = 0,
//     this.walletAmount = 0,
//     this.auto_apply_discount = 0,
//     this.customAdminCommissionValue = 0,
//     this.restaurantCost = 0,
//     this.closetime = '',
//     this.opentime = '',
//     this.closeDineTime = '',
//     this.openDineTime = '',
//     this.title = '',
//     this.reststatus = false,
//     this.auto_apply = false,
//     this.customAdminCommission = false,
//     this.isScheduled = false,
//     this.codWallet = true,
//     this.isLiveandScheduled = false,
//     geoFireData,
//     deliveryCharge,
//   })  : this.deliveryCharge = deliveryCharge ?? null,
//         this.geoFireData = geoFireData ??
//             GeoFireData(
//               geohash: "",
//               geoPoint: GeoPoint(0.0, 0.0),
//             );
//
//   factory VendorModel.fromJson(Map<String, dynamic> parsedJson) {
//     num restCost = 0;
//     if (parsedJson.containsKey("restaurantCost")) {
//       if (parsedJson['restaurantCost'] == null ||
//           parsedJson['restaurantCost'].toString().isEmpty) {
//         restCost = 0;
//       } else if (parsedJson['restaurantCost'] is String) {
//         restCost = num.parse(parsedJson['restaurantCost']);
//       } else if (parsedJson['restaurantCost'] is num) {
//         restCost = parsedJson['restaurantCost'];
//       }
//     }
//
//     List<SpecialDiscountModel> specialDiscount =
//         parsedJson.containsKey('specialDiscount')
//             ? List<SpecialDiscountModel>.from(
//                 (parsedJson['specialDiscount'] as List<dynamic>)
//                     .map((e) => SpecialDiscountModel.fromJson(e))).toList()
//             : [].cast<SpecialDiscountModel>();
//
//     List<WorkingHoursModel> workingHours =
//         parsedJson.containsKey('workingHours')
//             ? List<WorkingHoursModel>.from(
//                 (parsedJson['workingHours'] as List<dynamic>)
//                     .map((e) => WorkingHoursModel.fromJson(e))).toList()
//             : [].cast<WorkingHoursModel>();
//
//     List<CategoryModel> category = parsedJson.containsKey('category')
//         ? List<CategoryModel>.from((parsedJson['category'] as List<dynamic>)
//             .map((e) => CategoryModel.fromJson(e))).toList()
//         : [].cast<CategoryModel>();
//
//     return VendorModel(
//       author: parsedJson['author'] ?? '',
//       razorpayBankAcno: parsedJson['razorpayBankAcno'] ?? '',
//       // speedCashLevel: parsedJson['speedCashLevel'] ?? '',
//       speedCashId: parsedJson['speedCashId'] ?? '',
//       razorpayBankAcname: parsedJson['razorpayBankAcname'] ?? '',
//       hidephotos: parsedJson['hidephotos'] ?? false,
//       commingsoon: parsedJson['comming_soon'] ?? false,
//       authorName: parsedJson['authorName'] ?? '',
//       groceryandrestirant: parsedJson['groceryandrestirant'] ?? '',
//       authorProfilePic: parsedJson['authorProfilePic'] ?? '',
//       categoryPhoto: parsedJson['categoryPhoto'] ?? '',
//       category: category,
//       createdAt: parsedJson['createdAt'],
//       deliveryCharge: (parsedJson.containsKey('DeliveryCharge') &&
//               parsedJson['DeliveryCharge'] != null)
//           ? DeliveryChargeModel.fromJson(parsedJson['DeliveryCharge'])
//           : null,
//       description: parsedJson['description'] ?? '',
//       customAdminCommissionType: parsedJson['customAdminCommissionType'] ?? '',
//       phonenumber: parsedJson['phonenumber'] ?? '',
//       filters: parsedJson['filters'] ?? {},
//       id: parsedJson['id'] ?? '',
//       geoFireData: parsedJson.containsKey('g')
//           ? GeoFireData.fromJson(parsedJson['g'])
//           : GeoFireData(
//               geohash: "",
//               geoPoint: GeoPoint(0.0, 0.0),
//             ),
//       latitude: getDoubleVal(parsedJson['latitude']),
//       longitude: getDoubleVal(parsedJson['longitude']),
//       photo: parsedJson['photo'] ?? placeholderImage,
//       photos: parsedJson['photos'] ?? [],
//       isTempClose: parsedJson['isTempClose'] ?? false,
//       restaurantMenuPhotos: parsedJson['restaurantMenuPhotos'] ?? [],
//       location: parsedJson['location'] ?? '',
//       fcmToken: parsedJson['fcmToken'] ?? '',
//       auto_apply_coupon_id: parsedJson['auto_apply_coupon_id'] ?? '',
//       reviewsCount: parsedJson['reviewsCount'] ?? 0,
//       restaurantCost: restCost,
//       reviewsSum: parsedJson['reviewsSum'] ?? 0,
//       walletAmount: parsedJson['walletAmount'] ?? 0,
//       // auto_apply_discount: parsedJson['auto_apply_discount'] ?? 0,
//       auto_apply_discount: (parsedJson['auto_apply_discount'] is num)
//           ? parsedJson['auto_apply_discount']
//           : num.tryParse(parsedJson['auto_apply_discount'].toString()) ?? 0,
//       customAdminCommissionValue: parsedJson['customAdminCommissionValue'] ?? 0,
//       title: parsedJson['title'] ?? '',
//       closetime: parsedJson['closetime'] ?? '',
//       opentime: parsedJson['opentime'] ?? '',
//       closeDineTime: parsedJson['closeDineTime'] ?? '',
//       openDineTime: parsedJson['openDineTime'] ?? '',
//       specialDiscountEnable: parsedJson['specialDiscountEnable'] ?? false,
//       specialDiscount: specialDiscount,
//       workingHours: workingHours,
//       reststatus: parsedJson['reststatus'] ?? false,
//       auto_apply: parsedJson['auto_apply'] ?? false,
//       customAdminCommission: parsedJson['customAdminCommission'] ?? false,
//       isScheduled: parsedJson['isScheduled'] ?? false,
//       codWallet: parsedJson['codWallet'] ?? true,
//       isLiveandScheduled: parsedJson['isLiveandScheduled'] ?? false,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     Map<String, dynamic> json = {
//       'author': this.author,
//       'razorpayBankAcno': this.razorpayBankAcno,
//       // 'speedCashLevel': this.speedCashLevel,
//       'speedCashId': this.speedCashId,
//       'razorpayBankAcname': this.razorpayBankAcname,
//       'hidephotos': this.hidephotos,
//       'comming_soon ': this.commingsoon,
//       'authorName': this.authorName,
//       'groceryandrestirant': this.groceryandrestirant,
//       'authorProfilePic': this.authorProfilePic,
//       'categoryPhoto': this.categoryPhoto,
//       'category': this.category.map((e) => e.toJson()).toList(),
//       'createdAt': this.createdAt,
//       'description': this.description,
//       'customAdminCommissionType': this.customAdminCommissionType,
//       'phonenumber': this.phonenumber,
//       'filters': this.filters,
//       'restaurantCost': this.restaurantCost,
//       'id': this.id,
//       "g": this.geoFireData.toJson(),
//       'latitude': this.latitude,
//       'longitude': this.longitude,
//       'photo': this.photo,
//       'photos': this.photos,
//       'restaurantMenuPhotos': this.restaurantMenuPhotos,
//       'location': this.location,
//       'fcmToken': this.fcmToken,
//       'auto_apply_coupon_id': this.auto_apply_coupon_id,
//       'reviewsCount': this.reviewsCount,
//       'reviewsSum': this.reviewsSum,
//       'walletAmount': this.walletAmount,
//       'auto_apply_discount': this.auto_apply_discount,
//       'customAdminCommissionValue': this.customAdminCommissionValue,
//       'title': this.title,
//       'opentime': this.opentime,
//       'closetime': this.closetime,
//       'openDineTime': this.openDineTime,
//       'closeDineTime': this.closeDineTime,
//       'reststatus': this.reststatus,
//       'auto_apply': this.auto_apply,
//       'customAdminCommission': this.customAdminCommission,
//       'specialDiscount': this.specialDiscount.map((e) => e.toJson()).toList(),
//       'specialDiscountEnable': this.specialDiscountEnable,
//       'workingHours': this.workingHours.map((e) => e.toJson()).toList(),
//       'isTempClose': this.isTempClose,
//       'isScheduled': this.isScheduled,
//       'codWallet': this.codWallet,
//       'isLiveandScheduled': this.isLiveandScheduled,
//     };
//     if (deliveryCharge != null) {
//       json.addAll({'DeliveryCharge': this.deliveryCharge!.toJson()});
//     }
//     return json;
//   }
// }
//
// class GeoFireData {
//   String? geohash;
//   GeoPoint? geoPoint;
//
//   GeoFireData({this.geohash, this.geoPoint});
//
//   factory GeoFireData.fromJson(Map<dynamic, dynamic> parsedJson) {
//     return GeoFireData(
//       geohash: parsedJson['geohash'] ?? '',
//       geoPoint: parsedJson['geopoint'] ?? GeoPoint(0.0, 0.0),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'geohash': this.geohash,
//       'geopoint': this.geoPoint,
//     };
//   }
// }
//
// class Filters {
//   String cuisine;
//
//   String wifi;
//
//   String breakfast;
//
//   String dinner;
//
//   String lunch;
//
//   String seating;
//
//   String vegan;
//
//   String reservation;
//
//   String music;
//
//   String price;
//
//   Filters(
//       {required this.cuisine,
//       this.seating = '',
//       this.price = '',
//       this.breakfast = '',
//       this.dinner = '',
//       this.lunch = '',
//       this.music = '',
//       this.reservation = '',
//       this.vegan = '',
//       this.wifi = ''});
//
//   factory Filters.fromJson(Map<dynamic, dynamic> parsedJson) {
//     return new Filters(
//         cuisine: parsedJson["Cuisine"] ?? '',
//         wifi: parsedJson["Free Wi-Fi"] ?? 'No',
//         breakfast: parsedJson["Good for Breakfast"] ?? 'No',
//         dinner: parsedJson["Good for Dinner"] ?? 'No',
//         lunch: parsedJson["Good for Lunch"] ?? 'No',
//         music: parsedJson["Live Music"] ?? 'No',
//         price: parsedJson["Price"],
//         reservation: parsedJson["Takes Reservations"] ?? 'No',
//         vegan: parsedJson["Vegetarian Friendly"] ?? 'No',
//         seating: parsedJson["Outdoor Seating"] ?? 'No');
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'Cuisine': this.cuisine,
//       'Free Wi-Fi': this.wifi,
//       'Good for Breakfast': this.breakfast,
//       'Good for Dinner': this.dinner,
//       'Good for Lunch': this.lunch,
//       'Live Music': this.music,
//       'Price': this.price,
//       'Takes Reservations': this.reservation,
//       'Vegetarian Friendly': this.vegan,
//       'Outdoor Seating': this.seating
//     };
//   }
// }
