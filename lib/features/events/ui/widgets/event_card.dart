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
            borderRadius: BorderRadius.circular(5),
          ),
          child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        Row(
          children: [
            // 1. Details Section (Left)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.logoUrl != null
                              ? Image.network(
                                  widget.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: Colors.blue[100]),
                                )
                              : Container(color: Colors.blue[100]),
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                              fontSize: 22,
                              color: Color(0xFF151938),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Image Section (Center)
            Container(
              width: 400,
              height: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200]),
              alignment: Alignment.center,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                width: 400,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    Text("No Image", style: TextStyle(color: Colors.grey[600])),
              ),
            ),

            // 3. Timer Section (Right)
            Container(
              width: 380,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF5460CD),
                    Color(0xFF3A49D0),
                    Color(0xFF1C045F),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Starting in:",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTimerDisplay(isMobile: false),
                  const SizedBox(height: 30),
                  _buildLearnMore(isMobile: false),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 1. Image (Top)
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            errorBuilder: (context, error, stackTrace) =>
                Text("No Image", style: TextStyle(color: Colors.grey[600])),
          ),
        ),

        // 2. Details (Middle)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.logoUrl != null
                        ? Image.network(
                            widget.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.blue[100]),
                          )
                        : Container(color: Colors.blue[100]),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        color: Color(0xFF151938),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.date,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    widget.location,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Timer (Bottom)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5460CD), Color(0xFF3A49D0), Color(0xFF1C045F)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Column(
            children: [
              const Text(
                "Starting in:",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              _buildTimerDisplay(isMobile: true),
              const SizedBox(height: 20),
              _buildLearnMore(isMobile: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay({required bool isMobile}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 15 : 10,
        horizontal: isMobile ? 10 : 0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // shrink wrap on mobile
        children: [
          _buildTimeUnit(_timeLeft.inDays, "Days", isMobile),
          _buildSeparator(isMobile),
          _buildTimeUnit(_timeLeft.inHours % 24, "Hours", isMobile),
          _buildSeparator(isMobile),
          _buildTimeUnit(_timeLeft.inMinutes % 60, "Min", isMobile),
          _buildSeparator(isMobile),
          _buildTimeUnit(_timeLeft.inSeconds % 60, "Sec", isMobile),
        ],
      ),
    );
  }

  Widget _buildLearnMore({required bool isMobile}) {
    return InkWell(
      onTap: widget.onTap,
      child: Row(
        mainAxisAlignment: isMobile
            ? MainAxisAlignment.center
            : MainAxisAlignment.end,
        children: [
          Text(
            "Learn More",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: isMobile ? 16 : 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          if (!isMobile) const SizedBox(width: 20),
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
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 24 : 28,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 10,
            color: Color.fromRGBO(255, 255, 255, 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      height: isMobile ? 30 : 35,
      alignment: Alignment.topCenter,
      child: Text(
        ":",
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 24 : 28,
          color: Colors.white,
        ),
      ),
    );
  }
}
