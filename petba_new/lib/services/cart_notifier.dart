import 'package:flutter/foundation.dart';

class CartNotifier extends ChangeNotifier {
  static final CartNotifier _instance = CartNotifier._internal();
  factory CartNotifier() => _instance;
  CartNotifier._internal();

  int _cartCount = 0;
  int get cartCount => _cartCount;

  void updateCartCount(int count) {
    _cartCount = count;
    notifyListeners();
  }

  void incrementCart() {
    _cartCount++;
    notifyListeners();
  }

  void decrementCart() {
    if (_cartCount > 0) {
      _cartCount--;
      notifyListeners();
    }
  }
}