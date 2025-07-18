class CouponUsage {
  String couponId;
  String id;
  String useDate;
  String userId;

  CouponUsage({
    required this.couponId,
    required this.id,
    required this.useDate,
    required this.userId,
  });

  // Factory method to create a CouponUsage instance from a map
  factory CouponUsage.fromMap(Map<String, dynamic> map) {
    return CouponUsage(
      couponId: map['coupon_id'] as String,
      id: map['id'] as String,
      useDate: map['use_date'] as String,
      userId: map['user_id'] as String,
    );
  }

  // Method to convert a CouponUsage instance to a map
  Map<String, dynamic> toMap() {
    return {
      'coupon_id': couponId,
      'id': id,
      'use_date': useDate,
      'user_id': userId,
    };
  }
}
