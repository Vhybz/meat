import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/status_chip.dart';
import '../../models/butcher_models.dart';
import '../../services/butcher_service.dart';
import '../../services/label_service.dart';

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
        child: Padding(
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
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryMaroon),
        const SizedBox(width: AppSpacing.s),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildActiveBatchesList(WidgetRef ref, List<MeatBatch> batches) {
    if (batches.isEmpty) return const Text('No active batches ready for processing.');
    final recentCuts = ref.watch(recentCutsProvider).value ?? [];
    final wasteRecords = ref.watch(butcherWasteProvider).value ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return SizedBox(
          height: isMobile ? 220 : 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              
              // Calculate yield progress: (Cuts + Waste) / Intake Weight
              final batchCuts = recentCuts.where((c) => c.batchId == batch.id);
              final batchWaste = wasteRecords.where((w) => w['batch_id'] == batch.id);
              
              final processedWeight = batchCuts.fold(0.0, (sum, c) => sum + c.weight);
              final wastedWeight = batchWaste.fold(0.0, (sum, w) => sum + (double.tryParse(w['weight']?.toString() ?? '0') ?? 0));
              
              final totalAccounted = processedWeight + wastedWeight;
              final progress = (totalAccounted / batch.weight).clamp(0.0, 1.0);

              return Container(
                width: isMobile ? 260 : 320,
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
                            Flexible(child: Text('Batch: ${batch.id.substring(0,8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                            StatusChip(label: 'READY', color: Colors.green),
                          ],
                        ),
                        const Divider(),
                        Text('Type: ${batch.meatType}', style: const TextStyle(fontSize: 11)),
                        Text('Intake: ${WeightConverter.formatShort(batch.weight)}', style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cuts: ${WeightConverter.formatShort(processedWeight)}', 
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('Waste: ${WeightConverter.formatShort(wastedWeight)}', 
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        LinearProgressIndicator(
                          value: progress, 
                          backgroundColor: AppColors.surfaceWhite, 
                          color: progress > 0.95 ? Colors.green : AppColors.primaryMaroon,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('${(progress * 100).toStringAsFixed(0)}% Accounted', 
                                style: const TextStyle(fontSize: 9, color: AppColors.textLight),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis
                              ),
                            ),
                            const SizedBox(width: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _showRecordWasteDialog(context, ref, batch),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4), 
                                    minimumSize: Size.zero, 
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap
                                  ),
                                  child: const Text('Add Waste', style: TextStyle(fontSize: 9, color: Colors.orange)),
                                ),
                                const SizedBox(width: 4),
                                TextButton(
                                  onPressed: () => _confirmCloseBatch(context, ref, batch),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4), 
                                    minimumSize: Size.zero, 
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap
                                  ),
                                  child: const Text('Close Batch', style: TextStyle(fontSize: 9, color: Colors.red)),
                                ),
                              ],
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
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1.3),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: AppColors.surfaceWhite),
                      children: [
                        Padding(padding: EdgeInsets.all(12), child: Text('Cut Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(12), child: Text('Batch ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(12), child: Text('Weight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(12), child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(12), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    ...cuts.map((cut) => TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(12), child: Text(cut.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                        Padding(padding: const EdgeInsets.all(12), child: Text(cut.batchId.length > 8 ? cut.batchId.substring(0,8) : cut.batchId, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                        Padding(padding: const EdgeInsets.all(12), child: Text(WeightConverter.formatShort(cut.weight), style: const TextStyle(fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(12), child: Text(DateFormat('HH:mm').format(cut.processedAt), style: const TextStyle(fontSize: 11))),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: ElevatedButton.icon(
                            onPressed: () => LabelService.printCutLabel(cut),
                            icon: const Icon(Icons.print, size: 12),
                            label: const Text('REPRINT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMaroon,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
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
    final weightController = TextEditingController();
    MeatBatch? selectedBatch;
    String? selectedCutName;
    
    final batchesAsync = ref.read(meatBatchesProvider);
    final activeBatches = batchesAsync.value ?? [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          AnimalType? animalType;
          if (selectedBatch != null) {
            for (var type in AnimalType.values) {
              if (type.name[0].toUpperCase() + type.name.substring(1) == selectedBatch!.meatType || 
                  (type == AnimalType.hardChicken && selectedBatch!.meatType == 'Hard Chicken (Layers)') ||
                  (type == AnimalType.softChicken && selectedBatch!.meatType == 'Soft Chicken (Broilers)')) {
                animalType = type;
                break;
              }
            }
          }
          final availableCuts = animalType?.standardCuts ?? [];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
            title: const Row(
              children: [
                Icon(Icons.restaurant_rounded, color: AppColors.primaryMaroon),
                SizedBox(width: 12),
                Expanded(child: Text('Dissect Animal Part', overflow: TextOverflow.ellipsis)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<MeatBatch>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Select Source Batch', border: OutlineInputBorder()),
                      items: activeBatches.map((b) => DropdownMenuItem(
                        value: b, 
                        child: Text('${b.id.substring(0,8)} (${b.meatType})', overflow: TextOverflow.ellipsis)
                      )).toList(),
                      onChanged: (v) => setState(() {
                        selectedBatch = v;
                        selectedCutName = null; // Reset cut name when batch changes
                      }),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedCutName,
                      decoration: const InputDecoration(labelText: 'Select Part/Cut', border: OutlineInputBorder()),
                      items: availableCuts.map((cut) => DropdownMenuItem(
                        value: cut, 
                        child: Text(cut, overflow: TextOverflow.ellipsis)
                      )).toList(),
                      onChanged: (v) => setState(() => selectedCutName = v),
                      validator: (v) => v == null ? 'Required' : null,
                      disabledHint: const Text('Select a batch first'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: weightController,
                      decoration: const InputDecoration(labelText: 'Weight of Part (kg)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.scale)), 
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final weight = double.tryParse(v);
                        if (weight == null || weight <= 0) return 'Invalid weight';
                        return null;
                      },
                    ),
                  ],
                ),
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
                      name: selectedCutName!,
                      batchId: selectedBatch!.id,
                      weight: double.tryParse(weightController.text) ?? 0,
                      processedAt: DateTime.now(),
                    );

                    await ref.read(recentCutsProvider.notifier).addCut(cut);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${cut.name} (${cut.weight}kg) recorded for batch ${selectedBatch!.id.substring(0,8)}'))
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
                child: const Text('Save Cut'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showRecordWasteDialog(BuildContext context, WidgetRef ref, MeatBatch batch) {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(child: Text('Record Waste: ${batch.id.substring(0, 8)}', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Waste Type / Reason', 
                  hintText: 'e.g. Bone Trimmings, Fat', 
                  border: OutlineInputBorder()
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)', 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.scale)
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid weight';
                  return null;
                },
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
                  batch.id, 
                  reasonController.text, 
                  double.tryParse(weightController.text) ?? 0
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logged ${weightController.text}kg waste for Batch ${batch.id.substring(0, 8)}'))
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Save Waste'),
          ),
        ],
      ),
    );
  }
}
