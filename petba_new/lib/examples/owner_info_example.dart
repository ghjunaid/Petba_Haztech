// Example usage of OwnerService
// This file demonstrates how to fetch and display owner information

import 'package:flutter/material.dart';
import 'package:petba_new/services/owner_service.dart';

class OwnerInfoExample extends StatefulWidget {
  final int customerId;

  OwnerInfoExample({required this.customerId});

  @override
  _OwnerInfoExampleState createState() => _OwnerInfoExampleState();
}

class _OwnerInfoExampleState extends State<OwnerInfoExample> {
  Map<String, dynamic>? ownerInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
  }

  Future<void> _loadOwnerInfo() async {
    try {
      final info = await OwnerService.getOwnerInfo(widget.customerId);
      if (mounted) {
        setState(() {
          ownerInfo = info;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Owner Information'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ownerInfo != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Owner Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildInfoRow('Name', '${ownerInfo!['firstname'] ?? ''} ${ownerInfo!['lastname'] ?? ''}'),
                      _buildInfoRow('Email', ownerInfo!['email'] ?? 'Not provided'),
                      _buildInfoRow('Phone', ownerInfo!['telephone'] ?? 'Not provided'),
                      _buildInfoRow('Customer ID', ownerInfo!['customer_id']?.toString() ?? 'Not provided'),
                    ],
                  )
                : Center(
                    child: Text('Failed to load owner information'),
                  ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// Alternative: Using individual methods
class QuickOwnerInfo extends StatelessWidget {
  final int customerId;

  QuickOwnerInfo({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: OwnerService.getOwnerName(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        if (snapshot.hasData) {
          return Text('Owner: ${snapshot.data}');
        }
        
        return Text('Owner: Unknown');
      },
    );
  }
}
