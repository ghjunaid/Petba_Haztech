import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/services/user_data_service.dart';
import 'package:petba_new/screens/HomePage.dart';

class CitySelectionPage extends StatefulWidget {
  final bool isFromLogin; // To determine if coming from login or settings

  const CitySelectionPage({Key? key, this.isFromLogin = true}) : super(key: key);

  @override
  _CitySelectionPageState createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cityController = TextEditingController();

  // Form data
  String? _selectedCityId;
  String? _selectedCityName;
  List<Map<String, dynamic>> _cities = [];

  // Loading states
  bool _isLoadingCities = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    // You can optionally load user's previous city selection here
    final userData = await UserDataService.getUserData();
    if (userData != null && !widget.isFromLogin) {
      // If not from login, we might want to show current city
      final cityId = await UserDataService.getCityId();
      if (cityId != null) {
        setState(() {
          _selectedCityId = cityId.toString();
        });
      }
    }
  }

  Future<void> _searchCities(String searchText) async {
    if (searchText.trim().isEmpty) {
      setState(() {
        _cities = [];
        _selectedCityId = null;
        _selectedCityName = null;
      });
      return;
    }

    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _selectedCityId = null;
      _selectedCityName = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/search-city'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'off': 0,
          'search': searchText,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> citiesList = [];

        if (data['searchitems'] != null) {
          citiesList = List<Map<String, dynamic>>.from(data['searchitems']);
          citiesList = citiesList.map((item) {
            return {
              'city_id': item['city_id'],
              'city_name': item['city'],
              'district': item['district'],
              'state': item['state'],
            };
          }).toList();
        }

        setState(() {
          _cities = citiesList;
        });
      } else {
        throw Exception('Failed to load cities - Status: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Failed to load cities: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _saveCityAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCityId == null || _selectedCityName == null) {
      _showMessage('Please select a city', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Save city ID in user data
      bool success = await UserDataService.setCityId(int.parse(_selectedCityId!));

      if (success) {
        _showMessage('City selected successfully!', isError: false);

        // Navigate to HomePage after successful city selection
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            if (widget.isFromLogin) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            } else {
              Navigator.pop(context, _selectedCityName);
            }
          }
        });
      } else {
        _showMessage('Failed to save city selection', isError: true);
      }
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    // Logo/Icon
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      widget.isFromLogin ? 'Welcome to Petba!' : 'Change Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.isFromLogin
                          ? 'Please search and select your city to get started'
                          : 'Search and select a different city',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Form Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(0xFF2d2d2d),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),

                        // City Search Field
                        _buildSectionTitle('Search City *'),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: _cityController,
                          hintText: 'Type to search for your city (e.g., Mumbai, Delhi)',
                          onChanged: (value) {
                            if (value.length >= 1) {
                              _searchCities(value);
                            } else {
                              setState(() {
                                _cities = [];
                                _selectedCityId = null;
                                _selectedCityName = null;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter city name to search';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // City Results
                        if (_isLoadingCities)
                          Container(
                            height: 60,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFFF6B6B),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Searching cities...',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (!_isLoadingCities && _cities.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select from results:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1a1a1a),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                    ),
                                    child: ListView.builder(
                                      itemCount: _cities.length,
                                      itemBuilder: (context, index) {
                                        final city = _cities[index];
                                        final isSelected = _selectedCityId == city['city_id'].toString();

                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedCityId = city['city_id'].toString();
                                              _selectedCityName = city['city_name'].toString();
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Color(0xFFFF6B6B).withOpacity(0.1) : null,
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.withOpacity(0.2),
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        city['city_name'].toString(),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        '${city['district']}, ${city['state']}',
                                                        style: TextStyle(
                                                          color: Colors.grey[400],
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Color(0xFFFF6B6B),
                                                    size: 24,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (!_isLoadingCities && _cities.isEmpty && _cityController.text.isNotEmpty)
                          Container(
                            height: 60,
                            child: Center(
                              child: Text(
                                'No cities found. Try different search terms.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),

                        SizedBox(height: 20),

                        // Continue Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isSubmitting || _selectedCityId == null) ? null : _saveCityAndContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF6B6B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              disabledBackgroundColor: Colors.grey[700],
                            ),
                            child: _isSubmitting
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Please wait...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            )
                                : Text(
                              widget.isFromLogin ? 'Continue to Petba' : 'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        if (!widget.isFromLogin) ...[
                          SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
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
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?)? validator,
    required void Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Color(0xFF1a1a1a),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFF6B6B)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red),
        ),
        contentPadding: EdgeInsets.all(16),
        suffixIcon: _cityController.text.isNotEmpty
            ? IconButton(
          onPressed: () {
            _cityController.clear();
            setState(() {
              _cities = [];
              _selectedCityId = null;
              _selectedCityName = null;
            });
          },
          icon: Icon(Icons.clear, color: Colors.grey),
        )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}