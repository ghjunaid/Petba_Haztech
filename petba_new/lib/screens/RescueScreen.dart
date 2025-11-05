import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:petba_new/providers/Config.dart';

class AddRescuePage extends StatefulWidget {
  final String customerId;
  const AddRescuePage({Key? key, required this.customerId}) : super(key: key);

  @override
  _AddRescuePageState createState() => _AddRescuePageState();
}

class _AddRescuePageState extends State<AddRescuePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  //final TextEditingController _districtController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // Form data
  List<File> _selectedImages = [];
  String? _selectedAnimalType;
  String? _selectedGender;
  String? _selectedConditionType;
  String? _selectedConditionLevel;
  String? _selectedCityId;
  String? _selectedCityName;

  // Location data
  Position? _currentPosition;
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLoadingLocation = false;
  String _locationError = '';

  // API data
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _animalTypes = [];
  List<Map<String, dynamic>> _conditions = [];

  // Loading states
  bool _isLoadingCities = false;
  bool _isLoadingInitialData = true;
  bool _isSubmitting = false;

  // Static data
  final List<Map<String, dynamic>> _genders = [
    {'id': '1', 'name': 'Male'},
    {'id': '2', 'name': 'Female'},
  ];

  final List<Map<String, dynamic>> _conditionLevels = [
    {'id': '1', 'name': 'Critical'},
    {'id': '2', 'name': 'Severe'},
    {'id': '3', 'name': 'Moderate'},
    {'id': '4', 'name': 'Mild'},
    {'id': '5', 'name': 'Stable'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _getCurrentLocation();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoadingInitialData = true;
    });

    try {
      await Future.wait([
        _loadAnimalTypes(),
        _loadRescueFields(),
      ]);
    } catch (e) {
      _showMessage('Failed to load initial data: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingInitialData = false;
      });
    }
  }

  //getting current location
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled. Please enable them in settings.';
        });
        _showMessage(_locationError, isError: true);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permissions are denied';
          });
          _showMessage(_locationError, isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permissions are permanently denied. Please enable them in app settings.';
        });
        _showMessage(_locationError, isError: true);
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Location request timed out');
        },
      );

      if (!mounted) return;

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Address lookup timed out');
          },
        );

        if (!mounted) return;

        setState(() {
          _currentPosition = position;
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationError = '';

          // Safely handle placemark data
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String street = place.street ?? '';
            String subLocality = place.subLocality ?? '';
            String locality = place.locality ?? '';

            _addressController.text = '$street${street.isNotEmpty && subLocality.isNotEmpty ? ', ' : ''}$subLocality';
            _cityController.text = locality;

            // Auto-set city search field
            if (locality.isNotEmpty) {
              _cityController.text = locality;
              _searchCities(locality); // Auto-search cities
            }
          }
        });

      } catch (e) {
        // If address lookup fails, still save the coordinates
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationError = '';
        });
        _showMessage('Location obtained but address lookup failed: $e', isError: false);
      }

    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Error getting location: ${e.toString()}';

      // Handle specific error types
      if (e.toString().contains('timed out')) {
        errorMessage = 'Location request timed out. Please try again.';
      } else if (e.toString().contains('denied')) {
        errorMessage = 'Location permission denied. Please grant location permission.';
      } else if (e.toString().contains('disabled')) {
        errorMessage = 'Location services are disabled. Please enable location services.';
      }

      setState(() {
        _locationError = errorMessage;
      });
      _showMessage(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _loadAnimalTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$apiurl/api/animalbreed'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _animalTypes = List<Map<String, dynamic>>.from(data['animalbreed']);
        });
      } else {
        throw Exception('Failed to load animal types');
      }
    } catch (e) {
      print('Error loading animal types: $e');
      throw e;
    }
  }

  Future<void> _loadRescueFields() async {
    try {
      final response = await http.get(
        Uri.parse('$apiurl/api/rescueFields'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _conditions = List<Map<String, dynamic>>.from(data['condition']);
        });
      } else {
        throw Exception('Failed to load rescue fields');
      }
    } catch (e) {
      print('Error loading rescue fields: $e');
      throw e;
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
        throw Exception('Failed to search cities - Status: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Failed to search cities: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  // Image picking methods
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 6) {
      _showMessage('Maximum 6 images allowed', isError: true);
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            if (_selectedImages.length < 6) {
              _selectedImages.add(File(image.path));
            }
          }
        });
      }
    } catch (e) {
      _showMessage('Error picking images: $e', isError: true);
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= 6) {
      _showMessage('Maximum 6 images allowed', isError: true);
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      _showMessage('Error taking photo: $e', isError: true);
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2d2d2d),
          title: const Text('Select Image Source', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFFF6B6B)),
                title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFF6B6B)),
                title: const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Convert File to base64
  Future<String> _convertImageToBase64(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Check file size (limit to 5MB per image)
      int fileSizeInBytes = await imageFile.length();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 5) {
        throw Exception('Image size too large (${fileSizeInMB.toStringAsFixed(1)}MB). Please use images smaller than 5MB.');
      }

      print('Converting image: ${imageFile.path} (${fileSizeInMB.toStringAsFixed(2)}MB)');

      Uint8List imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);

      // Add proper data URL prefix
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('Error converting image to base64: $e');
      throw Exception('Failed to convert image: $e');
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitialData) {
      return Scaffold(
        backgroundColor: Color(0xFF1a1a1a),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF6B6B)),
              SizedBox(height: 16),
              Text(
                'Loading rescue form...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Color(0xFF2d2d2d),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFF6B6B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Rescue Pet',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (_isLoadingLocation)
            Container(
              margin: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF6B6B),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.pets, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Help Save a Life',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Report a pet that needs rescue',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Location Section - Updated like AddAdoptionPage
              _buildLocationInfo(),
              SizedBox(height: 20),

              // Address
              _buildSectionTitle('Address *'),
              SizedBox(height: 8),
              _buildTextField(
                controller: _addressController,
                hintText: 'Enter complete address',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // District and City Row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Search City *'),
                  SizedBox(height: 8),
                  _buildTextField(
                    controller: _cityController,
                    hintText: 'Type to search for your city ',
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
                  SizedBox(height: 16),

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
                    Container(
                      height: 200, // Fixed height for scrollable results
                      decoration: BoxDecoration(
                        color: Color(0xFF2d2d2d),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Select from results:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
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
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                '${city['district']}, ${city['state']}',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: Color(0xFFFF6B6B),
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                ],
              ),
              SizedBox(height: 20),

              // Animal Type and Gender Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Animal Type *'),
                        SizedBox(height: 8),
                        _buildApiDropdownField(
                          value: _selectedAnimalType,
                          items: _animalTypes,
                          hint: 'animal type',
                          displayKey: 'name',
                          valueKey: 'animal_id',
                          onChanged: (value) => setState(() => _selectedAnimalType = value),
                          validator: (value) => value == null ? 'Please select animal type' : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Gender *'),
                        SizedBox(height: 8),
                        _buildApiDropdownField(
                          value: _selectedGender,
                          items: _genders,
                          hint: 'Select gender',
                          displayKey: 'name',
                          valueKey: 'id',
                          onChanged: (value) => setState(() => _selectedGender = value),
                          validator: (value) => value == null ? 'Please select gender' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Condition Type and Level Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Condition Type *'),
                        SizedBox(height: 8),
                        _buildApiDropdownField(
                          value: _selectedConditionType,
                          items: _conditions,
                          hint: 'condition',
                          displayKey: 'name',
                          valueKey: 'id',
                          onChanged: (value) => setState(() => _selectedConditionType = value),
                          validator: (value) => value == null ? 'Please select condition type' : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Condition Level *'),
                        SizedBox(height: 8),
                        _buildApiDropdownField(
                          value: _selectedConditionLevel,
                          items: _conditionLevels,
                          hint: 'Select level',
                          displayKey: 'name',
                          valueKey: 'id',
                          onChanged: (value) => setState(() => _selectedConditionLevel = value),
                          validator: (value) => value == null ? 'Please select condition level' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Description
              _buildSectionTitle('Description *'),
              SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Describe the pet\'s condition, behavior, and any additional information...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a description';
                  }
                  if (value.trim().length < 20) {
                    return 'Description should be at least 20 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Image Upload Section
              _buildSectionTitle('Pet Photos (Up to 6) *'),
              SizedBox(height: 12),
              _buildImageUploadSection(),
              SizedBox(height: 32),

              // Submit Button
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
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
                        'Submitting...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                      : Text(
                    'Submit Rescue Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED: Safe method to find city name
  String? _findCityName(String? cityId) {
    if (cityId == null || _cities.isEmpty) return null;

    try {
      final city = _cities.firstWhere(
            (city) => city['city_id'].toString() == cityId,
        orElse: () => <String, dynamic>{}, // Return empty map if not found
      );

      // Check if we got an empty map (no element found)
      if (city.isEmpty) {
        print('Warning: City with ID $cityId not found in cities list');
        return null;
      }

      return city['city_name'];
    } catch (e) {
      print('Error finding city name for ID $cityId: $e');
      return null;
    }
  }

  // Updated Location Info Widget - Similar to AddAdoptionPage
  Widget _buildLocationInfo() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Location Information'),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(12),
              color: Color(0xFF2d2d2d),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFFFF6B6B), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Current Location',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currentPosition != null
                      ? 'Lat: ${_latitude.toStringAsFixed(6)}, Long: ${_longitude.toStringAsFixed(6)}'
                      : 'Getting location...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                if (_locationError.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    _locationError,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                if (_currentPosition == null || _locationError.isNotEmpty) ...[
                  SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text(_isLoadingLocation ? 'Getting Location...' : 'Retry'),
                    style: TextButton.styleFrom(foregroundColor: Color(0xFFFF6B6B)),
                  ),
                ],
              ],
            ),
          ),
        ],
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
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Color(0xFF2d2d2d),
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
      ),
    );
  }

  Widget _buildApiDropdownField({
    required String? value,
    required List<Map<String, dynamic>> items,
    required String hint,
    required String displayKey,
    required String valueKey,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? Color(0xFF2d2d2d) : Color(0xFF1a1a1a),
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
        contentPadding: EdgeInsets.all(16),
      ),
      dropdownColor: Color(0xFF2d2d2d),
      style: TextStyle(color: enabled ? Colors.white : Colors.grey),
      hint: Text(hint, style: TextStyle(color: Colors.grey)),
      items: enabled ? items.map((item) {
        return DropdownMenuItem<String>(
          value: item[valueKey].toString(),
          child: Text(
            item[displayKey].toString(),
            style: TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList() : [],
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Upload Button
          if (_selectedImages.length < 6)
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(0xFFFF6B6B),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      color: Color(0xFFFF6B6B),
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to add photos',
                      style: TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_selectedImages.length}/6 photos selected',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Selected Images Grid
          if (_selectedImages.isNotEmpty) ...[
            if (_selectedImages.length < 6) SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required fields
    if (_selectedAnimalType == null) {
      _showMessage('Please select animal type', isError: true);
      return;
    }
    if (_selectedGender == null) {
      _showMessage('Please select gender', isError: true);
      return;
    }
    if (_selectedConditionType == null) {
      _showMessage('Please select condition type', isError: true);
      return;
    }
    if (_selectedConditionLevel == null) {
      _showMessage('Please select condition level', isError: true);
      return;
    }
    if (_selectedCityId == null) {
      _showMessage('Please select city', isError: true);
      return;
    }
    if (_selectedImages.isEmpty) {
      _showMessage('Please add at least one image', isError: true);
      return;
    }
    if (_latitude == 0.0 || _longitude == 0.0) {
      _showMessage('Location is required. Please enable location services.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Convert images to base64 first
      List<String> convertedImages = [];
      for (int i = 0; i < _selectedImages.length && i < 6; i++) {
        String base64Image = await _convertImageToBase64(_selectedImages[i]);
        convertedImages.add(base64Image);
      }

      // CRITICAL: Must have at least one image for backend database requirement
      if (convertedImages.isEmpty) {
        _showMessage('At least one image is required', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      // Prepare the request body
      Map<String, dynamic> requestBody = {
        'c_id': widget.customerId,
        'city': _selectedCityName ?? '',
        'city_id': _selectedCityId ?? '',
        'address': _addressController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'description': _descriptionController.text.trim(),
        'condition_id': _selectedConditionType ?? '',
        'gender': _selectedGender ?? '',
        'animalType': _selectedAnimalType ?? '',
        'conditionLevel': _selectedConditionLevel ?? '',
        // FIXED: Send all image fields as empty strings initially
        // Backend will populate them based on the converted images
        'img1': convertedImages.length > 0 ? convertedImages[0] : '',
        'img2': convertedImages.length > 1 ? convertedImages[1] : '',
        'img3': convertedImages.length > 2 ? convertedImages[2] : '',
        'img4': convertedImages.length > 3 ? convertedImages[3] : '',
        'img5': convertedImages.length > 4 ? convertedImages[4] : '',
        'img6': convertedImages.length > 5 ? convertedImages[5] : '',
      };

      print('=== RESCUE REQUEST DATA ===');
      print('Customer ID: ${requestBody['c_id']}');
      print('Latitude: ${requestBody['latitude']}');
      print('Longitude: ${requestBody['longitude']}');
      print('Address: ${requestBody['address']}');
      print('City: ${requestBody['city']} (ID: ${requestBody['city_id']})');
      print('Animal Type: ${requestBody['animalType']}');
      print('Gender: ${requestBody['gender']}');
      print('Condition ID: ${requestBody['condition_id']}');
      print('Condition Level: ${requestBody['conditionLevel']}');
      print('Number of images: ${convertedImages.length}');

      // Debug image fields
      for (int i = 1; i <= 6; i++) {
        String imgField = 'img$i';
        var value = requestBody[imgField];
        if (value != null && value.toString().isNotEmpty) {
          print('$imgField: HAS_DATA (${value.toString().length} chars)');
        } else {
          print('$imgField: EMPTY');
        }
      }
      print('==========================');

      // Make API call
      final response = await http.post(
        Uri.parse('$apiurl/api/add-rescue-pet'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showMessage('Rescue request submitted successfully!', isError: false);

        // FIXED: Clear form first, then navigate
        _clearForm();

        // Navigate back with a slight delay to ensure UI updates
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = 'Failed to submit rescue request';

        if (errorData['error'] != null && errorData['error']['text'] != null) {
          errorMessage = errorData['error']['text'];
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }

        _showMessage(errorMessage, isError: true);
        print('API Error: $errorMessage');
      }
    } catch (e) {
      _showMessage('Error: $e', isError: true);
      print('Submit error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearForm() {
    // FIXED: Clear form safely without causing state errors
    try {
      _formKey.currentState?.reset();
      _addressController.clear();
      _descriptionController.clear();
      // _districtController.clear();
      _cityController.clear();

      if (mounted) {
        setState(() {
          _selectedImages.clear();
          _selectedAnimalType = null;
          _selectedGender = null;
          _selectedConditionType = null;
          _selectedConditionLevel = null;
          _selectedCityId = null;
          _selectedCityName = null;
          _cities.clear();
        });
      }
    } catch (e) {
      print('Error clearing form: $e');
    }
  }

  bool _validateAllFields() {
    print('=== FIELD VALIDATION ===');

    bool isValid = true;
    List<String> errors = [];

    if (!_formKey.currentState!.validate()) {
      errors.add('Form validation failed');
      isValid = false;
    }

    if (_selectedAnimalType == null) {
      errors.add('Animal type not selected');
      isValid = false;
    }

    if (_selectedGender == null) {
      errors.add('Gender not selected');
      isValid = false;
    }

    if (_selectedConditionType == null) {
      errors.add('Condition type not selected');
      isValid = false;
    }

    if (_selectedConditionLevel == null) {
      errors.add('Condition level not selected');
      isValid = false;
    }

    if (_selectedCityId == null) {
      errors.add('City not selected');
      isValid = false;
    }

    if (_selectedImages.isEmpty) {
      errors.add('No images selected');
      isValid = false;
    }

    if (_latitude == 0.0 || _longitude == 0.0) {
      errors.add('Location not available');
      isValid = false;
    }

    if (widget.customerId.isEmpty) {
      errors.add('Customer ID is empty');
      isValid = false;
    }

    print('Validation result: $isValid');
    if (!isValid) {
      print('Errors: ${errors.join(', ')}');
    }

    return isValid;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    //_districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}