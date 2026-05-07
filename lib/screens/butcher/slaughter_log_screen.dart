import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../services/butcher_service.dart';
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
                data: (logs) {
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
                      rows: filteredLogs.map((log) => DataRow(cells: [
                        DataCell(Text(log.id, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(log.animalId, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(log.type.displayName, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(
                          log.slaughterTime != null 
                            ? DateFormat('MM/dd HH:mm').format(log.slaughterTime!) 
                            : 'Pending',
                          style: const TextStyle(fontSize: 11),
                        )),
                        DataCell(Text(WeightConverter.formatShort(log.weight), style: const TextStyle(fontSize: 10))),
                        DataCell(Text(WeightConverter.formatShort(log.estimatedYield), 
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentGreen))),
                        DataCell(StatusChip(
                          label: log.status.name.toUpperCase(),
                          color: log.status == SlaughterStatus.completed ? Colors.green : Colors.blue,
                        )),
                        DataCell(IconButton(icon: const Icon(Icons.more_vert, size: 18), onPressed: () {})),
                      ])).toList(),
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

  Widget _buildSmartControls() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by ID or Animal ID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<AnimalType>(
              initialValue: _filterType,
              decoration: InputDecoration(
                hintText: 'All Animals',
                prefixIcon: const Icon(Icons.filter_list, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Animals')),
                ...AnimalType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))),
              ],
              onChanged: (v) => setState(() => _filterType = v),
            ),
          ),
        ],
      ),
    );
  }
}
