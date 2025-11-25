import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/screens/AddNewAddress.dart';
import 'package:petba_new/widgets/order_summary.dart';
import 'package:petba_new/widgets/step_header.dart';

class AddressListPage extends StatefulWidget {
  final String customerId;
  final String email;
  final String token;
  final double? total;
  final List<Map<String, dynamic>>? cartProducts;

  const AddressListPage({
    super.key,
    required this.customerId,
    required this.email,
    required this.token,
    this.total,
    this.cartProducts,
  });

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedAddressId;
  bool _isProceeding = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/addressList'),
        headers: {'Content-Type': 'application/json'},
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

        setState(() {
          _addresses = (data['address'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load addresses";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Network error: $e";
        _isLoading = false;
      });
    }
  }

  // -------------------------------------------------------------
  // BUILD ADDRESS CARD
  // -------------------------------------------------------------

  Widget _buildAddressTile(Map<String, dynamic> a) {
    final id = int.tryParse(a['adrs_id']?.toString() ?? "");
    final name = '${a['f_name']} ${a['l_name']}'.trim();
    final address1 = a['address'] ?? '';
    final address2 = a['address_2'] ?? '';
    final city = a['city'] ?? '';
    final pin = a['pin'] ?? '';
    final country = a['country'] ?? '';
    final landmark = a['landmark'] ?? '';
    final phone = a['shipping_phone'] ?? '';
    final alt = a['alt_number'] ?? '';
    final type = a['custom_field'] ?? '';

    final typeColor =
        {
          'Home': Colors.red,
          'Office': Colors.blue,
          'Other': Colors.green,
        }[type] ??
        Colors.grey;

    return Card(
      color: AppColors.primaryColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() => _selectedAddressId = id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- TOP ROW ----------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Radio<int>(
                    value: id ?? -1,
                    groupValue: _selectedAddressId,
                    onChanged: (v) => setState(() => _selectedAddressId = v),
                    activeColor: AppColors.green,
                    visualDensity: VisualDensity.compact,
                  ),

                  // ADDRESS CONTENT (EXPANDED)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),

                        SizedBox(height: 2),

                        Text(
                          address1,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),

                        if (address2.toString().isNotEmpty)
                          Text(
                            address2,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                            ),
                          ),

                        SizedBox(height: 2),

                        Text(
                          "$city - $pin",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),

                        Text(
                          country,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),

                        if (landmark.toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              "Landmark: $landmark",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // TYPE BADGE (RIGHT)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: typeColor),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),

              // ---------------- PHONE + EDIT + DELETE ----------------
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          "Phone: $phone",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        if (alt.toString().isNotEmpty) ...[
                          SizedBox(width: 6),
                          Text(
                            "Alt: $alt",
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // EDIT
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddNewAddressPage(
                            customerId: widget.customerId,
                            email: widget.email,
                            token: widget.token,
                            initialAddress: a,
                            total: widget.total,
                            cartProducts: widget.cartProducts,
                            onSuccess: () {},
                          ),
                        ),
                      ).then((_) => _loadAddresses());
                    },
                    child: Icon(Icons.edit, color: AppColors.blue, size: 19),
                  ),

                  SizedBox(width: 12),

                  // DELETE (EXTREME RIGHT)
                  InkWell(
                    onTap: () => _deleteAddress(id),
                    child: Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(Icons.delete, size: 22, color: AppColors.red),
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

  // -------------------------------------------------------------
  // DELETE ADDRESS
  // -------------------------------------------------------------

  Future<void> _deleteAddress(int? id) async {
    if (id == null) return;

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/deleteAddress'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userData': {
            'customer_id': widget.customerId,
            'email': widget.email,
            'token': widget.token,
          },
          'address_id': id,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _addresses.removeWhere(
            (a) => int.tryParse(a['adrs_id']?.toString() ?? "") == id,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Address deleted"),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete"),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.red),
      );
    }
  }

  // -------------------------------------------------------------
  // PROCEED TO PAYMENT
  // -------------------------------------------------------------

  Future<void> _proceedToPayment() async {
    if (_selectedAddressId == null) return;

    final selected = _addresses.firstWhere(
      (x) => int.tryParse(x['adrs_id'].toString()) == _selectedAddressId,
      orElse: () => null,
    );

    if (selected == null) return;

    setState(() => _isProceeding = true);

    try {
      final payload = {
        'email': widget.email,
        'total': widget.total,
        'firstname': selected['f_name'],
        'arddressid': selected['adrs_id'],
        'shipping_phone': selected['shipping_phone'],
        'cartproducts': widget.cartProducts,
      };

      final response = await http.post(
        Uri.parse('$apiurl/api/payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Redirecting to payment"),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment failed"),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.red),
      );
    } finally {
      setState(() => _isProceeding = false);
    }
  }

  // -------------------------------------------------------------
  // BUILD PAGE
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,

      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: true,
        title: Text("Select Address", style: TextStyle(color: Colors.white)),
      ),

      body: Column(
        children: [
          // 🔥 SHARED STEPPER (Active step = 2)
          StepHeader(activeStep: 2),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  )
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.white),
                    ),
                  )
                : _addresses.isEmpty
                ? _buildNoAddressView()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _addresses.length) {
                        return Column(
                          children: [
                            _buildAddressTile(
                              _addresses[index] as Map<String, dynamic>,
                            ),
                            SizedBox(height: 12),
                          ],
                        );
                      }

                      return OrderSummary(
                        cartProducts: widget.cartProducts ?? [],
                        totalOverride: widget.total,
                      );
                    },
                  ),
          ),
        ],
      ),

      bottomNavigationBar: _addresses.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildAddButton()),
                  SizedBox(width: 12),
                  Expanded(child: _buildProceedButton()),
                ],
              ),
            ),
    );
  }

  // ---------------- BUTTONS ----------------

  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddNewAddressPage(
              customerId: widget.customerId,
              email: widget.email,
              token: widget.token,
              total: widget.total,
              cartProducts: widget.cartProducts,
            ),
          ),
        ).then((_) => _loadAddresses());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text("Add Address"),
    );
  }

  Widget _buildProceedButton() {
    return ElevatedButton(
      onPressed: (_selectedAddressId == null || _isProceeding)
          ? null
          : _proceedToPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isProceeding
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text("Proceed"),
    );
  }

  // ---------------- EMPTY VIEW ----------------

  Widget _buildNoAddressView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("No addresses found", style: TextStyle(color: Colors.white)),
          SizedBox(height: 10),
          _buildAddButton(),
        ],
      ),
    );
  }
}
