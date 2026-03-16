import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/analytics_data.dart';
import '../providers/analytics_providers.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final routerState = GoRouterState.of(context);
    final eventId =
        int.tryParse(routerState.pathParameters['id'] ?? '0') ?? 0;

    final params = AnalyticsParams(eventId: eventId, days: _selectedDays);
    final asyncData = ref.watch(userAnalyticsProvider(params));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('Failed to load analytics',
                  style: AppTheme.heading2.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text('$err',
                  style: AppTheme.bodyText
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                style: AppTheme.primaryButtonStyle,
                onPressed: () =>
                    ref.invalidate(userAnalyticsProvider(params)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (data) => _buildDashboard(context, data, eventId),
    );
  }

  Widget _buildDashboard(
      BuildContext context, UserAnalyticsData data, int eventId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + day filter
          _buildHeader(),
          const SizedBox(height: 24),

          // Summary cards — 2x2 grid
          _SummaryCards(data: data),
          const SizedBox(height: 24),

          // Meeting status + Orders side-by-side on desktop
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final meetingSection = data.meetings.byStatus.isNotEmpty
                ? _MeetingStatusCard(meetings: data.meetings)
                : null;
            final orderSection = _OrdersCard(orders: data.orders);

            if (isWide && meetingSection != null) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: meetingSection),
                    const SizedBox(width: 16),
                    Expanded(child: orderSection),
                  ],
                ),
              );
            }
            return Column(
              children: [
                if (meetingSection != null) ...[
                  meetingSection,
                  const SizedBox(height: 16),
                ],
                orderSection,
              ],
            );
          }),
          const SizedBox(height: 16),

          // Team member views table (only if company exists)
          if (data.hasCompany && data.teamMemberViews.isNotEmpty) ...[
            _TeamMemberViewsCard(
              members: data.teamMemberViews,
              eventId: eventId,
            ),
            const SizedBox(height: 16),
          ],

          // Visa + Registration side-by-side on desktop
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final visaSection = data.visa.totalApplications > 0
                ? _VisaCard(visa: data.visa)
                : null;
            final regSection = data.registration.total > 0
                ? _RegistrationCard(registration: data.registration)
                : null;

            if (isWide && visaSection != null && regSection != null) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: visaSection),
                  const SizedBox(width: 16),
                  Expanded(child: regSection),
                ],
              );
            }
            return Column(
              children: [
                if (visaSection != null) ...[
                  visaSection,
                  const SizedBox(height: 16),
                ],
                if (regSection != null) ...[
                  regSection,
                  const SizedBox(height: 16),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.analytics_outlined,
              color: AppTheme.primaryColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analytics', style: AppTheme.heading1),
              Text(
                'Your event performance overview',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final days in [7, 14, 30])
                _DayChip(
                  days: days,
                  selected: _selectedDays == days,
                  onTap: () => setState(() => _selectedDays = days),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Day filter chip
// ---------------------------------------------------------------------------

class _DayChip extends StatelessWidget {
  final int days;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.days,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${days}d',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary cards — 2x2 colored gradient cards
// ---------------------------------------------------------------------------

class _SummaryCards extends StatelessWidget {
  final UserAnalyticsData data;

  const _SummaryCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = <_MetricCardData>[
      _MetricCardData(
        'Total Views',
        data.summary.totalProfileViews,
        Icons.visibility_outlined,
        const Color(0xFF3C4494),
        const Color(0xFF5C6BC0),
      ),
      if (data.hasCompany)
        _MetricCardData(
          'Company Views',
          data.summary.companyProfileViews,
          Icons.business_outlined,
          const Color(0xFF00897B),
          const Color(0xFF26A69A),
        ),
      _MetricCardData(
        'B2B Meetings',
        data.summary.b2bMeetingsCount,
        Icons.handshake_outlined,
        const Color(0xFFE65100),
        const Color(0xFFFF8F00),
      ),
      _MetricCardData(
        'B2G Meetings',
        data.summary.b2gMeetingsCount,
        Icons.account_balance_outlined,
        const Color(0xFF6A1B9A),
        const Color(0xFF9C27B0),
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      if (isWide) {
        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: _MetricCard(data: cards[i])),
            ],
          ],
        );
      }
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _MetricCard(data: cards[0])),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricCard(
                      data: cards.length > 1 ? cards[1] : cards[0])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _MetricCard(
                      data: cards.length > 2 ? cards[2] : cards[0])),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricCard(
                      data: cards.length > 3 ? cards[3] : cards[0])),
            ],
          ),
        ],
      );
    });
  }
}

class _MetricCardData {
  final String title;
  final int value;
  final IconData icon;
  final Color colorStart;
  final Color colorEnd;
  _MetricCardData(
      this.title, this.value, this.icon, this.colorStart, this.colorEnd);
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.colorStart, data.colorEnd],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: data.colorStart.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.value.toString(),
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card wrapper
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.inputBorder.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: AppColors.inputBorder.withValues(alpha: 0.2)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meeting status card
// ---------------------------------------------------------------------------

class _MeetingStatusCard extends StatelessWidget {
  final UserMeetingSummary meetings;

  const _MeetingStatusCard({required this.meetings});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Meeting Status',
      icon: Icons.event_note_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatPill(
                  label: 'B2B',
                  value: meetings.b2bTotal.toString(),
                  color: const Color(0xFFE65100)),
              const SizedBox(width: 12),
              _StatPill(
                  label: 'B2G',
                  value: meetings.b2gTotal.toString(),
                  color: const Color(0xFF6A1B9A)),
            ],
          ),
          if (meetings.byStatus.isNotEmpty) ...[
            const SizedBox(height: 16),
            _StatusChips(items: meetings.byStatus),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Orders card
// ---------------------------------------------------------------------------

class _OrdersCard extends StatelessWidget {
  final UserOrderSummary orders;

  const _OrdersCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Orders',
      icon: Icons.shopping_bag_outlined,
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              label: 'Total',
              value: orders.totalOrders.toString(),
              icon: Icons.receipt_long_outlined,
            ),
          ),
          Expanded(
            child: _MiniStat(
              label: 'Approved',
              value: orders.approvedOrders.toString(),
              icon: Icons.check_circle_outline,
              valueColor: AppTheme.successColor,
            ),
          ),
          Expanded(
            child: _MiniStat(
              label: 'Spent',
              value: '\$${orders.totalSpentUsd.toStringAsFixed(0)}',
              icon: Icons.attach_money,
              valueColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visa card
// ---------------------------------------------------------------------------

class _VisaCard extends StatelessWidget {
  final UserVisaSummary visa;

  const _VisaCard({required this.visa});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Visa Applications',
      icon: Icons.credit_card_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniStat(
            label: 'Applications',
            value: visa.totalApplications.toString(),
            icon: Icons.description_outlined,
          ),
          if (visa.byStatus.isNotEmpty) ...[
            const SizedBox(height: 16),
            _StatusChips(items: visa.byStatus),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Registration card
// ---------------------------------------------------------------------------

class _RegistrationCard extends StatelessWidget {
  final UserRegistrationSummary registration;

  const _RegistrationCard({required this.registration});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Registrations',
      icon: Icons.how_to_reg_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniStat(
            label: 'Total',
            value: registration.total.toString(),
            icon: Icons.people_outline,
          ),
          if (registration.byStatus.isNotEmpty) ...[
            const SizedBox(height: 16),
            _StatusChips(items: registration.byStatus),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Team member views card
// ---------------------------------------------------------------------------

class _TeamMemberViewsCard extends StatelessWidget {
  final List<TeamMemberViewRow> members;
  final int eventId;

  const _TeamMemberViewsCard({
    required this.members,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Team Member Views',
      icon: Icons.group_outlined,
      child: Column(
        children: [
          for (int i = 0; i < members.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  color: AppColors.inputBorder.withValues(alpha: 0.15)),
            _TeamMemberRow(
              member: members[i],
              rank: i + 1,
              onTap: () =>
                  context.push('/events/$eventId/team/${members[i].id}/edit'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamMemberRow extends StatelessWidget {
  final TeamMemberViewRow member;
  final int rank;
  final VoidCallback onTap;

  const _TeamMemberRow({
    required this.member,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundImage: member.photoUrl != null
                  ? NetworkImage(member.photoUrl!)
                  : null,
              backgroundColor:
                  AppTheme.primaryColor.withValues(alpha: 0.1),
              child: member.photoUrl == null
                  ? Text(
                      '${member.firstName.isNotEmpty ? member.firstName[0] : ''}${member.lastName.isNotEmpty ? member.lastName[0] : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${member.firstName} ${member.lastName}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    member.viewCount.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chips — colored by status
// ---------------------------------------------------------------------------

class _StatusChips extends StatelessWidget {
  final List<LabelCount> items;

  const _StatusChips({required this.items});

  static const _statusConfig = {
    'FILL_OUT': ('Fill Out', Color(0xFFFFF3E0), Color(0xFFE65100)),
    'NOT_STARTED': ('Not Started', Color(0xFFF5F5F5), Color(0xFF616161)),
    'PENDING': ('Pending', Color(0xFFFFF8E1), Color(0xFFF9A825)),
    'APPROVED': ('Approved', Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    'DECLINED': ('Declined', Color(0xFFFFEBEE), Color(0xFFC62828)),
    'CONFIRMED': ('Confirmed', Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    'CANCELLED': ('Cancelled', Color(0xFFFFEBEE), Color(0xFFC62828)),
    'SUBMITTED': ('Submitted', Color(0xFFE3F2FD), Color(0xFF1565C0)),
    'REJECTED': ('Rejected', Color(0xFFFFEBEE), Color(0xFFC62828)),
  };

  (String, Color, Color) _getConfig(String raw) {
    final config = _statusConfig[raw];
    if (config != null) return (config.$1, config.$2, config.$3);
    final formatted = raw
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
    return (formatted, AppColors.cardBackground, AppColors.textPrimary);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final (label, bgColor, textColor) = _getConfig(item.label);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$label (${item.count})',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat pill — small colored badge with label + value
// ---------------------------------------------------------------------------

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini stat — icon + label + value
// ---------------------------------------------------------------------------

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
