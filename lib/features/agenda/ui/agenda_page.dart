import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../notifications/ui/notification_drawer.dart';
import '../../profile/ui/profile_dialog.dart';
import '../services/tourism_service.dart';

class AgendaPage extends StatefulWidget {
  final String id;
  const AgendaPage({super.key, required this.id});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final _tourismService = TourismService();
  List<dynamic> _agendaItems = [];
  bool _isLoading = true;
  String _selectedTab = 'program'; // program, favourite
  String _selectedDate = '21'; // 21, 22, 23
  String _selectedHall = 'All';

  @override
  void initState() {
    super.initState();
    _loadAgenda();
  }

  Future<void> _loadAgenda() async {
    final items = await _tourismService.getAgenda(widget.id);
    setState(() {
      _agendaItems = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      body: Stack(
        children: [
          // Header
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFF1F1F6),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFF1F1F6),
                    ),
                  ),
                ),
                const SizedBox(width: 40),

                // Title
                Text(
                  AppLocalizations.of(context)!.agenda,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 40,
                    color: const Color(0xFFF1F1F6),
                  ),
                ),
                const SizedBox(width: 40),

                // Toggle
                Container(
                  width: 432,
                  height: 64,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 'program'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedTab == 'program'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(context)!.program,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                                fontSize: 26,
                                color: _selectedTab == 'program'
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedTab = 'favourite'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedTab == 'favourite'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(context)!.favourite,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                                fontSize: 26,
                                color: _selectedTab == 'favourite'
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Icons
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Scaffold.of(context).openEndDrawer(),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ProfileDialog(),
                        );
                      },
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Positioned(
            top: 164,
            left: 50,
            right: 50,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F6).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFFF1F1F6), size: 36),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        color: const Color(0xFFF1F1F6),
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.searchByEventName,
                        hintStyle: GoogleFonts.roboto(
                          fontSize: 20,
                          color: const Color(0xFFF1F1F6),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filters
          Positioned(
            top: 253,
            left: 50,
            right: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Halls
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        AppLocalizations.of(context)!.all,
                        'All',
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        AppLocalizations.of(context)!.forumHall,
                        'Forum Hall',
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        AppLocalizations.of(context)!.presentationHall,
                        'Presentation Hall',
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        AppLocalizations.of(context)!.hall50A,
                        'Hall 50A',
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        AppLocalizations.of(context)!.hall50B,
                        'Hall 50B',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Dates
                Row(
                  children: [
                    _buildDateChip('21', AppLocalizations.of(context)!.monday),
                    const SizedBox(width: 20),
                    _buildDateChip('22', AppLocalizations.of(context)!.tuesday),
                    const SizedBox(width: 20),
                    _buildDateChip(
                      '23',
                      AppLocalizations.of(context)!.wednesday,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content List
          Positioned(
            top: 441,
            left: 50,
            right: 50,
            bottom: 0,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _agendaItems.length,
                    itemBuilder: (context, index) {
                      final item = _agendaItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: _buildAgendaItem(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedHall == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedHall = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 47, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF151A4A) : const Color(0xFF9CA4CC),
          borderRadius: BorderRadius.circular(41.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            fontSize: 33,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String day, String label) {
    final isSelected = _selectedDate == day;
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = day),
      child: Container(
        width: isSelected ? 171 : 176,
        height: 61,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF151A4A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: GoogleFonts.roboto(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 25,
                color: isSelected
                    ? const Color(0xFFF4F4F2)
                    : const Color(0xFF20306C),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 2,
              height: 45,
              color: isSelected
                  ? const Color(0xFFF4F4F2)
                  : const Color(0xFF20306C),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 25,
                color: isSelected
                    ? const Color(0xFFF4F4F2)
                    : const Color(0xFF20306C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaItem(BuildContext context, dynamic item) {
    return SizedBox(
      height: 1235, // Fixed height from design, but should ideally be dynamic
      child: Stack(
        children: [
          // Time Card
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 236,
              height: 83,
              decoration: BoxDecoration(
                color: const Color(0xFF9CA4CC),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                "${item['start_time']}-${item['end_time']}",
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w700,
                  fontSize: 33,
                  color: const Color(0xFFF1F1F6),
                ),
              ),
            ),
          ),

          // Details Card
          Positioned(
            left: 271, // 321 - 50
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Star
                  const Positioned(
                    top: 15,
                    right: 15,
                    child: Icon(
                      Icons.star_border,
                      size: 30,
                      color: Color(0xFF949494),
                    ),
                  ),

                  // Date & Location
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Row(
                      children: [
                        _buildInfoChip(Icons.calendar_today, item['date']),
                        const SizedBox(width: 15),
                        _buildInfoChip(Icons.location_on, item['location']),
                      ],
                    ),
                  ),

                  // Title
                  Positioned(
                    top: 106,
                    left: 0,
                    right: 0,
                    child: Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 35,
                        color: const Color(0xFF151938),
                      ),
                    ),
                  ),

                  // Moderator & Sponsor
                  if (item['moderator'] != null) ...[
                    Positioned(
                      top: 175,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 130,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppLocalizations.of(context)!.moderator,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            item['moderator']['name'],
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              color: const Color(0xFF3C4494),
                            ),
                          ),
                          Text(
                            item['moderator']['title'],
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: const Color(0xFF3C4494),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Description
                  Positioned(
                    top: 539,
                    left: 115,
                    right: 115,
                    child: Text(
                      item['description'],
                      style: GoogleFonts.roboto(fontSize: 20, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Speakers
                  if (item['speakers'] != null) ...[
                    Positioned(
                      bottom: 400,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.speakers,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: 25,
                            color: const Color(0xFF151938),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50,
                      left: 50,
                      right: 50,
                      height: 312,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: (item['speakers'] as List).length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) =>
                            _buildSpeakerCard(item['speakers'][index]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF9CA4CC)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF9CA4CC)),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.roboto(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSpeakerCard(dynamic speaker) {
    return Container(
      width: 211,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    speaker['name'],
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    speaker['title'],
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
