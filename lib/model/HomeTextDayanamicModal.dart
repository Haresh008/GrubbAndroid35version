class HomeTextDayanamicModal {
  final String allRestaurantEmptyMsg;
  final String allRestaurantTitle;
  final String findRestaurantTitle;
  final String foodCategoriesEmptyMsg;
  final String foodCategoriesTitle;
  final String grubMartEmptyMsg;
  final String grubMartTitle;
  final String grubbMart;
  final String grubmartsubtitle;
  final String newArrivalsEmptyMsg;
  final String newArrivalsTitle;
  final String offerForYouEmptyMsg;
  final String offerForYouTitle;
  final String popularRestaurantEmptyMsg;
  final String popularRestaurantTitle;
  final String seeNeighborsBorderingEmptyMsg;
  final String seeNeighborsBorderingTitle;
  final String foodcategoriessubtitle;
  final String offer_for_you_sub_title;
  final String stories_title;
  final String stories_sub_title;
  final String stories_empty_msg;

  HomeTextDayanamicModal({
    required this.allRestaurantEmptyMsg,
    required this.offer_for_you_sub_title,
    required this.foodcategoriessubtitle,
    required this.grubmartsubtitle,
    required this.allRestaurantTitle,
    required this.findRestaurantTitle,
    required this.foodCategoriesEmptyMsg,
    required this.foodCategoriesTitle,
    required this.grubMartEmptyMsg,
    required this.grubMartTitle,
    required this.grubbMart,
    required this.newArrivalsEmptyMsg,
    required this.newArrivalsTitle,
    required this.offerForYouEmptyMsg,
    required this.offerForYouTitle,
    required this.popularRestaurantEmptyMsg,
    required this.popularRestaurantTitle,
    required this.seeNeighborsBorderingEmptyMsg,
    required this.seeNeighborsBorderingTitle,
    required this.stories_title,
    required this.stories_sub_title,
    required this.stories_empty_msg,
  });

  factory HomeTextDayanamicModal.fromJson(Map<String, dynamic> json) {
    return HomeTextDayanamicModal(
      allRestaurantEmptyMsg: json['all_restaurant_empty_msg'] as String,
      offer_for_you_sub_title: json['offer_for_you_sub_title'] as String,
      grubmartsubtitle: json['grub_mart_sub_title'] as String,
      allRestaurantTitle: json['all_restaurant_title'] as String,
      findRestaurantTitle: json['find_restaurant_title'] as String,
      foodCategoriesEmptyMsg: json['food_categories_empty_msg'] as String,
      foodCategoriesTitle: json['food_categories_title'] as String,
      grubMartEmptyMsg: json['grub_mart_empty_msg'] as String,
      grubMartTitle: json['grub_mart_title'] as String,
      grubbMart: json['grubb_mart'] ?? "",
      newArrivalsEmptyMsg: json['new_arrivals_empty_msg'] as String,
      newArrivalsTitle: json['new_arrivals_title'] as String,
      offerForYouEmptyMsg: json['offer_for_you_empty_msg'] as String,
      offerForYouTitle: json['offer_for_you_title'] as String,
      popularRestaurantEmptyMsg: json['popular_restaurant_empty_msg'] as String,
      popularRestaurantTitle: json['popular_restaurant_title'] as String,
      seeNeighborsBorderingEmptyMsg:
          json['see_neighbors_bordering_empty_msg'] as String,
      seeNeighborsBorderingTitle:
          json['see_neighbors_bordering_title'] as String,
      foodcategoriessubtitle: json['food_categories_sub_title'] as String,
      stories_title: json['stories_title'] as String,
      stories_sub_title: json['stories_sub_title'] as String,
      stories_empty_msg: json['stories_empty_msg'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'all_restaurant_empty_msg': allRestaurantEmptyMsg,
      'all_restaurant_title': allRestaurantTitle,
      'grub_mart_sub_title': grubmartsubtitle,
      'find_restaurant_title': findRestaurantTitle,
      'food_categories_empty_msg': foodCategoriesEmptyMsg,
      'food_categories_title': foodCategoriesTitle,
      'grub_mart_empty_msg': grubMartEmptyMsg,
      'grub_mart_title': grubMartTitle,
      'grubb_mart': grubbMart,
      'new_arrivals_empty_msg': newArrivalsEmptyMsg,
      'new_arrivals_title': newArrivalsTitle,
      'offer_for_you_empty_msg': offerForYouEmptyMsg,
      'offer_for_you_title': offerForYouTitle,
      'popular_restaurant_empty_msg': popularRestaurantEmptyMsg,
      'popular_restaurant_title': popularRestaurantTitle,
      'see_neighbors_bordering_empty_msg': seeNeighborsBorderingEmptyMsg,
      'see_neighbors_bordering_title': seeNeighborsBorderingTitle,
      'food_categories_sub_title': foodcategoriessubtitle,
      'offer_for_you_sub_title': offer_for_you_sub_title,
      'stories_title': stories_title,
      'stories_sub_title': stories_sub_title,
      'stories_empty_msg': stories_empty_msg,
    };
  }
}
