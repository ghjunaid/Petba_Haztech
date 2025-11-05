import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:petba_new/screens/ServiceDetailsScreen.dart';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/models/services.dart';

// Filter models
class FilterGroup {
  final int id;
  final String name;

  FilterGroup({required this.id, required this.name});

  factory FilterGroup.fromJson(Map<String, dynamic> json) {
    return FilterGroup(id: json['id'], name: json['name']);
  }
}

class Filter {
  final int filterId;
  final String name;
  final int filterGroupId;
  bool isSelected;

  Filter({
    required this.filterId,
    required this.name,
    required this.filterGroupId,
    this.isSelected = false,
  });

  factory Filter.fromJson(Map<String, dynamic> json) {
    return Filter(
      filterId: json['filter_id'],
      name: json['name'],
      filterGroupId: json['filter_group_id'],
    );
  }
}

class ServiceListPage extends StatefulWidget {
  final int
  serviceType; // 1: Foster, 2: Groomer, 3: Trainer, 4: Vet, 5: Shelter
  final String customerId;

  const ServiceListPage({
    Key? key,
    required this.serviceType,
    required this.customerId,
  }) : super(key: key);

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  List<ServiceModel> services = [];
  bool isLoading = true;
  String? errorMessage;

  // Filter data
  List<FilterGroup> filterGroups = [];
  List<Filter> filters = [];
  bool isLoadingFilters = false;

  // Location data
  Position? _currentPosition;
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLoadingLocation = false;
  String _locationError = '';

  // Sort data
  int _selectedFilterGroupIndex = 0; // Track which group is selected
  String _selectedSortOption = '';
  bool _isShowingSortOptions = false;
  final List<Map<String, String>> _sortOptions = [
    {'key': 'price_low_to_high', 'label': 'Price -- Low to High'},
    {'key': 'price_high_to_low', 'label': 'Price -- High to Low'},
    {'key': 'rating_high_to_low', 'label': 'Customer Rating'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.serviceType == 1 ||
        widget.serviceType == 2 ||
        widget.serviceType == 3 ||
        widget.serviceType == 4 ||
        widget.serviceType == 5) {
      // Vets, shelters, groomers, trainers, and foster homes need location
      _getCurrentLocation();
    } else {
      fetchServices();
    }
    // Load filters for supported service types
    if (widget.serviceType == 1 ||
        widget.serviceType == 2 ||
        widget.serviceType == 3 ||
        widget.serviceType == 4 ||
        widget.serviceType == 5) {
      _loadFilters();
    }
  }

  String get serviceTitle {
    switch (widget.serviceType) {
      case 1:
        return 'Veterinarians';
      case 2:
        return 'Pet Shelters';
      case 3:
        return 'Pet Groomers';
      case 4:
        return 'Trainers';
      case 5:
        return 'Foster Homes';
      default:
        return 'Services';
    }
  }

  Future<void> _loadFilters() async {
    setState(() {
      isLoadingFilters = true;
    });

    try {
      // Map Flutter serviceType to PHP API type
      int apiType;
      switch (widget.serviceType) {
        case 1: // Vet
          apiType = 1;
          break;
        case 2: // Shelter
          apiType = 2;
          break;
        case 3: // Groomer
          apiType = 3;
          break;
        case 4: // Trainer
          apiType = 4;
          break;
        case 5: // Foster
          apiType = 5;
          break;
        default:
          apiType = widget.serviceType;
      }

      final response = await http.post(
        Uri.parse('$apiurl/api/get-filters'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type': apiType.toString()}),
      );
      print('Filter: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          filterGroups = (data['FilterGroup'] as List)
              .map((json) => FilterGroup.fromJson(json))
              .toList();
          filters = (data['Filters'] as List)
              .map((json) => Filter.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading filters: $e');
    } finally {
      setState(() {
        isLoadingFilters = false;
      });
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Filters',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            for (var filter in filters) {
                              filter.isSelected = false;
                            }
                          });
                        },
                        child: const Text(
                          'Clear Filters',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter content
                Expanded(
                  child: Row(
                    children: [
                      // Left sidebar - Filter Groups
                      Container(
                        width: 120,
                        color: const Color(0xFFF9FAFB),
                        child: ListView.builder(
                          itemCount: filterGroups.length,
                          itemBuilder: (context, index) {
                            final group = filterGroups[index];
                            final groupFilters = filters
                                .where(
                                  (filter) => filter.filterGroupId == group.id,
                                )
                                .toList();
                            final selectedCount = groupFilters
                                .where((filter) => filter.isSelected)
                                .length;
                            final isSelected =
                                _selectedFilterGroupIndex == index;

                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                title: Text(
                                  group.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : Colors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                trailing: selectedCount > 0
                                    ? Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          selectedCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  setModalState(() {
                                    _selectedFilterGroupIndex = index;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      // Right content - Filter options for selected group only
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          child: _selectedFilterGroupIndex < filterGroups.length
                              ? ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    // Selected group title
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        filterGroups[_selectedFilterGroupIndex]
                                            .name,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    // Filters for selected group only
                                    ...filters
                                        .where(
                                          (filter) =>
                                              filter.filterGroupId ==
                                              filterGroups[_selectedFilterGroupIndex]
                                                  .id,
                                        )
                                        .map(
                                          (filter) => Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: filter.isSelected,
                                                  onChanged: (value) {
                                                    setModalState(() {
                                                      filter.isSelected =
                                                          value ?? false;
                                                    });
                                                  },
                                                  activeColor: const Color(
                                                    0xFF2563EB,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    filter.name,
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                )
                              : const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${services.length} products found',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              filters = filters;
                            });
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.black),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Sort By',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sort options
            ..._sortOptions
                .map(
                  (option) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSortOption = option['key']!;
                      });
                      Navigator.pop(context);
                      _applySorting();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: option['key']!,
                            groupValue: _selectedSortOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedSortOption = value!;
                              });
                              Navigator.pop(context);
                              _applySorting();
                            },
                            activeColor: const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            option['label']!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _applySorting() {
    if (_selectedSortOption.isEmpty) return;

    setState(() {
      switch (_selectedSortOption) {
        case 'price_low_to_high':
          services.sort((a, b) {
            double priceA = _extractPrice(a.price);
            double priceB = _extractPrice(b.price);
            return priceA.compareTo(priceB);
          });
          break;
        case 'price_high_to_low':
          services.sort((a, b) {
            double priceA = _extractPrice(a.price);
            double priceB = _extractPrice(b.price);
            return priceB.compareTo(priceA);
          });
          break;
        case 'rating_high_to_low':
          services.sort((a, b) => b.rating.compareTo(a.rating));
          break;
      }
    });
  }

  double _extractPrice(String priceString) {
    // Extract numeric value from price string (e.g., "₹500" -> 500.0)
    RegExp regExp = RegExp(r'[\d.]+');
    Match? match = regExp.firstMatch(priceString);
    return match != null ? double.tryParse(match.group(0)!) ?? 0.0 : 0.0;
  }

  void _applyFilters() {
    final selectedFilters = filters
        .where((filter) => filter.isSelected)
        .toList();

    if (selectedFilters.isEmpty) {
      // No filters selected, fetch all services
      fetchServices();
      _showMessage('Filters cleared', isError: false);
      return;
    }

    // Fetch services with applied filters
    fetchServices();
    _showMessage('${selectedFilters.length} filter(s) applied', isError: false);
  }

  int get _appliedFiltersCount {
    return filters.where((filter) => filter.isSelected).length;
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError =
              'Location services are disabled. Please enable them in settings.';
        });
        _showMessage(_locationError, isError: true);
        return;
      }

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

      setState(() {
        _currentPosition = position;
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationError = '';
      });

      fetchServices();
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
      _showMessage(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> fetchServices() async {
    // Check if location is required but not available
    if ((widget.serviceType == 1 ||
            widget.serviceType == 2 ||
            widget.serviceType == 3 ||
            widget.serviceType == 4 ||
            widget.serviceType == 5) &&
        (_latitude == 0.0 || _longitude == 0.0)) {
      setState(() {
        errorMessage = 'Location is required to find services nearby';
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      String apiEndpoint;
      Map<String, dynamic> requestBody;

      switch (widget.serviceType) {
        case 1: // Vet
          apiEndpoint = '$apiurl/api/listVets';
          requestBody = {"c_id": int.parse(widget.customerId)};
          // Add selected filters for vets
          final selectedFilterIds = filters
              .where((filter) => filter.isSelected)
              .map((filter) => filter.filterId)
              .toList();
          if (selectedFilterIds.isNotEmpty) {
            requestBody["filter"] = selectedFilterIds;
          }
          break;

        case 2: // Shelter
          apiEndpoint = '$apiurl/api/shelterlist';
          requestBody = {
            "c_id": int.parse(widget.customerId),
            "tab": "a",
            "latitude": _latitude != 0.0 ? _latitude : 15.2761,
            "longitude": _longitude != 0.0 ? _longitude : 73.9192,
          };
          break;

        case 3: // Groomer
          apiEndpoint = '$apiurl/api/list-grooming';
          requestBody = {
            "c_id": int.parse(widget.customerId),
            "latitude": _latitude,
            "longitude": _longitude,
          };
          break;

        case 4: // Trainer
          apiEndpoint = '$apiurl/api/list-trainer';
          requestBody = {
            "c_id": int.parse(widget.customerId),
            "latitude": _latitude,
            "longitude": _longitude,
          };
          // Add selected filters for trainers (if your trainer API supports filters)
          final selectedFilterIds = filters
              .where((filter) => filter.isSelected)
              .map((filter) => filter.filterId)
              .toList();
          if (selectedFilterIds.isNotEmpty) {
            requestBody["filter"] = selectedFilterIds;
          }
          break;

        case 5: // Foster
          apiEndpoint = '$apiurl/api/fosterlist';
          requestBody = {
            "c_id": int.parse(widget.customerId),
            "latitude": _latitude,
            "longitude": _longitude,
          };
          // Add selected filters for foster
          final selectedFilterIds = filters
              .where((filter) => filter.isSelected)
              .map((filter) => filter.filterId)
              .toList();
          if (selectedFilterIds.isNotEmpty) {
            requestBody["filter"] = selectedFilterIds;
          }
          break;

        default:
          throw Exception('Invalid service type');
      }

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      print('Service screen: $requestBody');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        List<dynamic> serviceList;
        if (widget.serviceType == 1) {
          // Vets
          serviceList = data['listvets'] ?? [];
        } else if (widget.serviceType == 2) {
          // Shelters
          serviceList = data['shelterlist'] ?? [];
        } else if (widget.serviceType == 3) {
          // Groomers
          serviceList =
              data['listgrooming'] ?? data['groomers'] ?? data['data'] ?? [];
        } else if (widget.serviceType == 4) {
          // Trainers
          serviceList = data['listtrainer'] ?? [];
        } else if (widget.serviceType == 5) {
          // Foster homes
          serviceList = data['fosterlist'] ?? [];
        } else {
          serviceList = [];
        }

        setState(() {
          services = serviceList
              .map((json) => ServiceModel.fromJson(json, widget.serviceType))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load ${serviceTitle.toLowerCase()}: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF60A5FA)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  serviceTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLoading || _isLoadingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF60A5FA),
                      ),
                    ),
                  ),
                if (!isLoading && !_isLoadingLocation && errorMessage == null)
                  IconButton(
                    onPressed: () {
                      if (widget.serviceType == 1 ||
                          widget.serviceType == 5 ||
                          (_latitude != 0.0 && _longitude != 0.0)) {
                        fetchServices();
                      } else {
                        _getCurrentLocation();
                      }
                    },
                    icon: const Icon(Icons.refresh, color: Color(0xFF60A5FA)),
                  ),
              ],
            ),
          ),

          // Filter and Sort Buttons
          if (widget.serviceType == 1 ||
              widget.serviceType == 2 ||
              widget.serviceType == 3 ||
              widget.serviceType == 4 ||
              widget.serviceType == 5)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Sort Button
                  Expanded(
                    child: GestureDetector(
                      onTap: _showSortOptions,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF9CA3AF)),
                          borderRadius: BorderRadius.circular(8),
                          color: _selectedSortOption.isNotEmpty
                              ? const Color(0xFF60A5FA).withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sort,
                              color: _selectedSortOption.isNotEmpty
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sort',
                              style: TextStyle(
                                color: _selectedSortOption.isNotEmpty
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 16,
                                fontWeight: _selectedSortOption.isNotEmpty
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Filter Button
                  Expanded(
                    child: GestureDetector(
                      onTap: isLoadingFilters ? null : _showFilterOptions,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _appliedFiltersCount > 0
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF9CA3AF),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: _appliedFiltersCount > 0
                              ? const Color(0xFF60A5FA).withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoadingFilters)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF60A5FA),
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.filter_list,
                                color: _appliedFiltersCount > 0
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              isLoadingFilters
                                  ? 'Loading...'
                                  : _appliedFiltersCount > 0
                                  ? 'Filter (${_appliedFiltersCount})'
                                  : 'Filter',
                              style: TextStyle(
                                color: _appliedFiltersCount > 0
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 16,
                                fontWeight: _appliedFiltersCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Location Info (for services that need location)
          if ((widget.serviceType == 2 ||
                  widget.serviceType == 3 ||
                  widget.serviceType == 4) &&
              (_isLoadingLocation || _locationError.isNotEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _locationError.isNotEmpty
                      ? const Color(0xFFEF4444).withOpacity(0.1)
                      : const Color(0xFF60A5FA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _locationError.isNotEmpty
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF60A5FA),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _locationError.isNotEmpty
                          ? Icons.error_outline
                          : Icons.location_on,
                      color: _locationError.isNotEmpty
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF60A5FA),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLoadingLocation
                            ? 'Getting your location...'
                            : _locationError,
                        style: TextStyle(
                          color: _locationError.isNotEmpty
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF60A5FA),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_locationError.isNotEmpty)
                      TextButton(
                        onPressed: _getCurrentLocation,
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: Color(0xFFEF4444)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
            ),
            SizedBox(height: 16),
            Text(
              'Getting your location...',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (isLoading &&
        (widget.serviceType == 1 ||
            widget.serviceType == 5 ||
            _latitude != 0.0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading ${serviceTitle.toLowerCase()}...',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (widget.serviceType == 1 ||
                    widget.serviceType == 5 ||
                    (_latitude != 0.0 && _longitude != 0.0)) {
                  fetchServices();
                } else {
                  _getCurrentLocation();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60A5FA),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (services.isEmpty &&
        (widget.serviceType == 1 ||
            widget.serviceType == 5 ||
            _latitude != 0.0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getServiceIcon(), color: const Color(0xFF9CA3AF), size: 48),
            const SizedBox(height: 16),
            Text(
              'No ${serviceTitle.toLowerCase()} found',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
            ),
          ],
        ),
      );
    }

    if ((widget.serviceType == 1 ||
            widget.serviceType == 3 ||
            widget.serviceType == 4) &&
        _latitude == 0.0 &&
        !_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, color: Color(0xFF9CA3AF), size: 48),
            SizedBox(height: 16),
            Text(
              'Location required to find services',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ServiceCard(
            service: service,
            serviceType: widget.serviceType,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailsPage(
                    service: service,
                    serviceType: widget.serviceType,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getServiceIcon() {
    switch (widget.serviceType) {
      case 1:
        return Icons.medical_services;
      case 2:
        return Icons.home_outlined;
      case 3:
        return Icons.content_cut;
      case 4:
        return Icons.fitness_center;
      case 5:
        return Icons.home_outlined;
      default:
        return Icons.business;
    }
  }
}

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final int serviceType;
  final VoidCallback onTap;

  const ServiceCard({
    Key? key,
    required this.service,
    required this.serviceType,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF374151),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Service Image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF4B5563),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  service.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      _getServiceIcon(),
                      color: const Color(0xFF60A5FA),
                      size: 32,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Service Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name with Verification (for Foster)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (serviceType == 5 && service.isVerified)
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Provider/Phone
                  Text(
                    serviceType == 5
                        ? 'Provider: ${service.provider}'
                        : 'Phone:',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating, Time, or Service Type
                  if (serviceType == 5) ...[
                    // Foster - Show service type
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: service.isPaid
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service.isPaid ? 'Paid Service' : 'Free Service',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Groomer/Trainer - Show rating and time
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFBBF24),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.rating.toString(),
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            service.time,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Price and Location
                  Row(
                    children: [
                      Text(
                        service.price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF9CA3AF),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          serviceType == 5
                              ? service.address?.split('\n').first.trim() ??
                                    service.location
                              : service.location,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow Icon
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 24),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon() {
    switch (serviceType) {
      case 1:
        return Icons.how_to_vote;
      case 2:
        return Icons.home;
      case 3:
        return Icons.content_cut;
      case 4:
        return Icons.emoji_events;
      case 5:
        return Icons.house_siding;
      default:
        return Icons.business;
    }
  }
}
