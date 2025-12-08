import 'dart:async';

import 'package:flutter/material.dart';

class EventCard extends StatefulWidget {
  final String title;
  final String date;
  final String location;
  final String imageUrl;
  final String? logoUrl;
  final DateTime eventStartTime;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.title,
    required this.date,
    required this.location,
    required this.imageUrl,
    this.logoUrl,
    required this.eventStartTime,
    this.onTap,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  Timer? _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  @override
  void didUpdateWidget(EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate timer if eventStartTime changed
    if (oldWidget.eventStartTime != widget.eventStartTime) {
      _timer?.cancel();
      _initTimer();
    }
  }

  void _initTimer() {
    _calculateTimeLeft();
    if (_timeLeft > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _calculateTimeLeft();
      });
    }
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (widget.eventStartTime.isAfter(now)) {
      setState(() {
        _timeLeft = widget.eventStartTime.difference(now);
      });
    } else {
      if (_timer != null) {
        setState(() {
          _timeLeft = Duration.zero;
        });
        _timer!.cancel();
      } else {
        _timeLeft = Duration.zero;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on width
        final isMobile = constraints.maxWidth < 900;

        return Container(
          width: 1310,
          // Let height be dynamic on mobile, fixed on desktop
          height: isMobile ? null : 242,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF5460CD), // Primary Blue/Purple color
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              color: Color(0xFF151938), // Dark text
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // 1. Details Section (Left) - Flex 4
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.only(
              left: 30,
              right: 15,
              top: 30,
              bottom: 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // Logo Container
                    Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(5),
                      child: widget.logoUrl != null
                          ? Image.network(
                              widget.logoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(),
                            )
                          : Container(),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          color: Color(0xFF151938),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow(Icons.calendar_today_outlined, widget.date),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.location_on_outlined, widget.location),
              ],
            ),
          ),
        ),

        // 2. Image Section (Center) - Flex 3
        Expanded(
          flex: 3,
          child: SizedBox(
            height: double.infinity,
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
            ),
          ),
        ),

        // 3. Timer Section (Right) - Flex 4
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5460CD), Color(0xFF352675)],
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Starting in:",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: _buildTimerDisplay(isMobile: false),
                    ),
                    const SizedBox(height: 20),
                    _buildLearnMore(isMobile: false),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 1. Details (Top) - Title and Info
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(5),
                    child: widget.logoUrl != null
                        ? Image.network(
                            widget.logoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(),
                          )
                        : Container(),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Color(0xFF151938),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.calendar_today_outlined, widget.date),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.location_on_outlined, widget.location),
            ],
          ),
        ),

        // 2. Image (Middle)
        Container(
          height: 200,
          width: double.infinity,
          color: Colors.white,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
          ),
        ),

        // 3. Timer (Bottom)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5460CD), Color(0xFF352675)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              const Text(
                "Starting in:",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: _buildTimerDisplay(isMobile: true),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: _buildLearnMore(isMobile: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay({required bool isMobile}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeUnit(_timeLeft.inDays, "Days", isMobile),
        _buildSeparator(isMobile),
        _buildTimeUnit(_timeLeft.inHours % 24, "Hours", isMobile),
        _buildSeparator(isMobile),
        _buildTimeUnit(_timeLeft.inMinutes % 60, "Minutes", isMobile),
        _buildSeparator(isMobile),
        _buildTimeUnit(_timeLeft.inSeconds % 60, "Second", isMobile),
      ],
    );
  }

  Widget _buildLearnMore({required bool isMobile}) {
    return InkWell(
      onTap: widget.onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            "Learn More",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label, bool isMobile) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 24 : 36,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w400,
            fontSize: 10,
            color: Color.fromRGBO(255, 255, 255, 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: isMobile ? 30 : 40,
      alignment: Alignment.topCenter,
      child: Text(
        ":",
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 24 : 36,
          color: Colors.white,
        ),
      ),
    );
  }
}
