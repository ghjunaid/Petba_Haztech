import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/services/user_data_service.dart';
import 'package:petba_new/models/product.dart';

import '../providers/Config.dart';
import 'CartPage.dart';
import 'WishListScreen.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final String? productName;

  const ProductDetailPage({
    Key? key,
    required this.productId,
    this.productName,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  ProductDetail? _productDetail;
  bool _isLoading = true;
  String _error = '';
  int _selectedQuantity = 1;
  bool _isFavorited = false;
  bool _isAddingToCart = false;
  bool _isAddingToWishlist = false;

  // Dark theme colors
  static const Color primaryDark = Color(0xFF1a1a1a);
  static const Color cardDark = Color(0xFF2a2a2a);
  static const Color surfaceDark = Color(0xFF333333);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      print('Fetching product details for ID: ${widget.productId}');

      final authData = await UserDataService.getAuthData();
      print('Auth data: $authData');

      if (authData == null) {
        setState(() {
          _error = 'Please login to view product details';
          _isLoading = false;
        });
        return;
      }

      final requestBody = {
        "userData": {
          "customer_id": authData['customer_id'].toString(),
          "email": authData['email'],
          "token": authData['token'],
          "product_id": widget.productId
        }
      };

      print('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$apiurl/api/productDetails'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');

        Map<String, dynamic>? productData;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('product_id') || data.containsKey('name')) {
            productData = data;
          } else if (data.containsKey('productDetails')) {
            productData = data['productDetails'];
          } else if (data.containsKey('proDetails')) {
            productData = data['proDetails'];
          } else if (data.containsKey('data')) {
            productData = data['data'];
          } else if (data.containsKey('success') && data['success'] == true) {
            for (String key in ['product', 'productDetails', 'proDetails', 'data', 'result']) {
              if (data.containsKey(key)) {
                productData = data[key];
                break;
              }
            }
          }
        }

        if (productData != null) {
          print('Product data found: $productData');
          setState(() {
            _productDetail = ProductDetail.fromJson(productData!);
            _isLoading = false;
          });
        } else {
          print('No product data found in response');
          setState(() {
            _error = 'Product details not found in response: ${data.toString()}';
            _isLoading = false;
          });
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        setState(() {
          _error = 'Server error (${response.statusCode}): ${response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception: $e');
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    if (_isAddingToCart) return; // Prevent multiple requests

    setState(() => _isAddingToCart = true);

    try {
      // Show loading state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Adding to cart...', style: TextStyle(color: textPrimary)),
            ],
          ),
          backgroundColor: cardDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      final authData = await UserDataService.getAuthData();
      if (authData == null) {
        _showErrorSnackBar('Please login to add items to cart');
        return;
      }

      final requestBody = {
        "userData": {
          "customer_id": authData['customer_id'].toString(),
          "email": authData['email'],
          "token": authData['token'],
          "product_id": widget.productId,
          "qty": _selectedQuantity
        }
      };

      print('Add to cart request: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$apiurl/api/addcart'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('Add to cart response: ${response.statusCode} - ${response.body}');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed cart response data: $data');

        // Check for success response
        if (data['added'] != null ) {
          // Success case
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Added to cart successfully!',
                          style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_productDetail!.name} (Qty: $_selectedQuantity)',
                    style: const TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  // Show total count if available
                  if (data['total'] != null)
                    Text(
                      'Total items in cart: ${data['total']}',
                      style: const TextStyle(color: textTertiary, fontSize: 11),
                    ),
                ],
              ),
              backgroundColor: cardDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View Cart',
                textColor: accentColor,
                onPressed: () {
                  _navigateToCart();
                },
              ),
            ),
          );
        // }
        // else if (data['added'] != null && data['added'] == "product already added to cart") {
        //   // Product already in cart
        //   _showErrorSnackBar('Product is already in your cart');
        } else {
          // Other response
          _showErrorSnackBar('Unexpected response: ${data.toString()}');
        }
      }
    } catch (e) {
      print('Add to cart error: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('Network error. Please check your connection.');
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  void _navigateToCart() async {
    final authData = await UserDataService.getAuthData();
    if (authData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartPage(
            customerId: authData['customer_id'].toString(),
            email: authData['email'],
            token: authData['token'],
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: cardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.productName ?? 'Product Details',
          style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardDark.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: cardDark.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited ? Colors.red : textPrimary,
                size: 20,
              ),
              onPressed: () {
                setState(() => _isFavorited = !_isFavorited);
                _addToWishlist();
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: cardDark.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: textPrimary, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Share feature coming soon!'),
                    backgroundColor: cardDark,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _productDetail != null ? _buildBottomBar() : null,
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Text(
            'Product ID: ${widget.productId}\n'
                'Loading: $_isLoading\n'
                'Error: $_error\n'
                'Product Detail: ${_productDetail?.name ?? 'null'}',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading product details...',
              style: TextStyle(color: textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Failed to load product details',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    'Retry',
                    Icons.refresh,
                    accentColor,
                        () => _fetchProductDetails(),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    'Debug',
                    Icons.bug_report,
                    surfaceDark,
                    _showDebugInfo,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_productDetail == null) {
      return const Center(
        child: Text(
          'No product details available',
          style: TextStyle(color: textSecondary, fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(),
          _buildProductInfo(),
          _buildDescription(),
          _buildSpecifications(),
          _buildReviews(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: textPrimary, size: 18),
      label: Text(
        text,
        style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 400,
      margin: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.network(
                '$producturl/${_productDetail!.image}',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cardDark, surfaceDark],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.pets,
                        size: 80,
                        color: textTertiary,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: cardDark,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 3,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_productDetail!.discount != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.redAccent],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_productDetail!.discount}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _productDetail!.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (_productDetail!.brand != null)
            Text(
              'by ${_productDetail!.brand}',
              style: const TextStyle(
                fontSize: 16,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 16),
          _buildRatingRow(),
          const SizedBox(height: 20),
          _buildPriceRow(),
          const SizedBox(height: 20),
          _buildStockStatus(),
          if (_productDetail!.inStock) ...[
            const SizedBox(height: 24),
            _buildQuantitySelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                _productDetail!.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${_productDetail!.reviews} reviews',
          style: const TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${_productDetail!.currentPrice.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 12),
        if (_productDetail!.originalPrice > _productDetail!.currentPrice) ...[
          Text(
            '₹${_productDetail!.originalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              decoration: TextDecoration.lineThrough,
              color: textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SAVE ₹${(_productDetail!.originalPrice - _productDetail!.currentPrice).toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _productDetail!.inStock
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _productDetail!.inStock
              ? Colors.green.withOpacity(0.5)
              : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _productDetail!.inStock ? Icons.check_circle : Icons.cancel,
            color: _productDetail!.inStock ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _productDetail!.inStock
                ? 'In Stock (${_productDetail!.quantity} available)'
                : 'Out of Stock',
            style: TextStyle(
              color: _productDetail!.inStock ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantity: ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                Icons.remove,
                _selectedQuantity > 1 ? () => setState(() => _selectedQuantity--) : null,
              ),
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Text(
                  '$_selectedQuantity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              _buildQuantityButton(
                Icons.add,
                _selectedQuantity < _productDetail!.quantity
                    ? () => setState(() => _selectedQuantity++)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback? onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: onPressed != null ? textPrimary : textTertiary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    // Clean and prepare description text
    String description = _productDetail!.description;
    String cleanDescription = _stripHtmlTags(description).trim();

    // Check if description is empty or just whitespace
    bool hasDescription = cleanDescription.isNotEmpty && cleanDescription.length > 1;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: surfaceDark.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          hasDescription
              ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cleanDescription,
              style: const TextStyle(
                fontSize: 16,
                color: textSecondary,
                height: 1.6,
              ),
            ),
          )
              : Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: textTertiary.withOpacity(0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: textTertiary,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No description available',
                  style: TextStyle(
                    fontSize: 16,
                    color: textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Raw data: "${description.isEmpty ? 'Empty' : description.substring(0, description.length > 50 ? 50 : description.length)}..."',
                  style: TextStyle(
                    fontSize: 12,
                    color: textTertiary.withOpacity(0.7),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecifications() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecRow('Category', _productDetail!.category),
          if (_productDetail!.brand != null)
            _buildSpecRow('Brand', _productDetail!.brand!),
          _buildSpecRow('Model', _productDetail!.model),
          _buildSpecRow('SKU', 'PRD${_productDetail!.productId}'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: textTertiary,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(color: textTertiary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all reviews
                },
                child: const Text(
                  'See all',
                  style: TextStyle(color: accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  '${_productDetail!.rating}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < _productDetail!.rating.floor()
                              ? Icons.star
                              : index < _productDetail!.rating
                              ? Icons.star_half
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on ${_productDetail!.reviews} reviews',
                      style: const TextStyle(color: textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(right: 8),
                child: OutlinedButton.icon(
                  onPressed: () => _addToWishlist(),
                  icon: Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? Colors.red : textSecondary,
                    size: 20,
                  ),
                  label: Text(
                    'Wishlist',
                    style: TextStyle(
                      color: _isFavorited ? Colors.red : textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _isFavorited ? Colors.red : textTertiary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _productDetail!.inStock ? () => _addToCart() : null,
                  icon: const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    _productDetail!.inStock ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _productDetail!.inStock ? accentColor : textTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _addToWishlist() async {
    if (_productDetail == null || _isAddingToWishlist) return; // Check flag

    try {
      // Set flag to prevent multiple calls
      setState(() {
        _isAddingToWishlist = true;
      });

      final authData = await UserDataService.getAuthData();
      if (authData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to add items to wishlist'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Prepare request data for wishlist API - MATCH THE WORKING POSTMAN REQUEST
      final requestData = {
        "userData": {
          "customer_id": int.parse(authData['customer_id'].toString()),
          "email": authData['email'],
          "token": authData['token'],
          "product_id": widget.productId
        }
      };

      print('=== ADDING TO WISHLIST ===');
      print('Request data: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('$apiurl/api/makewish'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 10));

      // Dismiss loading dialog
      Navigator.of(context).pop();

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Check if item was already in wishlist
        if (responseData['message']?.toString().toLowerCase().contains('already') == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_productDetail!.name} is already in your wishlist!'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_productDetail!.name} added to wishlist!'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View Wishlist',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WishlistPage()),
                  );
                },
              ),
            ),
          );
        }
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to add to wishlist'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error adding to wishlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to wishlist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset flag
      if (mounted) {
        setState(() {
          _isAddingToWishlist = false;
        });
      }
    }
  }

  // void _showDebugInfo() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: cardDark,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: const Text(
  //         'Debug Info',
  //         style: TextStyle(color: textPrimary),
  //       ),
  //       content: SingleChildScrollView(
  //         child: Text(
  //           'Product ID: ${widget.productId}\n'
  //               'Loading: $_isLoading\n'
  //               'Error: $_error\n'
  //               'Product Detail: ${_productDetail?.name ?? 'null'}',
  //           style: const TextStyle(
  //             fontFamily: 'monospace',
  //             color: textSecondary,
  //           ),
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text(
  //             'Close',
  //             style: TextStyle(color: accentColor),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  String _stripHtmlTags(String htmlText) {
    if (htmlText.isEmpty) return '';

    // Remove HTML tags
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String result = htmlText.replaceAll(exp, '');

    // Replace HTML entities
    result = result
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .replaceAll('&hellip;', '...')
        .replaceAll(RegExp(r'&#\d+;'), ' '); // Remove other numeric entities

    // Clean up whitespace
    result = result
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Clean up line breaks
        .trim();

    return result;
  }
}