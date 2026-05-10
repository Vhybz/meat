import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../services/butcher_service.dart';

class WasteManagementScreen extends ConsumerWidget {
  const WasteManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wasteAsync = ref.watch(butcherWasteProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Waste & By-Product Control', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Recording and monitoring slaughterhouse disposal', style: TextStyle(color: AppColors.textLight)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showRecordWasteDialog(context, ref),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Record Waste'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildWasteDashboard(wasteAsync),
          const SizedBox(height: AppSpacing.l),
          _buildRecentDisposals(wasteAsync),
        ],
      ),
    );
  }

  Widget _buildWasteDashboard(AsyncValue<List<Map<String, dynamic>>> wasteAsync) {
    return wasteAsync.when(
      data: (waste) {
        final totalWeight = waste.fold(0.0, (sum, w) => sum + (w['weight'] as num).toDouble());
        return Row(
          children: [
            _wasteStatCard('Total Waste (All Time)', '${totalWeight.toStringAsFixed(1)} kg', 'Real-time', Colors.red),
            _wasteStatCard('Last Entry', waste.isEmpty ? 'N/A' : '${(waste.first['weight'] as num).toDouble()} kg', 'Recent', Colors.green),
            _wasteStatCard('Records', '${waste.length}', 'Total logs', Colors.blue),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, error) => const Text('Error loading stats'),
    );
  }

  Widget _wasteStatCard(String title, String value, String trend, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(trend, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDisposals(AsyncValue<List<Map<String, dynamic>>> wasteAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Records', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.m),
            wasteAsync.when(
              data: (waste) {
                if (waste.isEmpty) return const Text('No waste records found.');
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: waste.length,
                  itemBuilder: (context, index) {
                    final w = waste[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.surfaceWhite, shape: BoxShape.circle),
                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      ),
                      title: Text('${w['reason']} - Batch ${w['batch_id'] ?? "Manual"}'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(w['recorded_at']))),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${(w['weight'] as num).toDouble()} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Text('Disposed', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordWasteDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    final weightController = TextEditingController();
    String? selectedBatchId;
    
    final batchesAsync = ref.read(meatBatchesProvider);
    final activeBatches = batchesAsync.value ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: const Text('Record Waste'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason (e.g. Bone trimmings)', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid weight';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Batch (Optional)', border: OutlineInputBorder()),
                items: activeBatches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.id))).toList(),
                onChanged: (v) => selectedBatchId = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ref.read(butcherWasteProvider.notifier).addWaste(
                  selectedBatchId ?? 'MANUAL', 
                  reasonController.text, 
                  double.tryParse(weightController.text) ?? 0
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
            child: const Text('Save Record'),
          ),
        ],
      ),
    );
  }
}
