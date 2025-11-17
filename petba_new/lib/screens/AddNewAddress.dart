import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:petba_new/models/Validate.dart';
import 'package:petba_new/models/address.dart';
import 'package:petba_new/providers/Config.dart';
import 'package:dropdown_search/dropdown_search.dart';


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

  bool _isSubmitting = false;
  bool _isLoadingCountryData = false;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  bool _isResolvingPincode = false;
  bool _isResolvingCity = false;

  final List<String> _countryOptions = ['India'];
  List<String> _stateOptions = [];
  List<Map<String, dynamic>> _cityOptions = [];

  String? _selectedCountry = 'India';
  String? _selectedState;
  String? _selectedCity;
  String? _selectedDistrict;

  Timer? _pincodeDebounce;

  @override
  void initState() {
    super.initState();
    _bootstrapLocationData();
  }

  @override
  void dispose() {
    _pincodeDebounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _landmarkController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  String? _validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    final cleaned = value.trim();
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(cleaned)) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  // Using separate first and last name fields; no splitting helper needed.

  Future<void> _bootstrapLocationData() async {
    if (_selectedCountry != null) {
      await _loadCountryData(_selectedCountry!);
    }
  }

  Future<void> _loadCountryData(String country) async {
    setState(() {
      _isLoadingCountryData = true;
      _isLoadingStates = true;
      _isLoadingCities = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/location/country'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({'country': country}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> states = data['states'] ?? [];
        final List<dynamic> cities = data['cities'] ?? [];

        setState(() {
          _stateOptions = states.map((e) => e.toString()).toList();
          _cityOptions = cities
              .map<Map<String, dynamic>>(
                (dynamic e) =>
                    Map<String, dynamic>.from(e as Map<String, dynamic>),
              )
              .toList();

          if (_selectedState != null &&
              !_stateOptions.contains(_selectedState)) {
            _selectedState = null;
          }

          if (_selectedCity != null &&
              !_cityOptions.any((c) => c['city'] == _selectedCity)) {
            _selectedCity = null;
          }
        });
      } else {
        throw Exception('Failed to load data for $country');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to load location data: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCountryData = false;
          _isLoadingStates = false;
          _isLoadingCities = false;
        });
      }
    }
  }

  Future<void> _loadCitiesForState(String state) async {
    setState(() {
      _isLoadingCities = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/location/state'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({'state': state}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> cities = data['cities'] ?? [];

        setState(() {
          _cityOptions = cities
              .map<Map<String, dynamic>>(
                (dynamic e) =>
                    Map<String, dynamic>.from(e as Map<String, dynamic>),
              )
              .toList();

          if (_selectedCity != null &&
              !_cityOptions.any((c) => c['city'] == _selectedCity)) {
            _selectedCity = null;
          }
        });
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to load cities: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
        });
      }
    }
  }

  Future<void> _fetchLocationByPincode(String pincode) async {
    if (pincode.length != 6) return;

    setState(() {
      _isResolvingPincode = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/location/pincode'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({'pincode': pincode}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic>? location = data['location'] != null
            ? Map<String, dynamic>.from(data['location'])
            : null;

        if (location != null) {
          final String? country = location['country']?.toString();
          final String? state = location['state']?.toString();
          final String? city = location['city']?.toString();
          final String? district = location['district']?.toString();

          setState(() {
            if (country != null) {
              _selectedCountry = country;
              if (!_countryOptions.contains(country)) {
                _countryOptions.add(country);
              }
            }

            if (state != null) {
              _ensureState(state);
              _selectedState = state;
            }

            if (city != null) {
              _ensureCity({
                'city': city,
                'state': state ?? '',
                'pincode': location['pincode'],
                'district': district,
              });
              _selectedCity = city;
            }

            _selectedDistrict = district;
            _pincodeController.text = pincode;
          });

          if (state != null) {
            await _loadCitiesForState(state);
          }
        }
      } else {
        throw Exception('Pincode not found');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to fetch location: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingPincode = false;
        });
      }
    }
  }

  Future<void> _fetchPincodeByCity(String city) async {
    if (city.isEmpty) return;

    setState(() {
      _isResolvingCity = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/location/city'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({'city': city, 'state': _selectedState}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        if (results.isNotEmpty) {
          final Map<String, dynamic> first = Map<String, dynamic>.from(
            results.first as Map<String, dynamic>,
          );
          setState(() {
            _pincodeController.text = first['pincode'].toString();
            _selectedState = first['state']?.toString() ?? _selectedState;
            _selectedDistrict =
                first['district']?.toString() ?? _selectedDistrict;
          });
        }
      } else {
        throw Exception('City not found');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to fetch pincode: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingCity = false;
        });
      }
    }
  }

  void _ensureState(String state) {
    if (!_stateOptions.contains(state)) {
      _stateOptions = [..._stateOptions, state];
    }
  }

  void _ensureCity(Map<String, dynamic> city) {
    if (!_cityOptions.any(
      (c) =>
          c['city'] == city['city'] &&
          c['state'] == city['state'] &&
          c['pincode'] == city['pincode'],
    )) {
      _cityOptions = [..._cityOptions, city];
    }
  }

  void _onPincodeChanged(String value) {
    final trimmed = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (_pincodeDebounce?.isActive ?? false) {
      _pincodeDebounce!.cancel();
    }

    if (trimmed.length == 6) {
      _pincodeDebounce = Timer(const Duration(milliseconds: 600), () {
        _fetchLocationByPincode(trimmed);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.token.isEmpty) {
      _showMessage(
        'Authentication token missing. Please login again.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    // Use first and last name fields directly
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (_selectedCountry == null || _selectedCountry!.isEmpty) {
      _showMessage('Please select a country', isError: true);
      return;
    }

    if (_selectedState == null || _selectedState!.isEmpty) {
      _showMessage('Please select a state', isError: true);
      return;
    }

    if (_selectedCity == null || _selectedCity!.isEmpty) {
      _showMessage('Please select a city', isError: true);
      return;
    }

    final addressPayload = Address(
      customerId: widget.customerId,
      email: widget.email,
      token: widget.token,
      firstName: firstName.isEmpty ? '' : firstName,
      lastName: lastName.isEmpty ? '' : lastName,
      addressLine1: _addressController.text.trim(),
      country: _selectedCountry ?? 'India',
      state: _selectedState ?? '',
      city: _selectedCity ?? '',
      pincode: _pincodeController.text.trim(),
      phone: _phoneController.text.trim(),
      altPhone: _altPhoneController.text.trim().isEmpty
          ? null
          : _altPhoneController.text.trim(),
      locality: _selectedDistrict ?? _selectedCity,
      landmark: _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
    );

    final body = json.encode(addressPayload.toJson());
    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/addAddress'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );
      print('Add to cart request: ${body}');

      Map<String, dynamic> responseBody = {};
      try {
        responseBody = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // If backend returns plain text we still need a readable message.
        responseBody = {'message': response.body};
      }

      final successMessage =
          responseBody['address'] ?? responseBody['message'] ?? 'Success';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          _showMessage(successMessage.toString(), isError: false);
          widget.onSuccess?.call();
          Navigator.pop(context, true);
        }
      } else {
        final errorMessage =
            responseBody['error'] ??
            responseBody['message'] ??
            'Request failed';
        if (mounted) {
          _showMessage(errorMessage.toString(), isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to add address: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.green),
      filled: true,
      fillColor: AppColors.primaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.green, width: 2),
      ),
    );
  }

  Widget _inlineLoader({Color color = AppColors.green}) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Align(
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
  }

  Widget _buildPincodeField() {
    return TextFormField(
      controller: _pincodeController,
      decoration: _inputDecoration('Pincode', Icons.pin_drop).copyWith(
        suffixIcon: _isResolvingPincode
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _inlineLoader(),
              )
            : IconButton(
                icon: const Icon(Icons.search, color: AppColors.green),
                onPressed: () =>
                    _fetchLocationByPincode(_pincodeController.text.trim()),
              ),
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      validator: _validatePincode,
      onChanged: _onPincodeChanged,
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
          .map(
            (country) =>
                DropdownMenuItem<String>(value: country, child: Text(country)),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountry = value;
          _selectedState = null;
          _selectedCity = null;
          _selectedDistrict = null;
        });
        if (value != null) {
          _loadCountryData(value);
        }
      },
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select a country' : null,
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
          .map(
            (state) =>
                DropdownMenuItem<String>(value: state, child: Text(state)),
          )
          .toList(),
      onChanged: _stateOptions.isEmpty
          ? null
          : (value) {
              setState(() {
                _selectedState = value;
                _selectedCity = null;
                _selectedDistrict = null;
              });
              if (value != null) {
                _loadCitiesForState(value);
              }
            },
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select a state' : null,
      dropdownColor: AppColors.primaryColor,
      style: const TextStyle(color: AppColors.white),
    );
  }

  Widget _buildCityDropdown() {
    final cityItems = _cityOptions
        .map(
          (city) => DropdownMenuItem<String>(
            value: city['city']?.toString(),
            child: Text(
              city['district'] != null && city['district'].toString().isNotEmpty
                  ? '${city['city']} • ${city['district']}'
                  : city['city']?.toString() ?? '',
            ),
          ),
        )
        .toList();

    return DropdownButtonFormField<String>(
      value: _selectedCity,
      decoration: _inputDecoration('City', Icons.location_city).copyWith(
        suffixIcon: (_isLoadingCities || _isResolvingCity)
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _inlineLoader(),
              )
            : null,
      ),
      items: cityItems,
      onChanged: _cityOptions.isEmpty
          ? null
          : (value) {
              setState(() {
                _selectedCity = value;
                final match = _cityOptions.firstWhere(
                  (city) => city['city'] == value,
                  orElse: () => <String, dynamic>{},
                );
                _selectedDistrict = match['district']?.toString();
              });
              if (value != null) {
                _fetchPincodeByCity(value);
              }
            },
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select a city' : null,
      dropdownColor: AppColors.primaryColor,
      style: const TextStyle(color: AppColors.white),
    );
  }

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
            _buildCityDropdown(),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade800, height: 1),
            const SizedBox(height: 24),
            _buildSectionLabel('Contact & address'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: _inputDecoration('First name', Icons.person),
                    textInputAction: TextInputAction.next,
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
                    textInputAction: TextInputAction.next,
                    validator: Validators.validateName,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: _inputDecoration('Phone number', Icons.phone),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
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
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  return Validators.validatePhoneNumber(value);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: _inputDecoration(
                'Address',
                Icons.location_on_outlined,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              validator: Validators.validateAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _landmarkController,
              decoration: _inputDecoration('Landmark (optional)', Icons.place),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  return null;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

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
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Fill in the details below to add a new delivery address.',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
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
