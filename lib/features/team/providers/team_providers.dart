import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/team_member.dart';
import '../services/team_service.dart';

/// Provider for TeamService.
final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService(ref.watch(authApiClientProvider));
});

/// Fetch all team members for a given company.
final teamMembersProvider =
    FutureProvider.family<List<TeamMember>, String>((ref, companyId) {
  return ref.watch(teamServiceProvider).getTeamMembers(companyId);
});
