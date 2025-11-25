// c:\Users\sahee\OneDrive\Desktop\petba_draft\petba_new\lib\widgets\order_summary.dart
import 'package:flutter/material.dart';

class OrderSummary extends StatelessWidget {
  final List<Map<String, dynamic>> cartProducts;
  final double? totalOverride;

  const OrderSummary({
    super.key,
    required this.cartProducts,
    this.totalOverride,
  });

  String _format(double v) {
    final s = v.toStringAsFixed(0);
    return s.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = theme.cardColor;
    final border = theme.dividerColor;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final primary = colorScheme.primary;
    final success = const Color(0xFF4CAF50);

    final int itemCount = cartProducts.fold<int>(
      0,
      (sum, p) => sum + (int.tryParse(p['qty'].toString()) ?? 0),
    );
    final double originalPrice = cartProducts.fold<double>(0.0, (sum, p) {
      final qty = int.tryParse(p['qty'].toString()) ?? 1;
      final price =
          double.tryParse(
            p['orig_price']?.toString() ?? p['price']?.toString() ?? '0',
          ) ??
          0.0;
      return sum + price * qty;
    });
    final double discounted = cartProducts.fold<double>(0.0, (sum, p) {
      final qty = int.tryParse(p['qty'].toString()) ?? 1;
      final eff =
          double.tryParse(
            (p['discounted_price'] ?? p['price'])?.toString() ?? '0',
          ) ??
          0.0;
      return sum + eff * qty;
    });
    final double totalDiscount = (originalPrice - discounted).clamp(
      0.0,
      double.infinity,
    );
    final double finalPayableAmount = totalOverride ?? discounted;
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price ($itemCount item${itemCount > 1 ? 's' : ''})',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              Text(
                'Rs ${_format(originalPrice)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discount',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              Text(
                '- Rs ${_format(totalDiscount)}',
                style: TextStyle(
                  color: success,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Shipping:', style: TextStyle()),
              Text('Free', style: TextStyle()),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: border, thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
              Text(
                'Rs ${_format(finalPayableAmount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (totalDiscount > 0)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: success.withOpacity(0.35), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer, size: 16, color: success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You'll save Rs ${_format(totalDiscount)} on this order",
                      style: TextStyle(
                        color: success.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
