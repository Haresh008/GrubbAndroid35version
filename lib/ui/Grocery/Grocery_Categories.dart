import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../AppGlobal.dart';
import '../../constants.dart';
import '../../model/VendorCategoryModel.dart';
import '../../services/FirebaseHelper.dart';
import '../../services/helper.dart';
import '../categoryDetailsScreen/CategoryDetailsScreen.dart';

class Grocery_Categories extends StatefulWidget {
  bool? isPageCallFromHomeScreen;
  String? itemName;
  String? id;

  Grocery_Categories({
    super.key,
    required this.isPageCallFromHomeScreen,
    required this.id,
    required this.itemName,
  });

  @override
  State<Grocery_Categories> createState() => _Grocery_CategoriesState();
}

final fireStoreUtils = FireStoreUtils();

class _Grocery_CategoriesState extends State<Grocery_Categories> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : null,
      appBar:
          widget.isPageCallFromHomeScreen!
              ? AppGlobal.buildAppBar(context, widget.itemName ?? '')
              : null,
      body: FutureBuilder<List<VendorCategoryModel>>(
        future: fireStoreUtils.getGrocerynkitchen(widget.id),
        initialData: [],
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
              ),
            );

          if (snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) {
            return snapshot.data!.length == 0
                ? showEmptyState('No Categories'.tr(), context)
                : ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return snapshot.data != null
                        ? buildCuisineCell(snapshot.data![index])
                        : showEmptyState('No Categories'.tr(), context);
                  },
                );
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }

  Widget buildCuisineCell(VendorCategoryModel cuisineModel) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap:
            () =>
            //     push(
            //   context,
            //   push(
            //     context,
            //     Grocery_Products(
            //       categoryName: cuisineModel.title,
            //       categoryId: cuisineModel.id,
            //     ),
            //   ),
            // ),
            push(
              context,
              CategoryDetailsScreen(
                category: cuisineModel,
                isDineIn: false,
                grubbmart: true,
              ),
            ),
        child: Stack(
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                image: DecorationImage(
                  image: NetworkImage(cuisineModel.photo.toString()),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Center(
                child:
                    Text(
                      cuisineModel.title.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppinsm",
                        fontSize: 27,
                      ),
                    ).tr(),
              ),
            ),

            // Add loader
            Positioned.fill(
              child: Image.network(
                cuisineModel.photo.toString(),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return SizedBox.shrink(); // Image loaded, no loader
                  }
                  return Center(
                    child: CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
