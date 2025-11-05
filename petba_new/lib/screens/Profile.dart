import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:petba_new/services/user_data_service.dart';
import 'package:petba_new/screens/SignIn.dart';

import '../providers/Config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;
  String? customerId;

  // controllers for editing
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController citySearchCtrl = TextEditingController();

  // City selection variables
  List<Map<String, dynamic>> selectedCities = [];
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  bool showDropdown = false;
  final FocusNode citySearchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    citySearchCtrl.dispose();
    citySearchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Get customer ID
    final customerIdResult = await UserDataService.getCustomerId();
    customerId = customerIdResult?.toString();
    if (customerId == null) {
      print("Customer ID not found");
      setState(() {
        isLoading = false;
      });
      return;
    }
    print("Customer id: $customerId");

    // Check if we have cached data first
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // String? cachedUserData = prefs.getString('userData');
    //
    // if (cachedUserData != null && cachedUserData.isNotEmpty) {
    //   try {
    //     Map<String, dynamic> data = json.decode(cachedUserData);
    //     setState(() {
    //       userData = data;
    //       firstNameCtrl.text = data['firstname'] ?? "";
    //       lastNameCtrl.text = data['lastname'] ?? "";
    //       emailCtrl.text = data['email'] ?? "";
    //       phoneCtrl.text = data['telephone'] ?? "";
    //       isLoading = false;
    //     });
    //     await _loadSelectedCities(); // Load user's selected cities
    //     print(" LOADED FROM CACHE - NO API CALL");
    //     return;
    //   } catch (e) {
    //     print("Cache error: $e");
    //   }
    // }

    // ONLY reach here if NO cache exists
    print(" NO CACHE - CALLING API");
    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/customerdata'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"c_id": customerId}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final customerData = decoded['customerData'];

        setState(() {
          userData = customerData;
          firstNameCtrl.text = customerData['firstname'] ?? "";
          lastNameCtrl.text = customerData['lastname'] ?? "";
          emailCtrl.text = customerData['email'] ?? "";
          phoneCtrl.text = customerData['telephone'] ?? "";
          isLoading = false;
        });

        await _loadSelectedCities(); // Load user's selected cities

        // // Save to cache for next time
        // await prefs.setString('userData', json.encode(customerData));
        // print(" LOADED FROM API & CACHED");
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("API Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadSelectedCities() async {
    if (customerId == null) return;

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/load-my-city'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"c_id": customerId}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final cities = decoded['load-my-city'] as List;

        setState(() {
          selectedCities = cities.map((city) => {
            'city_id': city['city_id'].toString(),
            'city_name': city['city_name'],
            'state': city['state'] ?? '',
            'rcp_id': city['rcp_id'].toString(),
          }).toList();
        });
      }
    } catch (e) {
      print("Error loading selected cities: $e");
    }
  }

  Future<void> _searchCities(String query) async {
    if (query.length < 2) {
      setState(() {
        searchResults = [];
        showDropdown = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
      showDropdown = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiurl/api/search-city'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"search": query, "off": 0}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final cities = decoded['searchitems'] as List;

        setState(() {
          searchResults = cities.map((city) => {
            'city_id': city['city_id'].toString(),
            'city': city['city'],
            'district': city['district'] ?? '',
            'state': city['state'] ?? '',
          }).toList();
          isSearching = false;
        });
      }
    } catch (e) {
      print("Search error: $e");
      setState(() {
        isSearching = false;
      });
    }
  }

  void _addCity(Map<String, dynamic> city) {
    // Check if city is already selected
    bool alreadySelected = selectedCities.any(
            (selected) => selected['city_id'] == city['city_id']
    );

    if (!alreadySelected) {
      setState(() {
        selectedCities.add({
          'city_id': city['city_id'],
          'city_name': city['city'],
          'state': city['state'],
          'rcp_id': '', // Will be set after saving to backend
        });
        citySearchCtrl.clear();
        searchResults = [];
        showDropdown = false;
      });
    }
  }

  Future<void> _removeCity(int index) async {
    final city = selectedCities[index];

    // If city has rcp_id (saved in backend), delete from backend
    if (city['rcp_id'].isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('$apiurl/api/delete-city'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({"id": city['rcp_id']}),
        );

        if (response.statusCode == 200) {
          setState(() {
            selectedCities.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("City removed successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to remove city"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print("Error removing city: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error removing city"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // If city is not yet saved (no rcp_id), just remove locally
      setState(() {
        selectedCities.removeAt(index);
      });
    }
  }

  Future<void> _saveSelectedCities() async {
    if (customerId == null || selectedCities.isEmpty) return;

    try {
      // Get city IDs for new cities (without rcp_id)
      List<String> cityIdsToAdd = selectedCities
          .where((city) => city['rcp_id'] == null || city['rcp_id'].toString().isEmpty)
          .map<String>((city) => city['city_id'].toString())
          .toList();

      if (cityIdsToAdd.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$apiurl/api/addCitiesLink'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            "c_id": customerId,
            "city": cityIdsToAdd,
            "flag": "1"
          }),
        );

        if (response.statusCode == 200) {
          print("Cities saved successfully");
          await _loadSelectedCities(); // Reload to get rcp_ids
        }
      }
    } catch (e) {
      print("Error saving cities: $e");
    }
  }

  Future<void> _saveUserData() async {
    setState(() {
      isSaving = true;
    });

    // Save cities first
    await _saveSelectedCities();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Keep all existing data, just update the edited fields
    Map<String, dynamic> updatedData = Map<String, dynamic>.from(userData ?? {});
    updatedData['firstname'] = firstNameCtrl.text;
    updatedData['lastname'] = lastNameCtrl.text;
    updatedData['email'] = emailCtrl.text;
    updatedData['telephone'] = phoneCtrl.text;

    userData = updatedData;
    await prefs.setString('userData', json.encode(userData));

    setState(() {
      isEditing = false;
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile updated successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  String get fullName {
    if (userData == null) return "";
    String first = firstNameCtrl.text;
    String last = lastNameCtrl.text;
    return "$first $last".trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          title: const Text("Profile"),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            // Hide dropdown when tapping outside
            if (showDropdown) {
              setState(() {
                showDropdown = false;
              });
            }
            // Remove focus from search field
            FocusScope.of(context).unfocus();
          },
          child: userData == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : "U",
                    style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fullName.isNotEmpty ? fullName : "User",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 24),

                // Profile Info
                isEditing
                    ? _buildTextField("First Name", firstNameCtrl)
                    : _buildCard(Icons.person, "First Name",
                    userData?['firstname'] ?? ""),
                const SizedBox(height: 12),
                isEditing
                    ? _buildTextField("Last Name", lastNameCtrl)
                    : _buildCard(Icons.person, "Last Name",
                    userData?['lastname'] ?? ""),
                const SizedBox(height: 12),
                isEditing
                    ? _buildTextField("Email", emailCtrl)
                    : _buildCard(Icons.email, "Email", userData?['email'] ?? ""),
                const SizedBox(height: 12),
                isEditing
                    ? _buildTextField("Phone", phoneCtrl)
                    : _buildCard(Icons.phone, "Phone", userData?['telephone'] ?? ""),
                const SizedBox(height: 12),

                // Rescue Cities Section
                isEditing ? _buildCitySelector() : _buildCityDisplay(),

                const SizedBox(height: 30),

                // Edit/Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : () {
                      if (isEditing) {
                        _saveUserData();
                      } else {
                        setState(() {
                          isEditing = true;
                        });
                      }
                    },
                    icon: isSaving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Icon(isEditing ? Icons.save : Icons.edit),
                    label: Text(isSaving
                        ? "Saving..."
                        : (isEditing ? "Save Profile" : "Edit Profile")),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

                // LOGOUT
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: const Text(
                              "Logout",
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              "Are you sure you want to logout?",
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.blueAccent),
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
                                        builder: (context) => LoginPage()),
                                  );
                                },
                                child: const Text(
                                  "Logout",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildCard(IconData icon, String label, String value) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.blueAccent),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
                const SizedBox(height: 4),
                Text(value.isNotEmpty ? value : "Not provided",
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  Widget _buildCityDisplay() {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_city, size: 28, color: Colors.blueAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Rescue Cities",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70)),
                  const SizedBox(height: 8),
                  selectedCities.isEmpty
                      ? const Text("No cities selected",
                      style: TextStyle(fontSize: 16, color: Colors.white))
                      : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedCities
                        .map((city) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueAccent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on,
                              size: 16,
                              color: Colors.blueAccent),
                          const SizedBox(width: 6),
                          Text(
                            "${city['city_name']}, ${city['state']}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ))
                        .toList(),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget _buildCitySelector() {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_city, size: 28, color: Colors.blueAccent),
                const SizedBox(width: 16),
                const Text("Rescue Cities",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 12),

            // Search Field
            Column(
              children: [
                TextField(
                  controller: citySearchCtrl,
                  focusNode: citySearchFocus,
                  style: const TextStyle(color: Colors.white),
                  onChanged: _searchCities,
                  onTap: () {
                    if (citySearchCtrl.text.isNotEmpty) {
                      setState(() {
                        showDropdown = true;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Search for cities...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: isSearching
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      ),
                    )
                        : const Icon(Icons.search, color: Colors.white54),
                  ),
                ),

                // Dropdown Results
                if (showDropdown && searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final city = searchResults[index];
                        return ListTile(
                          title: Text(
                            city['city'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "${city['district']}, ${city['state']}",
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          onTap: () => _addCity(city),
                          dense: true,
                        );
                      },
                    ),
                  ),
              ],
            ),

            // Selected Cities
            if (selectedCities.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "Selected Cities:",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedCities.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> city = entry.value;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${city['city_name']}, ${city['state']}",
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeCity(index),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
