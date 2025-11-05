import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:petba_new/models/Validate.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:petba_new/providers/Config.dart';
import 'HomePage.dart';

class AddPetPage extends StatefulWidget {
  final String customerId;
  const AddPetPage({Key? key, required this.customerId}) : super(key: key);

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  //final TextEditingController _cityController = TextEditingController();
  //final TextEditingController _districtController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  //final TextEditingController _antiRbsController = TextEditingController();
  //final TextEditingController _viralController = TextEditingController();
  final TextEditingController _animalNameController = TextEditingController();
  final TextEditingController _breedNameController = TextEditingController();

  // Form field values
  String? _selectedGender;
  DateTime? _selectedDate;
  String? _selectedAnimalId;
  String? _selectedBreedId;
  int? _selectedColorId;
  String? _selectedCityId;
  String? _selectedCityName;
  String? _selectedState;
  String? _selectedDistrict;
  DateTime? _selectedAntiRbsDate;
  DateTime? _selectedViralDate;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

  // Required variables for API
  Position? _currentPosition;
  List<Map<String, dynamic>> _colors = [];
  List<Map<String, dynamic>> _animals = [];
  List<Map<String, dynamic>> _breeds = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _districts = [];
  double _latitude = 0.0;
  double _longitude = 0.0;

  // Dropdown options
  final List<Map<String, dynamic>> _genderOptions = [
    {'id': '1', 'name': 'Male'},
    {'id': '2', 'name': 'Female'},
  ];

  // Loading states
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  bool _isLoadingAnimals = false;
  bool _isLoadingBreeds = false;
  bool _isLoadingColors = false;
  bool _isLoadingCities = false;
  bool _isLoadingStates = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingInitialData = true;
  bool _isFormCleared = false;
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    print('AddPetPage initialized');

    // Validate customerId
    if (widget.customerId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessage('Invalid user session. Please login again.', isError: true);
        Navigator.pop(context);
      });
      return;
    }
    _initializePageData();
  }

  Future<void> _initializePageData() async {
    setState(() {
      _isLoadingInitialData = true;
    });

    try {
      await Future.wait([
        _loadInitialData(),
        _getCurrentLocation(),
      ]);
    } catch (e) {
      _showMessage('Failed to load initial data: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingInitialData = false;
      });
    }
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _breedController.dispose();
    _addressController.dispose();
    //_cityController.dispose();
    //_districtController.dispose();
    _noteController.dispose();
    //_antiRbsController.dispose();
    //_viralController.dispose();
    _animalNameController.dispose();
    _breedNameController.dispose();
    super.dispose();
  }

  // Load initial data from APIs
  Future<void> _loadInitialData() async {
    print('Loading initial data...');
    await Future.wait([
      _loadColors(),
      _loadAnimals(),
      _loadStates(),
    ]);
    print('Initial data loaded');
  }

  // Load colors from API
  Future<void> _loadColors() async {
    if (!mounted) return;

    setState(() {
      _isLoadingColors = true;
    });

    try {
      print('Loading colors...');
      final response = await http.get(
        Uri.parse('$apiurl/api/colors'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _colors = List<Map<String, dynamic>>.from(data['color']);
        });
        print('Colors loaded: ${_colors.length}');
      } else {
        throw Exception('Failed to load colors');
      }
    } catch (e) {
      print('Error loading colors: $e');
      throw e;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingColors = false;
        });
      }
    }
  }

  // Load animals from API
  Future<void> _loadAnimals() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAnimals = true;
    });

    try {
      print('Loading animals...');
      final response = await http.get(
        Uri.parse('$apiurl/api/animalbreed'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _animals = List<Map<String, dynamic>>.from(data['animalbreed']);
        });
        print('Animals loaded: ${_animals.length}');
      } else {
        throw Exception('Failed to load animals');
      }
    } catch (e) {
      print('Error loading animals: $e');
      throw e;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnimals = false;
        });
      }
    }
  }

  // Load states from API
  Future<void> _loadStates() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStates = true;
    });

    try {
      print('Loading states...');
      final response = await http.post(
        Uri.parse('$apiurl/api/load-states'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'offset': 0}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> statesList = [];

        if (data['searchitems'] != null) {
          // Convert the response to proper format
          for (var item in data['searchitems']) {
            statesList.add({
              'state_code': item['state'],
              'state_name': item['state'],
            });
          }
        }

        setState(() {
          _states = statesList;
        });
        print('States loaded: ${_states.length}');
      } else {
        throw Exception('Failed to load states');
      }
    } catch (e) {
      print('Error loading states: $e');
      throw e;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStates = false;
        });
      }
    }
  }

  // Load districts from API
  Future<void> _loadDistricts(String state) async {
    if (!mounted || _isFormCleared || state.isEmpty) return;

    setState(() {
      _isLoadingDistricts = true;
      _selectedDistrict = null;
      _districts = [];
      _selectedCityId = null;
      _selectedCityName = null;
      _cities = [];
    });

    try {
      print('Loading districts for state: $state');
      final response = await http.post(
        Uri.parse('$apiurl/api/load-districts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'offset': 0,
          'state': state,
        }),
      );

      if (!mounted || _isFormCleared) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> districtsList = [];

        if (data['searchitems'] != null) {
          for (var district in data['searchitems']) {
            districtsList.add({
              'district_code': district,
              'district_name': district,
            });
          }
        }

        if (mounted && !_isFormCleared) {
          setState(() {
            _districts = districtsList;
          });
        }
        print('Districts loaded: ${_districts.length}');
      } else {
        throw Exception('Failed to load districts - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading districts: $e');
      if (mounted && !_isFormCleared) {
        _showMessage('Failed to load districts: $e', isError: true);
      }
    } finally {
      if (mounted && !_isFormCleared) {
        setState(() {
          _isLoadingDistricts = false;
        });
      }
    }
  }

  // COMPLETE REPLACEMENT for _loadBreeds method with flag check
  Future<void> _loadBreeds(String animalId) async {
    if (!mounted || _isFormCleared) return; // Add flag check

    setState(() {
      _isLoadingBreeds = true;
      _selectedBreedId = null;  // Clear selection BEFORE clearing list
      _breeds = [];             // Then clear the list
    });

    try {
      print('Loading breeds for animal: $animalId');
      final response = await http.post(
        Uri.parse('$apiurl/api/breed'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'animal_id': animalId,
        }),
      );

      // Check if form was cleared while we were loading
      if (!mounted || _isFormCleared) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> breedsList = [];

        if (data is List) {
          breedsList = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['breed'] != null) {
          breedsList = List<Map<String, dynamic>>.from(data['breed']);
        }

        if (mounted && !_isFormCleared) {
          setState(() {
            _breeds = breedsList;
            // Don't restore _selectedBreedId here - let user select again
          });
        }
        print('Breeds loaded: ${_breeds.length}');
      } else {
        throw Exception('Failed to load breeds - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading breeds: $e');
      if (mounted && !_isFormCleared) {
        _showMessage('Failed to load breeds: $e', isError: true);
      }
    } finally {
      if (mounted && !_isFormCleared) {
        setState(() {
          _isLoadingBreeds = false;
        });
      }
    }
  }

  // Load cities from API
  Future<void> _loadCities(String district) async {
    if (district.trim().isEmpty || !mounted || _isFormCleared) return;

    setState(() {
      _isLoadingCities = true;
      _selectedCityId = null;
      _selectedCityName = null;
      _cities = [];
    });

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/load-cities'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'offset': 0,
          'district': district,
        }),
      );

      if (!mounted || _isFormCleared) return;  // Check mounted before setState

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> citiesList = [];

        if (data['searchitems'] != null) {
          citiesList = List<Map<String, dynamic>>.from(data['searchitems']);
          citiesList = citiesList.map((item) {
            return {
              'city_id': item['city_id'],
              'city_name': item['city'],
            };
          }).toList();
        } else if (data['cities'] != null) {
          citiesList = List<Map<String, dynamic>>.from(data['cities']);
        } else if (data['data'] != null) {
          citiesList = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          citiesList = List<Map<String, dynamic>>.from(data);
        }

        if (mounted && !_isFormCleared) {
          setState(() {
            _cities = citiesList;
          });
        }
      } else {
        throw Exception('Failed to load cities - Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted && !_isFormCleared) {
        _showMessage('Failed to load cities: $e', isError: true);
      }
    } finally {
      if (mounted && !_isFormCleared) {
        setState(() {
          _isLoadingCities = false;
        });
      }
    }
  }

  // Get current location method
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

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String street = place.street ?? '';
            String subLocality = place.subLocality ?? '';
            String locality = place.locality ?? '';
            String state = place.administrativeArea ?? '';
            String district = place.subAdministrativeArea ?? locality;

            _addressController.text = '$street${street.isNotEmpty && subLocality.isNotEmpty ? ', ' : ''}$subLocality';
            //_cityController.text = locality;

            // Auto-select location data if available
            if (state.isNotEmpty) {
              _selectedState = state;
              _loadDistricts(state);

              if (district.isNotEmpty) {
                // Set district after a small delay to allow districts to load
                Future.delayed(Duration(milliseconds: 500), () {
                  if (mounted && !_isFormCleared) {
                    setState(() {
                      _selectedDistrict = district;
                    });
                    _loadCities(district);
                  }
                });
              }
            }
          }
        });

      } catch (e) {
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

  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Image picker methods
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
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

  // Convert File to base64
  Future<String> _convertImageToBase64(File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Failed to convert image to base64: $e');
    }
  }

  // Helper function to convert gender to integer
  int _convertGenderToInt(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 1;
      case 'female':
        return 2;
      default:
        return 1;
    }
  }

  // Add these date picker methods
  Future<void> _selectAntiRbsDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020), // Adjust as needed
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedAntiRbsDate) {
      setState(() {
        _selectedAntiRbsDate = picked;
      });
    }
  }

  Future<void> _selectViralDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020), // Adjust as needed
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedViralDate) {
      setState(() {
        _selectedViralDate = picked;
      });
    }
  }
  void _navigateToHomepage() {
    // Show success message briefly before navigating
    _showMessage('Pet added successfully! Redirecting to homepage...', isError: false);

    // Add a small delay to let user see the success message
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
        );
      }
    });
  }

  // Submit form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    String? genderError = Validators.validateGender(_selectedGender);
    if (genderError != null) {
      _showMessage(genderError, isError: true);
      return;
    }

    String? dateError = Validators.validateDateOfBirth(_selectedDate);
    if (dateError != null) {
      _showMessage(dateError, isError: true);
      return;
    }

    String? animalError = Validators.validateAnimalType(_selectedAnimalId);
    if (animalError != null) {
      _showMessage(animalError, isError: true);
      return;
    }

    String? imageError = Validators.validateImages(_selectedImages);
    if (imageError != null) {
      _showMessage(imageError, isError: true);
      return;
    }

    if (_selectedColorId == null) {
      _showMessage('Please select a color', isError: true);
      return;
    }

    if (_selectedState == null) {
      _showMessage('Please select a state', isError: true);
      return;
    }

    if (_selectedDistrict == null) {
      _showMessage('Please select a district', isError: true);
      return;
    }

    // Replace the existing breed validation with this:
    bool isCustomAnimal = _selectedAnimalId == '0' || _animals.any((animal) => animal['animal_id'].toString() == _selectedAnimalId && animal['name']?.toLowerCase() == 'other');

    if (isCustomAnimal) {
      // For custom animals, require custom breed name
      if (_breedNameController.text.trim().isEmpty) {
        _showMessage('Please enter custom breed name', isError: true);
        return;
      }
    } else {
      // For regular animals, require either breed selection or custom breed name
      if (_selectedBreedId == null && _breedNameController.text.trim().isEmpty) {
        _showMessage('Please select a breed or enter custom breed name', isError: true);
        return;
      }
    }

    if (_selectedCityId == null) {
      _showMessage('Please select a city', isError: true);
      return;
    }

    if (_latitude == 0.0 || _longitude == 0.0) {
      if (_addressController.text.trim().isEmpty ) {
        _showMessage('Location is required. Please enable location services or enter address manually.', isError: true);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Parse numeric values with proper error handling
      int customerId;
      int cityId;

      try {
        customerId = int.parse(widget.customerId);
      } catch (e) {
        throw Exception('Invalid customer ID format');
      }

      try {
        cityId = int.parse(_selectedCityId ?? '0');
      } catch (e) {
        throw Exception('Invalid city ID format');
      }

      // Prepare the request body
      Map<String, dynamic> requestBody = {
        'c_id': customerId,
        'name': _petNameController.text.trim(),
        'animal': _selectedAnimalId ?? '',
        'animalName': _animalNameController.text.trim().isEmpty ? null : _animalNameController.text.trim(),
        'gender': _selectedGender ?? '',
        'color': _selectedColorId.toString(),
        'breed': _selectedBreedId ?? '0',
        'breedName': _breedNameController.text.trim().isEmpty ? null : _breedNameController.text.trim(),
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        'city': _selectedCityName ?? '',
        'city_id': cityId,
        'district': _selectedDistrict ?? '',
        'state': _selectedState ?? '',
        'long': _longitude,
        'lat': _latitude,
        //'anti_rbs': _antiRbsController.text.trim().isEmpty ? null : _antiRbsController.text.trim(),
        //'viral': _viralController.text.trim().isEmpty ? null : _viralController.text.trim(),
        'anti_rbs': _selectedAntiRbsDate != null
            ? '${_selectedAntiRbsDate!.year}-${_selectedAntiRbsDate!.month.toString().padLeft(2, '0')}-${_selectedAntiRbsDate!.day.toString().padLeft(2, '0')}'
            : null,
        'viral': _selectedViralDate != null
            ? '${_selectedViralDate!.year}-${_selectedViralDate!.month.toString().padLeft(2, '0')}-${_selectedViralDate!.day.toString().padLeft(2, '0')}'
            : null,
        'dob': _selectedDate!.toIso8601String().split('T')[0],
        'img1': '',
        'img2': '',
        'img3': '',
        'img4': '',
        'img5': '',
        'img6': '',
      };

      // Convert selected images to base64
      for (int i = 0; i < _selectedImages.length && i < 6; i++) {
        String base64Image = await _convertImageToBase64(_selectedImages[i]);
        requestBody['img${i + 1}'] = base64Image;
        print('Image ${i + 1} converted successfully: ${base64Image.length} characters');
        // print('Base64: ${base64Image}');
      }

      print('=== PET REQUEST DATA ===');
      print('Customer ID: ${requestBody['c_id']} (Type: ${requestBody['c_id'].runtimeType})');
      print('Pet Name: ${requestBody['name']}');
      print('Animal: ${requestBody['animal']}');
      print('Gender: ${requestBody['gender']} (Type: ${requestBody['gender'].runtimeType})');
      print('State: ${requestBody['state']}');
      print('District: ${requestBody['district']}');
      print('City ID: ${requestBody['city_id']} (Type: ${requestBody['city_id'].runtimeType})');
      print('Breed ID: ${requestBody['breed']} (Type: ${requestBody['breed'].runtimeType})');
      print('AntiRbs: ${requestBody['anti_rbs']} (Type: ${requestBody['anti_rbs'].runtimeType})');
      print('Viral: ${requestBody['viral']} (Type: ${requestBody['viral'].runtimeType})');
      print('DOB: ${requestBody['dob']} (Type: ${requestBody['dob'].runtimeType})');
      print('Color ID: ${requestBody['color']} (Type: ${requestBody['color'].runtimeType})');
      print('Number of images: ${_selectedImages.length}');
      print('========================');

      // Make API call
      final response = await http.post(
        Uri.parse('$apiurl/api/addpet'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          _navigateToHomepage();
        }

        // Wait a moment before clearing to ensure user sees success
        await Future.delayed(Duration(milliseconds: 500));

        // Clear form after successful submission
        if (mounted) {
          _clearForm();
        }
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = 'Failed to add pet';

        if (errorData['error'] != null) {
          errorMessage = errorData['error'].toString();
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }

        if (mounted) {
          _showMessage(errorMessage, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error: $e', isError: true);
      }
      print('Submit error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    if (!mounted) return; // Add mounted check

    print('=== CLEARING FORM ===');

    // Set flag to prevent any pending async operations
    _isFormCleared = true;

    _formKey.currentState?.reset();

    _petNameController.clear();
    _breedController.clear();
    _addressController.clear();
    //_cityController.clear();
    //_districtController.clear();
    _noteController.clear();
    _animalNameController.clear();
    _breedNameController.clear();

    setState(() {
      // Clear all selections FIRST
      _selectedGender = null;
      _selectedDate = null;
      _selectedAnimalId = null;
      _selectedBreedId = null;  // Clear this BEFORE clearing breeds list
      _selectedColorId = null;
      _selectedCityId = null;
      _selectedCityName = null;
      _selectedState = null;
      _selectedDistrict = null;
      _selectedAntiRbsDate = null;
      _selectedViralDate = null;

      // Clear dependent lists AFTER clearing selections
      _breeds.clear();
      _cities.clear();
      _districts.clear(); // Add this line to clear districts as well
      _selectedImages.clear();

      // Reset location coordinates but keep current location if available
      // Don't reset _latitude and _longitude if we have current position
      // This prevents requiring location permission again
      // Reset loading states
      _isLoadingBreeds = false;
      _isLoadingCities = false;
      _isLoadingDistricts = false;
    });

    // Optionally scroll to top
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            Scrollable.ensureVisible(
              context,
              duration: Duration(milliseconds: 300),
            );
          } catch (e) {
            // Handle any scrolling errors silently
            print('Scrolling error: $e');
          }
        }
      });
    }
    // Reset the flag after a delay to allow new form usage
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _isFormCleared = false;
      }
    });

    print('=== FORM CLEARED ===');
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return; // Add mounted check

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
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
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Loading pet form...',
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
        title: const Text('Add Pet'),
        backgroundColor: Color(0xFF2d2d2d),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoadingLocation)
            Container(
              margin: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        color: Color(0xFF1a1a1a),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Error Display
                if (_locationError.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationError,
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Location Info
                _buildLocationInfo(),
                SizedBox(height: 20),

                // Pet Name
                _buildTextField(
                  label: 'Pet Name',
                  controller: _petNameController,
                  icon: Icons.pets,
                  validator: Validators.validatePetName,
                ),

                const SizedBox(height: 20),

                // Gender Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Gender *'),
                    SizedBox(height: 8),
                    _buildApiDropdownField(
                      value: _selectedGender,
                      items: _genderOptions,
                      hint: 'Select gender',
                      displayKey: 'name',
                      valueKey: 'id',
                      onChanged: (value) => setState(() => _selectedGender = value),
                      validator: (value) => value == null ? 'Please select gender' : null,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Date of Birth
                _buildDateField(),

                const SizedBox(height: 20),

                // Animal and Breed Row - UPDATED
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Animal Type *'),
                          SizedBox(height: 8),
                          _buildAnimalDropdownField(),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show normal breed dropdown only if NOT custom animal
                          if (!(_selectedAnimalId == '0' || _animals.any((animal) => animal['animal_id'].toString() == _selectedAnimalId && animal['name']?.toLowerCase() == 'other'))) ...[
                            _buildSectionTitle('Breed *'),
                            SizedBox(height: 8),
                            _buildBreedDropdownField(),
                          ]
                          // Show custom breed field if custom animal is selected
                          else ...[
                            _buildSectionTitle('Breed Name (Custom) *'),
                            SizedBox(height: 8),
                            _buildCustomBreedField(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

// Custom Animal Name Row - Show when custom animal selected
                if (_selectedAnimalId == '0' || _animals.any((animal) => animal['animal_id'].toString() == _selectedAnimalId && animal['name']?.toLowerCase() == 'other'))
                  Column(
                    children: [
                      _buildTextField(
                        label: 'Animal Type (Custom)',
                        controller: _animalNameController,
                        icon: Icons.pets,
                        isRequired: true,
                        validator: (value) {
                          if (_selectedAnimalId == '0' && (value == null || value.trim().isEmpty)) {
                            return 'Please enter custom type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

// Only show custom breed field separately if regular animal but custom breed selected
                if (!(_selectedAnimalId == '0' || _animals.any((animal) => animal['animal_id'].toString() == _selectedAnimalId && animal['name']?.toLowerCase() == 'other')) &&
                    (_selectedBreedId == '0' || _breeds.any((breed) => breed['id'].toString() == _selectedBreedId && breed['name']?.toLowerCase() == 'other')))
                  Column(
                    children: [
                      _buildTextField(
                        label: 'Breed Name (Custom)',
                        controller: _breedNameController,
                        icon: Icons.category,
                        isRequired: true,
                        validator: (value) {
                          if (_selectedBreedId == '0' && (value == null || value.trim().isEmpty)) {
                            return 'Please enter custom breed name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                const SizedBox(height: 20),

                //Colors
                _buildColorDropdownField(),
                const SizedBox(height: 20),

                // NEW: Cascading Location Dropdowns (State -> District -> City)
                _buildLocationSection(),

                const SizedBox(height: 20),

                // Address
                _buildTextField(
                  label: 'Address',
                  controller: _addressController,
                  icon: Icons.location_on,
                  validator: Validators.validateAddress,
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                /*// Anti RBS
                _buildTextField(
                  label: 'Anti RBS (Vaccination/Medical Info)',
                  controller: _antiRbsController,
                  icon: Icons.medical_services,
                  isRequired: false,
                  maxLines: 2,
                ),*/
                _buildAntiRbsDateField(),


                const SizedBox(height: 20),

                /*// Viral
                _buildTextField(
                  label: 'Viral (Vaccination/Medical Info)',
                  controller: _viralController,
                  icon: Icons.medical_services,
                  isRequired: false,
                  maxLines: 2,
                ),*/
                _buildViralDateField(),

                const SizedBox(height: 20),

                // Note
                _buildTextField(
                  label: 'Note',
                  controller: _noteController,
                  icon: Icons.note,
                  maxLines: 4,
                  isRequired: false,
                  validator: Validators.validateNote,
                ),

                const SizedBox(height: 30),

                // Image Upload Section
                _buildImageUploadSection(),

                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.grey[700],
                    ),
                    child: _isSubmitting
                        ? const Row(
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
                        Text('Submitting...'),
                      ],
                    )
                        : const Text(
                      'Submit',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build cascading location section (State -> District -> City) in one row
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Location *'),
        SizedBox(height: 12),

        // All three dropdowns in one row
        Row(
          children: [
            // State Dropdown
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('State *', style: TextStyle(color: Colors.white, fontSize: 12)),
                  SizedBox(height: 8),
                  _buildStateDropdownField(),
                ],
              ),
            ),

            SizedBox(width: 8),

            // District Dropdown
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('District *', style: TextStyle(color: Colors.white, fontSize: 12)),
                  SizedBox(height: 8),
                  _buildDistrictDropdownField(),
                ],
              ),
            ),

            SizedBox(width: 8),

            // City Dropdown
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('City *', style: TextStyle(color: Colors.white, fontSize: 12)),
                  SizedBox(height: 8),
                  _buildCityDropdownField(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // State Dropdown Field
  Widget _buildStateDropdownField() {
    // Find if the selected state exists in current states list
    bool selectedStateExists = _selectedState != null &&
        _states.any((state) => state['state_name'] == _selectedState);

    return DropdownButtonFormField<String>(
      value: selectedStateExists ? _selectedState : null, // Only use value if it exists
      items: _isLoadingStates || _states.isEmpty
          ? [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            _isLoadingStates ? 'Loading states...' : 'No states available',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ]
          : _states.map((Map<String, dynamic> state) {
        return DropdownMenuItem<String>(
          value: state['state_name'],
          child: Text(
            state['state_name'] ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: _isLoadingStates || _isFormCleared
          ? null
          : (value) {
        if (value != null && value.isNotEmpty) {
          setState(() {
            _selectedState = value;
            _selectedDistrict = null;
            _districts = [];
            _selectedCityId = null;
            _selectedCityName = null;
            _cities = [];
          });
          _loadDistricts(value);
        }
      },
      dropdownColor: Color(0xFF2d2d2d),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.map, color: Colors.blue),
        suffixIcon: _isLoadingStates
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 2,
          ),
        )
            : null,
        hintText: 'Select state',
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Color(0xFF2d2d2d),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  // District Dropdown Field
  Widget _buildDistrictDropdownField() {
    bool isDisabled = _selectedState == null || _isLoadingDistricts || _isFormCleared;

    // Find if the selected district exists in current districts list
    bool selectedDistrictExists = _selectedDistrict != null &&
        _districts.any((district) => district['district_name'] == _selectedDistrict);

    // If selected district doesn't exist in current list, clear it
    if (_selectedDistrict != null && !selectedDistrictExists && _districts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isFormCleared) {
          setState(() {
            _selectedDistrict = null;
            _selectedCityId = null;
            _selectedCityName = null;
            _cities = [];
          });
        }
      });
    }

    return DropdownButtonFormField<String>(
      value: selectedDistrictExists ? _selectedDistrict : null, // Only use value if it exists
      items: isDisabled || _districts.isEmpty
          ? [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            _selectedState == null
                ? 'Select state first'
                : _isLoadingDistricts
                ? 'Loading districts...'
                : 'No districts available',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ]
          : _districts.map((Map<String, dynamic> district) {
        return DropdownMenuItem<String>(
          value: district['district_name'],
          child: Text(
            district['district_name'] ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: isDisabled
          ? null
          : (value) {
        if (value != null && value.isNotEmpty) {
          setState(() {
            _selectedDistrict = value;
            _selectedCityId = null;
            _selectedCityName = null;
            _cities = [];
          });
          _loadCities(value);
        }
      },
      dropdownColor: Color(0xFF2d2d2d),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.location_city, color: isDisabled ? Colors.grey : Colors.blue),
        suffixIcon: _isLoadingDistricts
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 2,
          ),
        )
            : null,
        hintText: _selectedState == null ? 'Select state first' : 'Select district',
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        filled: true,
        fillColor: isDisabled ? Colors.grey[800] : Color(0xFF2d2d2d),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(color: isDisabled ? Colors.grey[500] : Colors.white),
    );
  }


  // Location Info Widget
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
              borderRadius: BorderRadius.circular(10),
              color: Color(0xFF2d2d2d),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue, size: 20),
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
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
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
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isRequired = true,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.green),
            hintText: 'Enter ${label.toLowerCase().replaceAll(' *', '')}', // ADDED: Dynamic hint text
            hintStyle: TextStyle(color: Colors.grey[400]), // FIXED: Light grey instead of black
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Color(0xFF2d2d2d),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomBreedField() {
    return TextFormField(
      controller: _breedNameController,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter custom breed name';
        }
        return null;
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.category, color: Colors.green),
        hintText: 'Enter custom breed name',
        hintStyle: TextStyle(color: Colors.grey[400]), // FIXED: Light grey for visibility
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Color(0xFF2d2d2d),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // Fixed API Dropdown Field with proper hint text color
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
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? Color(0xFF2d2d2d) : Color(0xFF1a1a1a),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green),
        ),
        contentPadding: EdgeInsets.all(16),
      ),
      dropdownColor: Color(0xFF2d2d2d),
      style: TextStyle(color: enabled ? Colors.white : Colors.grey),
      hint: Text(
          hint,
          style: TextStyle(color: Colors.grey[400]) // FIXED: Light grey for visibility
      ),
      items: enabled ? items.map((item) {
        return DropdownMenuItem<String>(
          value: item[valueKey].toString(),
          child: Text(
            item[displayKey].toString(),
            style: TextStyle(color: Colors.white),
          ),
        );
      }).toList() : [],
      onChanged: enabled ? onChanged : null,
    );
  }

  // Fixed Animal Dropdown with proper colors
  Widget _buildAnimalDropdownField() {
    return DropdownButtonFormField<String>(
      key: ValueKey('animal_dropdown_${_selectedAnimalId ?? 'null'}'), // Add key for rebuild
      value: _selectedAnimalId,
      items: _isLoadingAnimals || _animals.isEmpty
          ? [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            _isLoadingAnimals ? 'Loading animals...' : 'No animals available',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ]
          : _animals.map((Map<String, dynamic> animal) {
        return DropdownMenuItem<String>(
          value: animal['animal_id']?.toString() ?? animal['id']?.toString(),
          child: Text(
            animal['name'] ?? animal['animal_name'] ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: _isLoadingAnimals || _isFormCleared
          ? null
          : (value) {
        if (value != null && value.isNotEmpty) {
          setState(() {
            _selectedAnimalId = value;
            _selectedBreedId = null;
            _breeds = [];
          });
          _loadBreeds(value);
        }
      },
      dropdownColor: Color(0xFF2d2d2d),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.pets, color: Colors.blue),
        suffixIcon: _isLoadingAnimals
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 2,
          ),
        )
            : null,
        hintText: 'Select animal type',
        hintStyle: TextStyle(color: Colors.grey[400]), // Fixed hint color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Color(0xFF2d2d2d),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  // Fixed Breed Dropdown with proper colors
  Widget _buildBreedDropdownField() {
    bool isDisabled = _selectedAnimalId == null || _isLoadingBreeds || _isFormCleared;
    bool isCustomAnimal = _selectedAnimalId == '0' ||
        _animals.any((animal) => animal['animal_id'].toString() == _selectedAnimalId && animal['name']?.toLowerCase() == 'other');

    return DropdownButtonFormField<String>(
      key: ValueKey('breed_dropdown_${_selectedBreedId ?? 'null'}'),
      value: _selectedBreedId,
      items: isDisabled || (_breeds.isEmpty && !isCustomAnimal)
          ? [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            _selectedAnimalId == null
                ? 'Select animal first'
                : isCustomAnimal
                ? 'Enter custom breed below'  // NEW: Better message for custom animals
                : _isLoadingBreeds
                ? 'Loading breeds...'
                : 'No breeds available',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ]
          : [
        // Add "Other" option for custom breed entry when it's not a custom animal
        if (!isCustomAnimal)
          DropdownMenuItem<String>(
            value: '0',
            child: Text(
              'Other (Custom)',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        // Add existing breeds
        ..._breeds.map((Map<String, dynamic> breed) {
          return DropdownMenuItem<String>(
            value: breed['id']?.toString() ?? breed['breed_id']?.toString(),
            child: Text(
              breed['name'] ?? breed['breed_name'] ?? 'Unknown',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
      ],
      onChanged: isDisabled
          ? null
          : (value) {
        if (mounted && !_isFormCleared) {
          setState(() {
            _selectedBreedId = value;
          });
        }
      },
      dropdownColor: Color(0xFF2d2d2d),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.category, color: Colors.blue),
        suffixIcon: _isLoadingBreeds
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 2,
          ),
        )
            : null,
        hintText: _selectedAnimalId == null ? 'Select animal first' : 'Select breed',
        hintStyle: TextStyle(color: Colors.white), // Fixed hint color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        filled: true,
        fillColor: isDisabled ? Colors.grey[800] : Color(0xFF2d2d2d),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(color: isDisabled ? Colors.grey[500] : Colors.white),
    );
  }

  // Fixed Color Dropdown with proper colors
  Widget _buildColorDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedColorId,
          items: _isLoadingColors || _colors.isEmpty
              ? [
            DropdownMenuItem<int>(
              value: null,
              child: Text(
                _isLoadingColors ? 'Loading colors...' : 'No colors available',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ]
              : _colors.map((Map<String, dynamic> color) {
            return DropdownMenuItem<int>(
              value: color['id'],
              child: Text(
                color['color'] ?? color['name'] ?? color['color_name'] ?? 'Unknown',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: _isLoadingColors
              ? null
              : (value) {
            setState(() {
              _selectedColorId = value;
            });
          },
          dropdownColor: Color(0xFF2d2d2d),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.color_lens, color: Colors.blue),
            suffixIcon: _isLoadingColors
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 2,
              ),
            )
                : null,
            hintText: 'Select color',
            hintStyle: TextStyle(color: Colors.grey[400]), // Fixed hint color
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Color(0xFF2d2d2d),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  // Replace the text field builders with date field builders
  Widget _buildAntiRbsDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anti RBS Vaccination Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectAntiRbsDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(10),
              color: Color(0xFF2d2d2d),
            ),
            child: Row(
              children: [
                Icon(Icons.medical_services, color: Colors.blue),
                const SizedBox(width: 16),
                Text(
                  _selectedAntiRbsDate == null
                      ? 'Select Anti RBS vaccination date (optional)'
                      : Validators.formatDate(_selectedAntiRbsDate!),
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedAntiRbsDate == null ? Colors.grey[400] : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViralDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viral Vaccination Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectViralDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(10),
              color: Color(0xFF2d2d2d),
            ),
            child: Row(
              children: [
                Icon(Icons.medical_services, color: Colors.blue),
                const SizedBox(width: 16),
                Text(
                  _selectedViralDate == null
                      ? 'Select viral vaccination date (optional)'
                      : Validators.formatDate(_selectedViralDate!),
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedViralDate == null ? Colors.grey[400] : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Date of Birth',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(10),
              color: Color(0xFF2d2d2d),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 16),
                Text(
                  _selectedDate == null
                      ? 'Select date of birth'
                      : Validators.formatDate(_selectedDate!),
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate == null ? Colors.grey[400] : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Upload Images (Max 6)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Add Image Button
        if (_selectedImages.length < 6)
          InkWell(
            onTap: _showImageSourceDialog,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[600]!, width: 2, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(10),
                color: Color(0xFF2d2d2d),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add images',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  Text(
                    '${_selectedImages.length}/6 images selected',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Display Selected Images
        if (_selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
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
                    child: InkWell(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  // City Dropdown Field
  Widget _buildCityDropdownField() {
    bool isDisabled = _selectedDistrict == null || _isLoadingCities || _isFormCleared;

    // Find if the selected city exists in current cities list
    bool selectedCityExists = _selectedCityId != null &&
        _cities.any((city) => city['city_id'].toString() == _selectedCityId);

    // If selected city doesn't exist in current list, clear it
    if (_selectedCityId != null && !selectedCityExists && _cities.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isFormCleared) {
          setState(() {
            _selectedCityId = null;
            _selectedCityName = null;
          });
        }
      });
    }

    return DropdownButtonFormField<String>(
      value: selectedCityExists ? _selectedCityId : null, // Only use value if it exists
      items: isDisabled || _cities.isEmpty
          ? [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            _selectedDistrict == null
                ? 'Select district first'
                : _isLoadingCities
                ? 'Loading cities...'
                : 'No cities available',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ]
          : _cities.map((Map<String, dynamic> city) {
        return DropdownMenuItem<String>(
          value: city['city_id'].toString(),
          child: Text(
            city['city_name'] ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: isDisabled
          ? null
          : (value) {
        if (value != null && value.isNotEmpty) {
          setState(() {
            _selectedCityId = value;
            _selectedCityName = _cities
                .firstWhere((city) => city['city_id'].toString() == value,
                orElse: () => {'city_name': null})['city_name'];
          });
        }
      },
      dropdownColor: Color(0xFF2d2d2d),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.location_on, color: isDisabled ? Colors.grey : Colors.blue),
        suffixIcon: _isLoadingCities
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 2,
          ),
        )
            : null,
        hintText: _selectedDistrict == null ? 'Select district first' : 'Select city',
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        filled: true,
        fillColor: isDisabled ? Colors.grey[800] : Color(0xFF2d2d2d),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(color: isDisabled ? Colors.grey[500] : Colors.white),
    );
  }
}
