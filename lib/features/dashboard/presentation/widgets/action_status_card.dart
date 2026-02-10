import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart' as du;

class ActionStatusCard extends StatefulWidget {
  final String? locationName;
  const ActionStatusCard({super.key, this.locationName});

  @override
  State<ActionStatusCard> createState() => _ActionStatusCardState();
}

class _ActionStatusCardState extends State<ActionStatusCard> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
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

  String _formatLocation(String? location) {
    if (location == null) return "Memuat Lokasi...";

    // 1. Basic usage of abbreviation
    String formatted = location
        .replaceAll(RegExp(r'\bJalan\b', caseSensitive: false), 'Jl.')
        .replaceAll(RegExp(r'\bDokter\b', caseSensitive: false), 'Dr.');

    // 2. Check length (threshold ~35 characters)
    if (formatted.length > 35) {
      // If contains comma, try to take the part after the first comma
      if (location.contains(',')) {
        final parts = location.split(',');
        // Strategy: Drop the first part (Street Name)
        // Heuristic: If we have at least 2 parts, return the rest
        if (parts.length > 1) {
          return parts.sublist(1).join(',').trim();
        }
      }
    }

    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date (Kamis, 15 Jan 2026) - Smaller
        Text(
          du.DateUtils.formatDate(_currentTime),
          style: const TextStyle(
            fontSize: 14, // Smaller
            fontWeight: FontWeight.w500,
            color: Colors.white70, // Less opacity
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),

        // Huge Realtime Clock (Fitted)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            du.DateUtils.formatTime(_currentTime),
            style: const TextStyle(
              fontSize: 64, // Reduced from 80
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
              letterSpacing: -2,
              shadows: [
                Shadow(
                  color: Colors.black45, // Stronger shadow
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Location Info - Compact & White
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Compact
          children: [
            // Glassy Icon container or just icon? User said "Ikon + teks lebih rapat"
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _formatLocation(widget.locationName),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
