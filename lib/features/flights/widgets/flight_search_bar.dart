import 'package:flutter/material.dart';

/// Search bar widget for flight search.
class FlightSearchBar extends StatefulWidget {
  final String? initialOrigin;
  final String? initialDestination;
  final VoidCallback? onSearch;
  final Function(String origin, String destination)? onSwap;
  final Function(String)? onOriginChanged;
  final Function(String)? onDestinationChanged;
  final Function(DateTime)? onDateChanged;
  final Function(int)? onPassengersChanged;

  const FlightSearchBar({
    super.key,
    this.initialOrigin,
    this.initialDestination,
    this.onSearch,
    this.onSwap,
    this.onOriginChanged,
    this.onDestinationChanged,
    this.onDateChanged,
    this.onPassengersChanged,
  });

  @override
  State<FlightSearchBar> createState() => _FlightSearchBarState();
}

class _FlightSearchBarState extends State<FlightSearchBar> {
  late TextEditingController _originController;
  late TextEditingController _destinationController;
  DateTime? _selectedDate;
  int _passengers = 1;

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: widget.initialOrigin ?? '');
    _destinationController = TextEditingController(
      text: widget.initialDestination ?? '',
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    final temp = _originController.text;
    _originController.text = _destinationController.text;
    _destinationController.text = temp;
    widget.onSwap?.call(_originController.text, _destinationController.text);
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3C4494)),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      widget.onDateChanged?.call(date);
    }
  }

  void _selectPassengers() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _PassengerDialog(initialValue: _passengers),
    );
    if (result != null) {
      setState(() => _passengers = result);
      widget.onPassengersChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE1E3EE),
            borderRadius: BorderRadius.circular(15),
          ),
          child: isCompact ? _buildCompactLayout() : _buildWideLayout(),
        );
      },
    );
  }

  /// Compact layout for mobile screens - single row with truncated fields
  Widget _buildCompactLayout() {
    return Row(
      children: [
        // Origin - compact
        Expanded(
          child: _buildCompactInputField(
            controller: _originController,
            icon: Icons.location_on_outlined,
            hint: 'Ori...',
          ),
        ),

        // Swap button - smaller
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3),
            ],
          ),
          child: IconButton(
            onPressed: _swapLocations,
            icon: const Icon(Icons.swap_horiz, size: 16),
            color: const Color(0xFF3C4494),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ),

        // Destination - compact
        Expanded(
          child: _buildCompactInputField(
            controller: _destinationController,
            icon: Icons.location_on_outlined,
            hint: 'De...',
          ),
        ),

        const SizedBox(width: 4),

        // Date picker - compact
        Expanded(
          child: _buildCompactClickableField(
            icon: Icons.calendar_today_outlined,
            text: _selectedDate != null
                ? '${_selectedDate!.day}/${_selectedDate!.month}'
                : 'Ch...',
            onTap: _selectDate,
          ),
        ),

        const SizedBox(width: 4),

        // Passengers - compact
        _buildCompactClickableField(
          icon: Icons.person_outline,
          text: '$_passengers',
          onTap: _selectPassengers,
          width: 50,
        ),

        const SizedBox(width: 4),

        // Search button - compact
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF3C4494),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: widget.onSearch,
            icon: const Icon(Icons.search, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  /// Wide layout for larger screens
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Origin
        Expanded(
          flex: 2,
          child: _buildInputField(
            controller: _originController,
            icon: Icons.location_on_outlined,
            hint: 'Origin',
            onChanged: widget.onOriginChanged,
          ),
        ),

        // Swap button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
            ],
          ),
          child: IconButton(
            onPressed: _swapLocations,
            icon: const Icon(Icons.swap_horiz, size: 20),
            color: const Color(0xFF3C4494),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
        ),

        // Destination
        Expanded(
          flex: 2,
          child: _buildInputField(
            controller: _destinationController,
            icon: Icons.location_on_outlined,
            hint: 'Destination',
            onChanged: widget.onDestinationChanged,
          ),
        ),

        const SizedBox(width: 8),

        // Date picker
        Expanded(
          flex: 2,
          child: _buildClickableField(
            icon: Icons.calendar_today_outlined,
            text: _selectedDate != null
                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                : 'Check In / Check Out',
            onTap: _selectDate,
          ),
        ),

        const SizedBox(width: 8),

        // Passengers
        _buildClickableField(
          icon: Icons.person_outline,
          text: '$_passengers',
          onTap: _selectPassengers,
          width: 70,
        ),

        const SizedBox(width: 8),

        // Search button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3C4494),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: widget.onSearch,
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// Compact input field for mobile
  Widget _buildCompactInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: const TextStyle(fontSize: 12),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact clickable field for mobile
  Widget _buildCompactClickableField({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    double? width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    Function(String)? onChanged,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableField({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    double? width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerDialog extends StatefulWidget {
  final int initialValue;

  const _PassengerDialog({required this.initialValue});

  @override
  State<_PassengerDialog> createState() => _PassengerDialogState();
}

class _PassengerDialogState extends State<_PassengerDialog> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Passengers'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _value > 1 ? () => setState(() => _value--) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_value',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: _value < 9 ? () => setState(() => _value++) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _value),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3C4494),
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
