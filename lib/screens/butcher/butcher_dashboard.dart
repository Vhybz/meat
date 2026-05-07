import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/summary_row.dart';
import '../../widgets/workflow_step.dart';
import '../../services/butcher_service.dart';
import '../../models/butcher_models.dart';
import '../../services/butcher_navigation_provider.dart';
import '../../services/transfer_provider.dart';
import '../../models/transfer_models.dart';

class ButcherDashboard extends ConsumerWidget {
  const ButcherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(slaughterLogsProvider);
    final batchesAsync = ref.watch(activeBatchesProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? AppSpacing.l : AppSpacing.m),
          child: Column(
            children: [
              logsAsync.when(
                data: (logs) => _buildKPIGrid(constraints.maxWidth, logs, batchesAsync.value ?? []),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading stats'),
              ),
              const SizedBox(height: AppSpacing.l),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildInteractiveWorkflow(ref),
                          const SizedBox(height: AppSpacing.l),
                          _buildSlaughterLogs(logsAsync),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildSmartInsights(logsAsync),
                          const SizedBox(height: AppSpacing.l),
                          _buildMeatSummary(logsAsync),
                          const SizedBox(height: AppSpacing.l),
                          _buildQuickActions(ref),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildInteractiveWorkflow(ref),
                    const SizedBox(height: AppSpacing.l),
                    _buildSmartInsights(logsAsync),
                    const SizedBox(height: AppSpacing.l),
                    _buildMeatSummary(logsAsync),
                    const SizedBox(height: AppSpacing.l),
                    _buildSlaughterLogs(logsAsync),
                    const SizedBox(height: AppSpacing.l),
                    _buildQuickActions(ref),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartInsights(AsyncValue<List<SlaughterLog>> logsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: AppColors.accentGreen),
                SizedBox(width: 8),
                Text("Smart Insights", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            logsAsync.when(
              data: (logs) {
                final completed = logs.where((l) => l.status == SlaughterStatus.completed).toList();
                if (completed.isEmpty) return const Text("No yield data available yet.");
                
                final totalWeight = completed.fold(0.0, (sum, l) => sum + l.weight);
                final totalYield = completed.fold(0.0, (sum, l) => sum + l.estimatedYield);
                final avgEfficiency = (totalYield / totalWeight) * 100;

                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: CircularProgressIndicator(
                            value: avgEfficiency / 100,
                            strokeWidth: 12,
                            backgroundColor: AppColors.surfaceWhite,
                            color: AppColors.accentGreen,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          children: [
                            Text("${avgEfficiency.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                            const Text("Efficiency", style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      "Average yield efficiency across ${completed.length} animals.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text("Failed to calculate insights"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveWorkflow(WidgetRef ref) {
    final transfers = ref.watch(transferProvider);
    final pendingTransferCount = transfers.where((t) => t.status == TransferStatus.pending).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text("Active Operations Pipeline", style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Icon(Icons.info_outline, size: 14, color: AppColors.textLight),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStep(ref, 'Intake', '12', Icons.login, ButcherScreen.animalIntake, true),
                  _buildArrow(),
                  _buildStep(ref, 'Slaughter', '8', Icons.precision_manufacturing, ButcherScreen.slaughterLog, false),
                  _buildArrow(),
                  _buildStep(ref, 'Processing', '8', Icons.restaurant, ButcherScreen.meatProcessing, false),
                  _buildArrow(),
                  _buildStep(ref, 'Transfer', '$pendingTransferCount', Icons.local_shipping, ButcherScreen.stockTransfer, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(WidgetRef ref, String label, String count, IconData icon, ButcherScreen target, bool isActive) {
    return InkWell(
      onTap: () => ref.read(butcherNavProvider.notifier).setScreen(target),
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: WorkflowStep(label: label, count: count, icon: icon, isActive: isActive),
      ),
    );
  }

  Widget _buildKPIGrid(double maxWidth, List<SlaughterLog> logs, List<MeatBatch> batches) {
    final completedCount = logs.where((l) => l.status == SlaughterStatus.completed).length;
    final pendingCount = logs.where((l) => l.status == SlaughterStatus.pending).length;
    final totalYield = logs.where((l) => l.status == SlaughterStatus.completed).fold(0.0, (sum, l) => sum + l.estimatedYield);

    int crossAxisCount = maxWidth < 600 ? 2 : (maxWidth < 1200 ? 3 : 5);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: AppSpacing.m,
      mainAxisSpacing: AppSpacing.m,
      childAspectRatio: 2.2,
      children: [
        KPICard(title: 'Animals Today', value: '${logs.length}', subValue: '$pendingCount Pending', icon: Icons.pets, iconColor: Colors.blue, iconBgColor: const Color(0xFFE3F2FD)),
        KPICard(title: 'Slaughtered', value: '$completedCount', icon: Icons.done_all, iconColor: Colors.green, iconBgColor: const Color(0xFFE8F5E9)),
        KPICard(title: 'Yield (Est. kg)', value: totalYield.toStringAsFixed(1), icon: Icons.layers, iconColor: Colors.purple, iconBgColor: const Color(0xFFF3E5F5)),
        KPICard(title: 'Active Batches', value: '${batches.length}', icon: Icons.inventory_2, iconColor: Colors.orange, iconBgColor: const Color(0xFFFFF3E0)),
        const KPICard(title: 'Waste Recorded', value: '25.0 kg', icon: Icons.delete_outline, iconColor: Colors.red, iconBgColor: Color(0xFFFFEBEE)),
      ],
    );
  }

  Widget _buildArrow() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Icon(Icons.arrow_forward_ios, color: AppColors.borderGray, size: 12),
      );

  Widget _buildSlaughterLogs(AsyncValue<List<SlaughterLog>> logsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Recent Activity Logs', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                TextButton(onPressed: () {}, child: const Text('View Detailed Logs', style: TextStyle(fontSize: 12))),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            logsAsync.when(
              data: (logs) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 500),
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('ID', style: TextStyle(fontSize: 11))),
                      DataColumn(label: Text('Animal', style: TextStyle(fontSize: 11))),
                      DataColumn(label: Text('Type', style: TextStyle(fontSize: 11))),
                      DataColumn(label: Text('Weight', style: TextStyle(fontSize: 11))),
                      DataColumn(label: Text('Status', style: TextStyle(fontSize: 11))),
                    ],
                    rows: logs.take(5).map((log) => DataRow(cells: [
                      DataCell(Text(log.id, style: const TextStyle(fontSize: 11))),
                      DataCell(Text(log.animalId, style: const TextStyle(fontSize: 11))),
                      DataCell(Text(log.type.displayName, style: const TextStyle(fontSize: 11))),
                      DataCell(Text('${log.weight}kg', style: const TextStyle(fontSize: 11))),
                      DataCell(StatusChip(label: log.status.name.toUpperCase(), color: _getStatusColor(log.status))),
                    ])).toList(),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SlaughterStatus status) {
    switch (status) {
      case SlaughterStatus.completed: return Colors.green;
      case SlaughterStatus.processing: return Colors.blue;
      case SlaughterStatus.pending: return Colors.orange;
    }
  }

  Widget _buildMeatSummary(AsyncValue<List<SlaughterLog>> logsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yield Summary (MT)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.m),
            logsAsync.when(
              data: (logs) {
                final totalIntake = logs.fold(0.0, (sum, l) => sum + l.weight);
                final totalYield = logs.where((l) => l.status == SlaughterStatus.completed).fold(0.0, (sum, l) => sum + l.estimatedYield);
                return Column(
                  children: [
                    SummaryRow(icon: Icons.monitor_weight_outlined, label: 'Gross Intake', value: '${totalIntake.toStringAsFixed(0)}kg'),
                    SummaryRow(icon: Icons.restaurant, label: 'Est. Net Yield', value: '${totalYield.toStringAsFixed(0)}kg'),
                    SummaryRow(icon: Icons.delete_outline, label: 'Est. Waste/Bone', value: '${(totalIntake - totalYield).toStringAsFixed(0)}kg', iconColor: Colors.red),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text("Error loading summary"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Operational Control', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.m),
            _buildActionBtn('New Intake', Icons.add_circle_outline, true, () {
              ref.read(butcherNavProvider.notifier).setScreen(ButcherScreen.animalIntake);
            }),
            const SizedBox(height: AppSpacing.s),
            _buildActionBtn('Print Batch Labels', Icons.print, false, () {}),
            const SizedBox(height: AppSpacing.s),
            _buildActionBtn('Record Waste', Icons.delete_sweep, false, () {
              ref.read(butcherNavProvider.notifier).setScreen(ButcherScreen.wasteManagement);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, bool primary, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: primary 
        ? ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 16), label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)))
        : OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 16), label: Text(label, style: const TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16))),
    );
  }
}
