import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class DonationPage extends StatefulWidget {
  @override
  _DonationPageState createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customAmountController = TextEditingController();

  // Add Razorpay instance
  late Razorpay _razorpay;

  String selectedAmount = '';
  String selectedPaymentMethod = 'card';
  bool isProcessing = false;

  final List<String> predefinedAmounts = ['100', '500', '1000', '2500', '5000'];

  @override
  void initState() {
    super.initState();
    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _customAmountController.dispose();
    // Clear Razorpay event listeners
    _razorpay.clear();
    super.dispose();
  }

  // Payment success handler
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Successful! Payment ID: ${response.paymentId}"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );

    // Here you can save the donation details to your database
    // _saveDonationToDatabase(response);
  }

  // Payment error handler
  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Failed: ${response.message}"),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  // External wallet handler
  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet: ${response.walletName}"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Make a Donation', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Help Make a Difference',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your contribution helps us continue our mission',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Donation Form
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Selection
                    _buildSectionTitle('Select Donation Amount'),
                    SizedBox(height: 12),
                    _buildAmountSelection(),
                    SizedBox(height: 24),

                    // Personal Information
                    _buildSectionTitle('Personal Information'),
                    SizedBox(height: 12),
                    _buildPersonalInfoFields(),
                    SizedBox(height: 24),

                    // Payment Method
                    _buildSectionTitle('Payment Method'),
                    SizedBox(height: 12),
                    _buildPaymentMethods(),
                    SizedBox(height: 32),

                    // Donate Button
                    _buildDonateButton(),
                    SizedBox(height: 20),

                    // Security Note
                    _buildSecurityNote(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildAmountSelection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Predefined amounts
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: predefinedAmounts.map((amount) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedAmount = amount;
                    _customAmountController.clear();
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: selectedAmount == amount ? Color(0xFF6366F1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: selectedAmount == amount ? Color(0xFF6366F1) : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    '₹$amount',
                    style: TextStyle(
                      color: selectedAmount == amount ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 20),

          // Custom amount
          Text(
            'Or enter custom amount:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  selectedAmount = value;
                });
              }
            },
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: TextStyle(fontWeight: FontWeight.w600),
              hintText: 'Enter amount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF6366F1)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (selectedAmount.isEmpty && (value == null || value.isEmpty)) {
                return 'Please select or enter an amount';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoFields() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPaymentOption('card', Icons.credit_card, 'Credit/Debit Card'),
          Divider(height: 1),
          _buildPaymentOption('upi', Icons.account_balance_wallet, 'UPI'),
          Divider(height: 1),
          _buildPaymentOption('netbanking', Icons.account_balance, 'Net Banking'),
          Divider(height: 1),
          _buildPaymentOption('wallet', Icons.wallet, 'Wallet'),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, IconData icon, String title) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedPaymentMethod,
      onChanged: (String? newValue) {
        setState(() {
          selectedPaymentMethod = newValue!;
        });
      },
      title: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
      activeColor: Color(0xFF6366F1),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDonateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isProcessing ? null : _processDonation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isProcessing
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Processing...'),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security),
            SizedBox(width: 8),
            Text(
              'Donate ₹${selectedAmount.isNotEmpty ? selectedAmount : '0'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: Colors.green[600], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your payment is secured with 256-bit SSL encryption',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processDonation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedAmount.isEmpty || selectedAmount == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid donation amount')),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    _initiateRazorpayPayment();
  }

  void _initiateRazorpayPayment() {
    var options = {
      'key': "RAZORPAY_KEY", // Replace with your actual Razorpay key
      'amount': (int.parse(selectedAmount) * 100), // Amount in paise
      'name': 'Your Organization Name', // Replace with your organization name
      'description': 'Donation for a good cause',
      'prefill': {
        'contact': _phoneController.text,
        'email': _emailController.text,
        'name': _nameController.text,
      },
      'theme': {
        'color': '#6366F1'
      },
      'method': {
        'upi': true,
        'card': true,
        'netbanking': true,
        'wallet': true,
      },
      'modal': {
        'confirm_close': true,
        'ondismiss': () {
          setState(() {
            isProcessing = false;
          });
        }
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error opening Razorpay: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}