import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/status_chip.dart';
import '../../services/transfer_provider.dart';
import '../../services/butcher_service.dart';
import '../../models/transfer_models.dart';
import '../../models/butcher_models.dart';
import '../../models/branch_model.dart';
import '../../services/branch_provider.dart';
import '../../services/label_service.dart';
import '../../services/notification_service.dart';
import '../../services/product_service.dart';
import '../../services/sms_service.dart';

class StockTransferScreen extends ConsumerStatefulWidget {
  const StockTransferScreen({super.key});

  @override
  ConsumerState<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends ConsumerState<StockTransferScreen> {
  Widget _buildExpiryWarning() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.l),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meat Freshness Alert', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                Text('Some items have been in the butcher house for over 24 hours. Please transfer them to the Cold Room immediately.', 
                  style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNewTransferDialog() {
    showDialog(
      context: context,
      builder: (context) => const NewTransferDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transfers = ref.watch(transferProvider);
    final branchesAsync = ref.watch(branchesProvider);
    final activeBatches = ref.watch(activeBatchesProvider).value ?? [];
    final isMobile = MediaQuery.of(context).size.width < 600;

    final hasOldMeat = activeBatches.any((b) => 
      b.createdAt.isBefore(DateTime.now().subtract(const Duration(hours: 24)))
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasOldMeat)
            _buildExpiryWarning(),
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
          _buildRecentTransfers(transfers, branchesAsync.value ?? []),
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

  Widget _buildRecentTransfers(List<StockTransfer> transfers, List<Branch> branches) {
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
                      3: FlexColumnWidth(1.5),
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
                      ...transfers.reversed.map((t) {
                        final branch = branches.where((b) => b.code == t.destination).firstOrNull;
                        final destinationDisplay = branch != null ? '${branch.name} (${branch.location})' : t.destination;
                        
                        return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(12), child: Text(t.id.substring(t.id.length - 8), style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                          Padding(padding: const EdgeInsets.all(12), child: Text(DateFormat('hh:mm a').format(t.transferTime), style: const TextStyle(fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(12), child: Text('${t.meatType} (${WeightConverter.formatShort(t.weight)})', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
                          Padding(padding: const EdgeInsets.all(12), child: Text(destinationDisplay, style: const TextStyle(fontSize: 12))),
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
                      );
                      }),
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
  bool _isDirectTransfer = false;
  final _weightController = TextEditingController();
  
  String? _selectedBatchId;
  final Set<String> _selectedCutIds = {};
  String? _destination;
  bool _isThirdParty = false;
  final _thirdPartyCustomerController = TextEditingController();

  @override
  void dispose() {
    _thirdPartyCustomerController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(activeBatchesProvider);
    final cutsAsync = ref.watch(recentCutsProvider);
    final transfers = ref.watch(transferProvider);
    final branchesAsync = ref.watch(branchesProvider);
    final productsAsync = ref.watch(productsFutureProvider);
    
    final activeBatches = batchesAsync.value ?? [];
    final activeCuts = cutsAsync.value ?? [];
    final branches = branchesAsync.value ?? [];
    
    if (_destination == null && branches.isNotEmpty) {
      _destination = branches.first.code;
    }

    final selectedBatch = _selectedBatchId != null 
        ? activeBatches.where((b) => b.id == _selectedBatchId).firstOrNull 
        : null;

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
          Expanded(child: Text(_isDirectTransfer ? 'Direct Transfer / Sale' : 'Move Stock to Retail', style: const TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Batch'), icon: Icon(Icons.inventory_2)),
                    ButtonSegment(value: true, label: Text('Direct'), icon: Icon(Icons.bolt)),
                  ],
                  selected: {_isDirectTransfer},
                  onSelectionChanged: (val) => setState(() => _isDirectTransfer = val.first),
                ),
                const SizedBox(height: 16),
                if (_isDirectTransfer) ...[
                  productsAsync.when(
                    data: (products) => DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Product to Transfer', border: OutlineInputBorder()),
                      items: products.where((p) => !p.isDeleted).map((p) => DropdownMenuItem(
                        value: p.name, 
                        child: Text('${p.category} - ${p.name}', style: const TextStyle(fontSize: 12)),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedBatchId = v), // Reusing variable to store name
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Text('Error loading products'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Quantity (kg)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  ),
                ] else ...[
                  batchesAsync.when(
                    data: (batches) => DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedBatchId,
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
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
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
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Third Party Sale', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Notify CEO & Cashier for payment', style: TextStyle(fontSize: 11)),
                  value: _isThirdParty,
                  onChanged: (v) => setState(() => _isThirdParty = v),
                  activeThumbColor: AppColors.primaryMaroon,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_isThirdParty) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _thirdPartyCustomerController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name / Destination',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ] else if (!_isDirectTransfer)
                  branchesAsync.when(
                    data: (branches) => DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _destination,
                      decoration: const InputDecoration(labelText: 'Destination Branch', border: OutlineInputBorder()),
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            // Validation
            if (_isDirectTransfer) {
              if (_selectedBatchId == null || _weightController.text.isEmpty) return;
            } else {
              if (_selectedCutIds.isEmpty || selectedBatch == null) return;
              if (!_isThirdParty && _destination == null) return;
            }

            final List<StockTransfer> transfersList = [];
            final now = DateTime.now();

            if (_isDirectTransfer) {
              final weight = double.tryParse(_weightController.text) ?? 0.0;
              final String timestamp = now.millisecondsSinceEpoch.toString();
              final String suffix = timestamp.substring(timestamp.length - 12);
              
              transfersList.add(StockTransfer(
                id: '00000000-0000-0000-0000-$suffix',
                batchId: 'DIRECT',
                meatType: _selectedBatchId!, // This is the product name
                weight: weight,
                destination: _isThirdParty ? 'Third Party: ${_thirdPartyCustomerController.text}' : 'Cold Room',
                transferTime: now,
                isThirdParty: _isThirdParty,
                status: _isThirdParty ? TransferStatus.awaitingPayment : TransferStatus.pending,
              ));
            } else {
              for (final cutId in _selectedCutIds) {
                final cut = availableCuts.firstWhere((c) => c.id == cutId);
                final String timestamp = now.millisecondsSinceEpoch.toString();
                final String suffix = timestamp.substring(timestamp.length - 10);
                final String indexStr = transfersList.length.toString().padLeft(2, '0');
                
                transfersList.add(StockTransfer(
                  id: '00000000-0000-0000-0000-$suffix$indexStr',
                  batchId: cut.batchId,
                  meatType: '${selectedBatch!.meatType} - ${cut.name}',
                  weight: cut.weight,
                  destination: _isThirdParty ? 'Third Party: ${_thirdPartyCustomerController.text}' : _destination!,
                  transferTime: now,
                  isThirdParty: _isThirdParty,
                  status: _isThirdParty ? TransferStatus.awaitingPayment : TransferStatus.pending,
                ));
              }
            }

            ref.read(transferProvider.notifier).addTransfers(transfersList);
            
            // Notify CEO and Cashier
            final meatDescription = _isDirectTransfer 
                ? (_selectedBatchId ?? "Meat") 
                : (selectedBatch?.meatType ?? "Meat");
            final totalWeight = transfersList.fold(0.0, (sum, t) => sum + t.weight);

            final msg = _isThirdParty 
                ? 'URGENT: Third Party Transfer initiated. Butcher needs payment for ${totalWeight.toStringAsFixed(1)}kg of $meatDescription.'
                : 'Stock Transfer to Retail: ${transfersList.length} items moved to Cold Room';
            
            ref.read(notificationProvider.notifier).addNotification('Stock Alert', msg);
            SmsService.notifyAdmin(title: 'TRANSFER ALERT', message: msg);

            Navigator.pop(context);
            
            // Show Barcode Alert Dialog
            _showBarcodePrintPrompt(context, transfersList);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
          child: Text(_isThirdParty ? 'Initiate Transfer & Notify' : 'Confirm Transfer'),
        ),
      ],
    );
  }

  void _showBarcodePrintPrompt(BuildContext context, List<StockTransfer> transfers) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppColors.primaryMaroon),
            SizedBox(width: 12),
            Text('Attach Barcodes', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please print and attach the unique barcodes for these ${transfers.length} items to the package.'),
            const SizedBox(height: 12),
            const Text('The Receiver/Cashier will need to scan these to verify the stock receipt.', 
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('I\'ll do it later')
          ),
          ElevatedButton.icon(
            onPressed: () {
              LabelService.printMultipleTransferLabels(transfers);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.print),
            label: const Text('PRINT ALL LABELS'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
