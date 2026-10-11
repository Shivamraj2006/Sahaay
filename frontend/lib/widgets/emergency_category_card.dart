import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/emergency.dart';

class EmergencyCategoryCard extends StatelessWidget {
  final EmergencyCategory category;
  final VoidCallback onTap;

  const EmergencyCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color iconBg;
    String line1;
    String line2;

    switch (category) {
      case EmergencyCategory.medical:
        icon = Icons.favorite;
        iconColor = AppColors.brandRed;
        iconBg = AppColors.medicalBg;
        line1 = 'Medical';
        line2 = 'Emergency';
        break;
      case EmergencyCategory.fallInjury:
        icon = Icons.directions_walk;
        iconColor = AppColors.fallIcon;
        iconBg = AppColors.fallBg;
        line1 = 'Fall /';
        line2 = 'Injury';
        break;
      case EmergencyCategory.hospitalAssistance:
        icon = Icons.local_hospital;
        iconColor = AppColors.brandRedDark;
        iconBg = AppColors.hospitalBg;
        line1 = 'Need';
        line2 = 'Hospital';
        break;
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.slate900.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBg,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                line1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.slate900,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              Text(
                line2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.slate900,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
