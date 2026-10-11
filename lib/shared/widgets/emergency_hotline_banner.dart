import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyHotlineBanner extends StatelessWidget {
  const EmergencyHotlineBanner({super.key});

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF87171), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 22),
              SizedBox(width: 8),
              Text(
                'Public Emergency Services',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Sahaay complements official responders. If in immediate danger, dial national emergency helplines directly:',
            style: TextStyle(fontSize: 13, color: Color(0xFF7F1D1D), height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.call, color: Color(0xFFDC2626), size: 18),
                  label: const Text('Dial 112 (All Emergency)', style: TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 42),
                  ),
                  onPressed: () => _makeCall('112'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.local_hospital, color: Color(0xFFDC2626), size: 18),
                  label: const Text('Dial 108 (Ambulance)', style: TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 42),
                  ),
                  onPressed: () => _makeCall('108'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
