import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/Config.dart';
import 'AddPets.dart';
import 'AddAdoption.dart';
import 'package:petba_new/screens/MyPetsDetails.dart';

class MyPetsPage extends StatefulWidget {
  final String customerId;
  final String email;
  String? token;

  MyPetsPage({
    Key? key,
    required this.customerId,
    required this.email,
    this.token,
  }) : super(key: key);

  @override
  State<MyPetsPage> createState() => _MyPetsPageState();
}

class _MyPetsPageState extends State<MyPetsPage> {
  List<Map<String, dynamic>> myPets = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMyPets();
  }

  Future<void> _fetchMyPets() async {
    // Check if widget is still mounted before calling setState
    if (!mounted) return;
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      print('=== DEBUGGING FETCH MY PETS ===');
      print('Customer ID: ${widget.customerId}');
      print('Customer ID Type: ${widget.customerId.runtimeType}');

      final response = await http.post(
        Uri.parse('$apiurl/api/listpet'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'c_id': widget.customerId, // Keep as string
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded response: $data');
        print('Response type: ${data.runtimeType}');

        // FIX: Use 'listpet' instead of 'adopt' based on your API response
        List<Map<String, dynamic>> pets = [];
        if (data['listpet'] != null) {
          pets = List<Map<String, dynamic>>.from(data['listpet']);
        }

        print('Number of pets fetched: ${pets.length}');

        // Check if widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            myPets = pets;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load pets: ${response.statusCode}');
      }
    } catch (e) {
      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = e.toString();
        });
      }
    }
  }

  // Modified to navigate to AddAdoptionPage instead of direct API call
  void _navigateToAddForAdoption(Map<String, dynamic> pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAdoptionPage(
          customerId: widget.customerId,
          email: widget.email,
          token: widget.token,
          existingPetData: pet, // Pass the existing pet data
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from adoption page
      _fetchMyPets();
    });
  }

  // Add this method to your _MyPetsPageState class
  void _navigateToPetDetails(Map<String, dynamic> pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailsPage(
          pet: pet,
          customerId: widget.customerId,
          email: widget.email,
          token: widget.token,
          // Pass callback functions
          onAddForAdoption: (pet) => _navigateToAddForAdoption(pet),
          onRemovePet: (pet) => _showRemoveConfirmation(pet),
        ),
      ),
    );
  }

  // Replace your existing _removePet method in MyPets.dart with this:

  Future<void> _removePet(String petId) async {
    if (!mounted) return;

    try {
      print('=== DEBUGGING REMOVE PET ===');
      print('Pet ID to remove: $petId');
      print('Customer ID: ${widget.customerId}');
      print('Email: ${widget.email}');
      print('Token: ${widget.token}');

      final requestBody = {
        'adopt_id': petId,
        'c_id': widget.customerId,
        'email': widget.email,
        'token': widget.token,
      };

      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$apiurl/api/deleteMyPet'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Parsed response: $responseData');

        // Check if the response contains the expected success message
        if (responseData['message'] != null) {
          _showMessage('Pet removed successfully!', false);

          // Force refresh the pet list
          await _fetchMyPets();

          print('Pet list refreshed after deletion');
        } else {
          throw Exception('Unexpected response format');
        }
      } else if (response.statusCode == 404) {
        _showMessage('Pet not found or already deleted', true);
      } else if (response.statusCode == 401) {
        _showMessage('Authentication failed. Please login again.', true);
      } else {
        final errorData = json.decode(response.body);
        print('Error response: $errorData');
        throw Exception('Failed to remove pet: ${response.statusCode} - ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      print('Exception in _removePet: $e');
      if (mounted) {
        _showMessage('Error removing pet: $e', true);
      }
    }
  }

  // Future<void> _removePet(String petId) async {
  //   if (!mounted) return;
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$apiurl/api/deleteMyPet'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({
  //         'adopt_id': petId,
  //         'c_id': widget.customerId,
  //         'email': widget.email,
  //         'token': widget.token,
  //       }),
  //     );
  //
  //     if (!mounted) return;
  //
  //     if (response.statusCode == 200) {
  //       _showMessage('Pet removed successfully!', false);
  //       _fetchMyPets(); // Refresh the list
  //     } else {
  //       throw Exception('Failed to remove pet');
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       _showMessage('Error: $e', true);
  //     }
  //   }
  // }

  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showActionDialog(Map<String, dynamic> pet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2d2d2d),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Pet Actions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What would you like to do with ${pet['name']}?',
                style: TextStyle(color: Colors.grey[300]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToAddForAdoption(pet); // Updated to navigate instead
                      },
                      icon: Icon(Icons.favorite, color: Colors.white),
                      label: Text('Add for\nAdoption', textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showRemoveConfirmation(pet);
                      },
                      icon: Icon(Icons.delete, color: Colors.white),
                      label: Text('Remove\nPet', textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
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
        );
      },
    );
  }

  // Also update your _showRemoveConfirmation method to ensure proper pet ID handling:
  void _showRemoveConfirmation(Map<String, dynamic> pet) {
    print('=== PET DATA FOR REMOVAL ===');
    print('Full pet data: $pet');
    print('Pet adopt_id: ${pet['adopt_id']}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2d2d2d),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Remove Pet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to remove ${pet['name']}? This will remove the pet from your list.',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                // Get the pet ID - your API uses adopt_id
                String? petId = pet['adopt_id']?.toString();

                if (petId != null && petId.isNotEmpty) {
                  print('Removing pet with adopt_id: $petId');
                  _removePet(petId);
                } else {
                  print('Pet adopt_id is null or empty: $petId');
                  _showMessage('Error: Pet ID not found', true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddPet() {
    // Navigate to AddPetPage - you'll need to import and implement this
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPetPage(customerId: widget.customerId),
      ),
    ).then((_) {
      // Refresh the list when returning from add pet page
      _fetchMyPets();
    });
  }

  /*void _navigateToEditPet(Map<String, dynamic> pet) {
    // Navigate to EditPetPage - you'll need to implement this
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPetPage(
          customerId: widget.customerId,
          petId: pet['adopt_id'].toString(),
          petData: pet,
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from edit pet page
      _fetchMyPets();
    });
  }*/

  String _calculateAge(String dobString) {
    try {
      DateTime dob = DateTime.parse(dobString);
      DateTime now = DateTime.now();
      Duration difference = now.difference(dob);
      int days = difference.inDays;

      if (days < 30) {
        return '$days days old';
      } else if (days < 365) {
        int months = (days / 30).floor();
        return '$months month${months > 1 ? 's' : ''} old';
      } else {
        int years = (days / 365).floor();
        int remainingMonths = ((days % 365) / 30).floor();
        if (remainingMonths > 0) {
          return '$years year${years > 1 ? 's' : ''}, $remainingMonths month${remainingMonths > 1 ? 's' : ''} old';
        } else {
          return '$years year${years > 1 ? 's' : ''} old';
        }
      }
    } catch (e) {
      return 'Age unknown';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFF2d2d2d),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.pets,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Added Pets',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first pet to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddPet,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Add Your Pet', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    // Fix the image URL - add the full server URL
    String imageUrl = '';
    if (pet['img1'] != null && pet['img1'].toString().isNotEmpty) {
      String imgPath = pet['img1'].toString();
      imageUrl = '$apiurl/$imgPath';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToPetDetails(pet),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Pet Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[700],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[700],
                        child: Icon(
                          Icons.pets,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      );
                    },
                  )
                      : Icon(
                    Icons.pets,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                ),
              ),
              SizedBox(width: 16),

              // Pet Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet['name'] ?? 'Unnamed Pet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${pet['animalTypeName'] ?? pet['animalName'] ?? 'Unknown'} • ${pet['breed'] ?? 'Mixed'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          // Fix gender logic - your API returns 1 for male
                          pet['gender'] == 1 || pet['gender'] == '1' ||
                              pet['gender']?.toString().toLowerCase() == 'male'
                              ? Icons.male
                              : Icons.female,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          pet['gender'] == '1' || pet['gender']?.toString().toLowerCase() == 'male'
                              ? 'Male'
                              : 'Female',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.cake,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _calculateAge(pet['dob'] ?? ''),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 4),
                        Text(
                          pet['city'] ?? 'Unknown Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _showActionDialog(pet),
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      appBar: AppBar(
        title: Text(
          'My Pets',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2d2d2d),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (myPets.isNotEmpty)
            IconButton(
              onPressed: _navigateToAddPet,
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMyPets,
        backgroundColor: Color(0xFF2d2d2d),
        color: Colors.blue,
        child: isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Loading your pets...',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        )
            : hasError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load pets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              // Test buttons
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _fetchMyPets,
                    child: Text('Retry (String ID)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  /*ElevatedButton(
                    onPressed: _fetchMyPetsWithIntId,
                    child: Text('Try Integer ID'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),*/
                ],
              ),
            ],
          ),
        )
            : myPets.isEmpty
            ? _buildEmptyState()
            : Padding(
          padding: EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: myPets.length,
            itemBuilder: (context, index) {
              return _buildPetCard(myPets[index]);
            },
          ),
        ),
      ),
    );
  }
}
