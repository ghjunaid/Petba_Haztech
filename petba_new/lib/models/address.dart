class Address {
  final String customerId;
  final String email;
  final String token;
  final String firstName;
  final String lastName;
  final String addressLine1;
  final String country;
  final String state;
  final String city;
  final String pincode;
  final String phone;
  final String? altPhone;
  final String? locality;
  final String? landmark;

  Address({
    required this.customerId,
    required this.email,
    required this.token,
    required this.firstName,
    required this.lastName,
    required this.addressLine1,
    required this.country,
    required this.state,
    required this.city,
    required this.pincode,
    required this.phone,
    this.altPhone,
    this.locality,
    this.landmark,
  });

  /// Build an [Address] from backend JSON.
  /// Supports both payload-style keys (`first_name`) and response keys (`firstname`).
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      customerId: (json['customer_id'] ?? json['c_id'] ?? '').toString(),
      email: json['email'] ?? '',
      token: json['token'] ?? '',
      firstName: json['first_name'] ?? json['firstname'] ?? '',
      lastName: json['last_name'] ?? json['lastname'] ?? '',
      addressLine1: json['address'] ??
          json['address_1'] ??
          json['addressLine1'] ??
          '',
      country: json['country'] ?? json['country_name'] ?? 'India',
      state: json['state'] ?? json['state_name'] ?? '',
      city: json['city'] ?? '',
      pincode: (json['pincode'] ?? json['pin'] ?? '').toString(),
      phone: json['phone'] ?? json['shipping_phone'] ?? '',
      altPhone: json['Altphone'] ?? json['alt_number'],
      locality: json['locality'] ?? json['address_2'],
      landmark: json['landmark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'email': email,
      'token': token,
      'first_name': firstName,
      'last_name': lastName,
      'address': addressLine1,
      'country': country,
      'state': state,
      'city': city,
      'pincode': pincode,
      'phone': phone,
      'Altphone': altPhone,
      'locality': locality,
      'landmark': landmark,
    };
  }
}

