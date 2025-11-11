import 'package:flutter/material.dart';
import 'package:petba_new/screens/BlogScreen.dart';
import 'package:petba_new/screens/Page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/providers/LocationProvider.dart';
import 'package:petba_new/screens/PetDetailPage.dart';
import 'package:petba_new/screens/RescueScreen.dart';
import 'package:petba_new/screens/ServicesScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cart_notifier.dart';
import 'AddAdoption.dart';
import 'MyPets.dart';
import 'ProductDetailsScreen.dart';
import 'ProductsScreen.dart';
import 'package:petba_new/screens/AdoptionScreen.dart';
import 'package:petba_new/screens/Profile.dart';
import 'package:petba_new/screens/AddPets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/providers/Snap.dart';
import 'package:petba_new/screens/WishListScreen.dart';
import 'package:petba_new/services/user_data_service.dart';
//import 'package:petba_new/Chat/Pages/LoginScreen.dart';
import 'package:petba_new/screens/CartPage.dart';
import 'package:petba_new/screens/OrderScreen.dart';
import 'package:petba_new/models/adoption.dart';
import 'package:petba_new/models/dashboard.dart';
import 'package:petba_new/chat/Pages/LoginScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:petba_new/widgets/rescue_details_modal.dart';

import 'RescuePet.dart';
import 'SignIn.dart';
import 'SpecialProducts.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedLocation = 'select your location';

  // API data for dashboard
  List<AdoptionPet> _adoptionPets = [];
  List<DashboardProduct> _latestProducts = [];
  List<DashboardProduct> _featuredProducts = [];
  List<DashboardProduct> _specialProducts = [];
  List<BannerItem> _banners = [];
  bool _isLoadingDashboard = true;
  String _dashboardError = '';
  String? customerId;
  String? email;
  String? token;
  double? currentLatitude;
  double? currentLongitude;
  List<RescuePet> _rescuePets = [];
  double _rescueRadiusKm = 50.0; // radius for nearby rescues

  final CartNotifier _cartNotifier = CartNotifier();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    fetchCartItemCount();
    _cartNotifier.addListener(_onCartChanged);
    _initLocationAndNearbyRescues();
  }

  @override
  void dispose() {
    _cartNotifier.removeListener(_onCartChanged);
    super.dispose();
  }

  // ADD this method to _ProductsPageState:
  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> fetchCartItemCount() async {
    try {
      final authData = await UserDataService.getAuthData();
      if (authData == null) {
        _cartNotifier.updateCartCount(0);
        return;
      }

      final response = await http.post(
        Uri.parse('$apiurl/api/cartProducts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'userData': {
            'customer_id': authData['customer_id'].toString(),
            'email': authData['email'],
            'token': authData['token'],
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['cartProducts'] != null) {
          int totalQuantity = 0;
          for (var item in data['cartProducts']) {
            totalQuantity += int.parse(item['cart_qty']?.toString() ?? '1');
          }
          _cartNotifier.updateCartCount(totalQuantity);
        } else {
          _cartNotifier.updateCartCount(0);
        }
      }
    } catch (e) {
      _cartNotifier.updateCartCount(0);
      print('Error fetching cart count: $e');
    }
  }

  Future<void> _addToCart(DashboardProduct product) async {
    try {
      final authData = await UserDataService.getAuthData();
      if (authData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please login to add items to cart'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$apiurl/api/addcart'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'customer_id': authData['customer_id'].toString(),
          'product_id': product.productId.toString(),
          'quantity': 1,
        }),
      );

      if (response.statusCode == 200) {
        // Refresh cart count after adding item
        await fetchCartItemCount();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item to cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _refreshCartOnReturn() {
    fetchCartItemCount();
  }

  //API
  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        _isLoadingDashboard = true;
        _dashboardError = '';
      });

      final cityId = await UserDataService.getCityId();
      print('Retrieved cityId: $cityId');

      final customerIdResult = await UserDataService.getCustomerId();
      customerId = customerIdResult?.toString();
      final emailResult = await UserDataService.getUserEmail();
      email = emailResult?.toString();
      print('Email: $email');

      final tokenResult = await UserDataService.getUserToken();
      token = tokenResult?.toString(); // FIX: Actually assign the token
      print('Token: $token');
      final requestBody = await UserDataService.getHomePageData();

      if (requestBody == null) {
        setState(() {
          _dashboardError = 'User data not found. Please login again.';
          _isLoadingDashboard = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('$apiurl/api/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("FULL DASHBOARD RESPONSE: ${jsonEncode(data)}");
        print("ADOPTION: ${jsonEncode(data['adoption'])}");
        print("LATEST: ${jsonEncode(data['latest'])}");
        print("SPECIAL: ${jsonEncode(data['special'])}");
        print("FEATURED: ${jsonEncode(data['featured'])}");
        print("RESCUE: ${jsonEncode(data['rescueListhome'])}");

        // adoption (original is already a List)
        final adoptionData = data['adoption']?['original'] ?? [];
        final adoptionPets = (adoptionData as List)
            .map((item) => AdoptionPet.fromJson(item))
            .toList();

        // Filter out user's own pets from adoption list
        final filteredAdoptionPets = adoptionPets
            .where((pet) => pet.cId.toString() != customerId)
            .toList();

        // latest products (inside latestproduct list)
        final latestProductsData =
            data['latest']?['original']?['latestproduct'] ?? [];
        final latestProducts = (latestProductsData as List)
            .map((item) => DashboardProduct.fromJson(item))
            .toList();

        // featured products (inside featuredproducts list)
        final featuredProductsData =
            data['featured']?['original']?['featuredproducts'] ?? [];
        final featuredProducts = (featuredProductsData as List)
            .map((item) => DashboardProduct.fromJson(item))
            .toList();

        // special products (inside discountedproducts list)
        final specialProductsData =
            data['special']?['original']?['discountedproducts'] ?? [];
        final specialProducts = (specialProductsData as List)
            .map((item) => DashboardProduct.fromJson(item))
            .toList();

        // banners (already list at top level)
        final bannerData = data['banner'] ?? [];
        final banners = (bannerData as List)
            .map((item) => BannerItem.fromJson(item))
            .toList();

        // rescue pets (supports original as List or as Map with data key)
        final rescueOriginal = data['rescueListhome']?['original'];
        final dynamic rescueData = (rescueOriginal is List)
            ? rescueOriginal
            : (rescueOriginal is Map && rescueOriginal['data'] is List)
            ? rescueOriginal['data']
            : [];
        final rescuePets = (rescueData as List)
            .map((item) => RescuePet.fromJson(item))
            .toList();

        setState(() {
          _adoptionPets = filteredAdoptionPets;
          _latestProducts = latestProducts;
          _featuredProducts = featuredProducts;
          _specialProducts = specialProducts;
          _banners = banners;
          _isLoadingDashboard = false;
          _rescuePets = rescuePets;
        });
        // Refresh rescue pets using user's current location (non-blocking)
        _fetchNearbyRescues();
      } else if (response.statusCode == 401) {
        setState(() {
          _dashboardError = 'Session expired. Please login again.';
          _isLoadingDashboard = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _dashboardError = 'Access denied. Please check your permissions.';
          _isLoadingDashboard = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _dashboardError = 'Dashboard endpoint not found.';
          _isLoadingDashboard = false;
        });
      } else if (response.statusCode >= 500) {
        setState(() {
          _dashboardError = 'Server error. Please try again later.';
          _isLoadingDashboard = false;
        });
      } else {
        setState(() {
          _dashboardError =
              'Failed to load dashboard data (Status: ${response.statusCode})';
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      setState(() {
        _dashboardError = 'Error: ${e.toString()}';
        _isLoadingDashboard = false;
      });
    }
  }

  Future<void> _initLocationAndNearbyRescues() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        currentLatitude = pos.latitude;
        currentLongitude = pos.longitude;
      });
      await _fetchNearbyRescues();
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  Future<void> _fetchNearbyRescues() async {
    try {
      if (currentLatitude == null || currentLongitude == null) return;

      final requestBody = {
        'c_id': null,
        'latitude': currentLatitude,
        'longitude': currentLongitude,
        'lastPet': null,
        'filter': {'condition': [], 'animalType': [], 'gender': [], 'city': []},
        'sort': '1',
      };

      final response = await http.post(
        Uri.parse('$apiurl/api/rescueList'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> items = data['rescueList'] ?? [];

        // Compute distances client-side and filter by radius
        final List<Map<String, dynamic>> enriched = items
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
        for (final item in enriched) {
          try {
            final petLat = double.tryParse(item['latitude']?.toString() ?? '');
            final petLng = double.tryParse(item['longitude']?.toString() ?? '');
            if (petLat != null && petLng != null) {
              final meters = Geolocator.distanceBetween(
                currentLatitude!,
                currentLongitude!,
                petLat,
                petLng,
              );
              item['Distance'] = meters / 1000.0;
            }
          } catch (_) {}
        }

        final nearby = enriched.where((m) {
          final d = double.tryParse(m['Distance']?.toString() ?? '');
          return d == null ? true : d <= _rescueRadiusKm;
        }).toList();

        final rescuePets = nearby.map((m) => RescuePet.fromJson(m)).toList();
        if (mounted) {
          setState(() {
            _rescuePets = rescuePets;
          });
        }
      }
    } catch (e) {
      print('Error fetching nearby rescues: $e');
    }
  }

  String _calculateAge(String dob) {
    try {
      final DateTime birthDate = DateTime.parse(dob);
      final DateTime now = DateTime.now();
      final int years = now.year - birthDate.year;
      final int months = now.month - birthDate.month;

      if (years > 0) {
        return '$years year${years > 1 ? 's' : ''} old';
      } else if (months > 0) {
        return '$months month${months > 1 ? 's' : ''} old';
      } else {
        return 'Less than 1 month old';
      }
    } catch (e) {
      return 'Age unknown';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.white30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('images/Logo.png', width: 90),
                  Text(
                    'PETBA',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.home, color: AppColors.white),
              title: Text(
                'Home',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.firstAid, color: AppColors.white),
              title: Text(
                'Rescue',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RescuePage(customerId: customerId!),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.add, color: AppColors.white),
              title: Text(
                'Add Rescue',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddRescuePage(customerId: customerId!),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.paw, color: AppColors.white),
              title: Text(
                'Adoption',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdoptionPage()),
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.blog, color: AppColors.white),
              title: Text(
                'My Pets',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToMyPets();
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.blog, color: AppColors.white),
              title: Text(
                'Blog',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BlogListPage()),
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.store, color: AppColors.white),
              title: Text(
                'Store',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Add your store navigation here
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.spa, color: AppColors.white),
              title: Text(
                'Groomers',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceListPage(
                      serviceType: 3,
                      customerId: customerId!,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(
                FontAwesomeIcons.clinicMedical,
                color: AppColors.white,
              ),
              title: Text(
                'Veterinarian',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceListPage(
                      serviceType: 1,
                      customerId: customerId!,
                    ),
                  ),
                );
              },
            ),
            Divider(
              thickness: 0.5,
              color: AppColors.grey.withOpacity(0.40),
              indent: 10.0,
              endIndent: 10.0,
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(
                FontAwesomeIcons.solidHeart,
                color: AppColors.white,
              ),
              title: Text(
                'Wishlist',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WishlistPage()),
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.boxOpen, color: AppColors.white),
              title: Text(
                'Orders',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderHistoryPage(customerId: "48"),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.userAlt, color: AppColors.white),
              title: Text(
                'Profile',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 20.0),
              leading: Icon(FontAwesomeIcons.powerOff, color: AppColors.white),
              title: Text(
                'Log Out',
                style: TextStyle(fontSize: 18, color: AppColors.white),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: const Text(
                        "Logout",
                        style: TextStyle(color: AppColors.white),
                      ),
                      content: const Text(
                        "Are you sure you want to logout?",
                        style: TextStyle(color: AppColors.white),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: AppColors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.clear();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Logout",
                            style: TextStyle(color: AppColors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                '© 2025 Haztech',
                style: TextStyle(fontSize: 10, color: AppColors.grey),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.blue),
            onPressed: () {
              // Open the drawer instead of navigating to a new page
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/Logo.png', width: 20, height: 20),
            SizedBox(width: 8),
            Text(
              'Petba',
              style: TextStyle(color: AppColors.white, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_outlined, color: AppColors.blue),
            onPressed: () {
              // Add search functionality
            },
          ),
          SizedBox(),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: AppColors.blue),
            onPressed: () async {
              // Get user data from UserDataService
              final userData = await UserDataService.getUserData();
              final cityId = await UserDataService.getCityId();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Loginscreen(
                    userId: userData?['customer_id'],
                    userToken: userData?['token'],
                    userEmail: userData?['email'],
                    firstName: userData?['firstname'],
                    lastName: userData?['lastname'],
                    telephone: userData?['telephone'],
                    cityId: cityId,
                    userLocation: selectedLocation != 'select your location'
                        ? selectedLocation
                        : null,
                  ),
                ),
              );
            },
          ),
          SizedBox(),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: AppColors.blue),
            onPressed: () {
              // Add notifications functionality
            },
          ),
          SizedBox(),
          // IconButton(
          //   icon: Icon(Icons.shopping_cart_outlined, color: AppColors.blue),
          //   onPressed: () {
          //     _navigateToCart();
          //   },
          // ),
          _buildCartIcon(),
          SizedBox(),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location selector
            LocationPickerWidget(
              currentLocation: selectedLocation,
              onLocationSelected: (String location) {
                setState(() {
                  selectedLocation = location;
                });
              },
            ),
            SizedBox(height: 20),

            // Banner section (using API data)
            _buildBannerSection(),
            SizedBox(height: 20),

            // Services section
            Text(
              'Services',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Take A Snap button
            Center(
              child: ElevatedButton(
                onPressed: () => _navigateToPage(context, 'Take A Snap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Take A Snap',
                  style: TextStyle(color: AppColors.white, fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 30),

            // Service icons row
            Container(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildServiceIcon(
                    context,
                    Icons.medical_information,
                    'Vets',
                    AppColors.green,
                  ),
                  SizedBox(width: 10),
                  _buildServiceIcon(
                    context,
                    Icons.home,
                    'Shelters',
                    AppColors.blue,
                  ),
                  SizedBox(width: 10),
                  _buildServiceIcon(
                    context,
                    Icons.content_cut,
                    'Groomers',
                    Colors.pink,
                  ),
                  SizedBox(width: 10),
                  _buildServiceIcon(
                    context,
                    Icons.emoji_events,
                    'Trainers',
                    Colors.orange,
                  ),
                  SizedBox(width: 10),
                  _buildServiceIcon(
                    context,
                    Icons.house_siding,
                    'Fosters',
                    AppColors.red,
                  ),
                  SizedBox(width: 10),
                  _buildServiceIcon(
                    context,
                    Icons.volunteer_activism,
                    'Rescue',
                    AppColors.red,
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Pets for Adoption section (using API data)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pets For Adoption',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Row(
                  children: [
                    if (_isLoadingDashboard)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: AppColors.blue,
                          strokeWidth: 2,
                        ),
                      ),
                    if (_dashboardError.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: AppColors.blue,
                          size: 20,
                        ),
                        onPressed: _fetchDashboardData,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdoptionPage(),
                          ),
                        );
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(color: AppColors.blue, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),

            // Adoption pets list (using API data)
            Container(height: 200, child: _buildAdoptionPetsList()),
            SizedBox(height: 20),

            // Rescue Pets section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rescue Pets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RescuePage(customerId: customerId!),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(color: AppColors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              height: 180,
              child: _rescuePets.isNotEmpty
                  ? _buildRescuePetsList()
                  : Center(
                      child: Text(
                        "no pets for rescue in this city",
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 20),

            // Products section
            Text(
              'Products',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Featured Products Section (using API data)
            if (_featuredProducts.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductsPage()),
                      );
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(color: AppColors.blue, fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(height: 200, child: _buildFeaturedProductsList()),
              SizedBox(height: 20),
            ],

            // Latest Products Section (using API data)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductsPage()),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(color: AppColors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(height: 200, child: _buildLatestProductsList()),
            SizedBox(height: 20),

            // Special Offers section (using API data)
            if (_specialProducts.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Special Offers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpecialProductsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(color: AppColors.blue, fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(height: 200, child: _buildSpecialProductsList()),
              SizedBox(height: 20),
            ],

            // Discounts section (fallback when no special products)
            if (_specialProducts.isEmpty) ...[
              Text(
                'Discounts For You',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Special Offers Coming Soon!',
                    style: TextStyle(color: AppColors.grey, fontSize: 16),
                  ),
                ),
              ),
            ],

            // Add some extra space at the bottom
            SizedBox(height: 100),
          ],
        ),
      ),
      // Fixed floating action button at bottom right
      floatingActionButton: Container(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () => _showOptionsMenu(context),
          backgroundColor: AppColors.primaryColor,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.grey, width: 2),
          ),
          child: Icon(Icons.add, color: AppColors.grey, size: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // New method to build banner section with API data
  Widget _buildBannerSection() {
    if (_isLoadingDashboard) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    return Container(
      height: 200,
      child: PageView.builder(
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                '$apiurl/${banner.imgLink}',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.pets, size: 50, color: AppColors.white),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.grey,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.blue,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Method to build adoption pets list with API data
  Widget _buildAdoptionPetsList() {
    if (_isLoadingDashboard) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.blue),
            SizedBox(height: 8),
            Text('Loading pets...', style: TextStyle(color: AppColors.grey)),
          ],
        ),
      );
    }

    if (_dashboardError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.red, size: 40),
            SizedBox(height: 8),
            Text(
              _dashboardError,
              style: TextStyle(color: AppColors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchDashboardData,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
              child: Text('Retry', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 4),
      itemCount: _adoptionPets.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PetDetailPage(pet: _adoptionPets[index]),
              ),
            );
          },
          child: _buildApiAdoptionPetCard(_adoptionPets[index]),
        );
      },
    );
  }

  // Method to build latest products list with API data
  Widget _buildLatestProductsList() {
    if (_isLoadingDashboard) {
      return Center(child: CircularProgressIndicator(color: AppColors.blue));
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 4),
      itemCount: _latestProducts.length,
      itemBuilder: (context, index) {
        return _buildDashboardProductCard(_latestProducts[index]);
      },
    );
  }

  // Method to build featured products list with API data
  Widget _buildFeaturedProductsList() {
    if (_isLoadingDashboard) {
      return Center(child: CircularProgressIndicator(color: AppColors.blue));
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 4),
      itemCount: _featuredProducts.length,
      itemBuilder: (context, index) {
        return _buildDashboardProductCard(_featuredProducts[index]);
      },
    );
  }

  // Method to build special products list with API data
  Widget _buildSpecialProductsList() {
    if (_specialProducts.isEmpty) {
      return Container();
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 4),
      itemCount: _specialProducts.length,
      itemBuilder: (context, index) {
        return _buildDashboardProductCard(
          _specialProducts[index],
          isSpecial: true,
        );
      },
    );
  }

  // Updated method to build adoption pet card with API data
  Widget _buildApiAdoptionPetCard(AdoptionPet pet) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 120,
              width: double.infinity,
              child: Stack(
                children: [
                  pet.img1.isNotEmpty
                      ? Image.network(
                          '$apiurl/${pet.img1}',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.grey,
                              child: Icon(
                                Icons.pets,
                                size: 40,
                                color: AppColors.grey,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.grey,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.blue,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.grey,
                          child: Icon(
                            Icons.pets,
                            size: 40,
                            color: AppColors.grey,
                          ),
                        ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  _calculateAge(pet.dob),
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      pet.gender == 1 ? Icons.male : Icons.female,
                      size: 12,
                      color: pet.gender == 1 ? AppColors.blue : Colors.pink,
                    ),
                    SizedBox(width: 2),
                    Text(
                      pet.gender == 1 ? 'Male' : 'Female',
                      style: TextStyle(fontSize: 10, color: AppColors.grey),
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

  // Method to build dashboard product card with API data
  Widget _buildDashboardProductCard(
    DashboardProduct product, {
    bool isSpecial = false,
  }) {
    final double price = double.tryParse(product.price) ?? 0;
    final double? specialPrice = product.specialprice != null
        ? double.tryParse(product.specialprice!)
        : null;
    final double displayPrice = specialPrice ?? price;
    final bool hasDiscount = specialPrice != null && specialPrice < price;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productId: product.productId,
              productName: product.name,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 100,
                width: double.infinity,
                child: Stack(
                  children: [
                    Image.network(
                      '$producturl/${product.image}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.grey,
                          child: Icon(
                            Icons.shopping_bag,
                            size: 30,
                            color: AppColors.grey,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.grey,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.blue,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SALE',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '₹${displayPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blue,
                                ),
                              ),
                            ),
                            if (hasDiscount) ...[
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '₹${price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Brand: ${product.brand}',
                          style: TextStyle(fontSize: 10, color: AppColors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Stock: ${product.quantity}',
                          style: TextStyle(
                            fontSize: 10,
                            color: product.quantity > 10
                                ? AppColors.green
                                : AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRescuePetCard(String status, String gender, String image) {
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 100,
              width: double.infinity,
              child: Stack(
                children: [
                  Image.asset(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.grey,
                        child: Icon(
                          Icons.pets,
                          size: 30,
                          color: AppColors.grey,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.male, size: 12, color: AppColors.blue),
                    SizedBox(width: 2),
                    Text(
                      gender,
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
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

  Widget _buildServiceIcon(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _navigateToPage(context, label),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(height: 8),
          Container(
            width: 70,
            child: Text(
              label,
              style: TextStyle(color: AppColors.white, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Method to build API rescue pets list
  Widget _buildRescuePetsList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 4),
      itemCount: _rescuePets.length,
      itemBuilder: (context, index) {
        final pet = _rescuePets[index];
        return GestureDetector(
          onTap: () {
            final rescueMap = <String, dynamic>{
              'img1': pet.img1,
              'address': pet.address,
              'ConditionType': pet.conditionType,
              'conditionLevel_id': pet.conditionStatus,
              'status': pet.conditionStatus,
              'city': '',
              'Distance': pet.distance,
              'description': '',
              'apiurl': apiurl,
            };
            showRescueDetailsModal(context, rescueMap);
          },
          child: _buildApiRescuePetCard(pet),
        );
      },
    );
  }

  Widget _buildCartIcon() {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined, color: Colors.blue),
          onPressed: () {
            _navigateToCart();
          },
        ),
        if (_cartNotifier.cartCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _cartNotifier.cartCount > 99
                    ? '99+'
                    : _cartNotifier.cartCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildApiRescuePetCard(RescuePet pet) {
    String getStatusText(int status) {
      switch (status) {
        case 1:
          return 'Active';
        case 2:
          return 'In Progress';
        case 3:
          return 'Rescued';
        default:
          return 'Unknown';
      }
    }

    Color getStatusColor(int status) {
      switch (status) {
        case 1:
          return AppColors.red;
        case 2:
          return Colors.orange;
        case 3:
          return AppColors.green;
        default:
          return AppColors.grey;
      }
    }

    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 100,
              width: double.infinity,
              child: Stack(
                children: [
                  pet.img1.isNotEmpty
                      ? Image.network(
                          _constructImageUrl(pet.img1),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.grey,
                              child: Icon(
                                Icons.pets,
                                size: 30,
                                color: AppColors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.grey,
                          child: Icon(
                            Icons.pets,
                            size: 30,
                            color: AppColors.grey,
                          ),
                        ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: getStatusColor(pet.conditionStatus),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        getStatusText(pet.conditionStatus),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.conditionType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  pet.address,
                  style: TextStyle(fontSize: 10, color: AppColors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      pet.gender == 1 ? Icons.male : Icons.female,
                      size: 12,
                      color: pet.gender == 1 ? AppColors.blue : Colors.pink,
                    ),
                    SizedBox(width: 2),
                    Text(
                      pet.gender == 1 ? 'Male' : 'Female',
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                    if (pet.distance > 0) ...[
                      Spacer(),
                      Text(
                        '${pet.distance.toStringAsFixed(1)} km',
                        style: TextStyle(fontSize: 10, color: AppColors.grey),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Choose Action',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Add Rescue option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: AppColors.blue),
                ),
                title: Text(
                  'Add Rescue',
                  style: TextStyle(color: AppColors.white, fontSize: 16),
                ),
                subtitle: Text(
                  'Add pet for rescue',
                  style: TextStyle(color: AppColors.grey, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddRescuePage(customerId: customerId!),
                    ),
                  );
                },
              ),

              // Add Adoption option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: AppColors.blue),
                ),
                title: Text(
                  'Add Adoption',
                  style: TextStyle(color: AppColors.white, fontSize: 16),
                ),
                subtitle: Text(
                  'Add pet for Adoption',
                  style: TextStyle(color: AppColors.grey, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddAdoption();
                },
              ),

              // Add Pet option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: AppColors.blue),
                ),
                title: Text(
                  'Add Pet',
                  style: TextStyle(color: AppColors.white, fontSize: 16),
                ),
                subtitle: Text(
                  'Add pet',
                  style: TextStyle(color: AppColors.grey, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPetPage(customerId: customerId!),
                    ),
                  );
                },
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _navigateToAddAdoption() {
    // Validate required parameters
    if (customerId == null || customerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer ID not found. Please login again.'),
          backgroundColor: AppColors.red,
          action: SnackBarAction(
            label: 'Login',
            onPressed: () {
              // Navigate to login page
              // Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ),
      );
      return;
    }

    if (email == null || email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email not found. Please login again.'),
          backgroundColor: AppColors.red,
          action: SnackBarAction(
            label: 'Login',
            onPressed: () {
              // Navigate to login page
              // Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ),
      );
      return;
    }

    // Navigate with validated parameters
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAdoptionPage(
          customerId: customerId!, // Now safe to use ! after validation
          email: email!, // Now safe to use ! after validation
          token: token, // This can be null as per your constructor
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, String pageName) {
    Widget destinationPage;

    switch (pageName.toLowerCase()) {
      case 'vets':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceListPage(serviceType: 1, customerId: customerId!),
          ),
        );
        return;

      case 'shelters':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceListPage(serviceType: 2, customerId: customerId!),
          ),
        );
        return;

      case 'groomers':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceListPage(serviceType: 3, customerId: customerId!),
          ),
        );
        return;
      case 'trainers':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceListPage(serviceType: 4, customerId: customerId!),
          ),
        );
        return;

      case 'fosters':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceListPage(serviceType: 5, customerId: customerId!),
          ),
        );
        return;
      case 'take a snap':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SnapPage()),
        );
        return;
      case 'rescue':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RescuePage(customerId: customerId!),
          ),
        );
        return;
      default:
        destinationPage = PageWork();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationPage),
    );
  }

  // Dashboard Product details modal method
  void _showDashboardProductDetailsModal(
    BuildContext context,
    DashboardProduct product,
  ) {
    final double price = double.tryParse(product.price) ?? 0;
    final double? specialPrice = product.specialprice != null
        ? double.tryParse(product.specialprice!)
        : null;
    final double displayPrice = specialPrice ?? price;
    final bool hasDiscount = specialPrice != null && specialPrice < price;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Product image
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '$producturl/${product.image}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.grey,
                              child: Icon(
                                Icons.shopping_bag,
                                size: 80,
                                color: AppColors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Product name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Brand and Category
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.brand,
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category,
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Price (continuing from where your code cuts off)
                    Row(
                      children: [
                        Text(
                          '₹${displayPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 12),
                        if (hasDiscount)
                          Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 20,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        if (hasDiscount) ...[
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SALE',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 16),

                    // Stock Information
                    Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          color: product.quantity > 10
                              ? AppColors.green
                              : AppColors.red,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Stock: ${product.quantity} units',
                          style: TextStyle(
                            color: product.quantity > 10
                                ? AppColors.green
                                : AppColors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      product.description.isNotEmpty
                          ? _stripHtmlTags(product.description)
                          : 'High-quality pet product designed for your furry friend\'s comfort and well-being. Made with premium materials and built to last.',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 20),

                    // Product Details
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Details',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailRow(
                            'Product ID',
                            product.productId.toString(),
                          ),
                          _buildDetailRow('Model', product.model),
                          _buildDetailRow('Brand', product.brand),
                          _buildDetailRow('Category', product.category),
                          _buildDetailRow('Stock', '${product.quantity} units'),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),

                    // Action buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: product.quantity > 0
                                ? () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${product.name} added to cart!',
                                        ),
                                        backgroundColor: AppColors.green,
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: product.quantity > 0
                                  ? AppColors.blue
                                  : AppColors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              product.quantity > 0
                                  ? 'Add to Cart'
                                  : 'Out of Stock',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductsPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'View All Products',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to strip HTML tags from description
  String _stripHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString
        .replaceAll(exp, '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');
  }

  void _navigateToMyPets() {
    // Validate required parameters
    if (customerId == null || customerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer ID not found. Please login again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Login',
            onPressed: () {
              // Navigate to login page
              // Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ),
      );
      return;
    }

    if (email == null || email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email not found. Please login again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Login',
            onPressed: () {
              // Navigate to login page
              // Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ),
      );
      return;
    }

    // Navigate with validated parameters
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyPetsPage(
          customerId: customerId!, // Now safe to use ! after validation
          email: email!, // Now safe to use ! after validation
          token: token, // This can be null as per your constructor
        ),
      ),
    );
  }

  Future<void> _navigateToCart() async {
    try {
      final authData = await UserDataService.getAuthData();

      if (authData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CartPage(
              customerId: authData['customer_id'].toString(),
              email: authData['email'],
              token: authData['token'],
            ),
          ),
        );
      } else {
        // Show login required message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please login to view your cart'),
            backgroundColor: AppColors.red,
            action: SnackBarAction(
              label: 'Login',
              textColor: AppColors.white,
              onPressed: () {
                // Navigate to login page - replace with your login navigation
                // Navigator.pushNamed(context, '/login');
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing cart: ${e.toString()}'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}