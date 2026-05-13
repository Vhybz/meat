import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../services/butcher_service.dart';
import '../../services/label_service.dart';
import '../../widgets/status_chip.dart';
import '../../models/butcher_models.dart';

class SlaughterLogScreen extends ConsumerStatefulWidget {
  const SlaughterLogScreen({super.key});

  @override
  ConsumerState<SlaughterLogScreen> createState() => _SlaughterLogScreenState();
}

class _SlaughterLogScreenState extends ConsumerState<SlaughterLogScreen> {
  String _searchQuery = '';
  AnimalType? _filterType;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(slaughterLogsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmartControls(),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: Card(
              child: logsAsync.when(
                data: (List<SlaughterLog> logs) {
                  final filteredLogs = logs.where((log) {
                    final matchesSearch = log.id.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                          log.animalId.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesFilter = _filterType == null || log.type == _filterType;
                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (filteredLogs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: AppColors.textLight),
                          SizedBox(height: AppSpacing.m),
                          Text('No logs found matching your criteria', style: TextStyle(color: AppColors.textLight)),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        horizontalMargin: AppSpacing.m,
                        columnSpacing: AppSpacing.m,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Animal ID')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Date & Time')),
                          DataColumn(label: Text('Weight')),
                          DataColumn(label: Text('Est. Yield')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filteredLogs.map((SlaughterLog log) => DataRow(cells: [
                          DataCell(SizedBox(width: 80, child: Text(log.id, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                          DataCell(SizedBox(width: 80, child: Text(log.animalId, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                          DataCell(Text(log.type.displayName, style: const TextStyle(fontSize: 11))),
                          DataCell(Text(
                            log.slaughterTime != null 
                              ? DateFormat('MM/dd HH:mm').format(log.slaughterTime!) 
                              : 'Pending',
                            style: const TextStyle(fontSize: 10),
                          )),
                          DataCell(Text(WeightConverter.formatShort(log.weight), style: const TextStyle(fontSize: 10))),
                          DataCell(Text(WeightConverter.formatShort(log.estimatedYield), 
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentGreen))),
                          DataCell(StatusChip(
                            label: log.status.name.toUpperCase(),
                            color: log.status == SlaughterStatus.completed ? Colors.green : (log.status == SlaughterStatus.processing ? Colors.blue : Colors.orange),
                          )),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildActions(log),
                              if (log.status == SlaughterStatus.completed)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: ElevatedButton.icon(
                                    onPressed: () => LabelService.printSlaughterLabel(log),
                                    icon: const Icon(Icons.print, size: 12),
                                    label: const Text('REPRINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
                        ])).toList(),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(SlaughterLog log) {
    if (log.status == SlaughterStatus.completed) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 18);
    }

    return PopupMenuButton<String>(
      onSelected: (action) {
        if (action == 'start') {
          ref.read(slaughterLogsProvider.notifier).updateStatus(log.id, SlaughterStatus.processing);
        } else if (action == 'complete') {
          _showSlaughterCompletionDialog(log);
        }
      },
      icon: const Icon(Icons.more_vert, size: 18),
      itemBuilder: (context) => [
        if (log.status == SlaughterStatus.pending)
          const PopupMenuItem(
            value: 'start',
            child: Row(
              children: [
                Icon(Icons.play_arrow, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Text('Start Slaughter'),
              ],
            ),
          ),
        if (log.status == SlaughterStatus.processing)
          const PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(Icons.done_all, size: 18, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Log Breakdown', style: TextStyle(fontSize: 13))
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showSlaughterCompletionDialog(SlaughterLog log) {
    final List<String> cuts = log.type.standardCuts;
    final Map<String, TextEditingController> controllers = {
      for (var cut in cuts) cut: TextEditingController()
    };
    final TextEditingController wasteController = TextEditingController();
    bool isSaving = false;
    double currentYield = log.estimatedYield;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void updateYield() {
            final waste = double.tryParse(wasteController.text) ?? 0;
            setState(() {
              currentYield = log.weight - waste;
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppColors.primaryMaroon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Carcass Breakdown: ${log.type.displayName}', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Intake: ${log.weight}kg • Yield: ${currentYield.toStringAsFixed(1)}kg', 
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.s),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Recorded Waste (Bones/Offals)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            SizedBox(
                              width: 85,
                              child: TextFormField(
                                controller: wasteController,
                                decoration: const InputDecoration(suffixText: 'kg', isDense: true, border: OutlineInputBorder()),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                onChanged: (v) => updateYield(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Enter weights for all sellable parts obtained.', 
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                      const Divider(),
                      ...cuts.map((cut) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(cut, 
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis
                              )
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 75,
                              child: TextFormField(
                                controller: controllers[cut],
                                decoration: const InputDecoration(
                                  suffixText: 'kg',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context), 
                child: const Text('Cancel')
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  setState(() => isSaving = true);
                  try {
                    final List<MeatCut> meatCuts = [];
                    final now = DateTime.now();
                    final waste = double.tryParse(wasteController.text) ?? 0;

                    controllers.forEach((cutName, controller) {
                      final weight = double.tryParse(controller.text) ?? 0;
                      if (weight > 0) {
                        final String timestamp = now.millisecondsSinceEpoch.toString();
                        final String suffix = timestamp.substring(timestamp.length - 10);
                        final String indexStr = meatCuts.length.toString().padLeft(2, '0');
                        
                        meatCuts.add(MeatCut(
                          id: '00000000-0000-0000-0000-$suffix$indexStr',
                          name: cutName,
                          batchId: log.id,
                          weight: weight,
                          processedAt: now,
                        ));
                      }
                    });

                    if (meatCuts.isEmpty && waste <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter at least one weight or waste amount.'))
                      );
                      setState(() => isSaving = false);
                      return;
                    }

                    // 1. Save Waste to separate table if provided
                    if (waste > 0) {
                      await ref.read(butcherWasteProvider.notifier).addWaste(log.id, 'Slaughter Waste/Bones', waste);
                    }

                    // 2. Add all cuts to database
                    if (meatCuts.isNotEmpty) {
                      await ref.read(recentCutsProvider.notifier).addCuts(meatCuts);
                    }
                    
                    // 3. Mark slaughter as completed with the calculated waste
                    final updatedLog = log.copyWith(
                      status: SlaughterStatus.completed,
                      recordedWaste: waste,
                    );
                    await ref.read(slaughterLogsProvider.notifier).updateSlaughterRecord(updatedLog);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Carcass breakdown and waste recorded successfully.'))
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving breakdown: $e'), backgroundColor: Colors.red)
                      );
                    }
                  } finally {
                    if (mounted) setState(() => isSaving = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save & Complete'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmartControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.m),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
            ],
          ),
          child: isMobile 
            ? Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by ID or Animal ID...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  DropdownButtonFormField<AnimalType>(
                    value: _filterType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'All Animals',
                      prefixIcon: const Icon(Icons.filter_list, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Animals', overflow: TextOverflow.ellipsis)),
                      ...AnimalType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _filterType = v),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by ID or Animal ID...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<AnimalType>(
                      value: _filterType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'All Animals',
                        prefixIcon: const Icon(Icons.filter_list, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Animals', overflow: TextOverflow.ellipsis)),
                        ...AnimalType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) => setState(() => _filterType = v),
                    ),
                  ),
                ],
              ),
        );
      }
    );
  }
}
