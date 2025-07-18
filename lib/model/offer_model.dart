// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class OfferModel {
//   String? offerId;
//   String? offerCode;
//   String? couponusecount;
//   String? descriptionOffer;
//   String? discount;
//   String? discountType;
//   Timestamp? expireOfferDate;
//   bool? isEnableOffer;
//   String? imageOffer = "";
//   String? restaurantId;
//   String? maxdiscount;
//   String? minamount;
//   String? type;
//
//   OfferModel(
//       {this.descriptionOffer,
//       this.discount,
//       this.discountType,
//       this.couponusecount,
//       this.expireOfferDate,
//       this.imageOffer = "",
//       this.isEnableOffer,
//       this.offerCode,
//       this.offerId,
//       this.restaurantId,
//       this.maxdiscount,
//       this.minamount});
//
//   factory OfferModel.fromJson(Map<String, dynamic> parsedJson) {
//     return OfferModel(
//         descriptionOffer: parsedJson["description"],
//         discount: parsedJson["discount"],
//         couponusecount: parsedJson["coupon_use_count"],
//         discountType: parsedJson["discountType"],
//         expireOfferDate: parsedJson["expiresAt"],
//         imageOffer: parsedJson["image"] == null
//             ? ((parsedJson["photo"] == null ? "" : parsedJson["photo"]))
//             : parsedJson["image"],
//         isEnableOffer: parsedJson["isEnabled"],
//         offerCode: parsedJson["code"],
//         offerId: parsedJson["id"],
//         restaurantId: parsedJson["resturant_id"],
//         maxdiscount: parsedJson['maxDiscount'],
//         minamount: parsedJson['minOrderAmount']);
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "description": this.descriptionOffer,
//       "discount": this.discount,
//       "discountType": this.discountType,
//       "expiresAt": this.expireOfferDate,
//       "image": this.imageOffer,
//       "isEnabled": this.isEnableOffer,
//       "code": this.offerCode,
//       "id": this.offerId,
//       "coupon_use_count": this.restaurantId,
//       "resturant_id": this.couponusecount,
//       "maxdiscount": this.maxdiscount,
//       "minamount": this.minamount
//     };
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  String? offerId;
  String? offerCode;
  String? couponusecount;
  String? descriptionOffer;
  String? discount;
  String? discountType;
  Timestamp? expireOfferDate;
  bool? isEnableOffer;
  String? imageOffer = "";
  String? restaurantId;
  String? maxdiscount;
  String? minamount;
  String? type;
  List<String>? cities;

  OfferModel({
    this.descriptionOffer,
    this.discount,
    this.discountType,
    this.couponusecount,
    this.expireOfferDate,
    this.imageOffer = "",
    this.isEnableOffer,
    this.offerCode,
    this.offerId,
    this.restaurantId,
    this.maxdiscount,
    this.minamount,
    this.cities,
  });

  factory OfferModel.fromJson(Map<String, dynamic> parsedJson) {
    return OfferModel(
      descriptionOffer: parsedJson["description"],
      discount: parsedJson["discount"],
      couponusecount: parsedJson["coupon_use_count"],
      discountType: parsedJson["discountType"],
      expireOfferDate: parsedJson["expiresAt"],
      imageOffer:
          parsedJson["image"] == null
              ? ((parsedJson["photo"] == null ? "" : parsedJson["photo"]))
              : parsedJson["image"],
      isEnableOffer: parsedJson["isEnabled"],
      offerCode: parsedJson["code"],
      offerId: parsedJson["id"],
      restaurantId: parsedJson["resturant_id"],
      maxdiscount: parsedJson['maxDiscount'],
      minamount: parsedJson['minOrderAmount'],
      cities:
          parsedJson['cities'] != null
              ? List<String>.from(parsedJson['cities'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "description": this.descriptionOffer,
      "discount": this.discount,
      "discountType": this.discountType,
      "expiresAt": this.expireOfferDate,
      "image": this.imageOffer,
      "isEnabled": this.isEnableOffer,
      "code": this.offerCode,
      "id": this.offerId,
      "coupon_use_count": this.restaurantId,
      "resturant_id": this.couponusecount,
      "maxdiscount": this.maxdiscount,
      "minamount": this.minamount,
      "cities": this.cities,
    };
  }
}

// class OfferModel {
//   String? offerId;
//   String? offerCode;
//   String? couponusecount;
//   String? descriptionOffer;
//   double? discount;
//   String? discountType;
//   Timestamp? expireOfferDate;
//   bool? isEnableOffer;
//   String? imageOffer = "";
//   String? restaurantId;
//   String? maxdiscount;
//   String? minamount;
//   String? type;
//   List<String>? cities;
//
//   OfferModel(
//       {this.descriptionOffer,
//         this.discount,
//         this.discountType,
//         this.couponusecount,
//         this.expireOfferDate,
//         this.imageOffer = "",
//         this.isEnableOffer,
//         this.offerCode,
//         this.offerId,
//         this.restaurantId,
//         this.maxdiscount,
//         this.minamount,
//         this.cities});
//
//   factory OfferModel.fromJson(Map<String, dynamic> parsedJson) {
//     return OfferModel(
//         descriptionOffer: parsedJson["description"],
//         discount: parsedJson["discount"] != null
//             ? double.tryParse(parsedJson["discount"].toString())
//             : null,
//         couponusecount: parsedJson["coupon_use_count"],
//         discountType: parsedJson["discountType"],
//         expireOfferDate: parsedJson["expiresAt"],
//         imageOffer: parsedJson["image"] == null
//             ? ((parsedJson["photo"] == null ? "" : parsedJson["photo"]))
//             : parsedJson["image"],
//         isEnableOffer: parsedJson["isEnabled"],
//         offerCode: parsedJson["code"],
//         offerId: parsedJson["id"],
//         restaurantId: parsedJson["resturant_id"],
//         maxdiscount: parsedJson['maxDiscount'],
//         minamount: parsedJson['minOrderAmount'],
//         cities: parsedJson['cities'] != null
//             ? List<String>.from(parsedJson['cities'])
//             : null);
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "description": this.descriptionOffer,
//       "discount": this.discount,
//       "discountType": this.discountType,
//       "expiresAt": this.expireOfferDate,
//       "image": this.imageOffer,
//       "isEnabled": this.isEnableOffer,
//       "code": this.offerCode,
//       "id": this.offerId,
//       "coupon_use_count": this.couponusecount,
//       "resturant_id": this.restaurantId,
//       "maxdiscount": this.maxdiscount,
//       "minamount": this.minamount,
//       "cities": this.cities
//     };
//   }
// }
