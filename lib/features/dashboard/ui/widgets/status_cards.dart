import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'company_card.dart';
import 'orders_card.dart';
import 'team_card.dart';
import 'visa_card.dart';

/// 2x2 grid layout of the four dashboard status cards.
class DashboardStatusCards extends StatelessWidget {
  final int eventId;
  final bool isMobile;
  final bool hasPurchased;
  final AsyncValue<List<dynamic>> companies;
  final AsyncValue<List<dynamic>> teamMembers;
  final AsyncValue<List<Map<String, dynamic>>> visas;
  final AsyncValue<List<dynamic>> orders;

  const DashboardStatusCards({
    super.key,
    required this.eventId,
    required this.isMobile,
    required this.hasPurchased,
    required this.companies,
    required this.teamMembers,
    required this.visas,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          DashboardCompanyCard(
            eventId: eventId,
            isMobile: isMobile,
            hasPurchased: hasPurchased,
            companies: companies,
          ),
          const SizedBox(height: 16),
          DashboardTeamCard(
            eventId: eventId,
            isMobile: isMobile,
            hasPurchased: hasPurchased,
            teamMembers: teamMembers,
          ),
          const SizedBox(height: 16),
          DashboardVisaCard(
            eventId: eventId,
            isMobile: isMobile,
            hasPurchased: hasPurchased,
            visas: visas,
          ),
          const SizedBox(height: 16),
          DashboardOrdersCard(
            eventId: eventId,
            isMobile: isMobile,
            orders: orders,
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardCompanyCard(
                eventId: eventId,
                isMobile: isMobile,
                hasPurchased: hasPurchased,
                companies: companies,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardTeamCard(
                eventId: eventId,
                isMobile: isMobile,
                hasPurchased: hasPurchased,
                teamMembers: teamMembers,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DashboardVisaCard(
                eventId: eventId,
                isMobile: isMobile,
                hasPurchased: hasPurchased,
                visas: visas,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardOrdersCard(
                eventId: eventId,
                isMobile: isMobile,
                orders: orders,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
