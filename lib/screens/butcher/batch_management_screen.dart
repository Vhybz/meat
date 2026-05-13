import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../services/butcher_service.dart';
import '../../widgets/status_chip.dart';
import '../../core/utils.dart';
import '../../services/label_service.dart';

class BatchManagementScreen extends ConsumerWidget {
  const BatchManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(meatBatchesProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Batch Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Track production batches and generate QR labels.', style: TextStyle(color: AppColors.textLight)),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: batchesAsync.when(
              data: (batches) {
                if (batches.isEmpty) {
                  return const Center(child: Text('No batches found. Create one in Animal Intake.'));
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final int crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 1000 ? 2 : 3);
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppSpacing.m,
                        mainAxisSpacing: AppSpacing.m,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: batches.length,
                      itemBuilder: (context, index) {
                        final batch = batches[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(batch.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                    const Icon(Icons.qr_code, size: 20),
                                  ],
                                ),
                                const Divider(),
                                Text('Type: ${batch.meatType}', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                Text('Weight: ${WeightConverter.formatShort(batch.weight)}', style: const TextStyle(fontSize: 12)),
                                const Spacer(),
                                Row(
                                  children: [
                                    StatusChip(label: batch.status.toUpperCase(), color: Colors.blue),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => LabelService.printBatchLabel(batch),
                                      icon: const Icon(Icons.print, size: 16), 
                                      tooltip: 'Print Labels'
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
