import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ActionStatusCard extends StatefulWidget {
  const ActionStatusCard({super.key});

  @override
  State<ActionStatusCard> createState() => _ActionStatusCardState();
}

class _ActionStatusCardState extends State<ActionStatusCard> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _currentTime = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date
        Text(
          DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_currentTime),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // Big Time
        Text(
          DateFormat('HH.mm').format(_currentTime),
          style: const TextStyle(
            fontSize: 72, // Even bigger
            fontWeight: FontWeight.w900,
            color: Colors.black,
            height: 1,
            letterSpacing: -2, // Tighten spacing
          ),
        ),
        const SizedBox(height: 8),

        // Location
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.location_on_outlined, color: Colors.black87, size: 20),
            SizedBox(width: 8),
            Text(
              'Kantor Walikota',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
