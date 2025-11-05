import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/models/adoption.dart';
import 'package:petba_new/screens/PetDetailPage.dart';

import '../chat/Model/ChatModel.dart';
import '../chat/Model/Messagemodel.dart';
import '../chat/screens/Individualpage.dart';
import 'package:petba_new/chat/socket_sevice.dart';
import '../services/user_data_service.dart';

class AdoptionPage extends StatefulWidget {
  @override
  _AdoptionPageState createState() => _AdoptionPageState();
}

class _AdoptionPageState extends State<AdoptionPage> {
  List<AdoptionPet> _adoptionPets = [];
  List<AdoptionPet> _filteredPets = [];
  String _selectedSort = 'Name';
  bool _isLoading = true;
  String _error = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _fetchAdoptionData();
  }

  Future<void> _fetchAdoptionData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final userData = await UserDataService.getUserData();
      final currentUserId = userData?['customer_id'] ?? userData?['id'];

      final response = await http.post(
        Uri.parse('$apiurl/api/listadoption'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'c_id': currentUserId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> adoptionList = data['listadopt'] ?? [];
        setState(() {
          _adoptionPets = adoptionList
              .map((item) => AdoptionPet.fromJson(item))
              .toList();
          _filteredPets = List.from(_adoptionPets);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              'Failed to load adoption data. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _calculateAge(String dob) {
    try {
      final DateTime birthDate = DateTime.parse(dob);
      final DateTime now = DateTime.now();
      final int years = now.year - birthDate.year;
      final int months = now.month - birthDate.month;
      final int days = now.day - birthDate.day;

      if (years > 0) {
        return '$years year${years > 1 ? 's' : ''} old';
      } else if (months > 0) {
        return '$months month${months > 1 ? 's' : ''} old';
      } else {
        return '$days day${days > 1 ? 's' : ''} old';
      }
    } catch (e) {
      return 'Age unknown';
    }
  }

  void _sortPets(String sortBy) {
    setState(() {
      _selectedSort = sortBy;
      switch (sortBy) {
        case 'Name':
          _filteredPets.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Age':
          _filteredPets.sort((a, b) => a.dob.compareTo(b.dob));
          break;
        case 'Location':
          _filteredPets.sort((a, b) => a.city.compareTo(b.city));
          break;
      }
    });
  }

  void _filterPets(String filterType) {
    setState(() {
      switch (filterType) {
        case 'All':
          _filteredPets = List.from(_adoptionPets);
          break;
        case 'Dogs':
          _filteredPets = _adoptionPets
              .where((pet) => pet.animalName.toLowerCase().contains('dog'))
              .toList();
          break;
        case 'Cats':
          _filteredPets = _adoptionPets
              .where((pet) => pet.animalName.toLowerCase().contains('cat'))
              .toList();
          break;
        case 'Others':
          _filteredPets = _adoptionPets
              .where(
                (pet) =>
                    !pet.animalName.toLowerCase().contains('dog') &&
                    !pet.animalName.toLowerCase().contains('cat'),
              )
              .toList();
          break;
      }
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF2d2d2d),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sort by',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text('Name', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _sortPets('Name');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Age', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _sortPets('Age');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Location', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _sortPets('Location');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF2d2d2d),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter by',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text('All Pets', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _filterPets('All');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Dogs', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _filterPets('Dogs');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Cats', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _filterPets('Cats');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Others', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _filterPets('Others');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
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
          icon: Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Adoption',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: Colors.blue,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: _fetchAdoptionData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sort and Filter buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Sort',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _showFilterOptions,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Filter',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Adoption title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Adoption',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Content area
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.blue),
                        SizedBox(height: 16),
                        Text(
                          'Loading pets...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 64),
                        SizedBox(height: 16),
                        Text(
                          _error,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAdoptionData,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredPets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, color: Colors.grey, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No pets found',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _isGridView
                        ? GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: _filteredPets.length,
                            itemBuilder: (context, index) {
                              return _buildPetCard(_filteredPets[index]);
                            },
                          )
                        : ListView.builder(
                            itemCount: _filteredPets.length,
                            itemBuilder: (context, index) {
                              return _buildListPetCard(_filteredPets[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(AdoptionPet pet) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PetDetailPage(pet: pet)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  child: pet.img1.isNotEmpty
                      ? Image.network(
                          '$apiurl/${pet.img1}',
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade600,
                              child: Icon(
                                Icons.pets,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade600,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.blue,
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
                          color: Colors.grey.shade600,
                          child: Icon(
                            Icons.pets,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
              ),
            ),

            // Pet info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Pet type and breed badges
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pet.animalName,
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pet.breed,
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 2),

                    // Pet name
                    Text(
                      pet.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1),

                    Row(
                      children: [
                        Icon(
                          // Fix gender logic - your API returns 1 for male
                          pet.gender == 1 ||
                                  pet.gender == '1' ||
                                  pet.gender.toString().toLowerCase() == 'male'
                              ? Icons.male
                              : Icons.female,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          pet.gender == '1' ||
                                  pet.gender.toString().toLowerCase() == 'male'
                              ? 'Male'
                              : 'Female',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: const Color.fromARGB(255, 255, 153, 0),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _calculateAge(pet.dob),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5),

                    // Location
                    Text(
                      pet.city,
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildListPetCard(AdoptionPet pet) {
    // Fix the image URL - add the full server URL
    String imageUrl = pet.img1.isNotEmpty ? '$apiurl/${pet.img1}' : '';

    return Container(
      height: 130,
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PetDetailPage(pet: pet)),
          );
        },
        child: Row(
          children: [
            // Pet Image
            Expanded(
              flex: 2,
              child: Container(
                width: 5,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[700],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.fill,
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade600,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.blue,
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
                      : Icon(Icons.pets, color: Colors.grey[400], size: 40),
                ),
              ),
            ),
            SizedBox(width: 10),

            // Pet Details
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${pet.animalName} • ${pet.breed}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          // Fix gender logic - your API returns 1 for male
                          pet.gender == 1 ||
                                  pet.gender == '1' ||
                                  pet.gender.toString().toLowerCase() == 'male'
                              ? Icons.male
                              : Icons.female,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          pet.gender == '1' ||
                                  pet.gender.toString().toLowerCase() == 'male'
                              ? 'Male'
                              : 'Female',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: const Color.fromARGB(255, 255, 153, 0),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _calculateAge(pet.dob),
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
                          color: Colors.red[400],
                        ),
                        SizedBox(width: 4),
                        Text(
                          pet.city,
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
            ),

            // Action Button
            // Padding(
            //   padding: const EdgeInsets.only(right: 8.0),
            //   child: Container(
            //     decoration: BoxDecoration(
            //       color: Colors.blue.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     child: IconButton(
            //       onPressed: () => _showActionDialog(pet),
            //       icon: Icon(Icons.more_vert, color: Colors.blue),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  void _showActionDialog(AdoptionPet pet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2d2d2d),
          title: Text(
            'Actions for ${pet.name}',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'What would you like to do?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Add action here, e.g., contact owner
              },
              child: Text('Contact', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
