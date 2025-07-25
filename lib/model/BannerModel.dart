// class BannerModel {
//   int? setOrder;
//   String? photo;
//   String? title;
//   bool? isPublish;
//   String? redirect_type;
//   String? redirect_id;
//
//   BannerModel(
//       {this.setOrder,
//       this.photo,
//       this.title,
//       this.redirect_type,
//       this.redirect_id,
//       this.isPublish});
//
//   BannerModel.fromJson(Map<String, dynamic> json) {
//     setOrder = json['set_order'];
//     photo = json['photo'];
//     title = json['title'];
//     isPublish = json['is_publish'];
//     redirect_type = json['redirect_type'];
//     redirect_id = json['redirect_id'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['set_order'] = this.setOrder;
//     data['photo'] = this.photo;
//     data['title'] = this.title;
//     data['is_publish'] = this.isPublish;
//     data['redirect_type'] = redirect_type;
//     data['redirect_id'] = redirect_id;
//     return data;
//   }
// }
class BannerModel {
  int? setOrder;
  String? photo;
  String? title;
  bool? isPublish;
  String? redirect_type;
  String? redirect_id;
  List<String>? cities; // Cities list added

  BannerModel({
    this.setOrder,
    this.photo,
    this.title,
    this.redirect_type,
    this.redirect_id,
    this.isPublish,
    this.cities, // Add cities in constructor
  });

  BannerModel.fromJson(Map<String, dynamic> json) {
    setOrder = json['set_order'];
    photo = json['photo'];
    title = json['title'];
    isPublish = json['is_publish'];
    redirect_type = json['redirect_type'];
    redirect_id = json['redirect_id'];
    cities =
        (json['cities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(); // Parse cities list
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['set_order'] = setOrder;
    data['photo'] = photo;
    data['title'] = title;
    data['is_publish'] = isPublish;
    data['redirect_type'] = redirect_type;
    data['redirect_id'] = redirect_id;
    data['cities'] = cities; // Add cities in toJson
    return data;
  }
}
