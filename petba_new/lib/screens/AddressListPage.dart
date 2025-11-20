import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/screens/AddNewAddress.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:petba_new/widgets/order_summary.dart';

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
        setState(() {
          _addresses = (data['address'] as List<dynamic>?) ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load addresses';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildAddressTile(Map<String, dynamic> a) {
    final id = int.tryParse(a['adrs_id']?.toString() ?? '');
    final name = '${a['f_name'] ?? ''} ${a['l_name'] ?? ''}'.trim();
    final address1 = a['address']?.toString() ?? '';
    final address2 = a['address_2']?.toString() ?? '';
    final city = a['city']?.toString() ?? '';
    final pin = a['pin']?.toString() ?? '';
    final country = a['country']?.toString() ?? '';
    final phone = a['shipping_phone']?.toString() ?? '';
    final alt = a['alt_number']?.toString() ?? '';
    final landmark = a['landmark']?.toString() ?? '';
    final type = a['custom_field']?.toString() ?? '';

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
              // =====================================================
              // TOP ROW → Radio + Address Text + Type Badge (RIGHT)
              // =====================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Radio<int>(
                    value: id ?? -1,
                    groupValue: _selectedAddressId,
                    onChanged: (v) => setState(() => _selectedAddressId = v),
                    activeColor: AppColors.green,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),

                  // Expanded left content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (name.isNotEmpty)
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),

                        const SizedBox(height: 2),

                        Text(
                          address1,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),

                        if (address2.isNotEmpty)
                          Text(
                            address2,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                            ),
                          ),

                        const SizedBox(height: 2),

                        Text(
                          '$city - $pin',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),

                        if (country.isNotEmpty)
                          Text(
                            country,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                            ),
                          ),

                        if (landmark.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Landmark: $landmark',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // RIGHT-SIDE TYPE LABEL
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: typeColor, width: 1),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // =====================================================
              // PHONE + EDIT + DELETE (DELETE AT EXTREME RIGHT)
              // =====================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT SIDE (EXPANDED)
                  Expanded(
                    child: Row(
                      children: [
                        if (phone.isNotEmpty)
                          Text(
                            'Phone: $phone',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),

                        if (alt.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Alt: $alt',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // EDIT ICON
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddNewAddressPage(
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
                    child: const Icon(
                      Icons.edit,
                      color: AppColors.blue,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // DELETE ICON (EXTREME RIGHT)
                  InkWell(
                    onTap: () => _deleteAddress(id),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 0),
                      child: Icon(Icons.delete, color: AppColors.red, size: 22),
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

  Future<void> _deleteAddress(int? id) async {
    if (id == null) return;
    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/deleteAddress'),
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
          'address_id': id,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          _addresses.removeWhere(
            (a) => int.tryParse(a['adrs_id']?.toString() ?? '') == id,
          );
          if (_selectedAddressId == id) _selectedAddressId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted'),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete address'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _proceedToPayment() async {
    final selected = _addresses.firstWhere(
      (a) => int.tryParse(a['adrs_id']?.toString() ?? '') == _selectedAddressId,
      orElse: () => null,
    );
    if (selected == null) return;

    setState(() => _isProceeding = true);
    try {
      final payload = {
        'email': widget.email,
        'total': widget.total ?? 0,
        'firstname': selected['f_name'] ?? '',
        'arddressid': selected['adrs_id'],
        'shipping_phone': selected['shipping_phone'] ?? '',
        'cartproducts': widget.cartProducts ?? [],
      };
      final response = await http.post(
        Uri.parse('$apiurl/api/payment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirecting to payment'),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment initiation failed'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
      );
    } finally {
      setState(() => _isProceeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Select Address'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadAddresses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.white),
              ),
            )
          : _addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No addresses found',
                    style: TextStyle(color: AppColors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddNewAddressPage(
                            customerId: widget.customerId,
                            email: widget.email,
                            token: widget.token,
                            total: widget.total, // pass total
                            cartProducts:
                                widget.cartProducts, // pass cartProducts
                            onSuccess: () {},
                          ),
                        ),
                      ).then((_) => _loadAddresses());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Add New Address'),
                  ),
                ],
              ),
            )
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
                      const SizedBox(height: 12),
                    ],
                  );
                }
                return OrderSummary(
                  cartProducts: (widget.cartProducts ?? []),
                  totalOverride: widget.total,
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddNewAddressPage(
                        customerId: widget.customerId,
                        email: widget.email,
                        token: widget.token,
                        total: widget.total, // pass total
                        cartProducts: widget.cartProducts, // pass cartProducts
                        onSuccess: () {},
                      ),
                    ),
                  ).then((_) => _loadAddresses());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add New Address'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedAddressId == null || _isProceeding
                    ? null
                    : _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProceeding
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : const Text('Proceed to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
