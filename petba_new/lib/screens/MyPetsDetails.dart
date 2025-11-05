import 'package:flutter/material.dart';
import 'package:petba_new/screens/MyPets.dart';

import '../providers/Config.dart';

class PetDetailsPage extends StatelessWidget {
  final Map<String, dynamic> pet;
  final String customerId;
  final String? email;
  final String? token;
  final Function(Map<String, dynamic>)? onAddForAdoption;
  final Function(Map<String, dynamic>)? onRemovePet;

  const PetDetailsPage({
    Key? key,
    required this.pet,
    required this.customerId,
    this.email,
    this.token,
    this.onAddForAdoption,
    this.onRemovePet,
  }) : super(key: key);

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

  String _getGenderText() {
    if (pet['gender'] == 1 || pet['gender'] == '1' ||
        pet['gender']?.toString().toLowerCase() == 'male') {
      return 'Male';
    }
    return 'Female';
  }

  IconData _getGenderIcon() {
    if (pet['gender'] == 1 || pet['gender'] == '1' ||
        pet['gender']?.toString().toLowerCase() == 'male') {
      return Icons.male;
    }
    return Icons.female;
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = '';
    if (pet['img1'] != null && pet['img1'].toString().isNotEmpty) {
      String imgPath = pet['img1'].toString();
      imageUrl = '$apiurl/$imgPath';
    }

    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      appBar: AppBar(
        title: Text(
          pet['name'] ?? 'Pet Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2d2d2d),
        foregroundColor: Colors.white,
        elevation: 0,
        /*actions: [
          IconButton(
            onPressed: () {
              // You can add edit functionality here later
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Edit functionality coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: Icon(Icons.edit),
          ),
        ],*/
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet Image
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[700],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
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
                        size: 80,
                      ),
                    );
                  },
                )
                    : Icon(
                  Icons.pets,
                  color: Colors.grey[400],
                  size: 80,
                ),
              ),
            ),

            SizedBox(height: 24),

            // Pet Name
            Text(
              pet['name'] ?? 'Unnamed Pet',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 8),

            // Animal Type and Breed
            Text(
              '${pet['animalTypeName'] ?? pet['animalName'] ?? 'Unknown'} • ${pet['breed'] ?? 'Mixed'}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
              ),
            ),

            SizedBox(height: 32),

            // Details Cards
            _buildDetailCard(
              'Gender',
              _getGenderText(),
              _getGenderIcon(),
              Colors.blue,
            ),

            SizedBox(height: 16),

            _buildDetailCard(
              'Age',
              _calculateAge(pet['dob'] ?? ''),
              Icons.cake,
              Colors.orange,
            ),

            SizedBox(height: 16),

            _buildDetailCard(
              'Location',
              pet['city'] ?? 'Unknown Location',
              Icons.location_on,
              Colors.green,
            ),

            SizedBox(height: 16),

            _buildDetailCard(
              'Date of Birth',
              pet['dob'] ?? 'Unknown',
              Icons.calendar_today,
              Colors.purple,
            ),

            SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (onAddForAdoption != null) {
                        onAddForAdoption!(pet);
                      }
                    },
                    icon: Icon(Icons.favorite, color: Colors.white),
                    label: Text('Add for Adoption'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (onRemovePet != null) {
                        onRemovePet!(pet);
                      }
                    },
                    icon: Icon(Icons.delete, color: Colors.white),
                    label: Text('Remove Pet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

