import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/status_chip.dart';
import '../../models/butcher_models.dart';
import '../../services/butcher_service.dart';

class MeatProcessingScreen extends ConsumerWidget {
  const MeatProcessingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentCutsAsync = ref.watch(recentCutsProvider);
    final activeBatchesAsync = ref.watch(meatBatchesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordCutDialog(context, ref),
        label: const Text('Record New Cut'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Active Batches in Processing', Icons.inventory_2),
            const SizedBox(height: AppSpacing.m),
            activeBatchesAsync.when(
              data: (batches) => _buildActiveBatchesList(ref, batches),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader('Recent Cut Production', Icons.history),
            const SizedBox(height: AppSpacing.m),
            recentCutsAsync.when(
              data: (cuts) => _buildCutProductionList(cuts),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryMaroon),
        const SizedBox(width: AppSpacing.s),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildActiveBatchesList(WidgetRef ref, List<MeatBatch> batches) {
    if (batches.isEmpty) return const Text('No active batches.');

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: batches.length,
        itemBuilder: (context, index) {
          final batch = batches[index];
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: AppSpacing.m),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ID: ${batch.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        StatusChip(label: batch.status.toUpperCase(), color: Colors.blue),
                      ],
                    ),
                    const Divider(),
                    Text('Type: ${batch.meatType}', style: const TextStyle(fontSize: 12)),
                    Text('Batch Weight: ${WeightConverter.formatShort(batch.weight)}', style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    const LinearProgressIndicator(value: 0.6, backgroundColor: AppColors.surfaceWhite, color: AppColors.primaryMaroon),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Processing...', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                        TextButton(
                          onPressed: () => _confirmCloseBatch(context, ref, batch),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20)),
                          child: const Text('Close Batch', style: TextStyle(fontSize: 10, color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmCloseBatch(BuildContext context, WidgetRef ref, MeatBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Processing?'),
        content: Text('Are you sure you want to close Batch ${batch.id}? This will move it to the archive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(meatBatchesProvider.notifier).closeBatch(batch.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Close Batch'),
          ),
        ],
      ),
    );
  }

  Widget _buildCutProductionList(List<MeatCut> cuts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 600),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1.2),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: AppColors.surfaceWhite),
                      children: [
                        Padding(padding: EdgeInsets.all(12), child: Text('Cut Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(12), child: Text('Batch ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(12), child: Text('Weight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(12), child: Text('Time Processed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    ...cuts.map((cut) => TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(12), child: Text(cut.name, style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(12), child: Text(cut.batchId, style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(12), child: Text(WeightConverter.formatShort(cut.weight), style: const TextStyle(fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(12), child: Text(DateFormat('hh:mm a').format(cut.processedAt), style: const TextStyle(fontSize: 12))),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordCutDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    String? selectedBatchId;
    
    final batchesAsync = ref.read(meatBatchesProvider);
    final activeBatches = batchesAsync.value ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: const Row(
          children: [
            Icon(Icons.restaurant_rounded, color: AppColors.primaryMaroon),
            SizedBox(width: 12),
            Text('Record Meat Cut'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Cut Name (e.g. Ribeye)', border: OutlineInputBorder()),
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
                decoration: const InputDecoration(labelText: 'Select Batch', border: OutlineInputBorder()),
                items: activeBatches.map((b) => DropdownMenuItem(
                  value: b.id, 
                  child: Text('${b.id} (${b.meatType})')
                )).toList(),
                onChanged: (v) => selectedBatchId = v,
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                final String suffix = timestamp.substring(timestamp.length - 12);
                final String validUuid = '00000000-0000-0000-0000-$suffix';

                final cut = MeatCut(
                  id: validUuid,
                  name: nameController.text,
                  batchId: selectedBatchId!,
                  weight: double.tryParse(weightController.text) ?? 0,
                  processedAt: DateTime.now(),
                );

                await ref.read(recentCutsProvider.notifier).addCut(cut);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meat cut recorded.')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
            child: const Text('Save Cut'),
          ),
        ],
      ),
    );
  }
}
