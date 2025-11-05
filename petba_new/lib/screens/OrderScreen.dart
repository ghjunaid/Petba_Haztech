import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/models/orders.dart';
import 'package:petba_new/providers/Config.dart';

class OrderHistoryPage extends StatefulWidget {
  final String customerId;

  const OrderHistoryPage({Key? key, required this.customerId}) : super(key: key);

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<OrderItem> orders = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadOrderHistory();
  }

  Future<void> loadOrderHistory() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.post(
        Uri.parse('$apiurl/api/loadorderhistory'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'c_id': widget.customerId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> orderHistory = data['loadOrderHistory'] ?? [];

        setState(() {
          orders = orderHistory.map((order) => OrderItem.fromJson(order)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load orders. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading orders: $e';
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'complete':
        return Colors.green;
      case 'processed':
        return Colors.teal;
      case 'canceled':
      case 'cancelled':
        return Colors.red;
      case 'failed':
      case 'expired':
      case 'denied':
        return Colors.red.shade700;
      case 'refunded':
      case 'reversed':
      case 'chargeback':
        return Colors.amber;
      case 'voided':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.autorenew;
      case 'shipped':
        return Icons.local_shipping;
      case 'complete':
        return Icons.check_circle;
      case 'processed':
        return Icons.done;
      case 'canceled':
      case 'cancelled':
        return Icons.cancel;
      case 'failed':
        return Icons.error;
      case 'expired':
        return Icons.timer_off;
      case 'denied':
        return Icons.block;
      case 'refunded':
        return Icons.money_off;
      case 'reversed':
      case 'chargeback':
        return Icons.undo;
      case 'voided':
        return Icons.not_interested;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2d2d2d),
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadOrderHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadOrderHistory,
        backgroundColor: const Color(0xFF3d3d3d),
        color: Colors.white,
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : errorMessage.isNotEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loadOrderHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : orders.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: Colors.grey,
                size: 80,
              ),
              SizedBox(height: 16),
              Text(
                'No orders found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return OrderCard(
              order: order,
              statusColor: getStatusColor(order.orderStatus),
              statusIcon: getStatusIcon(order.orderStatus),
            );
          },
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderItem order;
  final Color statusColor;
  final IconData statusIcon;

  const OrderCard({
    Key? key,
    required this.order,
    required this.statusColor,
    required this.statusIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF3d3d3d),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Order ID and Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4d4d4d),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.orderStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product Information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF5d5d5d),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: order.image.isNotEmpty
                        ? Image.network(
                      'YOUR_IMAGE_BASE_URL/${order.image}', // Replace with your image base URL
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 30,
                        );
                      },
                    )
                        : const Icon(
                      Icons.shopping_bag,
                      color: Colors.grey,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${order.price}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.paymentMethod,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Order Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF252525),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow('Date', _formatDate(order.dateModified)),
                const SizedBox(height: 8),
                _buildDetailRow('Address', '${order.address1}, ${order.city} - ${order.postcode}'),
                if (order.company.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Company', order.company),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

