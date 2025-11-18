import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:petba_new/models/Validate.dart';
import 'package:petba_new/models/address.dart';
import 'package:petba_new/providers/Config.dart';

class AddNewAddressPage extends StatefulWidget {
  final String customerId;
  final String email;
  final String token;
  final VoidCallback? onSuccess;

  const AddNewAddressPage({
    super.key,
    required this.customerId,
    required this.email,
    required this.token,
    this.onSuccess,
  });

  @override
  State<AddNewAddressPage> createState() => _AddNewAddressPageState();
}

class _AddNewAddressPageState extends State<AddNewAddressPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _localityController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingCountryData = false;
  bool _isLoadingStates = false;

  final List<String> _countryOptions = ['India'];
  List<String> _stateOptions = [];

  String? _selectedCountry = 'India';
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    _loadCountryData('India');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _localityController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------
  // Validation
  // -----------------------------------------------------------

  String? _validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  // -----------------------------------------------------------
  // Load States from Backend (oc_zone)
  // -----------------------------------------------------------

  Future<void> _loadCountryData(String country) async {
    setState(() {
      _isLoadingCountryData = true;
      _isLoadingStates = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/location/country'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'country': country}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> states = data['states'] ?? [];

        setState(() {
          _stateOptions = states
              .map((e) => e['state_name'].toString())
              .toList();
        });
      }
    } catch (e) {
      _showMessage('Unable to load states: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingCountryData = false;
        _isLoadingStates = false;
      });
    }
  }

  // -----------------------------------------------------------
  // Submit Form
  // -----------------------------------------------------------

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null) {
      _showMessage('Please select a state', isError: true);
      return;
    }

    if (_cityController.text.trim().isEmpty) {
      _showMessage('Please enter a city', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final bodyData = Address(
      customerId: widget.customerId,
      email: widget.email,
      token: widget.token,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      addressLine1: _addressController.text.trim(),
      country: _selectedCountry!,
      state: _selectedState!,
      city: _cityController.text.trim(),
      pincode: _pincodeController.text.trim(),
      phone: _phoneController.text.trim(),
      altPhone: _altPhoneController.text.trim().isEmpty
          ? null
          : _altPhoneController.text.trim(),
      locality: _localityController.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
    );

    final payload = json.encode(bodyData.toJson());

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/addAddress'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: payload,
      );
      print('Address request: ${(payload)}');

      Map<String, dynamic> res = {};
      try {
        res = json.decode(response.body);
      } catch (_) {
        res = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showMessage(
          res['address'] ?? res['message'] ?? 'Success',
          isError: false,
        );
        widget.onSuccess?.call();
        Navigator.pop(context, true);
      } else {
        _showMessage(
          res['error'] ?? res['message'] ?? 'Request failed',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage('Failed to add address: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // -----------------------------------------------------------
  // Helpers & UI Components
  // -----------------------------------------------------------

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : AppColors.green,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: AppColors.green),
      filled: true,
      fillColor: AppColors.primaryColor,
      hintStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _inlineLoader() => SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
  );

  Widget _buildSectionLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    ),
  );

  // -----------------------------------------------------------
  // UI Fields
  // -----------------------------------------------------------

  Widget _buildPincodeField() {
    return TextFormField(
      controller: _pincodeController,
      decoration: _inputDecoration('Pincode', Icons.pin_drop),
      style: const TextStyle(color: AppColors.white),
      keyboardType: TextInputType.number,
      validator: _validatePincode,
    );
  }

  Widget _buildCityField() {
    return TextFormField(
      controller: _cityController,
      decoration: _inputDecoration('City', Icons.location_city),
      style: const TextStyle(color: AppColors.white),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Please enter a city' : null,
    );
  }

  Widget _buildLocalityField() {
    return TextFormField(
      controller: _localityController,
      decoration: _inputDecoration('Locality', Icons.location_searching),
      style: const TextStyle(color: AppColors.white),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Please enter a Locality'
          : null,
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      decoration: _inputDecoration('Country', Icons.public).copyWith(
        suffixIcon: _isLoadingCountryData
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _inlineLoader(),
              )
            : null,
      ),
      items: _countryOptions
          .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
          .toList(),
      onChanged: (value) {
        _selectedCountry = value;
        _selectedState = null;
        _loadCountryData(value!);
      },
      validator: (v) => v == null ? 'Select country' : null,
      dropdownColor: AppColors.primaryColor,
      style: const TextStyle(color: AppColors.white),
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedState,
      decoration: _inputDecoration('State', Icons.map).copyWith(
        suffixIcon: _isLoadingStates
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _inlineLoader(),
              )
            : null,
      ),
      items: _stateOptions
          .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
          .toList(),
      onChanged: (value) => setState(() => _selectedState = value),
      validator: (v) => v == null ? 'Select state' : null,
      dropdownColor: AppColors.primaryColor,
      style: const TextStyle(color: AppColors.white),
    );
  }

  // -----------------------------------------------------------
  // Main Form Card UI
  // -----------------------------------------------------------

  Widget _buildFormCard() {
    return Card(
      elevation: 3,
      color: AppColors.primaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionLabel('Location details'),
            const SizedBox(height: 12),
            _buildPincodeField(),
            const SizedBox(height: 16),
            _buildCountryDropdown(),
            const SizedBox(height: 16),
            _buildStateDropdown(),
            const SizedBox(height: 16),
            _buildCityField(),
            const SizedBox(height: 16),
            _buildLocalityField(),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade800),
            const SizedBox(height: 24),

            _buildSectionLabel('Contact & address'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: _inputDecoration('First name', Icons.person),
                    style: const TextStyle(color: AppColors.white),
                    validator: Validators.validateName,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: _inputDecoration(
                      'Last name',
                      Icons.person_outline,
                    ),
                    style: const TextStyle(color: AppColors.white),
                    validator: Validators.validateName,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: _inputDecoration('Phone number', Icons.phone),
              style: const TextStyle(color: AppColors.white),
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhoneNumber,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _altPhoneController,
              decoration: _inputDecoration(
                'Alternate phone (optional)',
                Icons.phone_in_talk,
              ),
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.white),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  return Validators.validatePhoneNumber(v);
                }
                return null;
              },
            ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: _inputDecoration('Address', Icons.location_on),
              style: const TextStyle(color: AppColors.white),
              maxLines: 3,
              validator: Validators.validateAddress,
            ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _landmarkController,
              decoration: _inputDecoration('Landmark', Icons.place),
              style: const TextStyle(color: AppColors.white),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter a landmark'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // Save Button
  // -----------------------------------------------------------

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Saving address...'),
                ],
              )
            : const Text(
                'Save address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  // -----------------------------------------------------------
  // Build Page
  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Add New Address'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Fill in the details below to add a new delivery address.',
                  style: TextStyle(color: Colors.grey.shade300),
                ),
                const SizedBox(height: 20),
                _buildFormCard(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
