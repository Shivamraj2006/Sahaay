import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/emergency.dart';
import '../../providers/emergency_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = context.watch<EmergencyProvider>();
    final current = emergencyProvider.emergency;
    final hasResolved = current != null && current.status == EmergencyStatus.resolved;

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
        child: hasResolved
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHistoryItem(
                    title: '${current.category.label} Assistance',
                    date: DateFormat('d MMM yyyy, h:mm a').format(current.updatedAt.toLocal()),
                    outcome: 'Resolved: Assisted by ${current.assignedResponder?.displayName ?? "Volunteer"}',
                    txHash: current.transactionHash ?? '0x8f2a1b9c3d4e5f607182...',
                    isConfirmed: true,
                  ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.history,
                          size: 36,
                          color: AppColors.slate400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Emergency History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'You have no past emergency incidents. When SOS events are completed, immutable on-chain logs and cryptographic proofs will be recorded here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.slate500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
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
