import 'package:flutter/material.dart';
import 'package:petba_new/services/location_service.dart';
import 'package:petba_new/services/user_data_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/providers/Config.dart';

class LocationPickerWidget extends StatefulWidget {
  final Function(String, int?) onLocationSelected;
  final String currentLocation;

  LocationPickerWidget({
    required this.onLocationSelected,
    required this.currentLocation,
  });

  @override
  _LocationPickerWidgetState createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  bool isLoadingLocation = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    LocationResult result = await LocationService.getCurrentLocation();

    setState(() {
      isLoadingLocation = false;
    });

    if (result.success) {
      // Print coordinates to console (as requested)
      if (result.latitude != null && result.longitude != null) {
        print('=== CURRENT LOCATION COORDINATES ===');
        print('Latitude: ${result.latitude}');
        print('Longitude: ${result.longitude}');
        print('Address: ${result.address ?? 'No address available'}');
        print('=====================================');

        // Save coordinates to UserDataService
        await UserDataService.setCoordinates(
          result.latitude!,
          result.longitude!,
        );
        print('Current location coordinates saved successfully');
      }

      // Pass the readable address to the UI
      String displayAddress = result.address ?? 'Current Location';
      widget.onLocationSelected(displayAddress, null);
      Navigator.pop(context);
    } else if (result.error != null) {
      Navigator.pop(context);
      LocationService.showLocationErrorDialog(context, result.error!);
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF2d2d2d),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return LocationPickerBottomSheet(
          onLocationSelected: (String location, int? cityId) async {
            // When a city is manually selected, get its coordinates and save them
            print('=== SELECTED LOCATION ===');
            print('Selected City: $location');
            print('City ID: $cityId');

            // Save city_id if available
            if (cityId != null) {
              await UserDataService.setCityId(cityId);
              print('City ID saved: $cityId');
            }

            // Clear previous coordinates when selecting a city
            await UserDataService.clearCoordinates();
            print('Previous coordinates cleared for city selection');

            // Try to get coordinates for the selected city
            try {
              // Use just the city name for better geocoding success
              String cityName = location.split(',')[0].trim();
              LocationResult result =
                  await LocationService.getCoordinatesFromAddress(cityName);
              if (result.success &&
                  result.latitude != null &&
                  result.longitude != null) {
                print('Latitude: ${result.latitude}');
                print('Longitude: ${result.longitude}');

                // Save coordinates to UserDataService
                await UserDataService.setCoordinates(
                  result.latitude!,
                  result.longitude!,
                );
                print('Coordinates saved successfully');
              } else {
                print('Could not get coordinates for: $location');
                // If geocoding fails, we still proceed but without coordinates
                // The dashboard will use city_id instead
              }
            } catch (e) {
              print('Error getting coordinates: $e');
              // If geocoding fails, we still proceed but without coordinates
              // The dashboard will use city_id instead
            }
            print('========================');

            widget.onLocationSelected(location, cityId);
          },
          onCurrentLocationTap: _getCurrentLocation,
          isLoadingLocation: isLoadingLocation,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showLocationPicker,
      child: Row(
        children: [
          Icon(Icons.public, color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.currentLocation.isNotEmpty
                  ? widget.currentLocation
                  : 'Select Location',
              style: TextStyle(color: Colors.blue, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Colors.blue, size: 20),
        ],
      ),
    );
  }
}

class LocationPickerBottomSheet extends StatefulWidget {
  final Function(String, int?) onLocationSelected;
  final VoidCallback onCurrentLocationTap;
  final bool isLoadingLocation;

  LocationPickerBottomSheet({
    required this.onLocationSelected,
    required this.onCurrentLocationTap,
    required this.isLoadingLocation,
  });

  @override
  _LocationPickerBottomSheetState createState() =>
      _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState extends State<LocationPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _cities = [];
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    // No need to initialize with popular cities, will load from API
  }

  Future<void> _searchCities(String searchText) async {
    if (searchText.trim().isEmpty) {
      setState(() {
        _cities = [];
      });
      return;
    }

    setState(() {
      _isLoadingCities = true;
      _cities = [];
    });

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/search-city'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'off': 0, 'search': searchText}),
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
        throw Exception(
          'Failed to load cities - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Show error message or handle silently
      print('Failed to load cities: $e');
    } finally {
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Title
          Text(
            'Select Location',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (value.length >= 1) {
                  _searchCities(value);
                } else {
                  setState(() {
                    _cities = [];
                  });
                }
              },
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for a city...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                // Add clear button when text is entered
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _cities = [];
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(height: 20),

          // Current Location option
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.isLoadingLocation
                    ? Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      )
                    : Icon(Icons.my_location, color: Colors.blue),
              ),
              title: Text(
                widget.isLoadingLocation
                    ? 'Getting location...'
                    : 'Use Current Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                widget.isLoadingLocation
                    ? 'Please wait while we fetch your location...'
                    : 'Get your current location automatically',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: widget.isLoadingLocation
                  ? null
                  : Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
              onTap: widget.isLoadingLocation
                  ? null
                  : () {
                      widget.onCurrentLocationTap();
                    },
            ),
          ),
          SizedBox(height: 15),

          // Divider
          Divider(color: Colors.grey.withOpacity(0.3), thickness: 1),
          SizedBox(height: 15),

          // Cities label
          Row(
            children: [
              Icon(Icons.location_city, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Search Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                '${_cities.length} cities',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 15),

          // Cities list
          Expanded(
            child: _isLoadingCities
                ? Center(
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
                  )
                : _cities.isEmpty && _searchController.text.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, color: Colors.grey, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'No cities found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          'Try different search terms',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _cities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: Colors.grey, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Start typing to search cities',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _cities.length,
                    itemBuilder: (context, index) {
                      final city = _cities[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.location_city,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            city['city_name'].toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          subtitle: Text(
                            '${city['district']}, ${city['state']}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 14,
                          ),
                          onTap: () {
                            String displayName =
                                '${city['city_name']}, ${city['state']}';
                            int? cityId = city['city_id'] as int?;
                            widget.onLocationSelected(displayName, cityId);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
