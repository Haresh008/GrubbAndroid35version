import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/AttributesModel.dart';
import 'package:foodie_customer/model/FavouriteItemModel.dart';
import 'package:foodie_customer/model/ItemAttributes.dart';
import 'package:foodie_customer/model/ProductModel.dart';
import 'package:foodie_customer/model/Ratingmodel.dart';
import 'package:foodie_customer/model/ReviewAttributeModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/model/variant_info.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/Indicator.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/auth/AuthScreen.dart';
import 'package:foodie_customer/ui/cartScreen/CartScreen.dart';
import 'package:foodie_customer/ui/container/ContainerScreen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/newVendorProductsScreen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/review.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Grocery_ProductsDetialsScreen extends StatefulWidget {
  final ProductModel productModel;
  final VendorModel vendorModel;

  const Grocery_ProductsDetialsScreen({
    Key? key,
    required this.productModel,
    required this.vendorModel,
  }) : super(key: key);

  @override
  _Grocery_ProductsDetialsScreenState createState() =>
      _Grocery_ProductsDetialsScreenState();
}

class _Grocery_ProductsDetialsScreenState
    extends State<Grocery_ProductsDetialsScreen> {
  late CartDatabase cartDatabase;

  String radioItem = '';
  int id = -1;
  List<AddAddonsDemo> lstAddAddonsCustom = [];
  List<AddAddonsDemo> lstTemp = [];
  double priceTemp = 0.0, lastPrice = 0.0;
  int productQnt = 0;

  List<String> productImage = [];

  List<Attributes>? attributes = [];
  List<Variants>? variants = [];

  List<String> selectedVariants = [];
  List<String> selectedIndexVariants = [];
  List<String> selectedIndexArray = [];

  bool isOpen = false;
  bool isPreOrderAvailable = false;

  statusCheck() {
    final now = DateTime.now();
    var day = DateFormat('EEEE', 'en_US').format(now);
    var date = DateFormat('dd-MM-yyyy').format(now);

    widget.vendorModel.workingHours.forEach((element) {
      if (day == element.day.toString()) {
        if (element.timeslot!.isNotEmpty) {
          element.timeslot!.forEach((slot) {
            var start = DateFormat(
              "dd-MM-yyyy HH:mm",
            ).parse("$date ${slot.from}");
            var end = DateFormat("dd-MM-yyyy HH:mm").parse("$date ${slot.to}");

            if (isCurrentDateInRange(start, end)) {
              setState(() {
                print("ani dar aviu ke kem");
                isOpen = true;
                isPreOrderAvailable =
                    false; // Live slot available, so pre-order false
                if (widget.vendorModel.isTempClose) {
                  isOpen = false;
                }
              });
            }
          });
        } else {
          setState(() {
            isOpen = false;
            isPreOrderAvailable = false; // No slot, so no pre-order
          });
        }
      }
    });
  }

  bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
    print(startDate);
    print(endDate);
    final currentDate = DateTime.now();
    print("date shu ave che ${currentDate}");
    print(
      "date shu ave che ${currentDate.isAfter(startDate) && currentDate.isBefore(endDate)}",
    );
    isPreOrderAvailable =
        currentDate.isAfter(startDate) && currentDate.isBefore(endDate)
            ? false
            : true;
    print("date isPreOrderAvailable ${isPreOrderAvailable}");
    return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  }

  Future<List<String>> getresturantcities() async {
    print('athata che');

    // Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Settings document fetch karo
    DocumentSnapshot documentSnapshot =
        await firestore
            .collection('coupons')
            .doc('${widget.vendorModel.auto_apply_coupon_id}')
            .get();
    if (documentSnapshot.exists) {
      List<String> cities = List<String>.from(documentSnapshot.get('cities'));
      setState(() {
        Timestamp expiresAt = documentSnapshot['expiresAt'];
        Timestamp startsAt = documentSnapshot['startsAt'];
        isEnabled = documentSnapshot['isEnabled'];
        DateTime now = DateTime.now();
        // Convert to DateTime
        DateTime expiresAtDateTime = expiresAt.toDate();
        DateTime startsAtDateTime = startsAt.toDate();
        print('Expires At (DateTime): $expiresAtDateTime');
        print('Expires At (DateTime): $startsAtDateTime');
        print('Expires At (DateTime): $isEnabled');
        isMyTime =
            now.isAfter(startsAtDateTime) && now.isBefore(expiresAtDateTime);
      });
      widget.vendorModel.auto_apply == true
          ? getproductdicountprice()
          : print("call nay thay");
      print("Is My Time: $isMyTime");
      print("citiescitiedfdsfsdfsfsfsdfdsffs${cities}");

      return cities;
    } else {
      // Default empty list return karo jya data na male
      return [];
    }
  }

  String? city1;
  bool cityaveche = false;
  bool isMyTime = false;
  bool isEnabled = false;

  Future<void> getCityrestaurantcity() async {
    try {
      // Latitude ane longitude thi location details melvo
      List<Placemark> placemarks = await placemarkFromCoordinates(
        MyAppState.currentUser?.userID == null ||
                MyAppState.currentUser?.userID == ""
            ? MyAppState.selectedPosotion.latitude
            : MyAppState.currentUser?.location.latitude == null ||
                MyAppState.currentUser?.location.latitude == 0.01
            ? MyAppState.selectedPosotion.latitude
            : double.parse(
              (MyAppState.currentUser?.location.latitude).toString(),
            ),
        MyAppState.currentUser?.userID == null ||
                MyAppState.currentUser?.userID == ""
            ? MyAppState.selectedPosotion.longitude
            : MyAppState.currentUser?.location.longitude == null ||
                MyAppState.currentUser?.location.longitude == 0.01
            ? MyAppState.selectedPosotion.longitude
            : double.parse(
              (MyAppState.currentUser?.location.longitude).toString(),
            ),
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          city1 = place.locality ?? 'City not found';
        });
        print('vendorcity ave che: $city1');
        List<String> cities = await getresturantcities();
        if (cities.contains(city1)) {
          setState(() {
            cityaveche = true;
          });
          widget.vendorModel.auto_apply == true
              ? getproductdicountprice()
              : print("call nay thay");
          print(
            'restaurant valu ave che  "$city1" is available in the Firestore cities.',
          );
        } else {
          setState(() {
            cityaveche = false;
          });
          widget.vendorModel.auto_apply == true
              ? getproductdicountprice()
              : print("call nay thay");
          print(
            'restaurant valu ave che "$city1" is not available in the Firestore cities.',
          );
        }
      } else {
        print('No location found for the given coordinates.');
        setState(() {
          cityaveche = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        cityaveche = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire();
    print("product Id ---->${widget.productModel}");
    print("product Id ---->${widget.productModel.name}");
    // productQnt = widget.productModel.quantity;
    widget.vendorModel.auto_apply == true
        ? getCityrestaurantcity()
        : print("call nay thay");
    getAddOnsData();
    statusCheck();
    if (widget.productModel.itemAttributes != null) {
      attributes = widget.productModel.itemAttributes!.attributes;
      variants = widget.productModel.itemAttributes!.variants;

      if (attributes!.isNotEmpty) {
        for (var element in attributes!) {
          if (element.attributeOptions!.isNotEmpty) {
            selectedVariants.add(
              attributes![attributes!.indexOf(element)].attributeOptions![0]
                  .toString(),
            );
            selectedIndexVariants.add(
              '${attributes!.indexOf(element)} _${attributes![0].attributeOptions![0].toString()}',
            );
            selectedIndexArray.add('${attributes!.indexOf(element)}_0');
          }
        }
      }

      if (variants!
          .where((element) => element.variantSku == selectedVariants.join('-'))
          .isNotEmpty) {
        widget.productModel.price =
            variants!
                .where(
                  (element) => element.variantSku == selectedVariants.join('-'),
                )
                .first
                .variantPrice ??
            '0';
        widget.productModel.disPrice = '0';
      }
    }
    getData();
  }

  List<ReviewAttributeModel> reviewAttributeList = [];

  List<ProductModel> productList = [];
  List<ProductModel> storeProductList = [];

  bool showLoader = true;
  List<FavouriteItemModel> lstFav = [];

  List<AttributesModel> attributesList = [];
  List<RatingModel> reviewList = [];

  getData() async {
    if (MyAppState.currentUser != null) {
      await FireStoreUtils()
          .getFavouritesProductList(MyAppState.currentUser!.userID)
          .then((value) {
            setState(() {
              lstFav = value;
            });
          });
    }

    if (widget.productModel.photos.isEmpty) {
      productImage.add(widget.productModel.photo);
    }
    for (var element in widget.productModel.photos) {
      productImage.add(element);
    }

    for (var element in variants!) {
      productImage.add(element.variantImage.toString());
    }

    await FireStoreUtils.getAttributes().then((value) {
      setState(() {
        attributesList = value;
      });
    });

    await FireStoreUtils.getAllReviewAttributes().then((value) {
      reviewAttributeList = value;
    });

    await FireStoreUtils().getReviewList(widget.productModel.id).then((value) {
      setState(() {
        reviewList = value;
      });
    });

    SharedPreferences sp = await SharedPreferences.getInstance();
    String? foodType = sp.getString("foodType") ?? "Delivery".tr();

    await FireStoreUtils.getGroceryProduct(
      widget.productModel.vendorID.toString(),
    ).then((value) {
      if (foodType == "Delivery") {
        for (var element in value) {
          if (element.id != widget.productModel.id &&
              element.takeaway == false) {
            storeProductList.add(element);
          }
        }
      } else {
        for (var element in value) {
          if (element.id != widget.productModel.id) {
            storeProductList.add(element);
          }
        }
      }
      setState(() {});
    });

    await FireStoreUtils.getProductListByCategoryId(
      widget.productModel.categoryID.toString(),
    ).then((value) {
      if (foodType == "Delivery") {
        for (var element in value) {
          if (element.id != widget.productModel.id &&
              element.takeaway == false) {
            productList.add(element);
          }
        }
      } else {
        for (var element in value) {
          if (element.id != widget.productModel.id) {
            productList.add(element);
          }
        }
      }

      setState(() {});
    });

    setState(() {});
  }

  @override
  void didChangeDependencies() {
    cartDatabase = Provider.of<CartDatabase>(context, listen: true);

    cartDatabase.allCartProducts.then((value) {
      final bool _productIsInList = value.any(
        (product) =>
            product.id ==
            widget.productModel.id +
                "~" +
                (variants!
                        .where(
                          (element) =>
                              element.variantSku == selectedVariants.join('-'),
                        )
                        .isNotEmpty
                    ? variants!
                        .where(
                          (element) =>
                              element.variantSku == selectedVariants.join('-'),
                        )
                        .first
                        .variantId
                        .toString()
                    : ""),
      );
      if (_productIsInList) {
        CartProduct element = value.firstWhere(
          (product) =>
              product.id ==
              widget.productModel.id +
                  "~" +
                  (variants!
                          .where(
                            (element) =>
                                element.variantSku ==
                                selectedVariants.join('-'),
                          )
                          .isNotEmpty
                      ? variants!
                          .where(
                            (element) =>
                                element.variantSku ==
                                selectedVariants.join('-'),
                          )
                          .first
                          .variantId
                          .toString()
                      : ""),
        );

        setState(() {
          productQnt = element.quantity;
        });
      } else {
        setState(() {
          productQnt = 0;
        });
      }
    });
    super.didChangeDependencies();
  }

  final PageController _controller = PageController(
    viewportFraction: 1,
    keepPage: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? Colors.black : Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.54,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.50,
                        child: PageView.builder(
                          itemCount: productImage.length,
                          scrollDirection: Axis.horizontal,
                          controller: _controller,
                          onPageChanged: (value) {
                            setState(() {});
                          },
                          allowImplicitScrolling: true,
                          itemBuilder:
                              (context, index) => CachedNetworkImage(
                                imageUrl: getImageVAlidUrl(productImage[index]),
                                imageBuilder:
                                    (context, imageProvider) => Container(
                                      decoration: BoxDecoration(
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
                                      AppGlobal.placeHolderImage!,
                                      fit: BoxFit.fitWidth,
                                    ),
                                fit: BoxFit.contain,
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Indicator(
                          controller: _controller,
                          itemCount: productImage.length,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top:
                      Platform.isIOS
                          ? MediaQuery.of(context).size.height * 0.10
                          : MediaQuery.of(context).size.height * 0.05,
                  left: MediaQuery.of(context).size.width * 0.03,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 20,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top:
                      Platform.isIOS
                          ? MediaQuery.of(context).size.height * 0.10
                          : MediaQuery.of(context).size.height * 0.05,
                  right: MediaQuery.of(context).size.width * 0.03,
                  child: GestureDetector(
                    onTap: () {
                      if (MyAppState.currentUser == null) {
                        push(context, AuthScreen());
                      } else {
                        setState(() {
                          var contain = lstFav.where(
                            (element) =>
                                element.productId == widget.productModel.id,
                          );

                          if (contain.isNotEmpty) {
                            FavouriteItemModel favouriteModel =
                                FavouriteItemModel(
                                  productId: widget.productModel.id,
                                  storeId: widget.vendorModel.id,
                                  userId: MyAppState.currentUser!.userID,
                                );
                            lstFav.removeWhere(
                              (item) =>
                                  item.productId == widget.productModel.id,
                            );
                            FireStoreUtils().removeFavouriteItem(
                              favouriteModel,
                            );
                          } else {
                            FavouriteItemModel favouriteModel =
                                FavouriteItemModel(
                                  productId: widget.productModel.id,
                                  storeId: widget.vendorModel.id,
                                  userId: MyAppState.currentUser!.userID,
                                );
                            FireStoreUtils().setFavouriteStoreItem(
                              favouriteModel,
                            );
                            lstFav.add(favouriteModel);
                          }
                        });
                      }
                    },
                    child:
                        lstFav
                                .where(
                                  (element) =>
                                      element.productId ==
                                      widget.productModel.id,
                                )
                                .isNotEmpty
                            ? Icon(Icons.favorite, color: Color(COLOR_PRIMARY))
                            : Icon(
                              Icons.favorite_border,
                              color:
                                  isDarkMode(context)
                                      ? Colors.white38
                                      : Colors.black38,
                            ),
                  ),
                ),
              ],
            ),
            Container(
              color:
                  isDarkMode(context) ? Colors.black : const Color(0xFFFFFFFF),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.productModel.name +
                                      ' (${widget.productModel.groceryWeight} ${widget.productModel.groceryUnit})',
                                  style: TextStyle(
                                    fontFamily: "Poppinsm",
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              // widget.productModel.disPrice == "" ||
                              //         widget.productModel.disPrice == "0"
                              //     ? Text(
                              //         "${amountShow(amount: widget.productModel.price)}",
                              //         style: TextStyle(
                              //             fontFamily: "Poppinsm",
                              //             letterSpacing: 0.5,
                              //             color: Color(COLOR_PRIMARY)),
                              //       )
                              //     : Row(
                              //         children: [
                              //           Text(
                              //             "${amountShow(amount: widget.productModel.disPrice)}",
                              //             style: TextStyle(
                              //               fontFamily: "Poppinsm",
                              //               fontWeight: FontWeight.bold,
                              //               color: Color(COLOR_PRIMARY),
                              //             ),
                              //           ),
                              //           const SizedBox(
                              //             width: 2,
                              //           ),
                              //           Text(
                              //             '${amountShow(amount: widget.productModel.price)}',
                              //             style: const TextStyle(
                              //                 fontFamily: "Poppinsm",
                              //                 fontWeight: FontWeight.bold,
                              //                 color: Colors.grey,
                              //                 decoration:
                              //                     TextDecoration.lineThrough),
                              //           ),
                              //         ],
                              //       ),
                              widget.productModel.disPrice == "" ||
                                      widget.productModel.disPrice == "0"
                                  ? isEnabled &&
                                          cityaveche &&
                                          isMyTime &&
                                          widget.vendorModel.auto_apply
                                      ? Text(
                                        "${amountShow(amount: finalprice.toString())}",
                                        style: TextStyle(
                                          fontFamily: "Poppinsm",
                                          letterSpacing: 0.5,
                                          color: Color(COLOR_PRIMARY),
                                        ),
                                      )
                                      : Text(
                                        "${amountShow(amount: widget.productModel.price)}",
                                        style: TextStyle(
                                          fontFamily: "Poppinsm",
                                          letterSpacing: 0.5,
                                          color: Color(COLOR_PRIMARY),
                                        ),
                                      )
                                  : isEnabled &&
                                      cityaveche &&
                                      isMyTime &&
                                      widget.vendorModel.auto_apply
                                  ? Row(
                                    children: [
                                      Text(
                                        "${amountShow(amount: finalprice.toString())}",
                                        style: TextStyle(
                                          fontFamily: "Poppinsm",
                                          fontWeight: FontWeight.bold,
                                          color: Color(COLOR_PRIMARY),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${amountShow(amount: widget.productModel.price)}',
                                        style: const TextStyle(
                                          fontFamily: "Poppinsm",
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Row(
                                    children: [
                                      Text(
                                        "${amountShow(amount: widget.productModel.disPrice)}",
                                        style: TextStyle(
                                          fontFamily: "Poppinsm",
                                          fontWeight: FontWeight.bold,
                                          color: Color(COLOR_PRIMARY),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${amountShow(amount: widget.productModel.price)}',
                                        style: const TextStyle(
                                          fontFamily: "Poppinsm",
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                          bottomLeft: Radius.circular(10),
                                          bottomRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              widget
                                                          .productModel
                                                          .reviewsCount !=
                                                      0
                                                  ? (widget
                                                              .productModel
                                                              .reviewsSum /
                                                          widget
                                                              .productModel
                                                              .reviewsCount)
                                                      .toStringAsFixed(1)
                                                  : 0.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.star, size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${widget.productModel.reviewsCount} " +
                                          "Review".tr(),
                                      style: TextStyle(
                                        fontFamily: "Poppinsm",
                                        color:
                                            isDarkMode(context)
                                                ? const Color(0xffffffff)
                                                : const Color(0xff000000),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isPreOrderAvailable || isOpen
                                  ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                if (productQnt != 0) {
                                                  productQnt--;
                                                }
                                                if (productQnt >= 0) {
                                                  removetocard(
                                                    widget.productModel,
                                                    true,
                                                  );
                                                }
                                              });
                                            },
                                            icon: Image(
                                              image: const AssetImage(
                                                "assets/images/minus.png",
                                              ),
                                              color: Color(COLOR_PRIMARY),
                                              height: 26,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            productQnt.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: "Poppinsm",
                                              color: Color(COLOR_PRIMARY),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          IconButton(
                                            onPressed:
                                                productQnt == 0
                                                    ? () {
                                                      if (MyAppState
                                                              .currentUser ==
                                                          null) {
                                                        push(
                                                          context,
                                                          AuthScreen(),
                                                        );
                                                      } else {
                                                        setState(() {
                                                          if (variants!
                                                              .where(
                                                                (element) =>
                                                                    element
                                                                        .variantSku ==
                                                                    selectedVariants
                                                                        .join(
                                                                          '-',
                                                                        ),
                                                              )
                                                              .isNotEmpty) {
                                                            if (int.parse(
                                                                      variants!
                                                                          .where(
                                                                            (
                                                                              element,
                                                                            ) =>
                                                                                element.variantSku ==
                                                                                selectedVariants.join(
                                                                                  '-',
                                                                                ),
                                                                          )
                                                                          .first
                                                                          .variantQuantity
                                                                          .toString(),
                                                                    ) >=
                                                                    1 ||
                                                                int.parse(
                                                                      variants!
                                                                          .where(
                                                                            (
                                                                              element,
                                                                            ) =>
                                                                                element.variantSku ==
                                                                                selectedVariants.join(
                                                                                  '-',
                                                                                ),
                                                                          )
                                                                          .first
                                                                          .variantQuantity
                                                                          .toString(),
                                                                    ) ==
                                                                    -1) {
                                                              VariantInfo?
                                                              variantInfo =
                                                                  VariantInfo();
                                                              widget
                                                                      .productModel
                                                                      .price =
                                                                  variants!
                                                                      .where(
                                                                        (
                                                                          element,
                                                                        ) =>
                                                                            element.variantSku ==
                                                                            selectedVariants.join(
                                                                              '-',
                                                                            ),
                                                                      )
                                                                      .first
                                                                      .variantPrice ??
                                                                  '0';
                                                              widget
                                                                  .productModel
                                                                  .disPrice = '0';

                                                              Map<
                                                                String,
                                                                String
                                                              >
                                                              mapData = Map();
                                                              for (var element
                                                                  in attributes!) {
                                                                mapData.addEntries([
                                                                  MapEntry(
                                                                    attributesList
                                                                        .where(
                                                                          (
                                                                            element1,
                                                                          ) =>
                                                                              element.attributesId ==
                                                                              element1.id,
                                                                        )
                                                                        .first
                                                                        .title
                                                                        .toString(),
                                                                    selectedVariants[attributes!
                                                                        .indexOf(
                                                                          element,
                                                                        )],
                                                                  ),
                                                                ]);
                                                                setState(() {});
                                                              }

                                                              variantInfo = VariantInfo(
                                                                variantPrice:
                                                                    variants!
                                                                        .where(
                                                                          (
                                                                            element,
                                                                          ) =>
                                                                              element.variantSku ==
                                                                              selectedVariants.join(
                                                                                '-',
                                                                              ),
                                                                        )
                                                                        .first
                                                                        .variantPrice ??
                                                                    '0',
                                                                variantSku:
                                                                    selectedVariants
                                                                        .join(
                                                                          '-',
                                                                        ),
                                                                variantOptions:
                                                                    mapData,
                                                                variantImage:
                                                                    variants!
                                                                        .where(
                                                                          (
                                                                            element,
                                                                          ) =>
                                                                              element.variantSku ==
                                                                              selectedVariants.join(
                                                                                '-',
                                                                              ),
                                                                        )
                                                                        .first
                                                                        .variantImage ??
                                                                    '',
                                                                variantId:
                                                                    variants!
                                                                        .where(
                                                                          (
                                                                            element,
                                                                          ) =>
                                                                              element.variantSku ==
                                                                              selectedVariants.join(
                                                                                '-',
                                                                              ),
                                                                        )
                                                                        .first
                                                                        .variantId ??
                                                                    '0',
                                                              );

                                                              widget
                                                                      .productModel
                                                                      .variantInfo =
                                                                  variantInfo;

                                                              setState(() {
                                                                productQnt = 1;
                                                              });
                                                              addtocard(
                                                                widget
                                                                    .productModel,
                                                                true,
                                                              );
                                                            } else {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    "Item out of stock’"
                                                                        .tr(),
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          } else {
                                                            if (widget
                                                                        .productModel
                                                                        .quantity >
                                                                    productQnt ||
                                                                widget
                                                                        .productModel
                                                                        .quantity ==
                                                                    -1) {
                                                              setState(() {
                                                                productQnt = 1;
                                                              });
                                                              addtocard(
                                                                widget
                                                                    .productModel,
                                                                true,
                                                              );
                                                            } else {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    "Item out of stock’"
                                                                        .tr(),
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          }
                                                        });
                                                      }
                                                    }
                                                    : () {
                                                      setState(() {
                                                        if (variants!
                                                            .where(
                                                              (element) =>
                                                                  element
                                                                      .variantSku ==
                                                                  selectedVariants
                                                                      .join(
                                                                        '-',
                                                                      ),
                                                            )
                                                            .isNotEmpty) {
                                                          if (int.parse(
                                                                    variants!
                                                                        .where(
                                                                          (
                                                                            element,
                                                                          ) =>
                                                                              element.variantSku ==
                                                                              selectedVariants.join(
                                                                                '-',
                                                                              ),
                                                                        )
                                                                        .first
                                                                        .variantQuantity
                                                                        .toString(),
                                                                  ) >
                                                                  productQnt ||
                                                              int.parse(
                                                                    variants!
                                                                        .where(
                                                                          (
                                                                            element,
                                                                          ) =>
                                                                              element.variantSku ==
                                                                              selectedVariants.join(
                                                                                '-',
                                                                              ),
                                                                        )
                                                                        .first
                                                                        .variantQuantity
                                                                        .toString(),
                                                                  ) ==
                                                                  -1) {
                                                            VariantInfo?
                                                            variantInfo =
                                                                VariantInfo();
                                                            Map<String, String>
                                                            mapData = Map();
                                                            for (var element
                                                                in attributes!) {
                                                              mapData.addEntries([
                                                                MapEntry(
                                                                  attributesList
                                                                      .where(
                                                                        (
                                                                          element1,
                                                                        ) =>
                                                                            element.attributesId ==
                                                                            element1.id,
                                                                      )
                                                                      .first
                                                                      .title
                                                                      .toString(),
                                                                  selectedVariants[attributes!
                                                                      .indexOf(
                                                                        element,
                                                                      )],
                                                                ),
                                                              ]);
                                                              setState(() {});
                                                            }

                                                            variantInfo = VariantInfo(
                                                              variantPrice:
                                                                  variants!
                                                                      .where(
                                                                        (
                                                                          element,
                                                                        ) =>
                                                                            element.variantSku ==
                                                                            selectedVariants.join(
                                                                              '-',
                                                                            ),
                                                                      )
                                                                      .first
                                                                      .variantPrice ??
                                                                  '0',
                                                              variantSku:
                                                                  selectedVariants
                                                                      .join(
                                                                        '-',
                                                                      ),
                                                              variantOptions:
                                                                  mapData,
                                                              variantImage:
                                                                  variants!
                                                                      .where(
                                                                        (
                                                                          element,
                                                                        ) =>
                                                                            element.variantSku ==
                                                                            selectedVariants.join(
                                                                              '-',
                                                                            ),
                                                                      )
                                                                      .first
                                                                      .variantImage ??
                                                                  '',
                                                              variantId:
                                                                  variants!
                                                                      .where(
                                                                        (
                                                                          element,
                                                                        ) =>
                                                                            element.variantSku ==
                                                                            selectedVariants.join(
                                                                              '-',
                                                                            ),
                                                                      )
                                                                      .first
                                                                      .variantId ??
                                                                  '0',
                                                            );

                                                            widget
                                                                    .productModel
                                                                    .variantInfo =
                                                                variantInfo;

                                                            setState(() {
                                                              productQnt++;
                                                            });

                                                            // widget.productModel.price = widget.productModel.disPrice == "" || widget.productModel.disPrice == "0" ? (widget.productModel.price) : (widget.productModel.disPrice!);
                                                            addtocard(
                                                              widget
                                                                  .productModel,
                                                              true,
                                                            );
                                                          } else {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  "Item out of stock’"
                                                                      .tr(),
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        } else {
                                                          if (widget
                                                                      .productModel
                                                                      .quantity >
                                                                  productQnt ||
                                                              widget
                                                                      .productModel
                                                                      .quantity ==
                                                                  -1) {
                                                            if (productQnt !=
                                                                0) {
                                                              productQnt++;
                                                            }
                                                            // widget.productModel.price = widget.productModel.disPrice == "" || widget.productModel.disPrice == "0" ? (widget.productModel.price) : (widget.productModel.disPrice!);
                                                            addtocard(
                                                              widget
                                                                  .productModel,
                                                              true,
                                                            );
                                                          } else {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  "Item out of stock’"
                                                                      .tr(),
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      });
                                                    },
                                            icon: Image(
                                              image: const AssetImage(
                                                "assets/images/plus.png",
                                              ),
                                              color: Color(COLOR_PRIMARY),
                                              height: 26,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                  : Container(),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          child: CachedNetworkImage(
                                            height: 40,
                                            width: 40,
                                            imageUrl: getImageVAlidUrl(
                                              widget.vendorModel.photo,
                                            ),
                                            imageBuilder:
                                                (
                                                  context,
                                                  imageProvider,
                                                ) => Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
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
                                                            15,
                                                          ),
                                                      child: Image.network(
                                                        placeholderImage,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        InkWell(
                                          onTap: () async {
                                            push(
                                              context,
                                              NewVendorProductsScreen(
                                                vendorModel: widget.vendorModel,
                                              ),
                                            );
                                          },
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.vendorModel.title,
                                                style: TextStyle(
                                                  color: Color(COLOR_PRIMARY),
                                                ),
                                              ),
                                              getTextStatus(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "packing Charges".tr(),
                                            // style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Color(COLOR_PRIMARY),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            widget
                                                            .productModel
                                                            .packingcharges ==
                                                        "" ||
                                                    widget
                                                            .productModel
                                                            .packingcharges ==
                                                        null
                                                ? "0.0"
                                                : widget
                                                    .productModel
                                                    .packingcharges,
                                            style: TextStyle(
                                              fontFamily: "Poppinsl",
                                              color:
                                                  isDarkMode(context)
                                                      ? const Color(0xffC6C4C4)
                                                      : const Color(0xff5E5C5C),
                                            ),
                                          ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Details".tr(),
                            // style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDarkMode(context)
                                      ? const Color(0xffffffff)
                                      : const Color(0xff000000),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.productModel.description,
                            style: TextStyle(
                              fontFamily: "Poppinsl",
                              color:
                                  isDarkMode(context)
                                      ? const Color(0xffC6C4C4)
                                      : const Color(0xff5E5C5C),
                            ),
                          ),
                        ],
                      ),
                    ),

                    attributes!.isEmpty
                        ? Container()
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.builder(
                              itemCount: attributes!.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                String title = "";
                                for (var element in attributesList) {
                                  if (attributes![index].attributesId ==
                                      element.id) {
                                    title = element.title.toString();
                                  }
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: Wrap(
                                        spacing: 6.0,
                                        runSpacing: 6.0,
                                        children:
                                            List.generate(
                                              attributes![index]
                                                  .attributeOptions!
                                                  .length,
                                              (i) {
                                                return InkWell(
                                                  onTap: () async {
                                                    setState(() {
                                                      if (selectedIndexVariants
                                                          .where(
                                                            (element) => element
                                                                .contains(
                                                                  '$index _',
                                                                ),
                                                          )
                                                          .isEmpty) {
                                                        selectedVariants.insert(
                                                          index,
                                                          attributes![index]
                                                              .attributeOptions![i]
                                                              .toString(),
                                                        );
                                                        selectedIndexVariants.add(
                                                          '$index _${attributes![index].attributeOptions![i].toString()}',
                                                        );
                                                        selectedIndexArray.add(
                                                          '${index}_$i',
                                                        );
                                                      } else {
                                                        selectedIndexArray.remove(
                                                          '${index}_${attributes![index].attributeOptions?.indexOf(selectedIndexVariants.where((element) => element.contains('$index _')).first.replaceAll('$index _', ''))}',
                                                        );
                                                        selectedVariants
                                                            .removeAt(index);
                                                        selectedIndexVariants.remove(
                                                          selectedIndexVariants
                                                              .where(
                                                                (
                                                                  element,
                                                                ) => element
                                                                    .contains(
                                                                      '$index _',
                                                                    ),
                                                              )
                                                              .first,
                                                        );
                                                        selectedVariants.insert(
                                                          index,
                                                          attributes![index]
                                                              .attributeOptions![i]
                                                              .toString(),
                                                        );
                                                        selectedIndexVariants.add(
                                                          '$index _${attributes![index].attributeOptions![i].toString()}',
                                                        );
                                                        selectedIndexArray.add(
                                                          '${index}_$i',
                                                        );
                                                      }
                                                    });

                                                    await cartDatabase.allCartProducts.then((
                                                      value,
                                                    ) {
                                                      final bool
                                                      _productIsInList = value.any(
                                                        (product) =>
                                                            product.id ==
                                                            widget
                                                                    .productModel
                                                                    .id +
                                                                "~" +
                                                                (variants!
                                                                        .where(
                                                                          (
                                                                            element,
                                                                          ) =>
                                                                              element.variantSku ==
                                                                              selectedVariants.join(
                                                                                '-',
                                                                              ),
                                                                        )
                                                                        .isNotEmpty
                                                                    ? variants!
                                                                        .where(
                                                                          (
                                                                            element,
                                                                          ) =>
                                                                              element.variantSku ==
                                                                              selectedVariants.join(
                                                                                '-',
                                                                              ),
                                                                        )
                                                                        .first
                                                                        .variantId
                                                                        .toString()
                                                                    : ""),
                                                      );
                                                      if (_productIsInList) {
                                                        CartProduct
                                                        element = value.firstWhere(
                                                          (product) =>
                                                              product.id ==
                                                              widget
                                                                      .productModel
                                                                      .id +
                                                                  "~" +
                                                                  (variants!
                                                                          .where(
                                                                            (
                                                                              element,
                                                                            ) =>
                                                                                element.variantSku ==
                                                                                selectedVariants.join(
                                                                                  '-',
                                                                                ),
                                                                          )
                                                                          .isNotEmpty
                                                                      ? variants!
                                                                          .where(
                                                                            (
                                                                              element,
                                                                            ) =>
                                                                                element.variantSku ==
                                                                                selectedVariants.join(
                                                                                  '-',
                                                                                ),
                                                                          )
                                                                          .first
                                                                          .variantId
                                                                          .toString()
                                                                      : ""),
                                                        );

                                                        setState(() {
                                                          productQnt =
                                                              element.quantity;
                                                        });
                                                      } else {
                                                        setState(() {
                                                          productQnt = 0;
                                                        });
                                                      }
                                                    });

                                                    if (variants!
                                                        .where(
                                                          (element) =>
                                                              element
                                                                  .variantSku ==
                                                              selectedVariants
                                                                  .join('-'),
                                                        )
                                                        .isNotEmpty) {
                                                      widget
                                                          .productModel
                                                          .price = variants!
                                                              .where(
                                                                (element) =>
                                                                    element
                                                                        .variantSku ==
                                                                    selectedVariants
                                                                        .join(
                                                                          '-',
                                                                        ),
                                                              )
                                                              .first
                                                              .variantPrice ??
                                                          '0';
                                                      widget
                                                          .productModel
                                                          .disPrice = '0';
                                                    }
                                                  },
                                                  child: _buildChip(
                                                    attributes![index]
                                                        .attributeOptions![i]
                                                        .toString(),
                                                    i,
                                                    selectedVariants.contains(
                                                          attributes![index]
                                                              .attributeOptions![i]
                                                              .toString(),
                                                        )
                                                        ? true
                                                        : false,
                                                  ),
                                                );
                                              },
                                            ).toList(),
                                      ),
                                    ),
                                    // ListView.builder(
                                    //   itemCount: attributes![index].attributeOptions!.length,
                                    //   physics: const NeverScrollableScrollPhysics(),
                                    //   shrinkWrap: true,
                                    //   padding: EdgeInsets.zero,
                                    //   itemBuilder: (context, i) {
                                    //     return Wrap(
                                    //       spacing: 6.0,
                                    //       runSpacing: 6.0,
                                    //       children: List.generate(
                                    //         attributes![index].attributeOptions!.length,
                                    //         (i) {
                                    //           return InkWell(onTap: () {
                                    //             setState(() {
                                    //               if (selectedIndexVariants.where((element) => element.contains('$index _')).isEmpty) {
                                    //                 selectedVariants.insert(index, attributes![index].attributeOptions![i].toString());
                                    //                 selectedIndexVariants.add('$index _${attributes![index].attributeOptions![i].toString()}');
                                    //                 selectedIndexArray.add('${index}_$i');
                                    //               } else {
                                    //                 selectedIndexArray.remove(
                                    //                     '${index}_${attributes![index].attributeOptions?.indexOf(selectedIndexVariants.where((element) => element.contains('$index _')).first.replaceAll('$index _', ''))}');
                                    //                 selectedVariants.removeAt(index);
                                    //                 selectedIndexVariants.remove(selectedIndexVariants.where((element) => element.contains('$index _')).first);
                                    //                 selectedVariants.insert(index, attributes![index].attributeOptions![i].toString());
                                    //                 selectedIndexVariants.add('$index _${attributes![index].attributeOptions![i].toString()}');
                                    //                 selectedIndexArray.add('${index}_$i');
                                    //               }
                                    //             });
                                    //             print('object ==> ${selectedVariants.toString()}');
                                    //             print('object ==> ${selectedIndexVariants.toString()}');
                                    //             print('object ==> ${selectedIndexArray.toString()}');
                                    //
                                    //             if (variants!.where((element) => element.variantSku == selectedVariants.join('-')).isNotEmpty) {
                                    //               widget.productModel.price =
                                    //                   variants!.where((element) => element.variantSku == selectedVariants.join('-')).first.variantPrice ?? '0';
                                    //               widget.productModel.disPrice =
                                    //                   variants!.where((element) => element.variantSku == selectedVariants.join('-')).first.variantPrice ?? '0';
                                    //             }
                                    //           }, child: _buildChip(attributes![index].attributeOptions![i].toString(), i,
                                    //           selectedVariants.contains(attributes![index].attributeOptions![i].toString()) ? true : false));
                                    //         },
                                    //       ).toList(),
                                    //     );
                                    //     // return Padding(
                                    //     //   padding: const EdgeInsets.symmetric(horizontal: 10),
                                    //     //   child: Row(
                                    //     //     children: [
                                    //     //       Expanded(child: Text(attributes![index].attributeOptions![i].toString())),
                                    //     //       Radio(
                                    //     //         visualDensity: const VisualDensity(horizontal: VisualDensity.minimumDensity, vertical: VisualDensity.minimumDensity),
                                    //     //         value: attributes![index].attributeOptions![i].toString(),
                                    //     //         groupValue: selectedVariants[index],
                                    //     //         activeColor: Color(COLOR_PRIMARY),
                                    //     //         onChanged: (value) {
                                    //     //           setState(() {
                                    //     //             if (selectedIndexVariants.where((element) => element.contains('$index _')).isEmpty) {
                                    //     //               selectedVariants.insert(index, attributes![index].attributeOptions![i].toString());
                                    //     //               selectedIndexVariants.add('$index _${attributes![index].attributeOptions![i].toString()}');
                                    //     //               selectedIndexArray.add('${index}_$i');
                                    //     //             } else {
                                    //     //               selectedIndexArray.remove(
                                    //     //                   '${index}_${attributes![index].attributeOptions?.indexOf(selectedIndexVariants.where((element) => element.contains('$index _')).first.replaceAll('$index _', ''))}');
                                    //     //               selectedVariants.removeAt(index);
                                    //     //               selectedIndexVariants.remove(selectedIndexVariants.where((element) => element.contains('$index _')).first);
                                    //     //               selectedVariants.insert(index, attributes![index].attributeOptions![i].toString());
                                    //     //               selectedIndexVariants.add('$index _${attributes![index].attributeOptions![i].toString()}');
                                    //     //               selectedIndexArray.add('${index}_$i');
                                    //     //             }
                                    //     //           });
                                    //     //           print('object ==> ${selectedVariants.toString()}');
                                    //     //           print('object ==> ${selectedIndexVariants.toString()}');
                                    //     //           print('object ==> ${selectedIndexArray.toString()}');
                                    //     //
                                    //     //           if (variants!.where((element) => element.variantSku == selectedVariants.join('-')).isNotEmpty) {
                                    //     //             widget.productModel.price =
                                    //     //                 variants!.where((element) => element.variantSku == selectedVariants.join('-')).first.variantPrice ?? '0';
                                    //     //             widget.productModel.disPrice =
                                    //     //                 variants!.where((element) => element.variantSku == selectedVariants.join('-')).first.variantPrice ?? '0';
                                    //     //           }
                                    //     //         },
                                    //     //       ),
                                    //     //     ],
                                    //     //   ),
                                    //     // );
                                    //   },
                                    // ),
                                    // Padding(
                                    //   padding: const EdgeInsets.symmetric(horizontal: 15),
                                    //   child: Wrap(
                                    //     spacing: 6.0,
                                    //     runSpacing: 6.0,
                                    //     children: List.generate(
                                    //       attributes![index].attributeOptions!.length,
                                    //       (i) {
                                    //         return InkWell(
                                    //             onTap: () {
                                    //
                                    //             },
                                    //             child: _buildChip(attributes![index].attributeOptions![i].toString(), i,
                                    //                 selectedVariants.contains(attributes![index].attributeOptions![i].toString()) ? true : false));
                                    //       },
                                    //     ).toList(),
                                    //   ),
                                    // ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    //   child: Card(
                    //       color: isDarkMode(context) ? const Color(DARK_COLOR) : const Color(0xffF2F4F6),
                    //       // Color(0XFFF9FAFE),
                    //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    //       child: Padding(
                    //           padding: const EdgeInsets.only(top: 10, right: 20, left: 20, bottom: 10),
                    //           child: Row(
                    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //             children: [
                    //               Column(
                    //                 children: [
                    //                   Text(
                    //                     widget.productModel.calories.toString(),
                    //                     style: const TextStyle(fontSize: 20),
                    //                   ),
                    //                   const SizedBox(
                    //                     height: 8,
                    //                   ),
                    //                   Text("kcal".tr(), style: const TextStyle(fontSize: 16, fontFamily: "Poppinsl"))
                    //                 ],
                    //               ),
                    //               Column(
                    //                 children: [
                    //                   Text(widget.productModel.grams.toString(), style: const TextStyle(fontSize: 20)),
                    //                   const SizedBox(
                    //                     height: 8,
                    //                   ),
                    //                   Text("grams".tr(), style: const TextStyle(fontSize: 16, fontFamily: "Poppinsl"))
                    //                 ],
                    //               ),
                    //               Column(
                    //                 children: [
                    //                   Text(widget.productModel.proteins.toString(), style: const TextStyle(fontSize: 20)),
                    //                   const SizedBox(
                    //                     height: 8,
                    //                   ),
                    //                   Text("proteins".tr(), style: const TextStyle(fontSize: 16, fontFamily: "Poppinsl"))
                    //                 ],
                    //               ),
                    //               Column(
                    //                 children: [
                    //                   Text(widget.productModel.fats.toString(), style: const TextStyle(fontSize: 20)),
                    //                   const SizedBox(
                    //                     height: 8,
                    //                   ),
                    //                   Text("fats".tr(), style: const TextStyle(fontSize: 16, fontFamily: "Poppinsl"))
                    //                 ],
                    //               )
                    //             ],
                    //           ))),
                    // ),
                    lstAddAddonsCustom.isEmpty
                        ? Container()
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              child: Text(
                                "Add Ons (Optional)".tr(),
                                style: TextStyle(
                                  fontFamily: "Poppinsm",
                                  fontSize: 16,
                                  color:
                                      isDarkMode(context)
                                          ? const Color(0xffffffff)
                                          : const Color(0xff000000),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              child: ListView.builder(
                                itemCount: lstAddAddonsCustom.length,
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(
                                      top: 15,
                                      bottom: 15,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          lstAddAddonsCustom[index].name!,
                                          style: TextStyle(
                                            fontFamily: "Poppinsl",
                                            color:
                                                isDarkMode(context)
                                                    ? const Color(0xffC6C4C4)
                                                    : const Color(0xff5E5C5C),
                                          ),
                                        ),
                                        const Expanded(child: SizedBox()),
                                        Text(
                                          amountShow(
                                            amount:
                                                lstAddAddonsCustom[index]
                                                    .price!,
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "Poppinsm",
                                            color: Color(COLOR_PRIMARY),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              lstAddAddonsCustom[index]
                                                      .isCheck =
                                                  !lstAddAddonsCustom[index]
                                                      .isCheck;
                                              if (variants!
                                                  .where(
                                                    (element) =>
                                                        element.variantSku ==
                                                        selectedVariants.join(
                                                          '-',
                                                        ),
                                                  )
                                                  .isNotEmpty) {
                                                VariantInfo? variantInfo =
                                                    VariantInfo();
                                                Map<String, String> mapData =
                                                    Map();
                                                for (var element
                                                    in attributes!) {
                                                  mapData.addEntries([
                                                    MapEntry(
                                                      attributesList
                                                          .where(
                                                            (element1) =>
                                                                element
                                                                    .attributesId ==
                                                                element1.id,
                                                          )
                                                          .first
                                                          .title
                                                          .toString(),
                                                      selectedVariants[attributes!
                                                          .indexOf(element)],
                                                    ),
                                                  ]);
                                                  setState(() {});
                                                }

                                                variantInfo = VariantInfo(
                                                  variantPrice:
                                                      variants!
                                                          .where(
                                                            (element) =>
                                                                element
                                                                    .variantSku ==
                                                                selectedVariants
                                                                    .join('-'),
                                                          )
                                                          .first
                                                          .variantPrice ??
                                                      '0',
                                                  variantSku: selectedVariants
                                                      .join('-'),
                                                  variantOptions: mapData,
                                                  variantImage:
                                                      variants!
                                                          .where(
                                                            (element) =>
                                                                element
                                                                    .variantSku ==
                                                                selectedVariants
                                                                    .join('-'),
                                                          )
                                                          .first
                                                          .variantImage ??
                                                      '',
                                                  variantId:
                                                      variants!
                                                          .where(
                                                            (element) =>
                                                                element
                                                                    .variantSku ==
                                                                selectedVariants
                                                                    .join('-'),
                                                          )
                                                          .first
                                                          .variantId ??
                                                      '0',
                                                );

                                                widget
                                                    .productModel
                                                    .variantInfo = variantInfo;
                                              }

                                              if (lstAddAddonsCustom[index]
                                                      .isCheck ==
                                                  true) {
                                                AddAddonsDemo
                                                addAddonsDemo = AddAddonsDemo(
                                                  name:
                                                      widget
                                                          .productModel
                                                          .addOnsTitle[index],
                                                  index: index,
                                                  isCheck: true,
                                                  categoryID:
                                                      widget.productModel.id,
                                                  price:
                                                      lstAddAddonsCustom[index]
                                                          .price,
                                                );
                                                lstTemp.add(addAddonsDemo);
                                                saveAddOns(lstTemp);
                                                addtocard(
                                                  widget.productModel,
                                                  false,
                                                );
                                              } else {
                                                var removeIndex = -1;
                                                for (
                                                  int a = 0;
                                                  a < lstTemp.length;
                                                  a++
                                                ) {
                                                  if (lstTemp[a].index ==
                                                          index &&
                                                      lstTemp[a].categoryID ==
                                                          lstAddAddonsCustom[index]
                                                              .categoryID) {
                                                    removeIndex = a;
                                                    break;
                                                  }
                                                }
                                                lstTemp.removeAt(removeIndex);
                                                saveAddOns(lstTemp);
                                                //widget.productModel.price = widget.productModel.disPrice==""||widget.productModel.disPrice=="0"? (widget.productModel.price) :(widget.productModel.disPrice!);
                                                addtocard(
                                                  widget.productModel,
                                                  false,
                                                );
                                              }
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              left: 10,
                                              right: 10,
                                            ),
                                            child: Icon(
                                              !lstAddAddonsCustom[index].isCheck
                                                  ? Icons
                                                      .check_box_outline_blank
                                                  : Icons.check_box,
                                              color:
                                                  isDarkMode(context)
                                                      ? null
                                                      : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                    Visibility(
                      visible: widget.productModel.specification.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Specification".tr(),
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                fontSize: 20,
                                color:
                                    isDarkMode(context)
                                        ? const Color(0xffffffff)
                                        : const Color(0xff000000),
                              ),
                            ),
                          ),
                          widget.productModel.specification.isNotEmpty
                              ? ListView.builder(
                                itemCount:
                                    widget.productModel.specification.length,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.productModel.specification.keys
                                                  .elementAt(index) +
                                              " : ",
                                          style: TextStyle(
                                            color: Colors.black.withOpacity(
                                              0.60,
                                            ),
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          widget
                                              .productModel
                                              .specification
                                              .values
                                              .elementAt(index),
                                          style: TextStyle(
                                            color: Colors.black.withOpacity(
                                              0.90,
                                            ),
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                              : Container(),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: storeProductList.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "More from this store".tr(),
                                    style: TextStyle(
                                      fontFamily: "Poppinsm",
                                      fontSize: 16,
                                      color:
                                          isDarkMode(context)
                                              ? const Color(0xffffffff)
                                              : const Color(0xff000000),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "See All".tr(),
                                    style: TextStyle(
                                      fontFamily: "Poppinsm",
                                      fontSize: 16,
                                      color:
                                          isDarkMode(context)
                                              ? const Color(0xffffffff)
                                              : Color(COLOR_PRIMARY),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.28,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount:
                                    storeProductList.length > 6
                                        ? 6
                                        : storeProductList.length,
                                itemBuilder: (context, index) {
                                  ProductModel productModel =
                                      storeProductList[index];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        VendorModel? vendorModel =
                                            await FireStoreUtils.getVendor(
                                              storeProductList[index].vendorID,
                                            );
                                        if (vendorModel != null) {
                                          push(
                                            context,
                                            Grocery_ProductsDetialsScreen(
                                              vendorModel: vendorModel,
                                              productModel: productModel,
                                            ),
                                          );
                                        }
                                      },
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.38,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isDarkMode(context)
                                                      ? const Color(
                                                        DarkContainerBorderColor,
                                                      )
                                                      : Colors.grey.shade100,
                                              width: 1,
                                            ),
                                            color:
                                                isDarkMode(context)
                                                    ? Color(DarkContainerColor)
                                                    : Colors.white,
                                            boxShadow: [
                                              isDarkMode(context)
                                                  ? const BoxShadow()
                                                  : BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    blurRadius: 5,
                                                  ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: CachedNetworkImage(
                                                    imageUrl: getImageVAlidUrl(
                                                      productModel.photo,
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
                                                              image:
                                                                  imageProvider,
                                                              fit:
                                                                  BoxFit
                                                                      .contain,
                                                            ),
                                                          ),
                                                        ),
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => Center(
                                                          child: CircularProgressIndicator.adaptive(
                                                            valueColor:
                                                                AlwaysStoppedAnimation(
                                                                  Color(
                                                                    COLOR_PRIMARY,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                    errorWidget:
                                                        (
                                                          context,
                                                          url,
                                                          error,
                                                        ) => ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          child: Image.network(
                                                            AppGlobal
                                                                .placeHolderImage!,
                                                            width:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width *
                                                                0.75,
                                                            fit:
                                                                BoxFit
                                                                    .fitHeight,
                                                          ),
                                                        ),
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  productModel.name,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                    fontFamily: "Poppinsm",
                                                    letterSpacing: 0.5,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ).tr(),
                                                const SizedBox(height: 5),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              5,
                                                            ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 5,
                                                              vertical: 2,
                                                            ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              productModel.reviewsCount !=
                                                                      0
                                                                  ? (productModel
                                                                              .reviewsSum /
                                                                          productModel
                                                                              .reviewsCount)
                                                                      .toStringAsFixed(
                                                                        1,
                                                                      )
                                                                  : 0.toString(),
                                                              style: const TextStyle(
                                                                fontFamily:
                                                                    "Poppinsm",
                                                                letterSpacing:
                                                                    0.5,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 3,
                                                            ),
                                                            const Icon(
                                                              Icons.star,
                                                              size: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    productModel.disPrice ==
                                                                "" ||
                                                            productModel
                                                                    .disPrice ==
                                                                "0"
                                                        ? Text(
                                                          "${amountShow(amount: productModel.price)}",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                "Poppinsm",
                                                            letterSpacing: 0.5,
                                                            color: Color(
                                                              COLOR_PRIMARY,
                                                            ),
                                                          ),
                                                        )
                                                        : Column(
                                                          children: [
                                                            Text(
                                                              "${amountShow(amount: productModel.disPrice)}",
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    "Poppinsm",
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                                color: Color(
                                                                  COLOR_PRIMARY,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              '${amountShow(amount: productModel.price)}',
                                                              style: const TextStyle(
                                                                fontFamily:
                                                                    "Poppinsm",
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                                color:
                                                                    Colors.grey,
                                                                decoration:
                                                                    TextDecoration
                                                                        .lineThrough,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  ],
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
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: productList.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "You might want to order".tr(),
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                fontSize: 16,
                                color:
                                    isDarkMode(context)
                                        ? const Color(0xffffffff)
                                        : const Color(0xff000000),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.28,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount:
                                    productList.length > 6
                                        ? 6
                                        : productList.length,
                                itemBuilder: (context, index) {
                                  ProductModel productModel =
                                      productList[index];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        VendorModel? vendorModel =
                                            await FireStoreUtils.getVendor(
                                              productModel.vendorID,
                                            );
                                        if (vendorModel != null) {
                                          push(
                                            context,
                                            Grocery_ProductsDetialsScreen(
                                              vendorModel: vendorModel,
                                              productModel: productModel,
                                            ),
                                          );
                                        }
                                      },
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.38,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isDarkMode(context)
                                                      ? const Color(
                                                        DarkContainerBorderColor,
                                                      )
                                                      : Colors.grey.shade100,
                                              width: 1,
                                            ),
                                            color:
                                                isDarkMode(context)
                                                    ? Color(DarkContainerColor)
                                                    : Colors.white,
                                            boxShadow: [
                                              isDarkMode(context)
                                                  ? const BoxShadow()
                                                  : BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    blurRadius: 5,
                                                  ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: CachedNetworkImage(
                                                    imageUrl: getImageVAlidUrl(
                                                      productModel.photo,
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
                                                              image:
                                                                  imageProvider,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => Center(
                                                          child: CircularProgressIndicator.adaptive(
                                                            valueColor:
                                                                AlwaysStoppedAnimation(
                                                                  Color(
                                                                    COLOR_PRIMARY,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                    errorWidget:
                                                        (
                                                          context,
                                                          url,
                                                          error,
                                                        ) => ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          child: Image.network(
                                                            AppGlobal
                                                                .placeHolderImage!,
                                                            width:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width *
                                                                0.75,
                                                            fit:
                                                                BoxFit
                                                                    .fitHeight,
                                                          ),
                                                        ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  productModel.name,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                    fontFamily: "Poppinsm",
                                                    letterSpacing: 0.5,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ).tr(),
                                                const SizedBox(height: 5),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              5,
                                                            ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 5,
                                                              vertical: 2,
                                                            ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              productModel.reviewsCount !=
                                                                      0
                                                                  ? (productModel
                                                                              .reviewsSum /
                                                                          productModel
                                                                              .reviewsCount)
                                                                      .toStringAsFixed(
                                                                        1,
                                                                      )
                                                                  : 0.toString(),
                                                              style: const TextStyle(
                                                                fontFamily:
                                                                    "Poppinsm",
                                                                letterSpacing:
                                                                    0.5,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 3,
                                                            ),
                                                            const Icon(
                                                              Icons.star,
                                                              size: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    productModel.disPrice ==
                                                                "" ||
                                                            productModel
                                                                    .disPrice ==
                                                                "0"
                                                        ? Text(
                                                          "${amountShow(amount: productModel.price)}",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                "Poppinsm",
                                                            letterSpacing: 0.5,
                                                            color: Color(
                                                              COLOR_PRIMARY,
                                                            ),
                                                          ),
                                                        )
                                                        : Column(
                                                          children: [
                                                            Text(
                                                              "${amountShow(amount: productModel.disPrice)}",
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    "Poppinsm",
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                                color: Color(
                                                                  COLOR_PRIMARY,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              amountShow(
                                                                amount:
                                                                    productModel
                                                                        .price,
                                                              ),
                                                              style: const TextStyle(
                                                                fontFamily:
                                                                    "Poppinsm",
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                                color:
                                                                    Colors.grey,
                                                                decoration:
                                                                    TextDecoration
                                                                        .lineThrough,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  ],
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
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: widget.productModel.reviewAttributes!.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "By feature".tr(),
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                fontSize: 20,
                                color:
                                    isDarkMode(context)
                                        ? const Color(0xffffffff)
                                        : const Color(0xff000000),
                              ),
                            ),
                          ),
                          widget.productModel.reviewAttributes != null
                              ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  itemCount:
                                      widget
                                          .productModel
                                          .reviewAttributes!
                                          .length,
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    ReviewAttributeModel reviewAttribute =
                                        ReviewAttributeModel();
                                    for (var element in reviewAttributeList) {
                                      if (element.id ==
                                          widget
                                              .productModel
                                              .reviewAttributes!
                                              .keys
                                              .elementAt(index)) {
                                        reviewAttribute = element;
                                      }
                                    }
                                    ReviewsAttribute reviewsAttributeModel =
                                        ReviewsAttribute.fromJson(
                                          widget
                                              .productModel
                                              .reviewAttributes!
                                              .values
                                              .elementAt(index),
                                        );
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              reviewAttribute.title.toString(),
                                              style: TextStyle(
                                                color: Colors.black.withOpacity(
                                                  0.60,
                                                ),
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          RatingBar.builder(
                                            ignoreGestures: true,
                                            initialRating:
                                                (reviewsAttributeModel
                                                        .reviewsSum!
                                                        .toDouble() /
                                                    reviewsAttributeModel
                                                        .reviewsCount!
                                                        .toDouble()),
                                            minRating: 1,
                                            itemSize: 20,
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            itemCount: 5,
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
                                          const SizedBox(width: 8),
                                          Text(
                                            (reviewsAttributeModel.reviewsSum!
                                                        .toDouble() /
                                                    reviewsAttributeModel
                                                        .reviewsCount!
                                                        .toDouble())
                                                .toStringAsFixed(1),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                              : Container(),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: reviewList.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ListView.builder(
                              itemCount:
                                  reviewList.length > 10
                                      ? 10
                                      : reviewList.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
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
                                          color: Colors.grey.withOpacity(
                                            0.5,
                                          ), //color of shadow
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CachedNetworkImage(
                                                height: 45,
                                                width: 45,
                                                imageUrl: getImageVAlidUrl(
                                                  reviewList[index].profile
                                                      .toString(),
                                                ),
                                                imageBuilder:
                                                    (
                                                      context,
                                                      imageProvider,
                                                    ) => Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              35,
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
                                                              Color(
                                                                COLOR_PRIMARY,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            35,
                                                          ),
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
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      reviewList[index].uname
                                                          .toString(),
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        letterSpacing: 1,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    RatingBar.builder(
                                                      ignoreGestures: true,
                                                      initialRating:
                                                          reviewList[index]
                                                              .rating ??
                                                          0.0,
                                                      minRating: 1,
                                                      itemSize: 22,
                                                      direction:
                                                          Axis.horizontal,
                                                      allowHalfRating: true,
                                                      itemCount: 5,
                                                      itemPadding:
                                                          const EdgeInsets.only(
                                                            top: 5.0,
                                                          ),
                                                      itemBuilder:
                                                          (context, _) => Icon(
                                                            Icons.star,
                                                            color: Color(
                                                              COLOR_PRIMARY,
                                                            ),
                                                          ),
                                                      onRatingUpdate: (
                                                        double rate,
                                                      ) {
                                                        // ratings = rate;
                                                        // print(ratings);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                orderDate(
                                                  reviewList[index].createdAt,
                                                ),
                                                style: TextStyle(
                                                  color:
                                                      isDarkMode(context)
                                                          ? Colors.grey.shade200
                                                          : const Color(
                                                            0XFF555353,
                                                          ),
                                                  fontFamily: "Poppinsr",
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            reviewList[index].comment
                                                .toString(),
                                            style: TextStyle(
                                              color: Colors.black.withOpacity(
                                                0.70,
                                              ),
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
                                                  itemCount:
                                                      reviewList[index]
                                                          .photos!
                                                          .length,
                                                  shrinkWrap: true,
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemBuilder: (
                                                    context,
                                                    index1,
                                                  ) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6.0,
                                                          ),
                                                      child: CachedNetworkImage(
                                                        height: 65,
                                                        width: 65,
                                                        imageUrl: getImageVAlidUrl(
                                                          reviewList[index]
                                                              .photos![index1],
                                                        ),
                                                        imageBuilder:
                                                            (
                                                              context,
                                                              imageProvider,
                                                            ) => Container(
                                                              decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                                image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                ),
                                                              ),
                                                            ),
                                                        placeholder:
                                                            (
                                                              context,
                                                              url,
                                                            ) => Center(
                                                              child: CircularProgressIndicator.adaptive(
                                                                valueColor:
                                                                    AlwaysStoppedAnimation(
                                                                      Color(
                                                                        COLOR_PRIMARY,
                                                                      ),
                                                                    ),
                                                              ),
                                                            ),
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) => ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                              child: Image.network(
                                                                placeholderImage,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
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
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.height * 0.06,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(COLOR_PRIMARY),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      side: BorderSide(
                                        color: Color(COLOR_PRIMARY),
                                      ),
                                    ),
                                  ),
                                  child:
                                      const Text(
                                        'See All Reviews',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ).tr(),
                                  onPressed: () {
                                    push(
                                      context,
                                      Review(productModel: widget.productModel),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
      // isOpen
      //     ?
      Container(
        color: Color(COLOR_PRIMARY),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20,
          top: 20,
        ),
        child: Row(
          children: [
            Expanded(
              child:
                  Text(
                    "Item Total".tr() +
                        " " +
                        amountShow(amount: priceTemp.toString()),
                    style: const TextStyle(
                      fontFamily: "Poppinsm",
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ).tr(),
            ),
            GestureDetector(
              onTap: () {
                print("fdfd");
                if (MyAppState.currentUser == null) {
                  push(context, AuthScreen());
                } else {
                  print("fdfd2");
                  pushAndRemoveUntil(
                    context,
                    ContainerScreen(
                      user: MyAppState.currentUser!,
                      drawerSelection: DrawerSelection.Cart,
                      currentWidget: CartScreen(
                        isopen: isOpen,
                        packingCharge: widget.productModel.packingcharges,
                      ),
                      appBarTitle: 'Your Cart'.tr(),
                    ),
                    false,
                  );
                }
              },
              child:
                  Text(
                    "VIEW CART".tr(),
                    style: const TextStyle(
                      fontFamily: "Poppinsm",
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ).tr(),
            ),
          ],
        ),
      ),
      // : null,
    );
  }

  addtocard(ProductModel productModel, bool isIncerementQuantity) async {
    bool isAddOnApplied = false;
    double addOnVal = 0;
    for (int i = 0; i < lstTemp.length; i++) {
      AddAddonsDemo addAddonsDemo = lstTemp[i];
      if (addAddonsDemo.categoryID == widget.productModel.id) {
        isAddOnApplied = true;
        addOnVal = addOnVal + double.parse(addAddonsDemo.price!);
      }
    }
    List<CartProduct> cartProducts = await cartDatabase.allCartProducts;
    if (productQnt > 1) {
      var joinTitleString = "";
      String mainPrice = "";
      List<AddAddonsDemo> lstAddOns = [];
      List<String> lstAddOnsTemp = [];
      double extrasPrice = 0.0;

      SharedPreferences sp = await SharedPreferences.getInstance();
      String addOns =
          sp.getString("musics_key") != null ? sp.getString('musics_key')! : "";

      bool isAddSame = false;
      if (!isAddSame) {
        if (productModel.disPrice != null &&
            productModel.disPrice!.isNotEmpty &&
            double.parse(productModel.disPrice!) != 0) {
          mainPrice = productModel.disPrice!;
        } else {
          mainPrice = productModel.price;
        }
      }

      if (addOns.isNotEmpty) {
        lstAddOns = AddAddonsDemo.decode(addOns);
        for (int a = 0; a < lstAddOns.length; a++) {
          AddAddonsDemo newAddonsObject = lstAddOns[a];
          if (newAddonsObject.categoryID == widget.productModel.id) {
            if (newAddonsObject.isCheck == true) {
              lstAddOnsTemp.add(newAddonsObject.name!);
              extrasPrice += (double.parse(newAddonsObject.price!));
            }
          }
        }

        joinTitleString = lstAddOnsTemp.join(",");
      }

      final bool _productIsInList = cartProducts.any(
        (product) =>
            product.id ==
            productModel.id +
                "~" +
                (productModel.variantInfo != null
                    ? productModel.variantInfo!.variantId.toString()
                    : ""),
      );
      if (_productIsInList) {
        CartProduct element = cartProducts.firstWhere(
          (product) =>
              product.id ==
              productModel.id +
                  "~" +
                  (productModel.variantInfo != null
                      ? productModel.variantInfo!.variantId.toString()
                      : ""),
        );

        await cartDatabase.updateProduct(
          CartProduct(
            id: element.id,
            name: element.name,
            photo: element.photo,
            price: element.price,
            item: element.item,
            groceryUnit: element.groceryUnit,
            groceryWeight: element.groceryWeight,
            packingcharges: element.packingcharges,
            vendorID: element.vendorID,
            quantity:
                isIncerementQuantity ? element.quantity + 1 : element.quantity,
            category_id: element.category_id,
            extras_price: extrasPrice.toString(),
            extras: joinTitleString,
            discountPrice: element.discountPrice!,
          ),
        );
      } else {
        await cartDatabase.updateProduct(
          CartProduct(
            id:
                productModel.id +
                "~" +
                (productModel.variantInfo != null
                    ? productModel.variantInfo!.variantId.toString()
                    : ""),
            name: productModel.name,
            photo: productModel.photo,
            packingcharges: productModel.packingcharges,
            price: mainPrice,
            item: productModel.item,
            groceryUnit: productModel.groceryUnit,
            groceryWeight: productModel.groceryWeight,
            discountPrice: productModel.disPrice,
            vendorID: productModel.vendorID,
            quantity: productQnt,
            extras_price: extrasPrice.toString(),
            extras: joinTitleString,
            category_id: productModel.categoryID,
            variant_info: productModel.variantInfo,
          ),
        );
      }
      //  });
      setState(() {});
    } else {
      if (cartProducts.isEmpty) {
        cartDatabase.addProduct(
          productModel,
          cartDatabase,
          isIncerementQuantity,
        );
      } else {
        if (cartProducts[0].vendorID == widget.vendorModel.id) {
          cartDatabase.addProduct(
            productModel,
            cartDatabase,
            isIncerementQuantity,
          );
        } else {
          cartDatabase.deleteAllProducts();
          cartDatabase.addProduct(
            productModel,
            cartDatabase,
            isIncerementQuantity,
          );

          if (isAddOnApplied && addOnVal > 0) {
            priceTemp += (addOnVal * productQnt);
          }
        }
      }
    }
    updatePrice();
  }

  removetocard(ProductModel productModel, bool isIncerementQuantity) async {
    double addOnVal = 0;
    for (int i = 0; i < lstTemp.length; i++) {
      AddAddonsDemo addAddonsDemo = lstTemp[i];
      addOnVal = addOnVal + double.parse(addAddonsDemo.price!);
    }
    List<CartProduct> cartProducts = await cartDatabase.allCartProducts;

    debugPrint("---->$productQnt");
    if (productQnt >= 1) {
      //setState(() async {

      var joinTitleString = "";
      String mainPrice = "";
      List<AddAddonsDemo> lstAddOns = [];
      List<String> lstAddOnsTemp = [];
      double extrasPrice = 0.0;

      SharedPreferences sp = await SharedPreferences.getInstance();
      String addOns =
          sp.getString("musics_key") != null ? sp.getString('musics_key')! : "";

      bool isAddSame = false;
      if (!isAddSame) {
        if (productModel.disPrice != null &&
            productModel.disPrice!.isNotEmpty &&
            double.parse(productModel.disPrice!) != 0) {
          mainPrice = productModel.disPrice!;
        } else {
          mainPrice = productModel.price;
        }
      }

      if (addOns.isNotEmpty) {
        lstAddOns = AddAddonsDemo.decode(addOns);
        for (int a = 0; a < lstAddOns.length; a++) {
          AddAddonsDemo newAddonsObject = lstAddOns[a];
          if (newAddonsObject.categoryID == widget.productModel.id) {
            if (newAddonsObject.isCheck == true) {
              lstAddOnsTemp.add(newAddonsObject.name!);
              extrasPrice += (double.parse(newAddonsObject.price!));
            }
          }
        }

        joinTitleString = lstAddOnsTemp.join(",");
      }

      final bool _productIsInList = cartProducts.any(
        (product) =>
            product.id ==
            productModel.id +
                "~" +
                (variants!
                        .where(
                          (element) =>
                              element.variantSku == selectedVariants.join('-'),
                        )
                        .isNotEmpty
                    ? variants!
                        .where(
                          (element) =>
                              element.variantSku == selectedVariants.join('-'),
                        )
                        .first
                        .variantId
                        .toString()
                    : ""),
      );
      if (_productIsInList) {
        CartProduct element = cartProducts.firstWhere(
          (product) =>
              product.id ==
              productModel.id +
                  "~" +
                  (variants!
                          .where(
                            (element) =>
                                element.variantSku ==
                                selectedVariants.join('-'),
                          )
                          .isNotEmpty
                      ? variants!
                          .where(
                            (element) =>
                                element.variantSku ==
                                selectedVariants.join('-'),
                          )
                          .first
                          .variantId
                          .toString()
                      : ""),
        );
        await cartDatabase.updateProduct(
          CartProduct(
            id: element.id,
            name: element.name,
            photo: element.photo,
            price: element.price,
            item: element.item,
            groceryUnit: element.groceryUnit,
            groceryWeight: element.groceryWeight,
            packingcharges: element.packingcharges,
            vendorID: element.vendorID,
            quantity:
                isIncerementQuantity ? element.quantity - 1 : element.quantity,
            category_id: element.category_id,
            extras_price: extrasPrice.toString(),
            extras: joinTitleString,
            discountPrice: element.discountPrice!,
          ),
        );
      } else {
        await cartDatabase.updateProduct(
          CartProduct(
            id:
                productModel.id +
                "~" +
                (variants!
                        .where(
                          (element) =>
                              element.variantSku == selectedVariants.join('-'),
                        )
                        .isNotEmpty
                    ? variants!
                        .where(
                          (element) =>
                              element.variantSku == selectedVariants.join('-'),
                        )
                        .first
                        .variantId
                        .toString()
                    : ""),
            name: productModel.name,
            photo: productModel.photo,
            packingcharges: productModel.packingcharges,
            price: mainPrice,
            item: productModel.item,
            groceryUnit: productModel.groceryUnit,
            groceryWeight: productModel.groceryWeight,
            discountPrice: productModel.disPrice,
            vendorID: productModel.vendorID,
            quantity: productQnt,
            extras_price: extrasPrice.toString(),
            extras: joinTitleString,
            category_id: productModel.categoryID,
            variant_info: productModel.variantInfo,
          ),
        );
      }
    } else {
      cartDatabase.removeProduct(
        productModel.id +
            "~" +
            (variants!
                    .where(
                      (element) =>
                          element.variantSku == selectedVariants.join('-'),
                    )
                    .isNotEmpty
                ? variants!
                    .where(
                      (element) =>
                          element.variantSku == selectedVariants.join('-'),
                    )
                    .first
                    .variantId
                    .toString()
                : ""),
      );
      setState(() {
        productQnt = 0;
      });
    }
    updatePrice();
  }

  void getAddOnsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String musicsString =
        prefs.getString('musics_key') != null
            ? prefs.getString('musics_key')!
            : "";

    if (musicsString.isNotEmpty) {
      setState(() {
        lstTemp = AddAddonsDemo.decode(musicsString);
      });
    }

    if (productQnt > 0) {
      lastPrice =
          widget.productModel.disPrice == "" ||
                  widget.productModel.disPrice == "0"
              ? double.parse(widget.productModel.price)
              : double.parse(widget.productModel.disPrice!) * productQnt;
    }

    if (lstTemp.isEmpty) {
      setState(() {
        if (widget.productModel.addOnsTitle.isNotEmpty) {
          for (int a = 0; a < widget.productModel.addOnsTitle.length; a++) {
            AddAddonsDemo addAddonsDemo = AddAddonsDemo(
              name: widget.productModel.addOnsTitle[a],
              index: a,
              isCheck: false,
              categoryID: widget.productModel.id,
              price: widget.productModel.addOnsPrice[a],
            );
            lstAddAddonsCustom.add(addAddonsDemo);
            //saveAddonData(lstAddAddonsCustom);
          }
        }
      });
    } else {
      var tempArray = [];

      for (int d = 0; d < lstTemp.length; d++) {
        if (lstTemp[d].categoryID == widget.productModel.id) {
          AddAddonsDemo addAddonsDemo = AddAddonsDemo(
            name: lstTemp[d].name,
            index: lstTemp[d].index,
            isCheck: true,
            categoryID: lstTemp[d].categoryID,
            price: lstTemp[d].price,
          );
          tempArray.add(addAddonsDemo);
        }
      }
      for (int a = 0; a < widget.productModel.addOnsTitle.length; a++) {
        var isAddonSelected = false;

        for (int temp = 0; temp < tempArray.length; temp++) {
          if (tempArray[temp].name == widget.productModel.addOnsTitle[a]) {
            isAddonSelected = true;
          }
        }
        if (isAddonSelected) {
          AddAddonsDemo addAddonsDemo = AddAddonsDemo(
            name: widget.productModel.addOnsTitle[a],
            index: a,
            isCheck: true,
            categoryID: widget.productModel.id,
            price: widget.productModel.addOnsPrice[a],
          );
          lstAddAddonsCustom.add(addAddonsDemo);
        } else {
          AddAddonsDemo addAddonsDemo = AddAddonsDemo(
            name: widget.productModel.addOnsTitle[a],
            index: a,
            isCheck: false,
            categoryID: widget.productModel.id,
            price: widget.productModel.addOnsPrice[a],
          );
          lstAddAddonsCustom.add(addAddonsDemo);
        }
      }
    }
    updatePrice();
  }

  void saveAddOns(List<AddAddonsDemo> lstTempDemo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedData = AddAddonsDemo.encode(lstTempDemo);
    await prefs.setString('musics_key', encodedData);
  }

  void clearAddOnData() {
    bool isAddOnApplied = false;
    double addOnVal = 0;

    for (int i = 0; i < lstTemp.length; i++) {
      if (lstTemp[i].categoryID == widget.productModel.id) {
        AddAddonsDemo addAddonsDemo = lstTemp[i];
        isAddOnApplied = true;
        addOnVal = addOnVal + double.parse(addAddonsDemo.price!);
      }
    }
    if (isAddOnApplied && addOnVal > 0 && productQnt > 0) {
      priceTemp -= (addOnVal * productQnt);
    }
  }

  /// admin user without runing code
  //   void updatePrice() {
  //     double addOnVal = 0;
  //     for (int i = 0; i < lstTemp.length; i++) {
  //       AddAddonsDemo addAddonsDemo = lstTemp[i];
  //       if (addAddonsDemo.categoryID == widget.productModel.id) {
  //         addOnVal = addOnVal + double.parse(addAddonsDemo.price!);
  //       }
  //     }
  //     List<CartProduct> cartProducts = [];
  //     Future.delayed(const Duration(milliseconds: 500), () {
  //       cartProducts.clear();
  //
  //       cartDatabase.allCartProducts.then((value) {
  //         priceTemp = 0;
  //         cartProducts.addAll(value);
  //         for (int i = 0; i < cartProducts.length; i++) {
  //           CartProduct e = cartProducts[i];
  //           if (e.extras_price != null &&
  //               e.extras_price != "" &&
  //               double.parse(e.extras_price!) != 0) {
  //             priceTemp += double.parse(e.extras_price!) * e.quantity;
  //           }
  //           double? packingCharges =
  //               double.tryParse(widget.productModel.packingcharges) ?? 0.0;
  //           priceTemp += double.parse(e.price) * e.quantity + packingCharges;
  //         }
  //         setState(() {});
  //       });
  //     });
  //   }
  var priceaveche;
  var finalprice;

  getproductdicountprice() {
    print("isEnabled sju ave che ${isEnabled}");
    print("isEnabled sju ave che ${cityaveche}");
    print("isEnabled sju ave che ${isMyTime}");
    print("isEnabled sju ave che ${widget.vendorModel.auto_apply}");
    if (isEnabled && cityaveche && isMyTime && widget.vendorModel.auto_apply) {
      print("ani adar ave che ");
      if (widget.productModel.disPrice == "0") {
        print("if ave che");
        priceaveche =
            num.parse(widget.productModel.price) *
            widget.vendorModel.auto_apply_discount /
            100;
        finalprice = num.parse(widget.productModel.price) - priceaveche;
        print("finalprice>>>>>>>>>>>>>${finalprice}");
        print("finalprice>>>>>>>>>>>>>${priceaveche}");
      } else {
        print("else  ave che");
        priceaveche =
            num.parse(widget.productModel.disPrice.toString()) *
            widget.vendorModel.auto_apply_discount /
            100;
        finalprice =
            num.parse(widget.productModel.disPrice.toString()) - priceaveche;
        print("finalprice>>>>>>>>>>>>>else ave che${finalprice}");
        print("finalprice>>>>>>>>>>>>> else price${priceaveche}");
      }
    } else {
      print("else call that che isenble check karva");
    }
  }

  double pricenew = 0.0;

  void updatePrice() {
    double addOnVal = 0;

    print("updatePriceupdatePriceupdatePriceupdatePrice${pricenew}");
    double originalPrice = 0;
    for (int i = 0; i < lstTemp.length; i++) {
      AddAddonsDemo addAddonsDemo = lstTemp[i];
      if (addAddonsDemo.categoryID == widget.productModel.id) {
        addOnVal = addOnVal + double.parse(addAddonsDemo.price!);
      }
    }
    List<CartProduct> cartProducts = [];
    Future.delayed(const Duration(milliseconds: 500), () {
      cartProducts.clear();

      cartDatabase.allCartProducts.then((value) {
        priceTemp = 0;
        pricenew = 0;
        print("=========>>>>>>>>>>>>>>>>${pricenew}");

        cartProducts.addAll(value);

        ///  a code working che
        for (int i = 0; i < cartProducts.length; i++) {
          print("cartProducts.length${cartProducts.length}");
          print("cartProducts.length${cartProducts[i].price}");

          CartProduct e = cartProducts[i];
          if (e.extras_price != null &&
              e.extras_price != "" &&
              double.parse(e.extras_price!) != 0) {
            priceTemp += double.parse(e.extras_price!) * e.quantity;
            print("priceTemppriceTemppriceTemp${priceTemp}");
          }
          print("priceTemp=====>>>>>>${priceTemp}");
          double? packingCharges =
              double.tryParse(widget.productModel.packingcharges) ?? 0.0;
          if (widget.vendorModel.auto_apply == true &&
              isMyTime == true &&
              cityaveche) {
            setState(() {
              pricenew =
                  double.parse(e.price) *
                  widget.vendorModel.auto_apply_discount /
                  100;
              double originalPrice = double.parse(e.price);
              // print("originalPriceoriginalPrice${originalPrice}");
              originalPrice = double.parse(e.price) - pricenew;
              priceTemp += originalPrice * e.quantity + packingCharges;
            });
            print(
              "priceaveche1priceaveche1priceaveche1priceaveche=====>>>>>>${pricenew}",
            );

            print("raam mer  ${priceTemp}");
            print("Haresh  ${originalPrice * e.quantity}");
            print(
              "originalPrice * e.quantity + packingCharges ${originalPrice * e.quantity + packingCharges}",
            );
            print("originalPrice ===>>> $originalPrice}");
            print("jay lo gando ${pricenew}");
            // print("finalprice finalprice====>>>>>>> ${finalprice}");
          } else {
            priceTemp += double.parse(e.price) * e.quantity + packingCharges;
            print(
              "packingChargespackingChargespackingCharges${widget.vendorModel.auto_apply_discount}",
            );
          }
        }

        //         for (int i = 0; i < cartProducts.length; i++) {
        //           print("cartProducts.length: ${cartProducts.length}");
        //           print("cartProducts[i].price: ${cartProducts[i].price}");
        //
        //           CartProduct e = cartProducts[i];
        //
        //           if (e.extras_price != null &&
        //               e.extras_price != "" &&
        //               double.parse(e.extras_price!) != 0) {
        //             priceTemp += double.parse(e.extras_price!) * e.quantity;
        //             print("priceTemp after extras_price: $priceTemp");
        //           }
        //
        //           double? packingCharges =
        //               double.tryParse(widget.productModel.packingcharges) ?? 0.0;
        //
        //           double originalPrice = double.parse(e.price);
        //
        //           // Auto apply discount check
        //           originalPrice = originalPrice - priceaveche;
        //           print("priceavechepriceavechepriceaveche${priceaveche}");
        // print("originalPriceoriginalPriceoriginalPriceoriginalPrice${originalPrice}");
        //           priceTemp += (originalPrice * e.quantity) + packingCharges;
        //           print("priceTemp after discount and packing: $priceTemp");
        //         }

        setState(() {});
      });
    });
  }

  Widget _buildChip(String label, int attributesOptionIndex, bool isSelected) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black),
          ),
        ],
      ),
      backgroundColor: isSelected ? Color(COLOR_PRIMARY) : Colors.white,
      elevation: 6.0,
      shadowColor: Colors.grey[60],
      padding: const EdgeInsets.all(8.0),
    );

    // Container(
    //   decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xffABBCC8), width: 0.5)),
    //   child: Padding(
    //     padding: const EdgeInsets.all(2.0),
    //     child: Container(
    //       decoration: BoxDecoration(
    //         color: isSelected ? Color(COLOR_PRIMARY) : Colors.white,
    //         borderRadius: BorderRadius.circular(30),
    //       ),
    //       child: Center(
    //         child: Text(
    //           label,
    //           style: TextStyle(
    //             color: isSelected ? Colors.white : Colors.black,
    //           ),
    //         ),
    //       ),
    //       // child: Chip(
    //       //   label: Text(
    //       //     label,
    //       //     style: const TextStyle(
    //       //       color: Colors.white,
    //       //     ),
    //       //   ),
    //       //   backgroundColor: colors,
    //       //   elevation: 6.0,
    //       //   shadowColor: Colors.grey[60],
    //       //   padding: const EdgeInsets.all(8.0),
    //       // ),
    //     ),
    //   ),
    // );
  }

  getTextStatus() {
    if (widget.vendorModel.isTempClose) {
      return Text(
        isOpen == true ? "Temporary Closed".tr() : "Temporary Closed".tr(),
        style: TextStyle(color: isOpen == true ? Colors.green : Colors.red),
      );
    } else {
      return Text(
        isOpen == true
            ? "Open".tr()
            : isPreOrderAvailable == true
            ? "Pre-order".tr()
            : "Closed".tr(),
        style: TextStyle(
          color:
              isOpen == true
                  ? Colors.green
                  : isPreOrderAvailable == true
                  ? Colors.green
                  : Colors.red,
        ),
      );
    }
  }
}

class AddAddonsDemo {
  String? name;
  int? index;
  String? price;
  bool isCheck;
  String? categoryID;

  AddAddonsDemo({
    this.name,
    this.index,
    this.price,
    this.isCheck = false,
    this.categoryID,
  });

  static Map<String, dynamic> toMap(AddAddonsDemo music) => {
    'index': music.index,
    'name': music.name,
    'price': music.price,
    'isCheck': music.isCheck,
    "categoryID": music.categoryID,
  };

  factory AddAddonsDemo.fromJson(Map<String, dynamic> jsonData) {
    return AddAddonsDemo(
      index: jsonData['index'],
      name: jsonData['name'],
      price: jsonData['price'],
      isCheck: jsonData['isCheck'],
      categoryID: jsonData["categoryID"],
    );
  }

  static String encode(List<AddAddonsDemo> item) => json.encode(
    item
        .map<Map<String, dynamic>>((item) => AddAddonsDemo.toMap(item))
        .toList(),
  );

  static List<AddAddonsDemo> decode(String item) =>
      (json.decode(item) as List<dynamic>)
          .map<AddAddonsDemo>((item) => AddAddonsDemo.fromJson(item))
          .toList();

  @override
  String toString() {
    return '{name: $name, index: $index, price: $price, isCheck: $isCheck, categoryID: $categoryID}';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'index': index,
      'price': price,
      'isCheck': isCheck,
      'categoryID': categoryID,
    };
  }
}

class SharedData {
  bool? isCheckedValue;
  String? categoryId;

  SharedData({this.categoryId, this.isCheckedValue});
}
