import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/screens/ServicesScreen.dart';
import 'package:petba_new/models/services.dart';

import 'DonationScreen.dart';


class ServiceDetailsPage extends StatefulWidget {
  final ServiceModel service;
  final int serviceType;

  const ServiceDetailsPage({
    Key? key,
    required this.service,
    required this.serviceType,
  }) : super(key: key);

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  ServiceDetailsModel? serviceDetails;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchServiceDetails();
  }

  String get serviceTitle {
    switch (widget.serviceType) {
      case 1:
        return 'Veterinarian Details';
      case 2:
        return 'Shelter Details';
      case 3:
        return 'Groomer Details';
      case 4:
        return 'Trainer Details';
      case 5:
        return 'Foster Details';
      default:
        return 'Service Details';
    }
  }

  Future<void> fetchServiceDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      String apiEndpoint;
      Map<String, dynamic> requestBody;

      switch (widget.serviceType) {
        case 1: // Vet
          apiEndpoint = '$apiurl/api/loadvetdetails';
          requestBody = {"id": widget.service.id};
          break;

        case 2: // Shelter
        apiEndpoint = '$apiurl/api/shelterdetails';
        requestBody = {"id": widget.service.id};
        break;

        case 3: // Groomer
          apiEndpoint = '$apiurl/api/loadgroomingdetails';
          requestBody = {"id": widget.service.id};
          break;

        case 4: // Trainer
        // For trainer, we'll use the existing data since there's no separate details API
          apiEndpoint = '$apiurl/api/loadtrainingdetails';
          requestBody = {"id": widget.service.id};
          break;

        case 5: // Foster
          apiEndpoint = '$apiurl/api/fosterdetails';
          requestBody = {"id": widget.service.id};
          break;

        default:
          throw Exception('Invalid service type');
      }

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          serviceDetails = ServiceDetailsModel.fromJson(data, widget.serviceType);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load service details: ${response.statusCode}';
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
        title: Text(
          serviceTitle,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (!isLoading && errorMessage == null)
            IconButton(
              onPressed: fetchServiceDetails,
              icon: const Icon(
                Icons.refresh,
                color: Color(0xFF60A5FA),
              ),
            ),
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: !isLoading && serviceDetails != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildContent() {
    if (isLoading) {
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
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 16,
              ),
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
            const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchServiceDetails,
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

    if (serviceDetails == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getServiceIcon(),
              color: const Color(0xFF9CA3AF),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Service details not found',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Image
          _buildImageSection(),
          const SizedBox(height: 20),

          // Service Details Card
          _buildDetailsCard(),
          const SizedBox(height: 16),

          // Doctor/Owner Card (for vets and shelters)
          if (widget.serviceType == 1 && serviceDetails!.doctor != null)
            _buildDoctorCard(),
          if (widget.serviceType == 1 && serviceDetails!.doctor != null)
            const SizedBox(height: 16),

          // Contact Information
          if (serviceDetails!.phoneNumber != null ||
              serviceDetails!.email != null ||
              serviceDetails!.address != null)
            _buildContactCard(),

          if (serviceDetails!.phoneNumber != null ||
              serviceDetails!.email != null ||
              serviceDetails!.address != null)
            const SizedBox(height: 16),

          // About Section
          if (serviceDetails!.about != null || serviceDetails!.description != null)
            _buildAboutCard(),

          if (serviceDetails!.about != null || serviceDetails!.description != null)
            const SizedBox(height: 16),

          // Services Section (for groomers)
          if (widget.serviceType == 3 && serviceDetails!.services.isNotEmpty)
            _buildServicesCard(),

          if (widget.serviceType == 3 && serviceDetails!.services.isNotEmpty)
            const SizedBox(height: 16),

          // Reviews Section (for vets)
          if (widget.serviceType == 1 && serviceDetails!.reviews.isNotEmpty)
           // _buildReviewsCard(),

          if (widget.serviceType == 1 && serviceDetails!.reviews.isNotEmpty)
            const SizedBox(height: 16),

          // Additional Images (for groomers and vets)
          if ((widget.serviceType == 3 || widget.serviceType == 1) &&
              serviceDetails!.additionalImages.isNotEmpty)
            _buildAdditionalImagesCard(),

          // Add some bottom padding for the bottom bar
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFF4B5563),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          serviceDetails!.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                _getServiceIcon(),
                color: const Color(0xFF60A5FA),
                size: 64,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Name with Verification Badge (for Foster)
          Row(
            children: [
              Expanded(
                child: Text(
                  serviceDetails!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.serviceType == 5 && serviceDetails!.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Provider Name (except for Foster)
          if (widget.serviceType != 5) ...[
            Text(
              '${_getProviderLabel()}: ${serviceDetails!.provider}',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Details (for groomers)
          if (serviceDetails!.details != null) ...[
            Text(
              serviceDetails!.details!,
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Service Type for Foster OR Rating for others
          if (widget.serviceType == 5) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: serviceDetails!.isPaid ? const Color(0xFF60A5FA) : const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                serviceDetails!.isPaid ? 'Paid Foster Service' : 'Free Foster Service',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFBBF24), size: 20),
                const SizedBox(width: 4),
                Text(
                  serviceDetails!.rating.toString(),
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${serviceDetails!.rating}/5)',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
                if (serviceDetails!.reviewCount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${serviceDetails!.reviewCount} reviews',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Available Hours
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 8),
              Text(
                'Available: ${serviceDetails!.time}',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price/Fee
          Row(
            children: [
              const Icon(Icons.currency_rupee, color: Color(0xFF60A5FA), size: 16),
              const SizedBox(width: 8),
              Text(
                '${_getPriceLabel()}: ${serviceDetails!.price}',
                style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  serviceDetails!.location,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          // Experience (for groomers and trainers)
          if (serviceDetails!.experience != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.work_outline, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Experience: ${serviceDetails!.experience}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doctor Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Doctor Image
              if (serviceDetails!.doctorImage != null)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B5563),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      serviceDetails!.doctorImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Color(0xFF60A5FA),
                          size: 30,
                        );
                      },
                    ),
                  ),
                ),
              if (serviceDetails!.doctorImage != null) const SizedBox(width: 16),

              // Doctor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${serviceDetails!.doctor!}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (serviceDetails!.qualification != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        serviceDetails!.qualification!,
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (serviceDetails!.experience != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${serviceDetails!.experience} years experience',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (serviceDetails!.about != null) ...[
            const SizedBox(height: 12),
            Text(
              serviceDetails!.about!,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],

          if (serviceDetails!.doctorDescription != null) ...[
            const SizedBox(height: 12),
            Text(
              serviceDetails!.doctorDescription!,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (serviceDetails!.phoneNumber != null) ...[
            Row(
              children: [
                const Icon(Icons.phone, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    serviceDetails!.phoneNumber!,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showMessage('Calling ${serviceDetails!.phoneNumber}', isError: false);
                  },
                  icon: const Icon(Icons.call, color: Color(0xFF10B981)),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (serviceDetails!.email != null) ...[
            Row(
              children: [
                const Icon(Icons.email, color: Color(0xFF60A5FA), size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    serviceDetails!.email!,
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showMessage('Opening email to ${serviceDetails!.email}', isError: false);
                  },
                  icon: const Icon(Icons.mail_outline, color: Color(0xFF60A5FA)),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (serviceDetails!.address != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Address:',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serviceDetails!.address!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showMessage('Opening maps', isError: false);
                  },
                  icon: const Icon(Icons.map, color: Color(0xFFEF4444)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (serviceDetails!.about != null) ...[
            Text(
              serviceDetails!.about!,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            if (serviceDetails!.description != null) const SizedBox(height: 12),
          ],

          if (serviceDetails!.description != null) ...[
            Text(
              serviceDetails!.description!,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services Offered',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: serviceDetails!.services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF60A5FA),
                    width: 1,
                  ),
                ),
                child: Text(
                  service,
                  style: const TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalImagesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gallery',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: serviceDetails!.additionalImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < serviceDetails!.additionalImages.length - 1 ? 12 : 0,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B5563),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        serviceDetails!.additionalImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image,
                              color: Color(0xFF60A5FA),
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF374151),
        border: Border(
          top: BorderSide(color: Color(0xFF4B5563), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Call Button
          if (serviceDetails!.phoneNumber != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showMessage('Calling ${serviceDetails!.phoneNumber}', isError: false);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          if (serviceDetails!.phoneNumber != null)
            const SizedBox(width: 12),

          // Main Action Button
          Expanded(
            flex: serviceDetails!.phoneNumber != null ? 3 : 5,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.serviceType == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationPage(),
                    ),
                  );
                } else {
                  _showMessage('${_getActionLabel()} confirmed for ${serviceDetails!.name}!', isError: false);
                }
              },
              icon: Icon(_getActionIcon()),
              label: Text(_getActionLabel()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60A5FA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF374151),
          title: Text(
            _getActionLabel(),
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getActionDescription()} ${serviceDetails!.name}',
                style: const TextStyle(color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 16),
              Text(
                '${_getPriceLabel()}: ${serviceDetails!.price}',
                style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available: ${serviceDetails!.time}',
                style: const TextStyle(color: Color(0xFF10B981)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigator.of(context).pop();
                // _showMessage('${_getSuccessMessage()} ${serviceDetails!.name}!', isError: false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60A5FA),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  IconData _getServiceIcon() {
    switch (widget.serviceType) {
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

  String _getProviderLabel() {
    switch (widget.serviceType) {
      case 1:
        return 'Doctor';
      case 2:
        return 'Owner';
      case 3:
        return 'Groomer';
      case 4:
        return 'Trainer';
      default:
        return 'Provider';
    }
  }

  String _getPriceLabel() {
    switch (widget.serviceType) {
      case 1:
        return 'Fee';
      case 4:
        return 'Training Fee';
      default:
        return 'Price';
    }
  }

  IconData _getActionIcon() {
    switch (widget.serviceType) {
      case 1:
        return Icons.pets;
      case 2:
        return Icons.calendar_today;
      case 3:
        return Icons.school;
      default:
        return Icons.book_online;
    }
  }

  String _getActionLabel() {
    switch (widget.serviceType) {
      case 1:
        return 'Book Appointment';
      case 2:
        return 'Donation';
      case 3:
        return 'Book Appointment';
      case 4:
        return 'Book Training';
      case 5:
        return 'Apply to Foster';
      default:
        return 'Book Service';
    }
  }

  String _getActionDescription() {
    switch (widget.serviceType) {
      case 3:
        return 'Book an appointment with';
      case 4:
        return 'Book a training session with';
      case 5:
        return 'Apply to foster at';
      default:
        return 'Book service with';
    }
  }

  // String _getSuccessMessage() {
  //   switch (widget.serviceType) {
  //     case 3:
  //       return 'Grooming appointment booked with';
  //     case 4:
  //       return 'Training session booked with';
  //     case 5:
  //       return 'Foster application sent to';
  //     default:
  //       return 'Service booked with';
  //   }
  // }
}