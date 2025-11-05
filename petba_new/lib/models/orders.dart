class OrderItem {
  final int orderId;
  final String firstname;
  final String lastname;
  final String telephone;
  final String paymentMethod;
  final String dateModified;
  final String city;
  final String postcode;
  final String address1;
  final String address2;
  final String company;
  final String name;
  final String price;
  final int productId;
  final String orderStatus;
  final String image;

  OrderItem({
    required this.orderId,
    required this.firstname,
    required this.lastname,
    required this.telephone,
    required this.paymentMethod,
    required this.dateModified,
    required this.city,
    required this.postcode,
    required this.address1,
    required this.address2,
    required this.company,
    required this.name,
    required this.price,
    required this.productId,
    required this.orderStatus,
    required this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderId: json['order_id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      telephone: json['telephone'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      dateModified: json['date_modified'] ?? '',
      city: json['city'] ?? '',
      postcode: json['postcode'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      company: json['company'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? '0',
      productId: json['product_id'] ?? 0,
      orderStatus: json['order_status'] ?? '',
      image: json['image'] ?? '',
    );
  }
}