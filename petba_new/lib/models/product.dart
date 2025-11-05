
class ProductDetail {
  final int productId;
  final String name;
  final String model;
  final String description;
  final String image;
  final String category;
  final String? brand;
  final double currentPrice;
  final double originalPrice;
  final int quantity;
  final String? discount;
  final double rating;
  final int reviews;
  final bool inStock;

  ProductDetail({
    required this.productId,
    required this.name,
    required this.model,
    required this.description,
    required this.image,
    required this.category,
    this.brand,
    required this.currentPrice,
    required this.originalPrice,
    required this.quantity,
    this.discount,
    required this.rating,
    required this.reviews,
    required this.inStock,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing ProductDetail from JSON: $json');

    // Handle price conversion
    double currentPrice = 0.0;
    double originalPrice = 0.0;

    try {
      if (json['specialprice'] != null && json['specialprice'].toString().isNotEmpty && json['specialprice'].toString() != 'null') {
        currentPrice = double.tryParse(json['specialprice'].toString()) ?? 0.0;
        originalPrice = double.tryParse(json['price'].toString()) ?? currentPrice;
      } else {
        currentPrice = double.tryParse(json['price'].toString()) ?? 0.0;
        originalPrice = currentPrice;
      }
    } catch (e) {
      print('❌ Price parsing error: $e');
      currentPrice = 0.0;
      originalPrice = 0.0;
    }

    return ProductDetail(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? 'Unknown Product',
      model: json['model'] ?? 'N/A',
      description: json['description'] ?? 'No description available',
      image: json['image'] ?? '',
      category: json['category'] ?? 'General',
      brand: json['brand'],
      currentPrice: currentPrice,
      originalPrice: originalPrice,
      quantity: json['quantity'] ?? 0,
      discount: json['discount']?.toString(),
      rating: 4.5, // Default rating since API might not provide it
      reviews: (json['quantity'] ?? 0) * 2, // Estimate reviews
      inStock: (json['quantity'] ?? 0) > 0,
    );
  }
}

class Product {
  final int productId;
  final String model;
  final String name;
  final String description;
  final int quantity;
  final String image;
  final String price;
  final String? specialPrice;
  final String? discount;
  final String category;
  final String? brand;

  // Computed properties for compatibility
  double get rating => 4.5; // Default rating since API doesn't provide it
  int get reviews => quantity * 2; // Estimate reviews based on quantity
  DateTime get dateAdded => DateTime.now(); // Default to current date

  Product({
    required this.productId,
    required this.model,
    required this.name,
    required this.description,
    required this.quantity,
    required this.image,
    required this.price,
    this.specialPrice,
    this.discount,
    required this.category,
    this.brand,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'] ?? 0,
      model: json['model'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      image: json['image'] ?? '',
      price: json['price'] ?? '0',
      specialPrice: json['specialprice'],
      discount: json['discount'],
      category: json['category'] ?? 'General',
      brand: json['brand'],
    );
  }
}