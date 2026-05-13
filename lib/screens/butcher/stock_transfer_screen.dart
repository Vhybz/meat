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
import '../../services/user_provider.dart';
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
  MeatBatch? _selectedBatch;
  MeatCut? _selectedCut;
  String? _destination;

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(activeBatchesProvider);
    final cutsAsync = ref.watch(recentCutsProvider);
    final transfers = ref.watch(transferProvider);
    final cashiers = ref.watch(userProvider.notifier).getCashiers();
    
    // Set default destination if not yet set
    if (_destination == null && cashiers.isNotEmpty) {
      _destination = cashiers.first.shopLocation ?? cashiers.first.name;
    }

    final activeCuts = cutsAsync.value ?? [];
    // Filter cuts by selected batch and ensure they haven't been transferred yet
    // (A simple check: if a transfer exists with this batchId and meatType containing the cut name)
    // Better: We should ideally have a unique ID for each cut in the transfer table.
    final availableCuts = _selectedBatch == null 
        ? <MeatCut>[] 
        : activeCuts.where((c) => c.batchId == _selectedBatch!.id && 
            !transfers.any((t) => t.batchId == c.batchId && t.meatType.contains(c.name))).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      title: const Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: AppColors.primaryMaroon),
          SizedBox(width: 12),
          Text('Move Stock to Retail'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              batchesAsync.when(
                data: (batches) => DropdownButtonFormField<MeatBatch>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '1. Select Source Batch', border: OutlineInputBorder()),
                  items: batches.map((b) => DropdownMenuItem(
                    value: b,
                    child: Text('${b.id.substring(0,8)} (${b.meatType})', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setState(() {
                    _selectedBatch = v;
                    _selectedCut = null;
                  }),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MeatCut>(
                isExpanded: true,
                value: _selectedCut,
                decoration: const InputDecoration(labelText: '2. Select Part/Cut to Move', border: OutlineInputBorder()),
                items: availableCuts.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text('${c.name} (${c.weight}kg)', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCut = v),
                disabledHint: const Text('Select batch first or no cuts available'),
              ),
              const SizedBox(height: 16),
              if (cashiers.isNotEmpty)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _destination,
                  decoration: const InputDecoration(labelText: '3. Destination Shop', border: OutlineInputBorder()),
                  items: cashiers.map((u) {
                    final label = u.shopLocation != null ? '${u.name} (${u.shopLocation})' : u.name;
                    final value = u.shopLocation ?? u.name;
                    return DropdownMenuItem(
                      value: value,
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _destination = v!),
                )
              else
                const Text('No cashier accounts found. Please create one in Admin.', 
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_selectedCut == null || _destination == null) ? null : () {
            final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
            final String suffix = timestamp.substring(timestamp.length - 12);
            final String validUuid = '00000000-0000-0000-0000-$suffix';

            // We combine animal type and cut name for the transfer record
            final transfer = StockTransfer(
              id: validUuid,
              batchId: _selectedCut!.batchId,
              meatType: '${_selectedBatch!.meatType} - ${_selectedCut!.name}',
              weight: _selectedCut!.weight,
              destination: _destination!,
              transferTime: DateTime.now(),
            );
            ref.read(transferProvider.notifier).addTransfer(transfer);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Transferring ${_selectedCut!.weight}kg of ${_selectedCut!.name} to $_destination')),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
          child: const Text('Confirm Transfer'),
        ),
      ],
    );
  }
}
