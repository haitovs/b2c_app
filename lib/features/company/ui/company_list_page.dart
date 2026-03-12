import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../models/company.dart';
import '../models/user_limits.dart';
import '../providers/company_providers.dart';

/// "My Companies Profiles" — table listing all user companies for the event.
class CompanyListPage extends ConsumerStatefulWidget {
  const CompanyListPage({super.key});

  @override
  ConsumerState<CompanyListPage> createState() => _CompanyListPageState();
}

class _CompanyListPageState extends ConsumerState<CompanyListPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '';
    final eventId = int.tryParse(eventIdStr) ?? 0;
    final companiesAsync = ref.watch(myCompaniesProvider(eventId));

    // Dynamic limits
    final limitsAsync = ref.watch(userLimitsProvider(eventId));
    final maxCompanies = limitsAsync.when(
      data: (l) => l.maxCompanies,
      loading: () => UserLimits.defaults.maxCompanies,
      error: (_, __) => UserLimits.defaults.maxCompanies,
    );

    return companiesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, _) => _buildError(error, eventId),
      data: (companies) =>
          _buildBody(companies, eventIdStr, eventId, maxCompanies),
    );
  }

  Widget _buildError(Object error, int eventId) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Failed to load companies',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(error.toString(),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(myCompaniesProvider(eventId)),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      List<Company> companies, String eventIdStr, int eventId, int maxCompanies) {
    final filtered = _searchQuery.isEmpty
        ? companies
        : companies.where((c) {
            final q = _searchQuery.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                (c.email ?? '').toLowerCase().contains(q) ||
                (c.mobile ?? '').contains(q) ||
                (c.categories ?? []).any((cat) => cat.toLowerCase().contains(q));
          }).toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row + Add button
          Row(
            children: [
              Expanded(
                child: Text(
                  isMobile ? 'My Companies' : 'My Companies Profiles',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              if (companies.length < maxCompanies)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('/events/$eventIdStr/company-profile/add'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Search bar + Sort
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search companies...',
                    hintStyle:
                        GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Sort by: All',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.expand_more,
                        size: 18, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table / Card list
          Expanded(
            child: companies.isEmpty
                ? _buildEmptyState(eventIdStr)
                : isMobile
                    ? _buildMobileList(filtered, eventIdStr, eventId)
                    : _buildTable(filtered, eventIdStr, eventId),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String eventIdStr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No companies yet',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first company to get started',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                context.go('/events/$eventIdStr/company-profile/add'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Company'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(
      List<Company> companies, String eventIdStr, int eventId) {
    return ListView.separated(
      itemCount: companies.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final company = companies[index];
        final category = company.categories?.isNotEmpty == true
            ? company.categories!.first
            : '';
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: company.brandIconUrl != null
                ? Image.network(company.brandIconUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.business, size: 18, color: Colors.grey.shade400))
                : Icon(Icons.business, size: 18, color: Colors.grey.shade400),
          ),
          title: Text(
            company.name,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: category.isNotEmpty
              ? Text(category,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey))
              : null,
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  context.go('/events/$eventIdStr/company-profile/${company.id}/edit');
                case 'preview':
                  context.go('/events/$eventIdStr/company-profile/${company.id}/preview');
                case 'delete':
                  _confirmDelete(company, eventId);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text('Edit', style: GoogleFonts.inter(fontSize: 14))),
              PopupMenuItem(value: 'preview', child: Text('Preview', style: GoogleFonts.inter(fontSize: 14))),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: GoogleFonts.inter(fontSize: 14, color: Colors.red)),
              ),
            ],
          ),
          onTap: () => context.go('/events/$eventIdStr/company-profile/${company.id}/edit'),
        );
      },
    );
  }

  Widget _buildTable(
      List<Company> companies, String eventIdStr, int eventId) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Name of company',
                      style: _headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Category:', style: _headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Email', style: _headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Number', style: _headerStyle),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Data rows
          Expanded(
            child: ListView.separated(
              itemCount: companies.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                final company = companies[index];
                return _buildRow(company, eventIdStr, eventId);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Company company, String eventIdStr, int eventId) {
    final category =
        company.categories?.isNotEmpty == true ? company.categories!.first : '';

    return InkWell(
      onTap: () => context.go(
          '/events/$eventIdStr/company-profile/${company.id}/edit'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Logo + Name
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  // Company logo
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: company.brandIconUrl != null
                        ? Image.network(
                            company.brandIconUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.business,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : Icon(Icons.business,
                            size: 18, color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      company.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Category
            Expanded(
              flex: 2,
              child: Text(
                category,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Email
            Expanded(
              flex: 2,
              child: Text(
                company.email ?? '',
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Number
            Expanded(
              flex: 2,
              child: Text(
                company.mobile ?? '',
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // More menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 20, color: Colors.grey.shade600),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.go(
                        '/events/$eventIdStr/company-profile/${company.id}/edit');
                  case 'preview':
                    context.go(
                        '/events/$eventIdStr/company-profile/${company.id}/preview');
                  case 'delete':
                    _confirmDelete(company, eventId);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text('Edit', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'preview',
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text('Preview', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Delete',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Company company, int eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text('Are you sure you want to delete "${company.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(companyServiceProvider).deleteCompany(company.id);
      ref.invalidate(myCompaniesProvider(eventId));
      if (!mounted) return;
      AppSnackBar.showSuccess(context, '"${company.name}" deleted');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Failed to delete: $e');
    }
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      );
}
