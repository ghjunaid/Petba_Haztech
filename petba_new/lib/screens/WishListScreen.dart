import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Import your UserDataService
import '../providers/Config.dart';
import '../services/user_data_service.dart';
import 'package:petba_new/models/wishlist.dart';

class WishlistPage extends StatefulWidget {
  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> with WidgetsBindingObserver {
  List<WishlistItem> wishlistItems = [];
  bool isLoading = true;
  String? errorMessage;


  Map<String, dynamic>? userData;
  int cartTotal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh wishlist when app comes back to foreground
    if (state == AppLifecycleState.resumed && userData != null) {
      fetchWishlistData(silent: true);
    }
  }

  // Handle route changes - refresh when returning to this page
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && userData != null) {
      // Small delay to ensure the page is fully loaded
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          fetchWishlistData(silent: true);
        }
      });
    }
  }

  Future<void> _initializeUserData() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await UserDataService.isUserLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          errorMessage = 'Please login to view your wishlist';
          isLoading = false;
        });
        return;
      }

      // Get auth data (customer_id, email, token)
      final authData = await UserDataService.getAuthData();
      if (authData == null) {
        setState(() {
          errorMessage = 'User data not found. Please login again.';
          isLoading = false;
        });
        return;
      }

      setState(() {
        userData = authData;
      });

      // Now fetch wishlist data
      await fetchWishlistData();
    } catch (e) {
      setState(() {
        errorMessage = 'Error initializing user data: $e';
        isLoading = false;
      });
    }
  }

  // Add this method to remove duplicates in the WishlistPage
  Future<void> fetchWishlistData({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      // Check if userData is available
      if (userData == null) {
        setState(() {
          errorMessage = 'User data not available. Please login again.';
          isLoading = false;
        });
        return;
      }

      print('=== WISHLIST - FETCHING DATA ===');
      print('User Data: $userData');

      final response = await http.post(
        Uri.parse('$apiurl/api/wishlist'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"userData": userData}),
      ).timeout(Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed API response: $data');

        // Parse the wishlist items from API response
        List<WishlistItem> items = [];

        try {
          // Handle different possible response structures
          List<dynamic>? wishlistData;

          if (data is List) {
            wishlistData = data;
          } else if (data is Map<String, dynamic>) {
            wishlistData = data['wishProducts'] as List<dynamic>? ??
                data['wishlist'] as List<dynamic>? ??
                data['data'] as List<dynamic>? ??
                data['items'] as List<dynamic>?;
          }

          if (wishlistData != null) {
            print('Found wishlist data: $wishlistData');

            // Use a Set to track unique product IDs
            Set<String> seenIds = Set<String>();

            for (var item in wishlistData) {
              try {
                if (item is Map<String, dynamic>) {
                  final wishlistItem = WishlistItem.fromJson(item);
                  if (wishlistItem.id.isNotEmpty) {
                    // Only add if we haven't seen this ID before
                    if (!seenIds.contains(wishlistItem.id)) {
                      seenIds.add(wishlistItem.id);
                      items.add(wishlistItem);
                      print('Added unique item: ${wishlistItem.id} - ${wishlistItem.name}');
                    } else {
                      print('Skipped duplicate item: ${wishlistItem.id} - ${wishlistItem.name}');
                    }
                  }
                }
              } catch (e) {
                print('Error parsing individual wishlist item: $e');
                print('Item data: $item');
              }
            }
          }

          // Update cart total from response if available
          if (data is Map<String, dynamic> && data['total'] != null) {
            try {
              cartTotal = int.parse(data['total'].toString());
            } catch (e) {
              cartTotal = 0;
            }
          }

          if (mounted) {
            setState(() {
              wishlistItems = items;
              isLoading = false;
            });
          }

          print('Successfully parsed ${items.length} unique wishlist items');

          // Show success message only if not silent and items were loaded
          if (!silent && items.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Wishlist updated - ${items.length} items'),
                duration: Duration(seconds: 1),
                backgroundColor: Colors.green[600],
              ),
            );
          }
        } catch (parseError) {
          print('Error parsing wishlist response: $parseError');
          if (mounted) {
            setState(() {
              errorMessage = 'Error parsing wishlist data: $parseError';
              isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 400) {
        if (mounted) {
          setState(() {
            errorMessage = 'Missing credentials. Please login again.';
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          setState(() {
            errorMessage = 'Unauthorized access. Please login again.';
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load wishlist: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching wishlist: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading wishlist: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> removeFromWishlist(String itemId) async {
    try {
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User data not available'),
            backgroundColor: Colors.red[400],
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Optimistically remove from UI
      final removedItem = wishlistItems.firstWhere((item) => item.id == itemId);
      setState(() {
        wishlistItems.removeWhere((item) => item.id == itemId);
      });

      // Prepare request data matching your PHP controller
      Map<String, dynamic> requestData = Map<String, dynamic>.from(userData!);
      requestData['product_id'] = itemId;

      final response = await http.post(
        Uri.parse('$apiurl/api/deletewisheditem'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"userData": requestData}),
      );

      // Dismiss loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Item removed from wishlist'),
            backgroundColor: Colors.green[400],
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () async {
                // Restore item on undo - call makewish API
                await addToWishlist(itemId);
              },
            ),
          ),
        );

        // Refresh wishlist to ensure sync
        await fetchWishlistData(silent: true);
      } else if (response.statusCode == 404) {
        // Item was not in wishlist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item was not in wishlist'),
            backgroundColor: Colors.orange[400],
          ),
        );
      } else if (response.statusCode == 401) {
        // Restore item if unauthorized
        setState(() {
          wishlistItems.add(removedItem);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Please login again.'),
            backgroundColor: Colors.red[400],
          ),
        );
      } else {
        // Restore item if API call failed
        setState(() {
          wishlistItems.add(removedItem);
        });
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['error'] ?? 'Failed to remove item from wishlist'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Restore item on error
      final removedItem = wishlistItems.firstWhere(
            (item) => item.id == itemId,
        orElse: () => WishlistItem.empty(),
      );
      if (removedItem.id.isNotEmpty) {
        setState(() {
          wishlistItems.add(removedItem);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  Future<void> addToWishlist(String productId) async {
    try {
      if (userData == null) return;

      // Prepare request data matching your PHP controller
      Map<String, dynamic> requestData = Map<String, dynamic>.from(userData!);
      requestData['product_id'] = productId;

      final response = await http.post(
        Uri.parse('$apiurl/api/makewish'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"userData": requestData}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        // Refresh wishlist to get updated data
        await fetchWishlistData(silent: true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Item added back to wishlist'),
            backgroundColor: Colors.green[400],
          ),
        );
      }
    } catch (e) {
      print('Error adding to wishlist: $e');
    }
  }

  Future<void> moveToCart(WishlistItem item) async {
    try {
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User data not available'),
            backgroundColor: Colors.red[400],
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$apiurl/api/cart/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "userData": userData,
          "item_id": item.id,
          "quantity": 1,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} added to cart'),
            backgroundColor: Colors.green[400],
          ),
        );
        // Optionally remove from wishlist after adding to cart
        // removeFromWishlist(item.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item to cart'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  Future<void> clearAllWishlist() async {
    try {
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User data not available'),
            backgroundColor: Colors.red[400],
          ),
        );
        return;
      }

      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Clear Wishlist'),
            content: Text('Are you sure you want to remove all items from your wishlist?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Clear All'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      // Store current items for potential undo
      final previousItems = List<WishlistItem>.from(wishlistItems);

      // Clear items optimistically
      setState(() {
        wishlistItems.clear();
      });

      // Remove items one by one (less efficient but works with current backend)
      bool allSuccessful = true;
      for (WishlistItem item in previousItems) {
        try {
          Map<String, dynamic> requestData = Map<String, dynamic>.from(userData!);
          requestData['product_id'] = item.id;

          final response = await http.post(
            Uri.parse('$apiurl/api/deletewisheditem'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({"userData": requestData}),
          );

          if (response.statusCode != 200) {
            allSuccessful = false;
            break;
          }
        } catch (e) {
          allSuccessful = false;
          break;
        }
      }

      if (allSuccessful) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wishlist cleared successfully'),
            backgroundColor: Colors.green[400],
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () async {
                // Restore all items
                for (WishlistItem item in previousItems) {
                  await addToWishlist(item.id);
                }
              },
            ),
          ),
        );

        // Refresh wishlist to ensure sync
        await fetchWishlistData(silent: true);
      } else {
        // Restore items if clearing failed
        setState(() {
          wishlistItems = previousItems;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear wishlist'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing wishlist: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  // Method to handle login redirect
  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login'); // Adjust route as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Wishlist',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (wishlistItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Wishlist shared!')));
              },
            ),
          IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                if (userData != null) {
                  fetchWishlistData();
                } else {
                  _initializeUserData();
                }
              }
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
          ? _buildErrorState()
          : wishlistItems.isEmpty
          ? _buildEmptyWishlist()
          : Column(
        children: [
          _buildWishlistHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (userData != null) {
                  await fetchWishlistData();
                } else {
                  await _initializeUserData();
                }
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: wishlistItems.length,
                itemBuilder: (context, index) {
                  return _buildWishlistItem(wishlistItems[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          SizedBox(height: 16),
          Text(
            'Loading wishlist...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            // Show different buttons based on error type
            if (errorMessage?.contains('login') == true ||
                errorMessage?.contains('Unauthorized') == true)
              ElevatedButton(
                onPressed: _redirectToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: Text('Go to Login'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  if (userData != null) {
                    fetchWishlistData();
                  } else {
                    _initializeUserData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: Text('Try Again'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            SizedBox(height: 24),
            Text(
              'Your wishlist is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add items to your wishlist to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to browse products
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            '${wishlistItems.length} items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          if (cartTotal > 0) ...[
            SizedBox(width: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Cart: $cartTotal items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          Spacer(),
          if (wishlistItems.isNotEmpty)
            TextButton.icon(
              onPressed: clearAllWishlist,
              icon: Icon(Icons.clear_all, size: 18),
              label: Text('Clear All'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(WishlistItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                      '$apiurl/${item.imageUrl}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 40,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    )
                        : Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                  ),
                ),
                // Sale badge
                if (item.isOnSale)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'SALE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.model.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      'Model: ${item.model}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  if (item.brand.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      'Brand: ${item.brand}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  if (item.category.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      'Category: ${item.category}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                      if (item.isOnSale) ...[
                        SizedBox(width: 8),
                        Text(
                          '\${item.originalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.quantity > 0) ...[
                    SizedBox(height: 2),
                    Text(
                      'Stock: ${item.quantity} available',
                      style: TextStyle(
                          fontSize: 12,
                          color: item.quantity < 10 ? Colors.orange[600] : Colors.green[600]
                      ),
                    ),
                  ],
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: item.quantity > 0 ? () => moveToCart(item) : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: item.quantity > 0 ? Colors.blue[600] : Colors.grey,
                            side: BorderSide(color: item.quantity > 0 ? Colors.blue[600]! : Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            item.quantity > 0 ? 'Add to Cart' : 'Out of Stock',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () => removeFromWishlist(item.id),
                        icon: Icon(Icons.delete_outline),
                        color: Colors.red[400],
                        constraints: BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

