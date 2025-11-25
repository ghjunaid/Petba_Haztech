import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:petba_new/widgets/step_header.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:petba_new/providers/Config.dart';

class PaymentPage extends StatefulWidget {
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double totalAmount;
  final Map<String, dynamic> selectedAddress;
  final List<Map<String, dynamic>> cartProducts;
  final String customerId;
  final String email;
  final String token;

  const PaymentPage({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.deliveryCharge,
    required this.totalAmount,
    required this.selectedAddress,
    required this.cartProducts,
    required this.customerId,
    required this.email,
    required this.token,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;

  final String razorpayKey = "YOUR_KEY_HERE"; // placeholder

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // ---------------------------
  // Razorpay Handlers
  // ---------------------------

  void _handleSuccess(PaymentSuccessResponse res) {
    log("Payment Success: ${res.paymentId}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment Successful"),
        backgroundColor: Colors.green,
      ),
    );

    // TODO: Navigate to Order Success Page
  }

  void _handleError(PaymentFailureResponse res) {
    log("Payment Error: ${res.code} | ${res.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment Failed"),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse res) {
    log("External Wallet: ${res.walletName}");
  }

  // ---------------------------
  // OPEN RAZORPAY CHECKOUT
  // ---------------------------

  void _startPayment() {
    final options = {
      'key': razorpayKey,
      'amount': (widget.totalAmount * 100).round(), // convert to paise
      'name': 'Petba Store',
      'description': 'Order Payment',
      'prefill': {
        'contact': widget.selectedAddress['shipping_phone'] ?? "",
        'email': widget.selectedAddress['email'] ?? "",
      },
      'theme': {'color': '#0ad4a4'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      log("ERROR: $e");
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ---------------------------
  // PAYMENT METHODS WIDGET
  // ---------------------------

  Widget paymentMethodTile(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xff1b1b1b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
        ],
      ),
    );
  }

  // ---------------------------
  // LINE ITEMS
  // ---------------------------

  Widget lineItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.white70,
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.white70,
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // MAIN UI
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------
            // STEPPER (STEP 3 ACTIVE)
            // ------------------------------------
            StepHeader(activeStep: 3),

            const SizedBox(height: 24),

            // ------------------------------------
            // LINE ITEMS SUMMARY
            // ------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff1b1b1b),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Column(
                children: [
                  lineItem(
                    "Subtotal",
                    "₹ ${widget.subtotal.toStringAsFixed(2)}",
                  ),
                  lineItem(
                    "Discount",
                    "- ₹ ${widget.discount.toStringAsFixed(2)}",
                  ),
                  lineItem(
                    "Delivery Charge",
                    "₹ ${widget.deliveryCharge.toStringAsFixed(2)}",
                  ),
                  const Divider(color: Colors.white24),
                  lineItem(
                    "Total Amount",
                    "₹ ${widget.totalAmount.toStringAsFixed(2)}",
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ------------------------------------
            // PAYMENT METHODS
            // ------------------------------------
            const Text(
              "Choose Payment Method",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),

            paymentMethodTile("UPI", Icons.account_balance_wallet),
            paymentMethodTile("Credit / Debit Card", Icons.credit_card),
            paymentMethodTile("NetBanking", Icons.account_balance),
            paymentMethodTile("Cash On Delivery", Icons.local_shipping),

            const SizedBox(height: 60),
          ],
        ),
      ),

      // --------------------------------------
      // PAY BUTTON
      // --------------------------------------
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _startPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            "Pay Securely",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
