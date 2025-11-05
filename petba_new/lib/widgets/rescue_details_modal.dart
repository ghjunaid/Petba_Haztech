import 'package:flutter/material.dart';

void showRescueDetailsModal(BuildContext context, Map<String, dynamic> rescue) {
  final String imageUrl = _constructImageUrl(
    rescue['img1']?.toString() ?? '',
    rescue['apiurl']?.toString(),
  );

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2d2d2d),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rescue Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (imageUrl.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[800],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[700],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets, color: Colors.grey[500], size: 48),
                              const SizedBox(height: 8),
                              Text('Image not available', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            _buildDetailRow('Condition', rescue['ConditionType'] ?? rescue['conditionType'] ?? 'Unknown'),
            _buildDetailRow(
              'Severity',
              _getConditionText((rescue['conditionLevel_id']?.toString() ?? rescue['conditionStatus']?.toString() ?? '0')),
            ),
            _buildDetailRow('Status', (rescue['status']?.toString() ?? rescue['conditionStatus']?.toString() ?? '0') == '0' ? 'Needs Rescue' : 'Rescued'),
            _buildDetailRow('Location', rescue['address'] ?? 'Not available'),
            _buildDetailRow('City', rescue['city'] ?? 'Unknown'),
            _buildDetailRow(
              'Distance',
              '${double.tryParse(rescue['Distance']?.toString() ?? '0')?.toStringAsFixed(1) ?? '0'} km',
            ),
            if (rescue['description'] != null && rescue['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                rescue['description'],
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _constructImageUrl(String imagePath, String? apiurl) {
  if (imagePath.isEmpty) return '';
  if (imagePath.startsWith('http')) return imagePath;
  final base = apiurl ?? '';
  final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
  return base.isNotEmpty ? '$base/$cleanPath' : cleanPath;
}

String _getConditionText(String conditionLevel) {
  switch (conditionLevel) {
    case '1':
      return 'Critical';
    case '2':
      return 'Severe';
    case '3':
      return 'Moderate';
    case '4':
      return 'Mild';
    case '5':
      return 'Stable';
    default:
      return 'Unknown';
  }
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}


