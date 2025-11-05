class WishlistItem {
  final String id;
  final String name;
  final String model;
  final String brand;
  final String category;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final int quantity;
  final bool isOnSale;

  WishlistItem({
    required this.id,
    required this.name,
    required this.model,
    required this.brand,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.quantity,
    required this.isOnSale,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    try {
      // Safe parsing function for different data types
      String parseString(dynamic value) {
        if (value == null) return '';
        return value.toString();
      }

      double parseDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          try {
            return double.parse(value);
          } catch (e) {
            return 0.0;
          }
        }
        return 0.0;
      }

      int parseInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          try {
            return int.parse(value);
          } catch (e) {
            return 0;
          }
        }
        return 0;
      }

      bool parseBool(dynamic value) {
        if (value == null) return false;
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) {
          return value.toLowerCase() == 'true' || value == '1';
        }
        return false;
      }

      // Parse all fields safely
      final id = parseString(json['product_id'] ?? json['id'] ?? json['item_id']);
      final name = parseString(json['name'] ?? json['product_name'] ?? json['title']);
      final model = parseString(json['model'] ?? json['product_model']);
      final brand = parseString(json['brand'] ?? json['product_brand']);
      final category = parseString(json['category'] ?? json['product_category']);

      // Handle price fields
      final currentPrice = parseDouble(json['price'] ?? json['current_price'] ?? json['selling_price'] ?? 0);
      final origPrice = parseDouble(json['original_price'] ?? json['mrp'] ?? json['price'] ?? currentPrice);

      // Handle image URL
      String imageUrl = parseString(json['image'] ?? json['image_url'] ?? json['product_image']);
      if (imageUrl.isNotEmpty && !imageUrl.startsWith('http') && !imageUrl.startsWith('image/')) {
        imageUrl = 'image/$imageUrl';
      }

      final quantity = parseInt(json['quantity'] ?? json['stock'] ?? json['available_quantity'] ?? 0);
      final isOnSale = origPrice > currentPrice && origPrice > 0;

      print('Parsed WishlistItem: id=$id, name=$name, price=$currentPrice, originalPrice=$origPrice');

      return WishlistItem(
        id: id,
        name: name,
        model: model,
        brand: brand,
        category: category,
        price: currentPrice,
        originalPrice: origPrice,
        imageUrl: imageUrl,
        quantity: quantity,
        isOnSale: isOnSale,
      );
    } catch (e) {
      print('Error parsing WishlistItem from JSON: $e');
      print('JSON data: $json');

      // Return a default item if parsing fails
      return WishlistItem(
        id: json['product_id']?.toString() ?? json['id']?.toString() ?? '0',
        name: json['name']?.toString() ?? 'Unknown Product',
        model: '',
        brand: '',
        category: '',
        price: 0.0,
        originalPrice: 0.0,
        imageUrl: '',
        quantity: 0,
        isOnSale: false,
      );
    }
  }

  // Empty constructor for creating placeholder items
  factory WishlistItem.empty() {
    return WishlistItem(
      id: '',
      name: '',
      model: '',
      brand: '',
      category: '',
      price: 0.0,
      originalPrice: 0.0,
      imageUrl: '',
      quantity: 0,
      isOnSale: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model': model,
      'brand': brand,
      'category': category,
      'price': price,
      'original_price': originalPrice,
      'image_url': imageUrl,
      'quantity': quantity,
      'is_on_sale': isOnSale,
    };
  }

  @override
  String toString() {
    return 'WishlistItem(id: $id, name: $name, price: $price, quantity: $quantity)';
  }

  // Equality operators for better list management
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
