import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../auth/services/auth_service.dart';
import '../services/meeting_service.dart';

class MeetingRequestPage extends StatefulWidget {
  const MeetingRequestPage({super.key});

  @override
  State<MeetingRequestPage> createState() => _MeetingRequestPageState();
}

class _MeetingRequestPageState extends State<MeetingRequestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String _subject = '';
  final String _location = 'Main Hall';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _targetCompanyId;
  int? _targetGovEntityId;

  // Data
  List<dynamic> _participants = [];
  List<dynamic> _govEntities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<MeetingService>();
      final participants = await service.fetchParticipants();
      final govEntities = await service.fetchGovEntities();
      setState(() {
        _participants = participants;
        _govEntities = govEntities;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final type = _tabController.index == 0 ? "B2B" : "B2G";
    if (type == "B2B" && _targetCompanyId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a company')));
      return;
    }
    if (type == "B2G" && _targetGovEntityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a government entity')),
      );
      return;
    }

    // Combine date and time
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final endDateTime = startDateTime.add(
      const Duration(hours: 1),
    ); // Default 1 hour

    setState(() => _isLoading = true);
    try {
      final data = {
        "subject": _subject,
        "type": type,
        "start_time": startDateTime.toIso8601String(),
        "end_time": endDateTime.toIso8601String(),
        "location": _location,
        if (type == "B2B") "target_company_id": _targetCompanyId,
        if (type == "B2G") "target_gov_entity_id": _targetGovEntityId,
      };

      await context.read<MeetingService>().createMeeting(data);
      if (mounted) {
        context.pop(); // Go back to list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting requested successfully!')),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProxyProvider<AuthService, MeetingService>(
      update: (_, auth, __) => MeetingService(auth),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Request Meeting",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: const Color(0xFF3C4494),
            tabs: const [
              Tab(text: "B2B (Company)"),
              Tab(text: "B2G (Government)"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFormContent(isB2B: true),
                    _buildFormContent(isB2B: false),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFormContent({required bool isB2B}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Target Selector
          if (isB2B) ...[
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Select Company",
                border: OutlineInputBorder(),
              ),
              items: _participants
                  .map(
                    (p) => DropdownMenuItem<int>(
                      value: p['id'],
                      child: Text(p['name'] ?? 'Unknown'),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _targetCompanyId = val),
            ),
          ] else ...[
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Select Gov Entity",
                border: OutlineInputBorder(),
              ),
              items: _govEntities
                  .map(
                    (g) => DropdownMenuItem<int>(
                      value: g['id'],
                      child: Text(g['name'] ?? 'Unknown'),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _targetGovEntityId = val),
            ),
          ],
          const SizedBox(height: 20),

          // Subject
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Subject / Topic",
              border: OutlineInputBorder(),
            ),
            validator: (val) => val == null || val.isEmpty ? "Required" : null,
            onSaved: (val) => _subject = val!,
          ),
          const SizedBox(height: 20),

          // Date & Time
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2026),
                      initialDate: _selectedDate,
                    );
                    if (d != null) setState(() => _selectedDate = d);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text("${_selectedDate.toLocal()}".split(' ')[0]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (t != null) setState(() => _selectedTime = t);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(_selectedTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Submit
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C4494),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text("Send Request", style: GoogleFonts.inter(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
