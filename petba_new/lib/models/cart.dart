class CartItem {
  final int productId;
  final String model;
  final String name;
  final String description;
  final int quantity;
  final String image;
  final double price;
  final double? specialprice;
  final double? discount;
  final String? category;
  final String? brand;
  final int cartId;
  int cartQty;

  CartItem({
    required this.productId,
    required this.model,
    required this.name,
    required this.description,
    required this.quantity,
    required this.image,
    required this.price,
    this.specialprice,
    this.discount,
    this.category,
    this.brand,
    required this.cartId,
    required this.cartQty,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: int.parse(json['product_id'].toString()),
      model: json['model'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: int.parse(json['quantity']?.toString() ?? '0'),
      image: json['image'] ?? '',
      price: double.parse(json['price']?.toString() ?? '0'),
      specialprice: json['specialprice'] != null ? double.tryParse(json['specialprice'].toString()) : null,
      discount: json['discount'] != null ? double.tryParse(json['discount'].toString()) : null,
      category: json['category'],
      brand: json['brand'],
      cartId: int.parse(json['cart_id'].toString()),
      cartQty: int.parse(json['cart_qty']?.toString() ?? '1'),
    );
  }

  double get effectivePrice {
    return specialprice ?? discount ?? price;
  }
}