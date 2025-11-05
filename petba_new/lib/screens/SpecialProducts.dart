import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:petba_new/providers/Config.dart';

// Model class for special products
class SpecialProduct {
  final int productId;
  final String model;
  final String name;
  final String description;
  final int quantity;
  final String image;
  final String price;
  final String specialPrice;
  final String? discount;
  final String category;
  final String brand;

  SpecialProduct({
    required this.productId,
    required this.model,
    required this.name,
    required this.description,
    required this.quantity,
    required this.image,
    required this.price,
    required this.specialPrice,
    this.discount,
    required this.category,
    required this.brand,
  });

  factory SpecialProduct.fromJson(Map<String, dynamic> json) {
    return SpecialProduct(
      productId: json['product_id'] ?? 0,
      model: json['model'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      image: json['image'] ?? '',
      price: json['price'] ?? '0.0000',
      specialPrice: json['specialprice'] ?? '0.0000',
      discount: json['discount'],
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
    );
  }
}

class SpecialProductsScreen extends StatefulWidget {
  @override
  _SpecialProductsScreenState createState() => _SpecialProductsScreenState();
}

class _SpecialProductsScreenState extends State<SpecialProductsScreen> {
  List<SpecialProduct> specialProducts = [];
  bool isLoading = true;
  String errorMessage = '';

  final Color primaryColor = Color(0xff253150);

  @override
  void initState() {
    super.initState();
    fetchSpecialProducts();
  }

  Future<void> fetchSpecialProducts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('$apiurl/api/special-product-list'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> specialList = data['special'] ?? [];

        setState(() {
          specialProducts = specialList
              .map((item) => SpecialProduct.fromJson(item))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load products. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  String _stripHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '').trim();
  }

  double _parsePrice(String priceString) {
    try {
      return double.parse(priceString.replaceAll(RegExp(r'[^\d.]'), ''));
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Special Products',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchSpecialProducts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchSpecialProducts,
        color: primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Loading special products...',
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchSpecialProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (specialProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: Colors.grey,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No special products available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: specialProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(specialProducts[index]);
      },
    );
  }

  Widget _buildProductCard(SpecialProduct product) {
    double originalPrice = _parsePrice(product.price);
    double specialPrice = _parsePrice(product.specialPrice);
    double discountPercent = 0;

    if (originalPrice > 0) {
      discountPercent = ((originalPrice - specialPrice) / originalPrice) * 100;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with brand and category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.brand,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Product name
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 8),

              // Product description
              Text(
                _stripHtmlTags(product.description),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 16),

              // Price section
              Row(
                children: [
                  // Special price
                  Text(
                    '₹${specialPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),

                  SizedBox(width: 8),

                  // Original price (strikethrough)
                  if (originalPrice > specialPrice)
                    Text(
                      '₹${originalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey[500],
                      ),
                    ),

                  SizedBox(width: 8),

                  // Discount percentage
                  if (discountPercent > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${discountPercent.toStringAsFixed(0)}% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 16),

              // Bottom section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Stock status
                  Row(
                    children: [
                      Icon(
                        product.quantity > 0
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: product.quantity > 0
                            ? Colors.green
                            : Colors.red,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        product.quantity > 0
                            ? 'In Stock (${product.quantity})'
                            : 'Out of Stock',
                        style: TextStyle(
                          color: product.quantity > 0
                              ? Colors.green
                              : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Add to cart button
                  ElevatedButton(
                    onPressed: product.quantity > 0
                        ? () {
                      // Handle add to cart
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart!'),
                          backgroundColor: primaryColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// // Usage example
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Pet Store Special Products',
//       theme: ThemeData(
//         primarySwatch: MaterialColor(0xff253150, {
//           50: Color(0xffe5e7eb),
//           100: Color(0xffbfc4d0),
//           200: Color(0xff959db2),
//           300: Color(0xff6a7594),
//           400: Color(0xff4a577d),
//           500: Color(0xff253150),
//           600: Color(0xff212c49),
//           700: Color(0xff1b2540),
//           800: Color(0xff151e37),
//           900: Color(0xff0c1227),
//         }),
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: SpecialProductsScreen(),
//     );
//   }
// }