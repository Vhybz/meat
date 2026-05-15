import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/status_chip.dart';
import '../../services/transfer_provider.dart';
import '../../services/butcher_service.dart';
import '../../models/transfer_models.dart';
import '../../models/butcher_models.dart';
import '../../services/branch_provider.dart';
import '../../services/label_service.dart';

class StockTransferScreen extends ConsumerStatefulWidget {
  const StockTransferScreen({super.key});

  @override
  ConsumerState<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends ConsumerState<StockTransferScreen> {
  void _showNewTransferDialog() {
    showDialog(
      context: context,
      builder: (context) => const NewTransferDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transfers = ref.watch(transferProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stock Transfers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Slaughterhouse → Retail Shop', style: TextStyle(color: AppColors.textLight)),
                ],
              ),
              if (isMobile) const SizedBox(height: AppSpacing.m),
              ElevatedButton.icon(
                onPressed: _showNewTransferDialog,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('New Transfer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildTransferSummary(context, transfers),
          const SizedBox(height: AppSpacing.l),
          _buildRecentTransfers(transfers),
        ],
      ),
    );
  }

  Widget _buildTransferSummary(BuildContext context, List<StockTransfer> transfers) {
    final pendingWeight = transfers
        .where((t) => t.status == TransferStatus.pending)
        .fold(0.0, (sum, t) => sum + t.weight);
    final completedTodayWeight = transfers
        .where((t) => t.status == TransferStatus.received && 
                t.transferTime.day == DateTime.now().day)
        .fold(0.0, (sum, t) => sum + t.weight);

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.m,
      children: [
        _summaryCard('In Transit', WeightConverter.formatShort(pendingWeight), Icons.local_shipping, Colors.blue, isMobile),
        _summaryCard('Completed Today', WeightConverter.formatShort(completedTodayWeight), Icons.check_circle, Colors.green, isMobile),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 250,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  const Icon(Icons.trending_up, color: AppColors.accentGreen, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransfers(List<StockTransfer> transfers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transfer History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: AppSpacing.m),
            if (transfers.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('No transfers recorded yet.', style: TextStyle(color: AppColors.textLight)),
              ))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 600),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(1.2),
                      4: FlexColumnWidth(1.2),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: AppColors.surfaceWhite),
                        children: [
                          Padding(padding: EdgeInsets.all(12), child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Destination', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      ...transfers.reversed.map((t) => TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(12), child: Text(t.id, style: const TextStyle(fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(12), child: Text(DateFormat('hh:mm a').format(t.transferTime), style: const TextStyle(fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(12), child: Text('${t.meatType} (${WeightConverter.formatShort(t.weight)})', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
                          Padding(padding: const EdgeInsets.all(12), child: Text(t.destination, style: const TextStyle(fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(8), child: StatusChip(
                            label: t.status.name.toUpperCase(), 
                            color: t.status == TransferStatus.pending ? Colors.blue : Colors.green
                          )),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: ElevatedButton.icon(
                              onPressed: () => LabelService.printTransferLabel(t),
                              icon: const Icon(Icons.print, size: 14),
                              label: const Text('REPRINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryMaroon,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
}

class NewTransferDialog extends ConsumerStatefulWidget {
  const NewTransferDialog({super.key});

  @override
  ConsumerState<NewTransferDialog> createState() => _NewTransferDialogState();
}

class _NewTransferDialogState extends ConsumerState<NewTransferDialog> {
  String? _selectedBatchId;
  final Set<String> _selectedCutIds = {};
  String? _destination;

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(activeBatchesProvider);
    final cutsAsync = ref.watch(recentCutsProvider);
    final transfers = ref.watch(transferProvider);
    final branchesAsync = ref.watch(branchesProvider);
    
    final activeBatches = batchesAsync.value ?? [];
    final activeCuts = cutsAsync.value ?? [];
    final branches = branchesAsync.value ?? [];
    
    // Set default destination branch if not yet set
    if (_destination == null && branches.isNotEmpty) {
      _destination = branches.first.code;
    }

    // Find the selected objects based on IDs (safe against provider refreshes)
    final selectedBatch = _selectedBatchId != null 
        ? activeBatches.where((b) => b.id == _selectedBatchId).firstOrNull 
        : null;

    // Filter cuts by selected batch and ensure they haven't been transferred yet
    final availableCuts = selectedBatch == null 
        ? <MeatCut>[] 
        : activeCuts.where((c) => c.batchId == selectedBatch.id && 
            !transfers.any((t) => t.batchId == c.batchId && t.meatType.contains(c.name))).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      title: Row(
        children: [
          const Icon(Icons.local_shipping_outlined, color: AppColors.primaryMaroon),
          const SizedBox(width: 12),
          Expanded(child: Text('Move Stock to Retail', style: const TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              batchesAsync.when(
                data: (batches) => DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedBatchId,
                  decoration: const InputDecoration(labelText: '1. Select Source Batch', border: OutlineInputBorder()),
                  items: batches.map((b) => DropdownMenuItem<String>(
                    value: b.id,
                    child: Text(
                      '${b.id.length > 8 ? b.id.substring(0,8) : b.id} (${b.meatType})', 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() {
                    _selectedBatchId = v;
                    _selectedCutIds.clear();
                  }),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading batches', style: const TextStyle(fontSize: 12, color: Colors.red)),
              ),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft, child: Text('2. Select Parts to Move', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              if (selectedBatch != null && availableCuts.isNotEmpty) 
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedCutIds.length == availableCuts.length) {
                          _selectedCutIds.clear();
                        } else {
                          _selectedCutIds.addAll(availableCuts.map((c) => c.id));
                        }
                      });
                    },
                    child: Text(_selectedCutIds.length == availableCuts.length ? 'Deselect All' : 'Select All Available'),
                  ),
                ),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: availableCuts.isEmpty 
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(selectedBatch == null ? 'Select batch first' : 'No parts available for transfer', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: availableCuts.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cut = availableCuts[index];
                          final isSelected = _selectedCutIds.contains(cut.id);
                          return CheckboxListTile(
                            title: Text(cut.name, style: const TextStyle(fontSize: 13)),
                            subtitle: Text('${cut.weight}kg', style: const TextStyle(fontSize: 11)),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedCutIds.add(cut.id);
                                } else {
                                  _selectedCutIds.remove(cut.id);
                                }
                              });
                            },
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                ),
              ),
              const SizedBox(height: 16),
              branchesAsync.when(
                data: (branches) => DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _destination,
                  decoration: const InputDecoration(labelText: '3. Destination Branch', border: OutlineInputBorder()),
                  items: branches.map((b) => DropdownMenuItem<String>(
                    value: b.code,
                    child: Text('${b.name} (${b.location})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() => _destination = v!),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Text('Error loading branches', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_selectedCutIds.isEmpty || _destination == null || selectedBatch == null) ? null : () {
            final List<StockTransfer> transfersList = [];
            final now = DateTime.now();

            for (final cutId in _selectedCutIds) {
              final cut = availableCuts.firstWhere((c) => c.id == cutId);
              final String timestamp = now.millisecondsSinceEpoch.toString();
              final String suffix = timestamp.substring(timestamp.length - 10);
              final String indexStr = transfersList.length.toString().padLeft(2, '0');
              
              transfersList.add(StockTransfer(
                id: '00000000-0000-0000-0000-$suffix$indexStr',
                batchId: cut.batchId,
                meatType: '${selectedBatch.meatType} - ${cut.name}',
                weight: cut.weight,
                destination: _destination!,
                transferTime: now,
              ));
            }

            ref.read(transferProvider.notifier).addTransfers(transfersList);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Transferred ${transfersList.length} items to $_destination')),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
          child: Text(_selectedCutIds.length > 1 ? 'Confirm Bulk Transfer' : 'Confirm Transfer'),
        ),
      ],
    );
  }
}
