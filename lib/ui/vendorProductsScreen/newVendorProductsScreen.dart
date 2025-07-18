import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/ProductModel.dart';
import 'package:foodie_customer/model/VendorCategoryModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/model/offer_model.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/Grocery/Grocery_Products_Details_Screen.dart';
import 'package:foodie_customer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/widgets/fappbar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:rect_getter/rect_getter.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/mail_setting.dart';

class NewVendorProductsScreen extends StatefulWidget {
  final VendorModel vendorModel;

  const NewVendorProductsScreen({Key? key, required this.vendorModel})
    : super(key: key);

  @override
  State<NewVendorProductsScreen> createState() =>
      _NewVendorProductsScreenState();
}

class _NewVendorProductsScreenState extends State<NewVendorProductsScreen>
    with SingleTickerProviderStateMixin {
  final FireStoreUtils fireStoreUtils = FireStoreUtils();

  final listViewKey = RectGetter.createGlobalKey();

  bool isCollapsed = false;

  late AutoScrollController scrollController;
  TabController? tabController;

  final double expandedHeight = 500.0;

  // final PageData data = ExampleData.data;
  final double collapsedHeight = kToolbarHeight;

  Map<int, dynamic> itemKeys = {};

  // prevent animate when press on tab bar
  bool pauseRectGetterIndex = false;

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

          print(
            'restaurant valu ave che  "$city1" is available in the Firestore cities.',
          );
        } else {
          setState(() {
            cityaveche = false;
          });
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
    getFoodType();
    statusCheck();
    initializeFlutterFire();
    print("location shu ave che ${MyAppState.selectedPosotion.latitude}");
    print("ato apply shu ave che${widget.vendorModel.auto_apply}");
    print("ato apply shu ave che${widget.vendorModel.auto_apply_coupon_id}");
    print("ato apply shu ave che${widget.vendorModel.auto_apply_discount}");
    widget.vendorModel.auto_apply == true
        ? getCityrestaurantcity()
        : print("call nay thay");
    scrollController = AutoScrollController();
    if (widget.vendorModel.isTempClose) {
      isOpen = false;
    }
    super.initState();
  }

  String? foodType;

  List a = [];
  List<ProductModel> productModel = [];

  void getFoodType() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    foodType = sp.getString("foodType") ?? "Delivery".tr();

    if (foodType == "Takeaway") {
      await fireStoreUtils
          .getVendorProductsTakeAWay(widget.vendorModel.id)
          .then((value) {
            productModel.clear();
            productModel.addAll(value);
            getVendorCategoryById();
            setState(() {});
          });
    } else {
      await fireStoreUtils
          .getVendorProductsDelivery(widget.vendorModel.id)
          .then((value) {
            productModel.clear();
            productModel.addAll(value);
            getVendorCategoryById();
            setState(() {});
          });
    }
  }

  List<VendorCategoryModel> vendorCateoryModel = [];
  List<OfferModel> offerList = [];

  getVendorCategoryById() async {
    vendorCateoryModel.clear();

    for (int i = 0; i < productModel.length; i++) {
      if (a.isNotEmpty && a.contains(productModel[i].categoryID)) {
      } else if (!a.contains(productModel[i].categoryID)) {
        a.add(productModel[i].categoryID);

        await fireStoreUtils
            .getVendorCategoryById(productModel[i].categoryID)
            .then((value) {
              if (value != null) {
                setState(() {
                  vendorCateoryModel.add(value);
                });
              }
            });
      }
    }
    setState(() {
      tabController = TabController(
        length: vendorCateoryModel.length,
        vsync: this,
      );
    });

    await FireStoreUtils().getOfferByVendorID(widget.vendorModel.id).then((
      value,
    ) {
      setState(() {
        offerList = value;
      });
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    tabController!.dispose();
    super.dispose();
  }

  List<int> getVisibleItemsIndex() {
    Rect? rect = RectGetter.getRectFromKey(listViewKey);
    List<int> items = [];
    if (rect == null) return items;
    itemKeys.forEach((index, key) {
      Rect? itemRect = RectGetter.getRectFromKey(key);
      if (itemRect == null) return;
      if (itemRect.top > rect.bottom) return;
      if (itemRect.bottom < rect.top) return;
      items.add(index);
    });
    return items;
  }

  void onCollapsed(bool value) {
    if (this.isCollapsed == value) return;
    setState(() => this.isCollapsed = value);
  }

  bool onScrollNotification(ScrollNotification notification) {
    if (pauseRectGetterIndex) return true;
    int lastTabIndex = tabController!.length - 1;
    List<int> visibleItems = getVisibleItemsIndex();

    bool reachLastTabIndex =
        visibleItems.isNotEmpty &&
        visibleItems.length <= 2 &&
        visibleItems.last == lastTabIndex;
    if (reachLastTabIndex) {
      tabController?.animateTo(lastTabIndex);
    } else if (visibleItems.isNotEmpty) {
      int sumIndex = visibleItems.reduce((value, element) => value + element);
      int middleIndex = sumIndex ~/ visibleItems.length;
      if (tabController!.index != middleIndex)
        tabController!.animateTo(middleIndex);
    }
    return false;
  }

  void animateAndScrollTo(int index) {
    pauseRectGetterIndex = true;
    tabController?.animateTo(index);
    scrollController
        .scrollToIndex(index, preferPosition: AutoScrollPosition.begin)
        .then((value) => pauseRectGetterIndex = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body:
          tabController == null
              ? const Center(child: CircularProgressIndicator())
              : RectGetter(
                key: listViewKey,
                child: NotificationListener<ScrollNotification>(
                  child: buildSliverScrollView(),
                  onNotification: onScrollNotification,
                ),
              ),
    );
  }

  Widget buildSliverScrollView() {
    return CustomScrollView(
      controller: scrollController,
      slivers: [buildAppBar(), buildBody()],
    );
  }

  @override
  void didChangeDependencies() {
    cartDatabase = Provider.of<CartDatabase>(context);
    super.didChangeDependencies();
  }

  SliverAppBar buildAppBar() {
    return FAppBar(
      vendorModel: widget.vendorModel,
      vendorCateoryModel: vendorCateoryModel,
      isOpen: isOpen,
      isPreOrderAvailable: isPreOrderAvailable,
      context: context,
      // scrollController: scrollController,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      isCollapsed: isCollapsed,
      onCollapsed: onCollapsed,
      tabController: tabController!,
      offerList: offerList,
      onTap: (index) => animateAndScrollTo(index),
    );
  }

  SliverList buildBody() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => buildCategoryItem(index),
        childCount: vendorCateoryModel.length,
      ),
    );
  }

  Widget buildCategoryItem(int index) {
    itemKeys[index] = RectGetter.createGlobalKey();
    VendorCategoryModel category = vendorCateoryModel[index];
    return RectGetter(
      key: itemKeys[index],
      child: AutoScrollTag(
        key: ValueKey(index),
        index: index,
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            productModel.isEmpty
                ? Container()
                : index == 0
                ? widget.vendorModel.groceryandrestirant == "Grubb Mart"
                    ? Container()
                    : buildVeg(veg, nonveg)
                : Container(),
            _buildSectionTileHeader(category),
            _buildFoodTileList(context, category),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTileHeader(VendorCategoryModel category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          category.title.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  var isAnother = 0;
  bool veg = false;
  bool nonveg = false;

  Widget _buildFoodTileList(
    BuildContext context,
    VendorCategoryModel category,
  ) {
    isAnother = 0;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Divider(color: Color(0xffE4E8EB), thickness: 1),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productModel.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, inx) {
            print("productModel[inx].disPrice${productModel[inx].disPrice}");

            return productModel[inx].categoryID == category.id
                ? buildRow(
                  productModel[inx],
                  veg,
                  nonveg,
                  productModel[inx].categoryID,
                  (inx == (productModel.length - 1)),
                )
                : (isAnother == 0 && (inx == (productModel.length - 1)))
                ? showEmptyState("No Food are available.".tr(), context)
                : Container();
          },
        ),
      ],
    );
  }

  buildRow(ProductModel productModel, veg, nonveg, inx, bool index) {
    if (vegSwitch == true && productModel.veg == true) {
      isAnother++;
      return datarow(productModel);
    } else if (nonVegSwitch == true && productModel.veg == false) {
      isAnother++;
      return datarow(productModel);
    } else if (vegSwitch != true && nonVegSwitch != true) {
      isAnother++;
      return datarow(productModel);
    } else if (nonVegSwitch == true && productModel.nonveg == true) {
      isAnother++;
      return datarow(productModel);
    } else if (inx == productModel.categoryID) {
      return (isAnother == 0 && index)
          ? showEmptyState("No Food are available.", context)
          : Container();
    }
  }

  late CartDatabase cartDatabase;
  late List<CartProduct> cartProducts = [];

  datarow(ProductModel productModel) {
    log('Kaa : ${productModel.price},');
    var price = double.parse(productModel.price);
    var priceaveche;
    var finalprice;
    print(
      "katalaveriyable true ave che ${isEnabled && cityaveche && isMyTime && widget.vendorModel.auto_apply}",
    );
    if (isEnabled && cityaveche && isMyTime && widget.vendorModel.auto_apply) {
      if (productModel.disPrice == "0") {
        print("if ave che");
        priceaveche =
            num.parse(productModel.price) *
            widget.vendorModel.auto_apply_discount /
            100;
        finalprice = num.parse(productModel.price) - priceaveche;
      } else {
        print("else  ave che");
        priceaveche =
            num.parse(productModel.disPrice.toString()) *
            widget.vendorModel.auto_apply_discount /
            100;
        finalprice = num.parse(productModel.disPrice.toString()) - priceaveche;
      }
    } else {
      print("else call that che isenble check karva");
    }
    // var priceaveche = productModel.disPrice == "0"
    //     ? num.parse(productModel.price)
    //     : num.parse(productModel.disPrice.toString()) *
    //         widget.vendorModel.auto_apply_discount /
    //         100;
    // print("priceavechepriceavechepriceavechepriceaveche${priceaveche}");
    // print(
    //     "dixcount price shu ae che e janavo${productModel.disPrice}");
    // var finalprice = productModel.disPrice == "0"
    //     ? num.parse(productModel.price)
    //     : num.parse(productModel.disPrice.toString()) - priceaveche;
    // print("finalpricefinalpricefinalpricefinalpricefinalprice${finalprice}");
    assert(price is double);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        productModel.item == "grocery"
            ? await Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder:
                        (context) => Grocery_ProductsDetialsScreen(
                          productModel: productModel,
                          vendorModel: widget.vendorModel,
                        ),
                  ),
                )
                .whenComplete(() {
                  setState(() {});
                })
            : await Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder:
                        (context) => ProductDetailsScreen(
                          productModel: productModel,
                          vendorModel: widget.vendorModel,
                        ),
                  ),
                )
                .whenComplete(() {
                  setState(() {});
                });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isDarkMode(context)
                    ? const Color(DarkContainerBorderColor)
                    : Colors.grey.shade100,
            width: 1,
          ),
          color: isDarkMode(context) ? Color(DarkContainerColor) : Colors.white,
          boxShadow: [
            isDarkMode(context)
                ? const BoxShadow()
                : BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5),
          ],
        ),
        child: Row(
          children: [
            // StreamBuilder<List<CartProduct>>(
            //     stream: cartDatabase.watchProducts,
            //     initialData: [],
            //     builder: (context, snapshot) {
            //       cartProducts = snapshot.data!;
            //       print("cart pro copre  " + cartProducts.length.toString());
            //       print(cartProducts.toString());
            //       print("cart pro co " + productModel.quantity.toString());
            //       Future.delayed(const Duration(milliseconds: 300), () {
            //         productModel.quantity = 0;
            //         if (cartProducts.isNotEmpty) {
            //           for (CartProduct cartProduct in cartProducts) {
            //             if (cartProduct.id == productModel.id) {
            //               productModel.quantity = cartProduct.quantity;
            //             }
            //           }
            //         }
            //       });
            //       return const SizedBox(
            //         height: 0,
            //         width: 0,
            //       );
            //     }),
            Stack(
              children: [
                CachedNetworkImage(
                  height: 80,
                  width: 80,
                  imageUrl: getImageVAlidUrl(productModel.photo),
                  imageBuilder:
                      (context, imageProvider) => Container(
                        // width: 100,
                        // height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          placeholderImage,
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                        ),
                      ),
                ),
                Positioned(
                  left: 5,
                  top: 5,
                  child: Icon(
                    Icons.circle,
                    color:
                        productModel.veg == true
                            ? const Color(0XFF3dae7d)
                            : Colors.redAccent,
                    size: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    productModel.item == "grocery"
                        ? (productModel.name +
                            ' (${productModel.groceryWeight} ${productModel.groceryUnit})')
                        : productModel.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: "Poppinssb",
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  isEnabled &&
                          cityaveche &&
                          isMyTime &&
                          widget.vendorModel.auto_apply
                      ? Row(
                        children: <Widget>[
                          isZeroOrEmpty(productModel.price) &&
                                  isZeroOrEmpty(productModel.disPrice)
                              ? Container()
                              : isZeroOrEmpty(productModel.disPrice)
                              ? Text(
                                // "${amountShow(amount: productModel.price.toString())}",
                                "${amountShow(amount: finalprice.toString())}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Poppinsm",
                                  letterSpacing: 0.5,
                                  color: Color(COLOR_PRIMARY),
                                ),
                              )
                              : Row(
                                children: [
                                  Text(
                                    // "${amountShow(amount: productModel.disPrice.toString())}",
                                    "${amountShow(amount: finalprice.toString())}",
                                    style: TextStyle(
                                      fontFamily: "Poppinsm",
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(COLOR_PRIMARY),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${amountShow(amount: productModel.price.toString())}",
                                    // "${amountShow(amount: finalprice.toString())}",
                                    style: const TextStyle(
                                      fontFamily: "Poppinsm",
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      )
                      : Row(
                        children: <Widget>[
                          isZeroOrEmpty(productModel.price) &&
                                  isZeroOrEmpty(productModel.disPrice)
                              ? Container()
                              : isZeroOrEmpty(productModel.disPrice)
                              ? Text(
                                "${amountShow(amount: productModel.price.toString())}",

                                // "${amountShow(amount: finalprice.toString())}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Poppinsm",
                                  letterSpacing: 0.5,
                                  color: Color(COLOR_PRIMARY),
                                ),
                              )
                              : Row(
                                children: [
                                  Text(
                                    "${amountShow(amount: productModel.disPrice.toString())}",
                                    // "${amountShow(amount: finalprice.toString())}",
                                    style: TextStyle(
                                      fontFamily: "Poppinsm",
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(COLOR_PRIMARY),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${amountShow(amount: productModel.price.toString())}",
                                    // "${amountShow(amount: finalprice.toString())}",
                                    style: const TextStyle(
                                      fontFamily: "Poppinsm",
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                  const SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            productModel.reviewsCount != 0
                                ? (productModel.reviewsSum /
                                        productModel.reviewsCount)
                                    .toStringAsFixed(1)
                                : 0.toString(),
                            style: const TextStyle(
                              fontFamily: "Poppinsm",
                              letterSpacing: 0.5,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.star, size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              child: Text(
                'View'.tr(),
                style: TextStyle(
                  fontFamily: "Poppinsm",
                  color: Color(COLOR_PRIMARY),
                ),
              ),
              onPressed: () async {
                productModel.item == "grocery"
                    ? await Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder:
                                (context) => Grocery_ProductsDetialsScreen(
                                  productModel: productModel,
                                  vendorModel: widget.vendorModel,
                                ),
                          ),
                        )
                        .whenComplete(() {
                          setState(() {});
                        })
                    : await Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder:
                                (context) => ProductDetailsScreen(
                                  productModel: productModel,
                                  vendorModel: widget.vendorModel,
                                ),
                          ),
                        )
                        .whenComplete(() {
                          setState(() {});
                        });
              },
              style: TextButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool vegSwitch = false;
  bool nonVegSwitch = false;

  buildVeg(veg, nonveg) {
    // var vegSwitch,nonVegSwitch = false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            width: MediaQuery.of(context).size.width / 2.1,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: vegSwitch,
                  onChanged: (bool isOn) {
                    setState(() {
                      vegSwitch = isOn;
                      // vegSwitch == false
                      //     ? nonVegSwitch = true
                      //     : nonVegSwitch = false;
                    });
                  },
                  activeColor: Color(COLOR_PRIMARY),
                  activeTrackColor: const Color(0xffCAD1D8),
                  inactiveTrackColor: const Color(0xffCAD1D8),
                  inactiveThumbColor: const Color(0xff9091A4),
                ),
                Text(
                  "Veg".tr(),
                  style: const TextStyle(
                    fontFamily: "Poppinsm",
                    color: Color(0xff9091A4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Text('|', style: TextStyle(color: Color(0xffCAD1D8))),
          SizedBox(
            height: 35,
            width: MediaQuery.of(context).size.width / 2.1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: nonVegSwitch,
                  onChanged: (bool isOn) {
                    setState(() {
                      nonVegSwitch = isOn;
                    });
                  },
                  activeColor: Colors.red,
                  activeTrackColor: const Color(0xffCAD1D8),
                  inactiveTrackColor: const Color(0xffCAD1D8),
                  inactiveThumbColor: const Color(0xff9091A4),
                ),
                Text(
                  "Non-Veg".tr(),
                  style: const TextStyle(
                    fontFamily: "Poppinsm",
                    color: Color(0xff9091A4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildVeg1() {
    // var vegSwitch,nonVegSwitch = false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            width: MediaQuery.of(context).size.width / 2.1,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: vegSwitch,
                  onChanged: (bool isOn) {
                    setState(() {
                      vegSwitch = isOn;
                      // vegSwitch == false
                      //     ? nonVegSwitch = true
                      //     : nonVegSwitch = false;
                    });
                  },
                  activeColor: Color(COLOR_PRIMARY),
                  activeTrackColor: const Color(0xffCAD1D8),
                  inactiveTrackColor: const Color(0xffCAD1D8),
                  inactiveThumbColor: const Color(0xff9091A4),
                ),
                Text(
                  "Veg".tr(),
                  style: const TextStyle(
                    fontFamily: "Poppinsm",
                    color: Color(0xff9091A4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Text('|', style: TextStyle(color: Color(0xffCAD1D8))),
          SizedBox(
            height: 35,
            width: MediaQuery.of(context).size.width / 2.1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: nonVegSwitch,
                  onChanged: (bool isOn) {
                    setState(() {
                      nonVegSwitch = isOn;
                    });
                  },
                  activeColor: Colors.red,
                  activeTrackColor: const Color(0xffCAD1D8),
                  inactiveTrackColor: const Color(0xffCAD1D8),
                  inactiveThumbColor: const Color(0xff9091A4),
                ),
                Text(
                  "Non-Veg".tr(),
                  style: const TextStyle(
                    fontFamily: "Poppinsm",
                    color: Color(0xff9091A4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool isOpen = false;
  bool isPreOrderAvailable = false;

  // statusCheck() {
  //   final now = new DateTime.now();
  //   var day = DateFormat('EEEE', 'en_US').format(now);
  //   var date = DateFormat('dd-MM-yyyy').format(now);
  //   widget.vendorModel.workingHours.forEach((element) {
  //     print("===>");
  //     print(element);
  //     if (day == element.day.toString()) {
  //       print("---->1" + element.day.toString());
  //       if (element.timeslot!.isNotEmpty) {
  //         element.timeslot!.forEach((element) {
  //           print("===>2");
  //           print(element);
  //           var start = DateFormat("dd-MM-yyyy HH:mm")
  //               .parse(date + " " + element.from.toString());
  //           var end = DateFormat("dd-MM-yyyy HH:mm")
  //               .parse(date + " " + element.to.toString());
  //           if (isCurrentDateInRange(start, end)) {
  //             print("===>1");
  //             setState(() {
  //               isOpen = true;
  //               print("===>");
  //               print("cxvxcvcxvdfgfjsfdgfhsfjghfjgh${isOpen}");
  //               if (widget.vendorModel.isTempClose) {
  //                 isOpen = false;
  //               }
  //             });
  //           }
  //         });
  //       }
  //     }
  //   });
  // }

  // bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
  //   final currentDate = DateTime.now();
  //   return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  // }

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

  bool isZeroOrEmpty(dynamic value) {
    if (value == null) return true;
    String valueStr = value.toString();
    return valueStr == '0' ||
        valueStr == '00' ||
        valueStr == '0.0' ||
        valueStr == '000' ||
        valueStr == '0.00' ||
        valueStr.trim().isEmpty;
  }
}
