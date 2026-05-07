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
    final activeBatchesAsync = ref.watch(activeBatchesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordCutDialog(context),
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
              data: (batches) => _buildActiveBatchesList(batches),
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

  Widget _buildActiveBatchesList(List<MeatBatch> batches) {
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
                        Text('ID: ${batch.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        StatusChip(label: batch.status.toUpperCase(), color: Colors.blue),
                      ],
                    ),
                    const Divider(),
                    Text('Type: ${batch.meatType}', style: const TextStyle(fontSize: 12)),
                    Text('Total Batch Weight: ${WeightConverter.formatShort(batch.weight)}', style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    const LinearProgressIndicator(value: 0.6, backgroundColor: AppColors.surfaceWhite, color: AppColors.primaryMaroon),
                    const SizedBox(height: 8),
                    const Text('Estimated 60% remaining', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
              ),
            ),
          );
        },
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
            Table(
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
                    Padding(padding: const EdgeInsets.all(12), child: Text(WeightConverter.formatShort(cut.weight), style: const TextStyle(fontSize: 10))),
                    Padding(padding: const EdgeInsets.all(12), child: Text(DateFormat('hh:mm a').format(cut.processedAt), style: const TextStyle(fontSize: 12))),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordCutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Meat Cut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Cut Name (e.g. Ribeye)')),
            const SizedBox(height: AppSpacing.m),
            const TextField(decoration: InputDecoration(labelText: 'Weight (kg)')),
            const SizedBox(height: AppSpacing.m),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Batch'),
              items: const [
                DropdownMenuItem(value: 'BCH-102', child: Text('BCH-102 (Beef)')),
                DropdownMenuItem(value: 'BCH-105', child: Text('BCH-105 (Pork)')),
              ],
              onChanged: (v) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context), 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
            child: const Text('Save Cut'),
          ),
        ],
      ),
    );
  }
}
