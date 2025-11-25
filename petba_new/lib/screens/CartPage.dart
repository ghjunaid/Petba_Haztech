//CartPage.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:petba_new/models/cart.dart';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/screens/AddNewAddress.dart';
import 'package:petba_new/screens/AddressListPage.dart';
import 'package:petba_new/widgets/order_summary.dart';

// NEW IMPORT
import 'package:petba_new/widgets/step_header.dart';

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

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _backgroundColor => _theme.scaffoldBackgroundColor;
  Color get _surfaceColor => _theme.cardColor;
  Color get _textPrimary => _colorScheme.onSurface;
  Color get _primaryAccent => _colorScheme.primary;
  Color get _secondaryAccent => _colorScheme.secondary;
  Color get _errorColor => _colorScheme.error;
  Color get _onPrimary => _colorScheme.onPrimary;

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
      final userData = {
        "userData": {
          "customer_id": widget.customerId,
          "email": widget.email,
          "token": widget.token,
        },
      };

      final response = await http.post(
        Uri.parse('$apiurl/api/cartProducts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey('cartProducts')) {
          final List<dynamic> products = responseData['cartProducts'];
          setState(() {
            cartItems = products
                .map((product) => CartItem.fromJson(product))
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            cartItems = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Failed to load cart";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> updateCartItemQuantity(
    int cartId,
    int productId,
    int newQuantity,
  ) async {
    try {
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
          },
        }),
      );

      if (removeResponse.statusCode == 200) {
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
            },
          }),
        );

        if (addResponse.statusCode == 200) {
          await fetchCartProducts();
        } else {
          throw Exception('Failed to add updated quantity');
        }
      } else {
        throw Exception('Failed to remove old quantity');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity'),
          backgroundColor: _errorColor,
        ),
      );
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
          },
        }),
      );

      if (response.statusCode == 200) {
        await fetchCartProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item removed'),
            backgroundColor: _secondaryAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item'),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  double get originalPrice =>
      cartItems.fold(0.0, (sum, item) => sum + (item.price * item.cartQty));

  double get totalAmount => cartItems.fold(
    0.0,
    (sum, item) =>
        (item.specialprice ?? item.discount ?? item.price) * item.cartQty,
  );

  double get finalPayableAmount => totalAmount;

  Future<List<dynamic>?> _fetchAddressList() async {
    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/addressList'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'userData': {
            'customer_id': widget.customerId,
            'email': widget.email,
            'token': widget.token,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['address'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleCheckout() async {
    if (cartItems.isEmpty) return;

    final token = widget.token;

    final list = await _fetchAddressList();

    if (list == null) return;

    if (list.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddNewAddressPage(
            customerId: widget.customerId,
            email: widget.email,
            token: token!,
            onSuccess: () async => await fetchCartProducts(),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddressListPage(
            customerId: widget.customerId,
            email: widget.email,
            token: token!,
            total: finalPayableAmount,
            cartProducts: cartItems
                .map(
                  (ci) => {
                    'name': ci.name,
                    'qty': ci.cartQty,
                    'orig_price': ci.price,
                    'discounted_price': ci.effectivePrice,
                  },
                )
                .toList(),
          ),
        ),
      );
    }
  }

  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.cartQty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,

      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        // Make status bar icons adapt to the current theme brightness
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        centerTitle: true,
        title: Text(
          'Your Cart',
          style: TextStyle(color: _textPrimary, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryAccent),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: IconThemeData(color: _primaryAccent),
        titleTextStyle: TextStyle(color: _textPrimary, fontSize: 16),
      ),

      // 🔥 DARK STEPPER (ACTIVE STEP = 1)
      body: Column(
        children: [
          StepHeader(activeStep: 1),

          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: _primaryAccent),
                  )
                : errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: _errorColor),
                    ),
                  )
                : cartItems.isEmpty
                ? Center(
                    child: Text(
                      "Your cart is empty",
                      style: TextStyle(color: _textPrimary),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final cartItem = cartItems[index];
                          return CartTile(
                            data: cartItem,
                            onQuantityChanged: (newQty) async {
                              setState(() => cartItem.cartQty = newQty);
                              await updateCartItemQuantity(
                                cartItem.cartId,
                                cartItem.productId,
                                newQty,
                              );
                            },
                            onRemove: () async {
                              await removeCartItem(cartItem.cartId);
                            },
                          );
                        },
                        separatorBuilder: (_, __) => SizedBox(height: 16),
                        itemCount: cartItems.length,
                      ),

                      SizedBox(height: 20),

                      OrderSummary(
                        cartProducts: cartItems
                            .map(
                              (ci) => {
                                'qty': ci.cartQty,
                                'orig_price': ci.price,
                                'discounted_price': ci.effectivePrice,
                              },
                            )
                            .toList(),
                        totalOverride: finalPayableAmount,
                      ),
                    ],
                  ),
          ),
        ],
      ),

      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.all(16),
              color: _surfaceColor,
              child: ElevatedButton(
                onPressed: _handleCheckout,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _primaryAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Checkout  •  ",
                      style: TextStyle(
                        color: _onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₹ ${finalPayableAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: _onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
// ------------------------------------------------------
// CART TILE WIDGET (REQUIRED IN CART PAGE)
// ------------------------------------------------------

class CartTile extends StatelessWidget {
  final CartItem data;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartTile({
    super.key,
    required this.data,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final primaryAccent = colorScheme.primary;
    final surfaceVariant = colorScheme.surfaceVariant;
    final onPrimary = colorScheme.onPrimary;
    final errorColor = colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: surfaceVariant,
            ),
            clipBehavior: Clip.hardEdge,
            child: data.image.isNotEmpty
                ? Builder(
                    builder: (context) {
                      // Build full URL for images returned as relative paths
                      String imagePath = data.image.trim();
                      String finalUrl;

                      if (imagePath.toLowerCase().startsWith('http')) {
                        finalUrl = imagePath;
                      } else {
                        // use producturl for relative backend images
                        String cleanPath = imagePath.startsWith('/')
                            ? imagePath.substring(1)
                            : imagePath;

                        finalUrl = "$producturl/$cleanPath";
                      }

                      finalUrl = Uri.encodeFull(finalUrl);

                      print("Cart image URL: $finalUrl");

                      return Image.network(
                        finalUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: textSecondary,
                        ),
                      );
                    },
                  )
                : Icon(
                    Icons.image_not_supported,
                    size: 40,
                    color: textSecondary,
                  ),
          ),

          SizedBox(width: 14),

          // PRODUCT DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),

                SizedBox(height: 4),

                Row(
                  children: [
                    Text(
                      "₹${data.effectivePrice}",
                      style: TextStyle(
                        color: primaryAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (data.price > data.effectivePrice)
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          "₹${data.price}",
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  children: [
                    // - button
                    GestureDetector(
                      onTap: () {
                        if (data.cartQty > 1) {
                          onQuantityChanged(data.cartQty - 1);
                        }
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.remove, size: 18, color: textPrimary),
                      ),
                    ),

                    // Qty
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '${data.cartQty}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),

                    // + button
                    GestureDetector(
                      onTap: () => onQuantityChanged(data.cartQty + 1),
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: primaryAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.add, size: 18, color: onPrimary),
                      ),
                    ),

                    Spacer(),

                    // Remove icon
                    GestureDetector(
                      onTap: onRemove,
                      child: Icon(Icons.delete_outline, color: errorColor),
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
