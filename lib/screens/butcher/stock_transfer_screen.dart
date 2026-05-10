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
                  Text('Stock Transfers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Slaughterhouse → Retail Shop', style: TextStyle(color: AppColors.textLight)),
                ],
              ),
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
          _buildTransferSummary(transfers),
          const SizedBox(height: AppSpacing.l),
          _buildRecentTransfers(transfers),
        ],
      ),
    );
  }

  Widget _buildTransferSummary(List<StockTransfer> transfers) {
    final pendingWeight = transfers
        .where((t) => t.status == TransferStatus.pending)
        .fold(0.0, (sum, t) => sum + t.weight);
    final completedTodayWeight = transfers
        .where((t) => t.status == TransferStatus.received && 
                t.transferTime.day == DateTime.now().day)
        .fold(0.0, (sum, t) => sum + t.weight);

    return Row(
      children: [
        _summaryCard('In Transit', WeightConverter.formatShort(pendingWeight), Icons.local_shipping, Colors.blue),
        _summaryCard('Completed Today', WeightConverter.formatShort(completedTodayWeight), Icons.check_circle, Colors.green),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
              Table(
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
                      Padding(padding: EdgeInsets.all(12), child: Text('Print', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                        child: IconButton(
                          icon: const Icon(Icons.print, size: 18, color: AppColors.primaryMaroon),
                          onPressed: () => LabelService.printTransferLabel(t),
                        ),
                      ),
                    ],
                  )),
                ],
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
  String? _destination;

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(activeBatchesProvider);
    final cashiers = ref.watch(userProvider.notifier).getCashiers();
    
    // Set default destination if not yet set
    if (_destination == null && cashiers.isNotEmpty) {
      _destination = cashiers.first.shopLocation ?? cashiers.first.name;
    }

    return AlertDialog(
      title: const Text('Move to Retail Sales'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          batchesAsync.when(
            data: (batches) => DropdownButtonFormField<MeatBatch>(
              decoration: const InputDecoration(labelText: 'Select Batch'),
              items: batches.map((b) => DropdownMenuItem(
                value: b,
                child: Text('${b.meatType} (${b.weight}kg)'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedBatch = v),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 16),
          if (cashiers.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _destination,
              decoration: const InputDecoration(labelText: 'Destination (Cashier Account)'),
              items: cashiers.map((u) {
                final label = u.shopLocation != null ? '${u.name} (${u.shopLocation})' : u.name;
                final value = u.shopLocation ?? u.name;
                return DropdownMenuItem(
                  value: value,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (v) => setState(() => _destination = v!),
            )
          else
            const Text('No cashier accounts found. Please create one in Admin.', 
              style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_selectedBatch == null || _destination == null) ? null : () {
            final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
            final String suffix = timestamp.substring(timestamp.length - 12);
            final String validUuid = '00000000-0000-0000-0000-$suffix';

            final transfer = StockTransfer(
              id: validUuid,
              batchId: _selectedBatch!.id,
              meatType: _selectedBatch!.meatType,
              weight: _selectedBatch!.weight,
              destination: _destination!,
              transferTime: DateTime.now(),
            );
            ref.read(transferProvider.notifier).addTransfer(transfer);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transfer initiated successfully')),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
          child: const Text('Confirm Transfer'),
        ),
      ],
    );
  }
}
