// Updated ProductsPage.dart with API integration
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/providers/sort_products.dart';
import 'package:petba_new/screens/ProductDetailsScreen.dart';
import 'package:petba_new/models/product.dart';

import '../providers/Config.dart';
import '../services/user_data_service.dart';
import 'CartPage.dart';



class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _selectedCategory = 'All';
  String _sortBy = 'Featured';
  List<Product> _allProducts = [];
  bool _isLoading = true;
  String _error = '';

  // Filter state
  List<Filter> _selectedFilters = [];

  // Map category names to filter_group_id
  final Map<String, int> _categoryToFilterGroupId = {
    'Food': 2,
    'Toys': 3,
    'Accessories': 4,
    'Health': 5,
    'Grooming': 6,
  };

  final List<String> _categories = [
    'All',
    'Food',
    'Toys',
    'Accessories',
    'Health',
    'Grooming',
    'Cats',
    'Dogs',
  ];

  final List<String> _sortOptions = [
    'Featured',
    'Price: Low to High',
    'Price: High to Low',
    'Rating',
    'Newest',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Fetch products from API
  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await http.get(
        Uri.parse('$apiurl/api/latestproduct'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> productsJson = data['latestproduct'];
        print('Products response: ${response.body}');

        // Deduplicate products by productId to handle products in multiple categories
        Map<int, Product> productMap = {};
        for (var json in productsJson) {
          Product product = Product.fromJson(json);
          productMap[product.productId] = product;
        }

        setState(() {
          _allProducts = productMap.values.toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load products. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading products: $e';
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    var filtered = _selectedCategory == 'All'
        ? _allProducts
        : _allProducts.where((p) => p.categories.contains(_selectedCategory)).toList();

    switch (_sortBy) {
      case 'Price: Low to High': filtered.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'Price: High to Low': filtered.sort((a, b) => b.price.compareTo(a.price)); break;
      case 'Rating': filtered.sort((a, b) => b.rating.compareTo(a.rating)); break;
      case 'Newest': filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded)); break;
      default: filtered.sort((a, b) => b.quantity.compareTo(a.quantity));
    }
    return filtered;
  }

  void _showSortBottomSheet() {
    SortBottomSheet.show(
      context: context,
      currentSortBy: _sortBy,
      onSortChanged: (newSortBy) => setState(() => _sortBy = newSortBy),
      sortOptions: _sortOptions,
    );
  }

  Future<void> _navigateToCart() async {
    try {
      final authData = await UserDataService.getAuthData();
      if (authData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view your cart'), backgroundColor: Colors.red),
        );
        return;
      }
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CartPage(
          customerId: authData['customer_id'].toString(),
          email: authData['email'],
          token: authData['token'],
        ),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Pet Products'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              _navigateToCart();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories and Sort
          Container(
            color: Colors.grey.shade900,
            child: Column(
              children: [
                // Categories with proper scrolling
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      final hasFilterGroup = _categoryToFilterGroupId.containsKey(category);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                          // If category has a filter group, show filter options
                          if (hasFilterGroup) {
                            final filterGroupId = _categoryToFilterGroupId[category]!;
                            _showProductFilterOptions(filterGroupId);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                            right: 12,
                            top: 8,
                            bottom: 8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Sort and Filter
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Text(
                          '${_filteredProducts.length} products found',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: SortButton(
                          currentSortBy: _sortBy,
                          onPressed: _showSortBottomSheet,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Products Grid or Loading/Error states
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_error, style: TextStyle(color: Colors.grey.shade400, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchProducts, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No products found', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (_, index) => _buildProductCard(_filteredProducts[index]),
    );
  }

  Widget _buildProductCard(Product product) {
    final originalPrice = product.specialPrice != null
        ? double.parse(product.price.toString())
        : 0.0;
    final currentPrice = product.specialPrice != null
        ? double.parse(product.specialPrice.toString())
        : double.parse(product.price.toString());

    final discountPercent = product.specialPrice != null
        ? ((originalPrice - currentPrice) / originalPrice * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with discount badge
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.network(
                        '$producturl/${product.image}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              _getCategoryIcon(product.category),
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (discountPercent > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (product.quantity <= 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.brand ?? 'Pet Store',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${product.rating} (${product.reviews})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '₹${currentPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (product.specialPrice != null)
                              Flexible(
                                child: Text(
                                  '₹${originalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        // const SizedBox(height: 4),
                        // SizedBox(
                        //   width: double.infinity,
                        //   height: 26,
                        //   child: ElevatedButton(
                        //     onPressed: product.quantity > 0
                        //         ? () => _addToCart(product)
                        //         : null,
                        //     style: ElevatedButton.styleFrom(
                        //       padding: const EdgeInsets.symmetric(vertical: 1),
                        //       textStyle: const TextStyle(fontSize: 10),
                        //       minimumSize: Size.zero,
                        //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        //     ),
                        //     child: FittedBox(
                        //       child: Text(
                        //         product.quantity > 0
                        //             ? 'Add to Cart'
                        //             : 'Out of Stock',
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': case 'cats': case 'dogs': return Icons.restaurant;
      case 'toys': return Icons.sports_soccer;
      case 'accessories': return Icons.shopping_bag;
      case 'health': return Icons.medical_services;
      case 'grooming': return Icons.content_cut;
      default: return Icons.pets;
    }
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Search Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetails(Product product) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProductDetailPage(productId: product.productId, productName: product.name),
    ));
  }

  Future<void> _showProductFilterOptions(int filterGroupId) async {
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/filter-by-group'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'filter_group_id': filterGroupId}),
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode != 200) {
        final error = json.decode(response.body)['error'] ?? 'Failed to load filters';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red));
        return;
      }

      final data = json.decode(response.body);
      if (data.containsKey('error') || data['filter_group'] == null || data['filters'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid response'), backgroundColor: Colors.red));
        return;
      }

      final filtersList = (data['filters'] as List).map((json) {
        final filter = Filter.fromJson(json);
        final existing = _selectedFilters.firstWhere((f) => f.filterId == filter.filterId, orElse: () => Filter(filterId: -1, name: '', filterGroupId: -1));
        if (existing.filterId != -1) filter.isSelected = existing.isSelected;
        return filter;
      }).toList();

      if (filtersList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No filters found'), backgroundColor: Colors.orange));
        return;
      }

      if (!mounted) return;
      _showFilterBottomSheet(data['filter_group'], filtersList, filterGroupId);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showFilterBottomSheet(Map<String, dynamic> filterGroup, List<Filter> filters, int filterGroupId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (_, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
                    Expanded(child: Text(filterGroup['name'] ?? 'Filters', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                    TextButton(
                      onPressed: () => setModalState(() => filters.forEach((f) => f.isSelected = false)),
                      child: const Text('Clear Filters', style: TextStyle(color: Color(0xFF2563EB), fontSize: 14)),
                    ),
                  ],
                ),
              ),
              // Filters
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: filters.map((filter) => CheckboxListTile(
                    title: Text(filter.name),
                    value: filter.isSelected,
                    onChanged: (value) => setModalState(() => filter.isSelected = value ?? false),
                    activeColor: const Color(0xFF2563EB),
                  )).toList(),
                ),
              ),
              // Bottom bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
                child: Row(
                  children: [
                    Text('${filters.where((f) => f.isSelected).length} selected', style: const TextStyle(fontSize: 14)),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedFilters.removeWhere((f) => f.filterGroupId == filterGroupId);
                            _selectedFilters.addAll(filters.where((f) => f.isSelected));
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyFilters() async {
    if (_selectedFilters.isEmpty) {
      _fetchProducts();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/filtered-products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'filter_ids': _selectedFilters.map((f) => f.filterId).toList()}),
      );

      if (response.statusCode == 200) {
        final productsJson = (json.decode(response.body)['products'] as List?) ?? [];
        final productMap = <int, Product>{};
        for (var json in productsJson) {
          final product = Product.fromJson(json);
          productMap[product.productId] = product;
        }
        setState(() {
          _allProducts = productMap.values.toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
}
