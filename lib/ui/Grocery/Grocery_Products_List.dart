import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/Grocery/Grocery_Products_Details_Screen.dart';

import '../../AppGlobal.dart';
import '../../constants.dart';
import '../../model/ProductModel.dart';
import '../../model/VendorModel.dart';
import '../../services/FirebaseHelper.dart';
import 'Grocery_Categories.dart';

class Grocery_Products extends StatefulWidget {
  String? categoryName;
  String? categoryId;

  Grocery_Products({
    super.key,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<Grocery_Products> createState() => _Grocery_ProductsState();
}

bool isLoading = true;
List<ProductModel> productModel = [];

class _Grocery_ProductsState extends State<Grocery_Products> {
  void getGroceries() async {
    log('Kaa Id Che ${widget.categoryId}');
    await fireStoreUtils
        .getAllGroceryProducts(widget.categoryId.toString())
        .then((value) {
          productModel.clear();
          productModel.addAll(value);
          // log('Jo Aa Pelli Product ${productModel[0].name}');
          setState(() {
            isLoading = false;
          });
        });
  }

  bool isEnable = false;

  Future<void> getIsEnableStatus() async {
    print('isEnable Status: ');
    // Firestore instance banavo
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Document nu reference lidhu, jema 'grubb_mart' collection ane tamaru document name che
    DocumentSnapshot document =
        await firestore.collection('settings').doc('grubb_mart').get();

    if (document.exists) {
      print('isEnable Status: ');
      // isEnable field check kari ne fetch karo
      isEnable = document.get('isEnable');
      print('isEnable Status: $isEnable');
    } else {
      print('Document not found');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      isLoading = true;
    });
    getGroceries();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGlobal.buildAppBar(context, widget.categoryName ?? ''),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                ),
              )
              : SingleChildScrollView(
                child:
                    productModel.length == 0
                        ? Container(
                          height: MediaQuery.of(context).size.height * 0.90,
                          child: showEmptyState('No Products', context),
                        )
                        : Column(
                          children: [
                            for (
                              int i = 0;
                              i < (productModel.length ?? 0);
                              i++
                            ) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
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
                                          color: Colors.grey.withOpacity(0.5),
                                          blurRadius: 5,
                                        ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        CachedNetworkImage(
                                          height: 80,
                                          width: 80,
                                          imageUrl: getImageVAlidUrl(
                                            productModel[i].photo,
                                          ),
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(
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
                                                      width:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.width,
                                                      height:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.height,
                                                    ),
                                                  ),
                                        ),
                                        Positioned(
                                          left: 5,
                                          top: 5,
                                          child: Icon(
                                            Icons.circle,
                                            color:
                                                productModel[i].veg == true
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            productModel[i].name +
                                                ' (${productModel[i].groceryWeight} ${productModel[i].groceryUnit})',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontFamily: "Poppinssb",
                                              letterSpacing: 0.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: <Widget>[
                                              productModel[i].disPrice == "" ||
                                                      productModel[i]
                                                              .disPrice ==
                                                          "0"
                                                  ? Text(
                                                    "${amountShow(amount: productModel[i].price.toString())}",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontFamily: "Poppinsm",
                                                      letterSpacing: 0.5,
                                                      color: Color(
                                                        COLOR_PRIMARY,
                                                      ),
                                                    ),
                                                  )
                                                  : Row(
                                                    children: [
                                                      Text(
                                                        "${amountShow(amount: productModel[i].disPrice)}",
                                                        style: TextStyle(
                                                          fontFamily:
                                                              "Poppinsm",
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            COLOR_PRIMARY,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        "${amountShow(amount: productModel[i].price)}",
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              "Poppinsm",
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.grey,
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              // productModel.quantity == 0
                                              //     ? isOpen != true
                                              //         ? const Center()
                                              //         : Padding(
                                              //             padding: const EdgeInsets.only(right: 15),
                                              //             child: SizedBox(
                                              //                 height: 33,
                                              //                 // width: 80,
                                              //                 // alignment:Alignment.center,
                                              //                 child: Center(
                                              //                   // height: 10,
                                              //                   //  width: 80,
                                              //                   child: TextButton.icon(
                                              //                     onPressed: () {
                                              //                       if (MyAppState.currentUser == null) {
                                              //                         push(context, const AuthScreen());
                                              //                       } else {
                                              //                         setState(() {
                                              //                           productModel.quantity = 1;
                                              //                           // productModel.price = productModel.disPrice == "" || productModel.disPrice == "0"?productModel.price:productModel.disPrice;
                                              //                           addtocard(productModel, productModel.quantity);
                                              //                         });
                                              //                       }
                                              //                     },
                                              //                     icon: Icon(Icons.add, size: 18, color: Color(COLOR_PRIMARY)),
                                              //                     label: Text(
                                              //                       'ADD'.tr(),
                                              //                       style: TextStyle(height: 1.2, fontFamily: "Poppinssb", letterSpacing: 0.5, color: Color(COLOR_PRIMARY)),
                                              //                     ),
                                              //                     style: TextButton.styleFrom(
                                              //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                              //                       side: const BorderSide(color: Color(0XFFC3C5D1), width: 1.5),
                                              //                     ),
                                              //                   ),
                                              //                 )))
                                              //     : Row(
                                              //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              //         crossAxisAlignment: CrossAxisAlignment.center,
                                              //         children: [
                                              //           IconButton(
                                              //               onPressed: () {
                                              //                 if (productModel.quantity != 0) {
                                              //                   setState(() {
                                              //                     productModel.quantity--;
                                              //                     if (productModel.quantity >= 0) {
                                              //                       // productModel.price = productModel.disPrice == "" || productModel.disPrice == "0"?productModel.price:productModel.disPrice;
                                              //                       removetocard(productModel, productModel.quantity);
                                              //                     } else {
                                              //                       // addtocard(productModel);
                                              //                       //removeQuntityFromCartProduct(productModel);
                                              //
                                              //                     }
                                              //
                                              //                     //: addtocard(productModel);
                                              //                   });
                                              //                 }
                                              //                 //   productModel.quantity >=1?
                                              //                 //   removetocard(productModel, productModel.quantity)
                                              //                 //  :null;
                                              //                 // },
                                              //                 // );
                                              //               },
                                              //               icon: Image(
                                              //                 image: const AssetImage("assets/images/minus.png"),
                                              //                 color: Color(COLOR_PRIMARY),
                                              //                 height: 28,
                                              //               )),
                                              //           const SizedBox(
                                              //             width: 5,
                                              //           ),
                                              //
                                              //           // cartData( productModel.id)== null?
                                              //
                                              //           StreamBuilder<List<CartProduct>>(
                                              //               stream: cartDatabase.watchProducts,
                                              //               initialData: const [],
                                              //               builder: (context, snapshot) {
                                              //                 cartProducts = snapshot.data!;
                                              //                 return SizedBox(
                                              //                     height: 25,
                                              //                     width: 0,
                                              //                     child: Column(children: [
                                              //                       Expanded(
                                              //                           child: ListView.builder(
                                              //                               itemCount: cartProducts.length,
                                              //                               itemBuilder: (context, index) {
                                              //                                 cartProducts[index].id == productModel.id ? productModel.quantity = cartProducts[index].quantity : null;
                                              //                                 // print('yahaaaaa');
                                              //                                 if (cartProducts[index].id == productModel.id) {
                                              //                                   return const Center();
                                              //                                 } else {
                                              //                                   return Container();
                                              //                                 }
                                              //                                 //  return Center();
                                              //
                                              //                                 // print(quen);
                                              //                               }))
                                              //                     ]));
                                              //               }),
                                              //           Text(
                                              //             '${productModel.quantity}'.tr(),
                                              //             style: const TextStyle(
                                              //               fontSize: 20,
                                              //               color: Colors.black,
                                              //               letterSpacing: 0.5,
                                              //             ),
                                              //           ),
                                              //           //  Text("null"),
                                              //           const SizedBox(
                                              //             width: 5,
                                              //           ),
                                              //           IconButton(
                                              //               onPressed: () {
                                              //                 setState(() {
                                              //                   if (productModel.quantity != 0) {
                                              //                     productModel.quantity++;
                                              //                   }
                                              //                   //productModel.price = productModel.disPrice == "" || productModel.disPrice == "0"?productModel.price:productModel.disPrice;
                                              //                   addtocard(productModel, productModel.quantity);
                                              //                 });
                                              //               },
                                              //               icon: Image(
                                              //                 image: const AssetImage("assets/images/plus.png"),
                                              //                 color: Color(COLOR_PRIMARY),
                                              //                 height: 28,
                                              //               ))
                                              //         ],
                                              //       )
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    productModel[i]
                                                                .reviewsCount !=
                                                            0
                                                        ? (productModel[i]
                                                                    .reviewsSum /
                                                                productModel[i]
                                                                    .reviewsCount)
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
                                                  const Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        VendorModel? vendorModel =
                                            await FireStoreUtils.getVendor(
                                              productModel[i].vendorID,
                                            );
                                        push(
                                          context,
                                          Grocery_ProductsDetialsScreen(
                                            productModel: productModel[i],
                                            vendorModel: vendorModel!,
                                          ),
                                        );

                                        // await Navigator.of(context)
                                        //     .push(MaterialPageRoute(
                                        //     builder: (context) => ProductDetailsScreen(
                                        //         productModel: productModel,
                                        //         vendorModel: widget.vendorModel)))
                                        //     .whenComplete(() => {setState(() {})});
                                      },
                                      icon: Icon(
                                        Icons.add,
                                        color: Color(COLOR_PRIMARY),
                                        size: 16,
                                      ),
                                      label: Text(
                                        'ADD'.tr(),
                                        style: TextStyle(
                                          fontFamily: "Poppinsm",
                                          color: Color(COLOR_PRIMARY),
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        side: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
              ),
    );
  }
}
