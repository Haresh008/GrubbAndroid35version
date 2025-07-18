class NewAddressModal {
  final String id; // New variable
  final String country;
  final String zipCode;
  final String userId;
  final String longitude;
  final String city;
  final String landmark;
  final String addressType;
  final String street;
  final String latitude;

  NewAddressModal({
    required this.id, // Updated constructor
    required this.country,
    required this.zipCode,
    required this.userId,
    required this.longitude,
    required this.city,
    required this.landmark,
    required this.addressType,
    required this.street,
    required this.latitude,
  });

  factory NewAddressModal.fromMap(Map<String, dynamic> data) {
    return NewAddressModal(
      id: data['id'] ?? '',
      // Initialize id from data map
      country: data['country'] ?? '',
      zipCode: data['zip_code'] ?? '',
      userId: data['user_id'] ?? '',
      longitude: data['longitude'] ?? '',
      city: data['city'] ?? '',
      landmark: data['landmark'] ?? '',
      addressType: data['address_type'] ?? '',
      street: data['street'] ?? '',
      latitude: data['latitude'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Include id in the map
      'country': country,
      'zip_code': zipCode,
      'user_id': userId,
      'longitude': longitude,
      'city': city,
      'landmark': landmark,
      'address_type': addressType,
      'street': street,
      'latitude': latitude,
    };
  }
}
