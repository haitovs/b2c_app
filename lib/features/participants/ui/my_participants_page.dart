import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

/// Page showing user's registration details, delegates, packages, and fees.
class MyParticipantsPage extends StatefulWidget {
  final int eventId;

  const MyParticipantsPage({super.key, required this.eventId});

  @override
  State<MyParticipantsPage> createState() => _MyParticipantsPageState();
}

class _MyParticipantsPageState extends State<MyParticipantsPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authService = context.read<AuthService>();
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/my-participants/${widget.eventId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _data = jsonDecode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _error = 'No registration found for this event';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C4494),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/events/${widget.eventId}/menu'),
        ),
        title: const Text(
          'My Participants',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF1F1F6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.go('/events/${widget.eventId}/registration'),
              child: const Text('Register Now'),
            ),
          ],
        ),
      );
    }

    if (_data == null) return const SizedBox();

    final contact = _data!['contact'] as Map<String, dynamic>?;
    final packages = _data!['package_selections'] as List? ?? [];
    final products = _data!['product_selections'] as List? ?? [];
    final fees = _data!['fees'] as Map<String, dynamic>? ?? {};
    final status = _data!['status'] as String? ?? 'DRAFT';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          _buildStatusBadge(status),
          const SizedBox(height: 20),

          // Contact Info
          if (contact != null) _buildContactCard(contact),
          const SizedBox(height: 20),

          // Delegates Section
          if (packages.isNotEmpty) ...[
            _buildSectionTitle('Delegates & Packages'),
            const SizedBox(height: 12),
            ...packages.map(
              (p) => _buildPackageCard(p as Map<String, dynamic>),
            ),
          ],

          // Products Section
          if (products.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionTitle('Products & Services'),
            const SizedBox(height: 12),
            ...products.map(
              (p) => _buildProductCard(p as Map<String, dynamic>),
            ),
          ],

          // Fee Summary
          const SizedBox(height: 20),
          _buildFeeSummary(fees),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'SUBMITTED':
        color = Colors.orange;
        icon = Icons.hourglass_top;
        break;
      case 'REJECTED':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.edit;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            'Status: $status',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF3C4494),
                child: Text(
                  '${contact['first_name'][0]}${contact['last_name'][0]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${contact['first_name']} ${contact['last_name']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      contact['company_name'] ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _infoRow(Icons.email_outlined, contact['email']),
          _infoRow(Icons.phone_outlined, contact['mobile']),
          _infoRow(
            Icons.location_on_outlined,
            '${contact['city']}, ${contact['country']}',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3C4494),
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final delegates = pkg['delegates'] as List? ?? [];
    final packageId =
        pkg['id']?.toString() ?? pkg['package_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('package_$packageId'),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            collapsedIconColor: const Color(0xFF3C4494),
            iconColor: const Color(0xFF3C4494),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF3C4494).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.card_membership,
                color: Color(0xFF3C4494),
              ),
            ),
            title: Text(
              pkg['package_name'] ?? 'Package',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Row(
              children: [
                Text(
                  '${pkg['quantity']}x • ${pkg['currency']} ${(pkg['total_price'] as num).toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  '${delegates.length} delegate${delegates.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            children: [
              const Divider(),
              const SizedBox(height: 8),
              if (delegates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No delegates added yet'),
                )
              else
                ...delegates.map(
                  (d) => _buildDelegateRow(d as Map<String, dynamic>),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDelegateRow(Map<String, dynamic> delegate) {
    final isSelf = delegate['is_self_registration'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelf
            ? const Color(0xFF3C4494).withValues(alpha: 0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: isSelf
            ? Border.all(color: const Color(0xFF3C4494).withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isSelf
                ? const Color(0xFF3C4494)
                : Colors.grey[400],
            child: Text(
              '${delegate['first_name'][0]}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${delegate['first_name']} ${delegate['last_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3C4494),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  delegate['email'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '#${delegate['delegate_number']}',
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product_name'] ?? 'Product',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  product['product_category'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '${product['currency']} ${(product['total_price'] as num).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSummary(Map<String, dynamic> fees) {
    final currency = fees['currency'] ?? 'USD';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _feeRow('Packages Total', fees['packages_total'] ?? 0, currency),
          _feeRow('Products Total', fees['products_total'] ?? 0, currency),
          if ((fees['service_fee'] ?? 0) > 0)
            _feeRow('Service Fee', fees['service_fee'] ?? 0, currency),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '$currency ${((fees['grand_total'] ?? 0) as num).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C4494),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String label, num amount, String currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
