//AddPet - Updated with AddRescue functionalities
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// removed unused imports
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
// removed unused import

import '../providers/Config.dart';
import 'package:petba_new/services/user_data_service.dart';

class RescuePage extends StatefulWidget {
  final String customerId;

  const RescuePage({Key? key, required this.customerId}) : super(key: key);

  @override
  _RescuePageState createState() => _RescuePageState();
}

class _RescuePageState extends State<RescuePage> {
  List<Map<String, dynamic>> _rescueList = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _lastPet = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isLoadingInitialData = true;
  int? _cityId; // currently selected city id
  // Radius (in km) to filter nearby rescues after sorting by distance
  double _radiusKm = 50.0;

  // Location data
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLoadingLocation = false;
  String _locationError = '';
  Position? _currentPosition;

  // Controllers (add these if you need them for other functionality)
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  // Filters
  String _sortOption = '1'; // 1 = Distance, 2 = Recent
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    print('Rescue Page initialised');
    // Validate customerId
    if (widget.customerId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessage(
          'Invalid user session. Please login again.',
          isError: true,
        );
        Navigator.pop(context);
      });
      return;
    }
    // Call the correct method
    _initializePageData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreRescuePets();
      }
    }
  }

  // Fixed: Single _initializePageData method
  Future<void> _initializePageData() async {
    setState(() {
      _isLoadingInitialData = true;
    });

    try {
      // Load city id and location concurrently
      final results = await Future.wait([
        _getCurrentLocation(),
        UserDataService.getCityId(),
      ]);
      // results[1] holds city id
      final fetchedCityId = results[1] as int?;
      if (mounted) {
        setState(() {
          _cityId = fetchedCityId;
        });
      }
      // Load data after location is obtained
      await _loadRescuePets(refresh: true);
    } catch (e) {
      _showMessage('Failed to load initial data: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingInitialData = false;
      });
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
          _locationError =
              'Location services are disabled. Please enable them in settings.';
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
          _locationError =
              'Location permissions are permanently denied. Please enable them in app settings.';
        });
        _showMessage(_locationError, isError: true);
        return;
      }

      // Get current position with timeout
      Position position =
          await Geolocator.getCurrentPosition(
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
        List<Placemark> placemarks =
            await placemarkFromCoordinates(
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

            _addressController.text =
                '$street${street.isNotEmpty && subLocality.isNotEmpty ? ', ' : ''}$subLocality';
            _cityController.text = locality;

            if (locality.isNotEmpty) {
              _districtController.text = locality;
              // _loadCities(locality); // Uncomment if you have this method
            }
          }
        });

        print('Location obtained: $_latitude, $_longitude');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationError = '';
        });
        print('Location obtained but address lookup failed: $e');
        // Don't show error message for address lookup failure, just use coordinates
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Error getting location: ${e.toString()}';

      if (e.toString().contains('timed out')) {
        errorMessage = 'Location request timed out. Please try again.';
      } else if (e.toString().contains('denied')) {
        errorMessage =
            'Location permission denied. Please grant location permission.';
      } else if (e.toString().contains('disabled')) {
        errorMessage =
            'Location services are disabled. Please enable location services.';
      }

      setState(() {
        _locationError = errorMessage;
      });
      print('Location error: $errorMessage');
      _showMessage(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _loadRescuePets({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _lastPet = 0;
        _hasMoreData = true;
      });
    }

    try {
      print('Loading rescue pets...');
      print('Customer ID: ${widget.customerId}');
      print('Latitude: $_latitude');
      print('Longitude: $_longitude');
      print('Last Pet: $_lastPet');
      print('Sort Option: $_sortOption');

      // Determine city id; fetch if not yet loaded
      // We no longer use city filtering; rely on distance ordering

      // Create request body: do NOT filter by customer or city (global),
      // and sort by distance on the backend using provided lat/lon
      final requestBody = {
        'c_id': null, // allow global results, not user-specific
        'latitude': _latitude,
        'longitude': _longitude,
        'lastPet': refresh ? null : _lastPet,
        'filter': {
          'condition': [],
          'animalType': [],
          'gender': [],
          'city': [],
        },
        'sort': _sortOption,
      };

      print('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$apiurl/api/rescueList'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');

        List<Map<String, dynamic>> newRescues =
            List<Map<String, dynamic>>.from(data['rescueList'] ?? []);

        print('New rescues count: ${newRescues.length}');

        // Calculate distances for each rescue item
        for (var rescue in newRescues) {
          if (rescue.containsKey('latitude') &&
              rescue.containsKey('longitude') &&
              rescue['latitude'] != null &&
              rescue['longitude'] != null) {
            try {
              double petLat = double.parse(rescue['latitude'].toString());
              double petLng = double.parse(rescue['longitude'].toString());
              double distanceInMeters = Geolocator.distanceBetween(
                _latitude,
                _longitude,
                petLat,
                petLng,
              );
              double distanceInKm = distanceInMeters / 1000.0;
              rescue['Distance'] = distanceInKm;
              print(
                'Calculated distance for pet: ${distanceInKm.toStringAsFixed(2)} km',
              );
            } catch (e) {
              print('Error calculating distance: $e');
              rescue['Distance'] = 0.0;
            }
          } else {
            rescue['Distance'] = 0.0;
          }
        }

        // Keep only rescues within the selected radius
        newRescues = newRescues
            .where((r) =>
                double.tryParse(r['Distance']?.toString() ?? '0') != null &&
                (double.tryParse(r['Distance']?.toString() ?? '0') ?? 0) <=
                    _radiusKm)
            .toList();

        setState(() {
          if (refresh) {
            _rescueList = newRescues;
          } else {
            _rescueList.addAll(newRescues);
          }

          _lastPet += newRescues.length;
          _hasMoreData = newRescues.length == 6; // API returns 6 items per page
          _isLoading = false;
          _isLoadingMore = false;
          _hasError = false;
        });

        print('Rescue list updated. Total items: ${_rescueList.length}');
      } else {
        throw Exception(
          'Failed to load rescue pets. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error loading rescue pets: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreRescuePets() async {
    setState(() {
      _isLoadingMore = true;
    });
    await _loadRescuePets();
  }

  Future<void> _refreshData() async {
    await _getCurrentLocation();
    await _loadRescuePets(refresh: true);
  }

  void _changeSortOption(String newSort) {
    if (_sortOption != newSort) {
      setState(() {
        _sortOption = newSort;
      });
      _loadRescuePets(refresh: true);
    }
  }

  String _getConditionText(String conditionLevel) {
    switch (conditionLevel) {
      case '1':
        return 'Critical';
      case '2':
        return 'Severe';
      case '3':
        return 'Moderate';
      case '4':
        return 'Mild';
      case '5':
        return 'Stable';
      default:
        return 'Unknown';
    }
  }

  Color _getConditionLevelColor(String conditionLevel) {
    switch (conditionLevel) {
      case '1':
        return Colors.red[700]!;
      case '2':
        return Colors.orange[700]!;
      case '3':
        return Colors.yellow[700]!;
      case '4':
        return Colors.blue[700]!;
      case '5':
        return Colors.green[700]!;
      default:
        return Colors.grey;
    }
  }

  // Fixed image URL construction
  String _constructImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    // If it already starts with http, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Remove leading slash if present to avoid double slashes
    String cleanPath = imagePath.startsWith('/')
        ? imagePath.substring(1)
        : imagePath;

    // Construct full URL
    return '$apiurl/$cleanPath';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Rescue Pets',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: Color(0xFFFF6B6B)),
            color: Color(0xFF2d2d2d),
            onSelected: _changeSortOption,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: '1',
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _sortOption == '1'
                          ? Color(0xFFFF6B6B)
                          : Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sort by Distance',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: '2',
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _sortOption == '2'
                          ? Color(0xFFFF6B6B)
                          : Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sort by Recent',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingInitialData || (_isLoading && _rescueList.isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFFF6B6B)),
            SizedBox(height: 16),
            Text(
              'Loading rescue pets...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'Failed to load rescue pets',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B6B),
              ),
              child: Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_rescueList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, color: Color(0xFFFF6B6B), size: 64),
            SizedBox(height: 16),
            Text(
              'No rescue pets found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later or adjust your filters',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B6B),
              ),
              child: Text('Refresh', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Color(0xFFFF6B6B),
      backgroundColor: Color(0xFF2d2d2d),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: _rescueList.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _rescueList.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFFFF6B6B)),
              ),
            );
          }

          return _buildRescueCard(_rescueList[index]);
        },
      ),
    );
  }

  Widget _buildRescueCard(Map<String, dynamic> rescue) {
    String imageUrl = _constructImageUrl(rescue['img1']?.toString() ?? '');
    double distance =
        double.tryParse(rescue['Distance']?.toString() ?? '0') ?? 0;
    String conditionType = rescue['ConditionType'] ?? 'Unknown';
    String conditionLevel = rescue['conditionLevel_id']?.toString() ?? '0';
    String status = rescue['status']?.toString() ?? '0';

    print('Image URL constructed: $imageUrl'); // Debug log

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.grey[800],
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print(
                          'Image loading error for $imageUrl: $error',
                        ); // Debug log
                        return Container(
                          color: Colors.grey[700],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pets,
                                  color: Colors.grey[500],
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[700],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF6B6B),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: Colors.grey[700],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, color: Colors.grey[500], size: 48),
                          SizedBox(height: 8),
                          Text(
                            'No Image Available',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Content Section
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and Condition Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getConditionLevelColor(conditionLevel),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getConditionText(conditionLevel),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == '0'
                            ? Colors.orange[600]
                            : Colors.green[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status == '0' ? 'Pending' : 'Rescued',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Condition Type
                Text(
                  conditionType,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFFFF6B6B), size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        rescue['address'] ?? 'Location not available',
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // City and Distance
                Row(
                  children: [
                    Icon(Icons.place, color: Color(0xFFFF6B6B), size: 16),
                    SizedBox(width: 4),
                    Text(
                      rescue['city'] ?? 'Unknown City',
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                    Spacer(),
                    Icon(Icons.straighten, color: Color(0xFFFF6B6B), size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  ],
                ),

                // Description (if available)
                if (rescue['description'] != null &&
                    rescue['description'].toString().isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    rescue['description'],
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showRescueDetails(rescue);
                        },
                        icon: Icon(Icons.visibility, size: 18),
                        label: Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF6B6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showContactOptions(rescue);
                        },
                        icon: Icon(Icons.contact_phone, size: 18),
                        label: Text('Contact'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFFFF6B6B),
                          side: BorderSide(color: Color(0xFFFF6B6B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRescueDetails(Map<String, dynamic> rescue) {
    String imageUrl = _constructImageUrl(rescue['img1']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF2d2d2d),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Rescue Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Image
              if (imageUrl.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[800],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[700],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pets,
                                  color: Colors.grey[500],
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Details
              _buildDetailRow(
                'Condition',
                rescue['ConditionType'] ?? 'Unknown',
              ),
              _buildDetailRow(
                'Severity',
                _getConditionText(
                  rescue['conditionLevel_id']?.toString() ?? '0',
                ),
              ),
              _buildDetailRow(
                'Status',
                rescue['status'] == '0' ? 'Needs Rescue' : 'Rescued',
              ),
              _buildDetailRow('Location', rescue['address'] ?? 'Not available'),
              _buildDetailRow('City', rescue['city'] ?? 'Unknown'),
              _buildDetailRow(
                'Distance',
                '${double.tryParse(rescue['Distance']?.toString() ?? '0')?.toStringAsFixed(1) ?? '0'} km',
              ),

              if (rescue['description'] != null &&
                  rescue['description'].toString().isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Description:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  rescue['description'],
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
              ],

              SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF6B6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactOptions(Map<String, dynamic> rescue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2d2d2d),
        title: Text('Contact Options', style: TextStyle(color: Colors.white)),
        content: Text(
          'Contact functionality would be implemented here based on your app\'s messaging/calling features.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}
