//CartPage
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../providers/Config.dart';

class CartPage extends StatefulWidget {
  final String customerId;
  final String email;
  final String? token;

  CartPage({
    Key? key,
    required this.customerId,
    required this.email,
    this.token,
  }) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> cartItems = [];
  bool isLoading = true;
  String errorMessage = '';

  // // Static user data for testing
  // static Map<String, dynamic> staticUserData = {
  //   "userData": {
  //     "customer_id": "29",
  //     "email": "Manthansutar99@gmail.com",
  //     "token": "f-UpT89sF6Q:APA91bH-dMBAi59RoP5mip60AAwHZSyaRa4_djXaYfH7BHfVRJPPmB8V2n0XrPHJ0ND3spj9Ww-7ZSGszw5D0qZw"
  //   }
  // };


  @override
  void initState() {
    super.initState();
    fetchCartProducts();
  }

  Future<void> fetchCartProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Create dynamic user data
      final userData = {
        "userData": {
          "customer_id": widget.customerId,
          "email": widget.email,
          "token": widget.token,
        }
      };

      final response = await http.post(
        Uri.parse('$apiurl/api/cartProducts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(userData), // Use dynamic userData
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey('cartProducts')) {
          final List<dynamic> products = responseData['cartProducts'];
          setState(() {
            cartItems = products.map((product) => CartItem.fromJson(product)).toList();
            isLoading = false;
          });
        } else if (responseData.containsKey('cart')) {
          // No cart data found
          setState(() {
            cartItems = [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Unexpected response format';
            isLoading = false;
          });
        }
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['error'] ?? 'Failed to load cart';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching cart: $e');
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> updateCartItemQuantity(int cartId, int productId, int newQuantity) async {
    try {
      // Step 1: Remove the existing item
      final removeResponse = await http.post(
        Uri.parse('$apiurl/api/deletecartitem'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userData': {
            'customer_id': widget.customerId,
            'email': widget.email,
            'token': widget.token,
            'c_id': cartId,
          }
        }),
      );

      if (removeResponse.statusCode == 200) {
        // Step 2: Add the product back with new quantity
        final addResponse = await http.post(
          Uri.parse('$apiurl/api/addcart'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'userData': {
              'customer_id': widget.customerId,
              'email': widget.email,
              'token': widget.token,
              'product_id': productId,
              'qty': newQuantity,
            }
          }),
        );

        if (addResponse.statusCode == 200) {
          // Successfully updated quantity
          print('Quantity updated successfully');
          // Refresh the cart to get updated data
          await fetchCartProducts();
        } else {
          throw Exception('Failed to re-add product with new quantity');
        }
      } else {
        throw Exception('Failed to remove product for quantity update');
      }
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      // Refresh cart to ensure consistency
      await fetchCartProducts();
    }
  }

  Future<void> removeCartItem(int cartId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/deletecartitem'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userData': {
            'customer_id': widget.customerId,
            'email': widget.email,
            'token': widget.token,
            'c_id': cartId,
          }
        }),
      );

      if (response.statusCode == 200) {
        // Refresh cart after successful removal
        await fetchCartProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item removed from cart'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to remove item');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double get totalAmount {
    return cartItems.fold(0.0, (sum, item) {
      double price = item.specialprice ?? item.discount ?? item.price;
      return sum + (price * item.cartQty);
    });
  }

  int get itemCount {
    return cartItems.fold(0, (sum, item) => sum + item.cartQty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text('Your Cart',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text('$itemCount items',
                style: TextStyle(
                    fontSize: 10, color: Colors.black.withOpacity(0.7))),
          ],
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back, color: Colors.black),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            width: MediaQuery.of(context).size.width,
            color: Colors.grey[300],
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      // Checkout Button
      bottomNavigationBar: cartItems.isEmpty ? null : Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1))),
        child: ElevatedButton(
          onPressed: () {
            if (cartItems.isNotEmpty) {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => OrderSuccessPage()));
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 6,
                child: Text(
                  'Checkout',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18),
                ),
              ),
              Container(
                width: 2,
                height: 26,
                color: Colors.white.withOpacity(0.5),
              ),
              Flexible(
                flex: 6,
                child: Text(
                  'Rs ${totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
              ),
            ],
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 100, color: Colors.red),
            SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchCartProducts,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Continue Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : ListView(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final cartItem = cartItems[index];
              return CartTile(
                data: cartItem,
                onQuantityChanged: (newQuantity) async {
                  final originalQuantity = cartItem.cartQty;

                  // Update local state immediately for better UX
                  setState(() {
                    cartItem.cartQty = newQuantity;
                  });

                  // Update on server using remove + add approach
                  await updateCartItemQuantity(cartItem.cartId, cartItem.productId, newQuantity);
                },
                onRemove: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Remove Item'),
                      content: Text('Are you sure you want to remove this item from cart?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Remove'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await removeCartItem(cartItem.cartId);
                  }
                },
              );
            },
            separatorBuilder: (context, index) => SizedBox(height: 16),
            itemCount: cartItems.length,
          ),
          // Order Summary Section
          Container(
            margin: EdgeInsets.only(top: 24),
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Summary',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal:', style: TextStyle(color: Colors.grey[700])),
                    Text('Rs ${totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Shipping:', style: TextStyle(color: Colors.grey[700])),
                    Text('Free', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text('Rs ${totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Cart Item Model
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

// Cart Tile Widget
class CartTile extends StatelessWidget {
  final CartItem data;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartTile({
    Key? key,
    required this.data,
    required this.onQuantityChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: data.image.isNotEmpty
                ? Image.network(
              data.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.image_not_supported, size: 40, color: Colors.grey);
              },
            )
                : Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
          ),
          SizedBox(width: 16),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                if (data.category != null)
                  Text(
                    data.category!,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Rs ${data.effectivePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (data.specialprice != null || data.discount != null)
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Rs ${data.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    // Quantity Controls
                    IconButton(
                      onPressed: () {
                        if (data.cartQty > 1) {
                          onQuantityChanged(data.cartQty - 1);
                        }
                      },
                      icon: Icon(Icons.remove),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        minimumSize: Size(32, 32),
                      ),
                    ),
                    Container(
                      width: 40,
                      child: Text(
                        data.cartQty.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        onQuantityChanged(data.cartQty + 1);
                      },
                      icon: Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: Size(32, 32),
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: onRemove,
                      icon: Icon(Icons.delete_outline),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
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
}

// Simple Order Success Page
class OrderSuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Placed'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            SizedBox(height: 20),
            Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('Continue Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
