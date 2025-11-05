import 'package:flutter/material.dart';
import 'package:petba_new/services/location_service.dart';

class LocationPickerWidget extends StatefulWidget {
  final Function(String) onLocationSelected;
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
      }

      // Pass the readable address to the UI
      String displayAddress = result.address ?? 'Current Location';
      widget.onLocationSelected(displayAddress);
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
          onLocationSelected: (String location) async {
            // When a city is manually selected, optionally get its coordinates
            print('=== SELECTED LOCATION ===');
            print('Selected City: $location');

            // Try to get coordinates for the selected city
            try {
              LocationResult result = await LocationService.getCoordinatesFromAddress(location);
              if (result.success && result.latitude != null && result.longitude != null) {
                print('Latitude: ${result.latitude}');
                print('Longitude: ${result.longitude}');
              } else {
                print('Could not get coordinates for: $location');
              }
            } catch (e) {
              print('Error getting coordinates: $e');
            }
            print('========================');

            widget.onLocationSelected(location);
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
  final Function(String) onLocationSelected;
  final VoidCallback onCurrentLocationTap;
  final bool isLoadingLocation;

  LocationPickerBottomSheet({
    required this.onLocationSelected,
    required this.onCurrentLocationTap,
    required this.isLoadingLocation,
  });

  @override
  _LocationPickerBottomSheetState createState() => _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState extends State<LocationPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<String> popularCities = [
    'Mumbai, Maharashtra',
    'Delhi, NCR',
    'Bangalore, Karnataka',
    'Chennai, Tamil Nadu',
    'Kolkata, West Bengal',
    'Hyderabad, Telangana',
    'Pune, Maharashtra',
    'Goa, India',
    'Ahmedabad, Gujarat',
    'Jaipur, Rajasthan',
    'Lucknow, Uttar Pradesh',
    'Kochi, Kerala',
    'Indore, Madhya Pradesh',
    'Coimbatore, Tamil Nadu',
    'Visakhapatnam, Andhra Pradesh',
    'Nagpur, Maharashtra',
    'Patna, Bihar',
    'Bhopal, Madhya Pradesh',
    'Ludhiana, Punjab',
    'Agra, Uttar Pradesh',
  ];

  List<String> filteredCities = [];

  @override
  void initState() {
    super.initState();
    filteredCities = popularCities;
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCities = popularCities;
      } else {
        filteredCities = popularCities
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
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
              onChanged: _filterCities,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for a city...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                // Add clear button when text is entered
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterCities('');
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
                widget.isLoadingLocation ? 'Getting location...' : 'Use Current Location',
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
              onTap: widget.isLoadingLocation ? null : () {
                widget.onCurrentLocationTap();
              },
            ),
          ),
          SizedBox(height: 15),

          // Divider
          Divider(color: Colors.grey.withOpacity(0.3), thickness: 1),
          SizedBox(height: 15),

          // Popular Cities label
          Row(
            children: [
              Icon(Icons.location_city, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Popular Cities',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                '${filteredCities.length} cities',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),

          // Cities list
          Expanded(
            child: filteredCities.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    color: Colors.grey,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No cities found',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
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
                : ListView.builder(
              itemCount: filteredCities.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      filteredCities[index],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 14,
                    ),
                    onTap: () {
                      widget.onLocationSelected(filteredCities[index]);
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