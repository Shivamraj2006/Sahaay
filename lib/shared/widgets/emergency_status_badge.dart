import 'package:flutter/material.dart';

class EmergencyStatusBadge extends StatelessWidget {
  final String status;

  const EmergencyStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        icon = Icons.campaign_rounded;
        label = 'SOS ACTIVE — SEEKING RESPONDER';
        break;
      case 'ASSIGNED':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = Icons.person_pin_circle_rounded;
        label = 'RESPONDER ASSIGNED';
        break;
      case 'RESPONDER_ARRIVED':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        icon = Icons.health_and_safety_rounded;
        label = 'RESPONDER ARRIVED';
        break;
      case 'ESCALATED':
        bg = const Color(0xFFFCE7F3);
        fg = const Color(0xFFBE185D);
        icon = Icons.warning_amber_rounded;
        label = 'ESCALATED / SUPPORT INVOLVED';
        break;
      case 'RESOLVED':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        icon = Icons.check_circle_rounded;
        label = 'RESOLVED';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        icon = Icons.cancel_outlined;
        label = 'CANCELLED';
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.black87;
        icon = Icons.info_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fg.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
