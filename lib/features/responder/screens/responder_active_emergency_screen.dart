import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../elderly/models/emergency_model.dart';
import '../providers/responder_provider.dart';
import '../../../shared/widgets/emergency_status_badge.dart';

class ResponderActiveEmergencyScreen extends ConsumerStatefulWidget {
  const ResponderActiveEmergencyScreen({super.key});

  @override
  ConsumerState<ResponderActiveEmergencyScreen> createState() => _ResponderActiveEmergencyScreenState();
}

class _ResponderActiveEmergencyScreenState extends ConsumerState<ResponderActiveEmergencyScreen> {
  final _resolutionNoteController = TextEditingController();
  String _selectedOutcome = 'ASSISTED';

  @override
  void dispose() {
    _resolutionNoteController.dispose();
    super.dispose();
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responderState = ref.watch(responderProvider);
    final emergency = responderState.assignedEmergency;

    if (emergency == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assigned Incident')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text('No Active Assigned Incident', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/responder'),
                child: const Text('Return to Command Feed'),
              ),
            ],
          ),
        ),
      );
    }

    final isArrived = emergency.status == EmergencyStatus.responderArrived;
    final isTerminal = emergency.status.isTerminal;
    final hasCoordinates = emergency.location != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Incident Mission'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(responderProvider.notifier).fetchEmergencyById(emergency.id);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: EmergencyStatusBadge(status: emergency.status.value)),
              const SizedBox(height: 16),

              // Status messages banner
              if (responderState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    responderState.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (responderState.actionSuccessMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    responderState.actionSuccessMessage!,
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Citizen In Distress Profile Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFFEE2E2),
                            child: Icon(Icons.person, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emergency.owner.displayName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Category: ${emergency.category.label}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (emergency.owner.phone != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.phone),
                          label: Text('Call ${emergency.owner.displayName} (${emergency.owner.phone})'),
                          onPressed: () => _callPhone(emergency.owner.phone!),
                        ),
                      ],
                      if (emergency.notes != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Note from citizen: "${emergency.notes}"',
                          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Exact Location Card (Released only after server-side assignment confirmed)
              Card(
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.location_on, color: Color(0xFF2563EB), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Exact Location (Unlocked)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (hasCoordinates) ...[
                        Text(
                          'Lat: ${emergency.location!.latitude.toStringAsFixed(5)}, Lng: ${emergency.location!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 15, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.navigation),
                          label: const Text('Open in Google Maps Navigation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _openMaps(
                            emergency.location!.latitude,
                            emergency.location!.longitude,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Waiting for coordinate payload authorization...',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Blockchain Attestation Card (Shared contract Section 11)
              Card(
                color: const Color(0xFFFAF5FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFC084FC), width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.link, color: Color(0xFF7E22CE), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Blockchain Audit Attestation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B21A8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Status: ${emergency.proof.status.value}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (emergency.proof.transactionHash != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tx: ${emergency.proof.transactionHash}',
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.blueGrey),
                        ),
                      ],
                      const SizedBox(height: 4),
                      const Text(
                        'Note: Proofs are queued asynchronously to audit arrival & resolution without blocking dispatch.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons:
              // 1. Mark Arrived (POST /emergencies/:id/arrive)
              if (!isArrived && !isTerminal) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.where_to_vote, size: 24),
                  label: const Text('Mark Arrived At Scene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: responderState.isLoading
                      ? null
                      : () async {
                          await ref.read(responderProvider.notifier).markArrived(emergency.id);
                        },
                ),
                const SizedBox(height: 12),
              ],

              // 2. Resolve Incident (POST /emergencies/:id/resolve)
              if (isArrived && !isTerminal) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Record Resolution Outcome',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedOutcome,
                          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Outcome'),
                          items: const [
                            DropdownMenuItem(value: 'ASSISTED', child: Text('Assisted Citizen Directly')),
                            DropdownMenuItem(
                                value: 'REFERRED_TO_EMERGENCY_SERVICES',
                                child: Text('Referred to 112 / Hospital')),
                            DropdownMenuItem(value: 'NO_CONTACT', child: Text('No Contact / False Alarm')),
                            DropdownMenuItem(value: 'OTHER', child: Text('Other Resolution')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedOutcome = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _resolutionNoteController,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Operational note (No sensitive clinical data)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Complete & Submit Resolution'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: responderState.isLoading
                              ? null
                              : () async {
                                  final ok = await ref.read(responderProvider.notifier).resolveEmergency(
                                        emergencyId: emergency.id,
                                        outcome: _selectedOutcome,
                                        note: _resolutionNoteController.text.trim(),
                                      );
                                  if (ok && context.mounted) {
                                    ref.read(responderProvider.notifier).clearAssigned();
                                    context.go('/responder');
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 3. Escalate Incident (POST /emergencies/:id/escalate)
              if (!isTerminal) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.warning, color: Colors.deepOrange),
                  label: const Text('Escalate (Need 108 / Extra Responders)', style: TextStyle(color: Colors.deepOrange)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.deepOrange)),
                  onPressed: () async {
                    await ref.read(responderProvider.notifier).escalateEmergency(
                          emergency.id,
                          'Responder requested additional medical personnel / ambulance',
                        );
                  },
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    ref.read(responderProvider.notifier).clearAssigned();
                    context.go('/responder');
                  },
                  child: const Text('Return to Responder Feed'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
