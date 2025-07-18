import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodie_customer/model/AddressModel.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/localDatabase.dart';

import 'TaxModel.dart';

class OrderModel {
  String authorID, paymentMethod;

  User author;

  User? driver;

  String? driverID;
  String? razorpayorderid;

  List<CartProduct> products;
  List<CartProduct> admincommssionproducts;

  Timestamp createdAt;

  String vendorID;

  VendorModel vendor;
  String status;
  String customAdminCommissionType;
  AddressModel address;
  String id;
  num? discount;
  num? customAdminCommissionValue;
  num freeDeliveryWallet;
  String? couponCode;
  String? couponId, notes;
  String? tipValue;
  String? item;
  String? groceryUnit;
  String? groceryWeight;
  String? adminCommission;
  String? adminCommissionType;
  final bool? takeAway;
  List<TaxModel>? taxModel;
  String? deliveryCharge;
  String? packingcharges;
  String? admindiscountbyadmincommssion;
  String? admindiscountbyadmincommssiontype;
  Map<String, dynamic>? specialDiscount;
  String? estimatedTimeToPrepare;
  Timestamp? scheduleTime;
  bool? customAdminCommission;
  bool? freeDelivery;

  OrderModel({
    address,
    author,
    this.driver,
    this.customAdminCommission,
    this.freeDelivery,
    this.driverID,
    this.razorpayorderid,
    this.packingcharges,
    this.admindiscountbyadmincommssion,
    this.admindiscountbyadmincommssiontype,
    this.authorID = '',
    this.paymentMethod = '',
    createdAt,
    this.id = '',
    this.products = const [],
    this.admincommssionproducts = const [],
    this.status = '',
    this.customAdminCommissionType = '',
    this.discount = 0,
    this.customAdminCommissionValue = 0,
    this.freeDeliveryWallet = 0,
    this.couponCode = '',
    this.couponId = '',
    this.notes = '',
    this.item = '',
    this.groceryUnit = '',
    this.groceryWeight = '',
    vendor,
    /*this.extras = const [], this.extra_size,*/ this.tipValue,
    this.adminCommission,
    this.takeAway = false,
    this.adminCommissionType,
    this.deliveryCharge,
    this.specialDiscount,
    this.estimatedTimeToPrepare,
    this.vendorID = '',
    this.scheduleTime,
    this.taxModel,
  }) : this.address = address ?? AddressModel(),
       this.author = author ?? User(),
       this.createdAt = createdAt ?? Timestamp.now(),
       this.vendor = vendor ?? VendorModel();

  factory OrderModel.fromJson(Map<String, dynamic> parsedJson) {
    List<CartProduct> products =
        parsedJson.containsKey('products')
            ? List<CartProduct>.from(
              (parsedJson['products'] as List<dynamic>).map(
                (e) => CartProduct.fromJson(e),
              ),
            ).toList()
            : [].cast<CartProduct>();
    List<CartProduct> admincommssionproducts =
        parsedJson.containsKey('admincommssionproducts')
            ? List<CartProduct>.from(
              (parsedJson['admincommssionproducts'] as List<dynamic>).map(
                (e) => CartProduct.fromJson(e),
              ),
            ).toList()
            : [].cast<CartProduct>();

    List<TaxModel>? taxList;
    if (parsedJson['taxSetting'] != null) {
      taxList = <TaxModel>[];
      parsedJson['taxSetting'].forEach((v) {
        taxList!.add(TaxModel.fromJson(v));
      });
    }
    return OrderModel(
      address:
          parsedJson.containsKey('address')
              ? AddressModel.fromJson(parsedJson['address'])
              : AddressModel(),
      author:
          parsedJson.containsKey('author')
              ? User.fromJson(parsedJson['author'])
              : User(),
      authorID: parsedJson['authorID'] ?? '',
      createdAt: parsedJson['createdAt'] ?? Timestamp.now(),
      id: parsedJson['id'] ?? '',
      products: products,
      admincommssionproducts: admincommssionproducts,
      status: parsedJson['status'] ?? '',
      customAdminCommissionType: parsedJson['customAdminCommissionType'] ?? '',
      customAdminCommission: parsedJson['customAdminCommission'] ?? false,
      freeDelivery: parsedJson['freeDelivery'] ?? false,
      discount: double.parse(parsedJson['discount'].toString()),
      customAdminCommissionValue: double.parse(
        parsedJson['customAdminCommissionValue'].toString(),
      ),
      freeDeliveryWallet: double.parse(
        parsedJson['freeDeliveryWallet'].toString(),
      ),
      couponCode: parsedJson['couponCode'] ?? '',
      couponId: parsedJson['couponId'] ?? '',
      notes:
          (parsedJson["notes"] != null &&
                  parsedJson["notes"].toString().isNotEmpty)
              ? parsedJson["notes"]
              : "",
      vendor:
          parsedJson.containsKey('vendor')
              ? VendorModel.fromJson(parsedJson['vendor'])
              : VendorModel(),
      vendorID: parsedJson['vendorID'] ?? '',
      driver:
          parsedJson['driver'] != null
              ? User.fromJson(parsedJson['driver'])
              : null,
      driverID:
          parsedJson.containsKey('driverID') ? parsedJson['driverID'] : null,
      adminCommission:
          parsedJson["adminCommission"] != null
              ? parsedJson["adminCommission"]
              : "",
      razorpayorderid:
          parsedJson["razorpayorderid"] != null
              ? parsedJson["razorpayorderid"]
              : "",
      adminCommissionType:
          parsedJson["adminCommissionType"] != null
              ? parsedJson["adminCommissionType"]
              : "",
      tipValue:
          parsedJson["tip_amount"] != null ? parsedJson["tip_amount"] : "",
      item: parsedJson["item"] != null ? parsedJson["item"] : "",
      groceryWeight:
          parsedJson["groceryWeight"] != null
              ? parsedJson["groceryWeight"]
              : "",
      groceryUnit:
          parsedJson["groceryUnit"] != null ? parsedJson["groceryUnit"] : "",
      specialDiscount: parsedJson["specialDiscount"] ?? {},

      takeAway: parsedJson["takeAway"] != null ? parsedJson["takeAway"] : false,
      //extras: parsedJson["extras"]!=null?parsedJson["extras"]:[],
      // extra_size: parsedJson["extras_price"]!=null?parsedJson["extras_price"]:"",
      deliveryCharge:
          parsedJson["deliveryCharge"] != null
              ? parsedJson["deliveryCharge"]
              : "0.0",
      packingcharges:
          parsedJson["packingcharges"] != null
              ? parsedJson["packingcharges"]
              : "0.0",
      admindiscountbyadmincommssion:
          parsedJson["admindiscountbyadmincommssion"] != null
              ? parsedJson["admindiscountbyadmincommssion"]
              : "0.0",
      admindiscountbyadmincommssiontype:
          parsedJson["admindiscountbyadmincommssiontype"] != null
              ? parsedJson["admindiscountbyadmincommssiontype"]
              : "Percent",
      paymentMethod: parsedJson["payment_method"] ?? '',
      estimatedTimeToPrepare: parsedJson["estimatedTimeToPrepare"] ?? '',
      scheduleTime: parsedJson["scheduleTime"],

      taxModel: taxList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': this.address.toJson(),
      'author': this.author.toJson(),
      'authorID': this.authorID,
      'createdAt': this.createdAt,
      'payment_method': this.paymentMethod,
      'customAdminCommission': this.customAdminCommission,
      'freeDelivery': this.freeDelivery,
      'id': this.id,
      'products': this.products.map((e) => e.toJson()).toList(),
      'admincommssionproducts':
          this.admincommssionproducts.map((e) => e.toJson()).toList(),
      'status': this.status,
      'customAdminCommissionType': this.customAdminCommissionType,
      'discount': this.discount,
      'customAdminCommissionValue': this.customAdminCommissionValue,
      'freeDeliveryWallet': this.freeDeliveryWallet,
      'couponCode': this.couponCode,
      'couponId': this.couponId,
      'notes': this.notes,
      'vendor': this.vendor.toJson(),
      'vendorID': this.vendorID,
      'adminCommission': this.adminCommission,
      'razorpayorderid': this.razorpayorderid,
      'adminCommissionType': this.adminCommissionType,
      "tip_amount": this.tipValue,
      "item": this.item,
      "groceryUnit": this.groceryUnit,
      "groceryWeight": this.groceryWeight,
      "taxSetting":
          taxModel != null ? taxModel!.map((v) => v.toJson()).toList() : null,
      "takeAway": this.takeAway,
      "deliveryCharge": this.deliveryCharge,
      "packingcharges": this.packingcharges,
      "admindiscountbyadmincommssion": this.admindiscountbyadmincommssion,
      "admindiscountbyadmincommssiontype":
          this.admindiscountbyadmincommssiontype,
      "specialDiscount": this.specialDiscount,
      "estimatedTimeToPrepare": this.estimatedTimeToPrepare,
      "scheduleTime": this.scheduleTime,
    };
  }
}

/// old code
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:foodie_customer/model/AddressModel.dart';
// import 'package:foodie_customer/model/User.dart';
// import 'package:foodie_customer/model/VendorModel.dart';
// import 'package:foodie_customer/services/localDatabase.dart';
//
// import 'TaxModel.dart';
//
// class OrderModel {
//   String authorID, paymentMethod;
//
//   User author;
//
//   User? driver;
//
//   String? driverID;
//   String? razorpayorderid;
//
//   List<CartProduct> products;
//   List<CartProduct> admincommssionproducts;
//
//   Timestamp createdAt;
//
//   String vendorID;
//
//   VendorModel vendor;
//   String status;
//   String customAdminCommissionType;
//   AddressModel address;
//   String id;
//   num? discount;
//   num? customAdminCommissionValue;
//   String? couponCode;
//   String? couponId, notes;
//   String? tipValue;
//   String? item;
//   String? groceryUnit;
//   String? groceryWeight;
//   String? adminCommission;
//   String? adminCommissionType;
//   final bool? takeAway;
//   List<TaxModel>? taxModel;
//   String? deliveryCharge;
//   String? packingcharges;
//   String? admindiscountbyadmincommssion;
//   String? admindiscountbyadmincommssiontype;
//   Map<String, dynamic>? specialDiscount;
//   String? estimatedTimeToPrepare;
//   Timestamp? scheduleTime;
//   bool? customAdminCommission;
//   OrderModel(
//       {address,
//       author,
//       this.driver,
//         this.customAdminCommission,
//       this.driverID,
//       this.razorpayorderid,
//       this.packingcharges,
//       this.admindiscountbyadmincommssion,
//       this.admindiscountbyadmincommssiontype,
//       this.authorID = '',
//       this.paymentMethod = '',
//       createdAt,
//       this.id = '',
//       this.products = const [],
//       this.admincommssionproducts = const [],
//       this.status = '',
//       this.customAdminCommissionType = '',
//       this.discount = 0,
//       this.customAdminCommissionValue = 0,
//       this.couponCode = '',
//       this.couponId = '',
//       this.notes = '',
//       this.item = '',
//       this.groceryUnit = '',
//       this.groceryWeight = '',
//       vendor,
//       /*this.extras = const [], this.extra_size,*/ this.tipValue,
//       this.adminCommission,
//       this.takeAway = false,
//       this.adminCommissionType,
//       this.deliveryCharge,
//       this.specialDiscount,
//       this.estimatedTimeToPrepare,
//       this.vendorID = '',
//       this.scheduleTime,
//       this.taxModel})
//       : this.address = address ?? AddressModel(),
//         this.author = author ?? User(),
//         this.createdAt = createdAt ?? Timestamp.now(),
//         this.vendor = vendor ?? VendorModel();
//
//   factory OrderModel.fromJson(Map<String, dynamic> parsedJson) {
//     List<CartProduct> products = parsedJson.containsKey('products')
//         ? List<CartProduct>.from((parsedJson['products'] as List<dynamic>)
//             .map((e) => CartProduct.fromJson(e))).toList()
//         : [].cast<CartProduct>();
//     List<CartProduct> admincommssionproducts = parsedJson.containsKey('admincommssionproducts')
//         ? List<CartProduct>.from((parsedJson['admincommssionproducts'] as List<dynamic>)
//             .map((e) => CartProduct.fromJson(e))).toList()
//         : [].cast<CartProduct>();
//
//     List<TaxModel>? taxList;
//     if (parsedJson['taxSetting'] != null) {
//       taxList = <TaxModel>[];
//       parsedJson['taxSetting'].forEach((v) {
//         taxList!.add(TaxModel.fromJson(v));
//       });
//     }
//     return OrderModel(
//       address: parsedJson.containsKey('address')
//           ? AddressModel.fromJson(parsedJson['address'])
//           : AddressModel(),
//       author: parsedJson.containsKey('author')
//           ? User.fromJson(parsedJson['author'])
//           : User(),
//       authorID: parsedJson['authorID'] ?? '',
//       createdAt: parsedJson['createdAt'] ?? Timestamp.now(),
//       id: parsedJson['id'] ?? '',
//       products: products,
//       admincommssionproducts: admincommssionproducts,
//       status: parsedJson['status'] ?? '',
//       customAdminCommissionType: parsedJson['customAdminCommissionType'] ?? '',
//       customAdminCommission: parsedJson['customAdminCommission'] ?? false,
//       discount: double.parse(parsedJson['discount'].toString()),
//       customAdminCommissionValue: double.parse(parsedJson['customAdminCommissionValue'].toString()),
//       couponCode: parsedJson['couponCode'] ?? '',
//       couponId: parsedJson['couponId'] ?? '',
//       notes: (parsedJson["notes"] != null &&
//               parsedJson["notes"].toString().isNotEmpty)
//           ? parsedJson["notes"]
//           : "",
//       vendor: parsedJson.containsKey('vendor')
//           ? VendorModel.fromJson(parsedJson['vendor'])
//           : VendorModel(),
//       vendorID: parsedJson['vendorID'] ?? '',
//       driver: parsedJson['driver'] != null
//           ? User.fromJson(parsedJson['driver'])
//           : null,
//       driverID:
//           parsedJson.containsKey('driverID') ? parsedJson['driverID'] : null,
//       adminCommission: parsedJson["adminCommission"] != null
//           ? parsedJson["adminCommission"]
//           : "",
//       razorpayorderid: parsedJson["razorpayorderid"] != null
//           ? parsedJson["razorpayorderid"]
//           : "",
//       adminCommissionType: parsedJson["adminCommissionType"] != null
//           ? parsedJson["adminCommissionType"]
//           : "",
//       tipValue:
//           parsedJson["tip_amount"] != null ? parsedJson["tip_amount"] : "",
//       item: parsedJson["item"] != null ? parsedJson["item"] : "",
//       groceryWeight: parsedJson["groceryWeight"] != null
//           ? parsedJson["groceryWeight"]
//           : "",
//       groceryUnit:
//           parsedJson["groceryUnit"] != null ? parsedJson["groceryUnit"] : "",
//       specialDiscount: parsedJson["specialDiscount"] ?? {},
//
//       takeAway: parsedJson["takeAway"] != null ? parsedJson["takeAway"] : false,
//       //extras: parsedJson["extras"]!=null?parsedJson["extras"]:[],
//       // extra_size: parsedJson["extras_price"]!=null?parsedJson["extras_price"]:"",
//       deliveryCharge: parsedJson["deliveryCharge"] != null
//           ? parsedJson["deliveryCharge"]
//           : "0.0",
//       packingcharges: parsedJson["packingcharges"] != null
//           ? parsedJson["packingcharges"]
//           : "0.0",
//       admindiscountbyadmincommssion: parsedJson["admindiscountbyadmincommssion"] != null
//           ? parsedJson["admindiscountbyadmincommssion"]
//           : "0.0",
//       admindiscountbyadmincommssiontype: parsedJson["admindiscountbyadmincommssiontype"] != null
//           ? parsedJson["admindiscountbyadmincommssiontype"]
//           : "Percent",
//       paymentMethod: parsedJson["payment_method"] ?? '',
//       estimatedTimeToPrepare: parsedJson["estimatedTimeToPrepare"] ?? '',
//       scheduleTime: parsedJson["scheduleTime"],
//
//       taxModel: taxList,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'address': this.address.toJson(),
//       'author': this.author.toJson(),
//       'authorID': this.authorID,
//       'createdAt': this.createdAt,
//       'payment_method': this.paymentMethod,
//       'customAdminCommission': this.customAdminCommission,
//       'id': this.id,
//       'products': this.products.map((e) => e.toJson()).toList(),
//       'admincommssionproducts': this.admincommssionproducts.map((e) => e.toJson()).toList(),
//       'status': this.status,
//       'customAdminCommissionType': this.customAdminCommissionType,
//       'discount': this.discount,
//       'customAdminCommissionValue': this.customAdminCommissionValue,
//       'couponCode': this.couponCode,
//       'couponId': this.couponId,
//       'notes': this.notes,
//       'vendor': this.vendor.toJson(),
//       'vendorID': this.vendorID,
//       'adminCommission': this.adminCommission,
//       'razorpayorderid': this.razorpayorderid,
//       'adminCommissionType': this.adminCommissionType,
//       "tip_amount": this.tipValue,
//       "item": this.item,
//       "groceryUnit": this.groceryUnit,
//       "groceryWeight": this.groceryWeight,
//       "taxSetting":
//           taxModel != null ? taxModel!.map((v) => v.toJson()).toList() : null,
//       "takeAway": this.takeAway,
//       "deliveryCharge": this.deliveryCharge,
//       "packingcharges": this.packingcharges,
//       "admindiscountbyadmincommssion": this.admindiscountbyadmincommssion,
//       "admindiscountbyadmincommssiontype": this.admindiscountbyadmincommssiontype,
//       "specialDiscount": this.specialDiscount,
//       "estimatedTimeToPrepare": this.estimatedTimeToPrepare,
//       "scheduleTime": this.scheduleTime,
//     };
//   }
// }
