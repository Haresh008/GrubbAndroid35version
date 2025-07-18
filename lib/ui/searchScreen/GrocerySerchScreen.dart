import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/model/ProductModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';

import '../../model/mail_setting.dart';

class GrocerySearchScreen extends StatefulWidget {
  const GrocerySearchScreen({Key? key}) : super(key: key);

  @override
  GrocerySearchScreenState createState() => GrocerySearchScreenState();
}

class GrocerySearchScreenState extends State<GrocerySearchScreen> {
  late List<VendorModel> vendorList = [];
  late List<VendorModel> vendorSearchList = [];

  late List<ProductModel> productList = [];
  late List<ProductModel> productSearchList = [];

  final FireStoreUtils fireStoreUtils = FireStoreUtils();

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
    fireStoreUtils.getVendors().then((value) {
      setState(() {
        vendorList = value;
      });
    });
    fireStoreUtils.getAllProducts().then((value) {
      setState(() {
        productList = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        ),
        actions: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 50,
                top: 10,
                right: 10,
                bottom: 10,
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: TextFormField(
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    onSearchTextChanged(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search...'.tr(),
                    contentPadding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 10,
                    ),
                    hintStyle: const TextStyle(
                      color: Color(0XFF8A8989),
                      fontFamily: 'Poppinsr',
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Color(COLOR_PRIMARY),
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Visibility(
                visible: vendorSearchList.isNotEmpty,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Restaurant",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vendorSearchList.length,
                      itemBuilder: (context, index) {
                        return data(vendorSearchList[index]);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Visibility(
                visible: productSearchList.isNotEmpty,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Items".tr(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: productSearchList.length,
                      itemBuilder: (context, index) {
                        return product(productSearchList[index]);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  onSearchTextChanged(String text) {
    if (text.isEmpty) {
      setState(() {});
      return;
    }
    vendorSearchList.clear();
    productSearchList.clear();
    print("1");
    for (var element in vendorList) {
      if (element.title.toLowerCase().contains(text.toLowerCase())) {
        setState(() {
          vendorSearchList.add(element);
        });
      }
    }

    for (var element in productList) {
      if (element.name.toLowerCase().contains(text.toLowerCase())) {
        print("7");
        setState(() {
          productSearchList.add(element);
        });
      }
    }
  }

  @override
  void dispose() {
    vendorSearchList.clear();
    productSearchList.clear();
    super.dispose();
  }

  data(VendorModel vendorModel) {
    return vendorModel.commingsoon
        ? GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {},
          child: Stack(
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.matrix(<double>[
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      CachedNetworkImage(
                        height: MediaQuery.of(context).size.height * 0.075,
                        width: MediaQuery.of(context).size.width * 0.16,
                        imageUrl: getImageVAlidUrl(vendorModel.photo),
                        imageBuilder:
                            (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.network(
                                AppGlobal.placeHolderImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  vendorModel.title,
                                  style: TextStyle(
                                    fontFamily: "Poppinsr",
                                    fontSize: 16,
                                    color:
                                        isDarkMode(context)
                                            ? const Color(0xffFFFFFF)
                                            : const Color(0xff272727),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.location_on_sharp,
                                      color: Color(0xff9091A4),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 3),
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 200,
                                        maxHeight: 50,
                                      ),
                                      child: Text(
                                        vendorModel.location,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontFamily: "Poppinsl",
                                          fontSize: 14,
                                          color: Color(0XFF555353),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'coming_soon'.tr(),
                    style: TextStyle(
                      fontFamily: "Poppinsm",
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        : GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap:
              () => push(
                context,
                NewVendorProductsScreen(vendorModel: vendorModel),
              ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    CachedNetworkImage(
                      height: MediaQuery.of(context).size.height * 0.075,
                      width: MediaQuery.of(context).size.width * 0.16,
                      imageUrl: getImageVAlidUrl(vendorModel.photo),
                      imageBuilder:
                          (context, imageProvider) => Container(
                            // width: 100,
                            // height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.network(
                              AppGlobal.placeHolderImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                vendorModel.title,
                                style: TextStyle(
                                  fontFamily: "Poppinsr",
                                  fontSize: 16,
                                  color:
                                      isDarkMode(context)
                                          ? const Color(0xffFFFFFF)
                                          : const Color(0xff272727),
                                  // Color(0xff272727)
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.location_on_sharp,
                                    color: Color(0xff9091A4),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 3),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 200,
                                      maxHeight: 50,
                                    ),
                                    child: Text(
                                      vendorModel.location,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontFamily: "Poppinsl",
                                        fontSize: 14,
                                        color: Color(0XFF555353),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              vendorModel.freeDelivery == true
                  ? Positioned(
                    top: 8,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 10,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Free Delivery'.tr(),
                        style: TextStyle(
                          fontFamily: "Poppinsm",
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  : Container(),
            ],
          ),
        );
  }

  product(ProductModel productModel) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
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
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CachedNetworkImage(
              height: MediaQuery.of(context).size.height * 0.075,
              width: MediaQuery.of(context).size.width * 0.16,
              imageUrl: getImageVAlidUrl(productModel.photo),
              imageBuilder:
                  (context, imageProvider) => Container(
                    // width: 100,
                    // height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      AppGlobal.placeHolderImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        productModel.name,
                        style: TextStyle(
                          fontFamily: "Poppinsr",
                          fontSize: 16,
                          color:
                              isDarkMode(context)
                                  ? const Color(0xffFFFFFF)
                                  : const Color(0xff272727),
                          // Color(0xff272727)
                        ),
                      ),
                      const SizedBox(height: 3),
                      productModel.disPrice == "" ||
                              productModel.disPrice == "0"
                          ? Text(
                            "${amountShow(amount: productModel.price.toString())}",
                            style: TextStyle(
                              fontFamily: "Poppinsm",
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: Color(COLOR_PRIMARY),
                            ),
                          )
                          : Row(
                            children: [
                              Text(
                                "${amountShow(amount: productModel.disPrice.toString())}",
                                style: TextStyle(
                                  fontFamily: "Poppinsm",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(COLOR_PRIMARY),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${amountShow(amount: productModel.price.toString())}",
                                style: const TextStyle(
                                  fontFamily: "Poppinsm",
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
