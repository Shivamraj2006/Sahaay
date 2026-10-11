import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Emergency History'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.slate100, height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHistoryItem(
              title: 'Fall / Injury Assistance',
              date: '10 Oct 2026, 4:15 PM',
              outcome: 'Resolved: Assisted by Rahul Sharma',
              txHash: '0xe9f50cb90e7a1e0b...',
              isConfirmed: true,
            ),
            const SizedBox(height: 12),
            _buildHistoryItem(
              title: 'Medical Check Alert',
              date: '28 Sep 2026, 11:30 AM',
              outcome: 'Resolved: Assisted by Dr. Meera Iyer',
              txHash: '0xc1d4e7f9a2b5e8c3...',
              isConfirmed: true,
            ),
            const SizedBox(height: 12),
            _buildHistoryItem(
              title: 'Hospital Assistance',
              date: '14 Sep 2026, 8:45 AM',
              outcome: 'Referred to Emergency Services (108)',
              txHash: '0xf8a2c4e6b1d3f5a7...',
              isConfirmed: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String date,
    required String outcome,
    required String txHash,
    required bool isConfirmed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
              ),
              if (isConfirmed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandSuccessLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 12, color: AppColors.brandSuccess),
                      SizedBox(width: 4),
                      Text(
                        'ON-CHAIN AUDITED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 8),
          Text(
            outcome,
            style: const TextStyle(fontSize: 13, color: AppColors.slate700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tx: $txHash',
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}
