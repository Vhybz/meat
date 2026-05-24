import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../services/butcher_service.dart';
import '../../models/butcher_models.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(slaughterLogsProvider);
    final wasteAsync = ref.watch(butcherWasteProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.l),
          
          logsAsync.when(
            data: (logs) {
              final waste = wasteAsync.value ?? [];
              return _buildAnalyticsContent(context, logs, waste);
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Error loading reports: $err'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Operational Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text('Butcher unit efficiency and yield analysis', style: TextStyle(color: AppColors.textLight, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (!isMobile) _buildHeaderButtons(context),
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: AppSpacing.m),
              _buildHeaderButtons(context),
            ],
          ],
        );
      }
    );
  }

  Widget _buildHeaderButtons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () {}, 
          icon: const Icon(Icons.filter_list, size: 16),
          label: const Text('Filter', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generating PDF Report...'))
            );
          },
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Export PDF', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, List<SlaughterLog> logs, List<Map<String, dynamic>> waste) {
    final completed = logs.where((l) => l.status == SlaughterStatus.completed).toList();
    
    double avgYieldRate = 0;
    if (completed.isNotEmpty) {
      final totalIntake = completed.fold(0.0, (sum, l) => sum + l.weight);
      final totalYield = completed.fold(0.0, (sum, l) => sum + l.estimatedYield);
      avgYieldRate = (totalYield / totalIntake) * 100;
    }

    final totalWasteWeight = waste.fold(0.0, (sum, w) => sum + (w['weight'] as num).toDouble());
    final totalIntakeAll = logs.fold(0.0, (sum, l) => sum + l.weight);
    final wasteRatio = totalIntakeAll > 0 ? (totalWasteWeight / totalIntakeAll) * 100 : 0.0;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        GridView.count(
          crossAxisCount: isMobile ? 2 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.m,
          mainAxisSpacing: AppSpacing.m,
          childAspectRatio: isMobile ? 1.2 : 1.8,
          children: [
            _buildResponsiveKPI(
              title: 'Avg. Yield Rate', 
              value: '${avgYieldRate.toStringAsFixed(1)}%', 
              icon: Icons.auto_graph, 
              color: Colors.green, 
              bgColor: const Color(0xFFE8F5E9)
            ),
            _buildResponsiveKPI(
              title: 'Total Waste', 
              value: '${totalWasteWeight.toStringAsFixed(1)} kg', 
              icon: Icons.delete_sweep_outlined, 
              color: Colors.red, 
              bgColor: const Color(0xFFFFEBEE)
            ),
            _buildResponsiveKPI(
              title: 'Waste Ratio', 
              value: '${wasteRatio.toStringAsFixed(1)}%', 
              icon: Icons.analytics_outlined, 
              color: Colors.orange, 
              bgColor: const Color(0xFFFFF3E0)
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth < 900;
            if (isTablet) {
              return Column(
                children: [
                  _buildYieldEfficiencyCard(completed),
                  const SizedBox(height: AppSpacing.l),
                  _buildRecentAnimalsCard(logs),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildYieldEfficiencyCard(completed),
                ),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  flex: 1,
                  child: _buildRecentAnimalsCard(logs),
                ),
              ],
            );
          }
        ),
      ],
    );
  }

  Widget _buildYieldEfficiencyCard(List<SlaughterLog> logs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yield Efficiency by Animal Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: AppSpacing.m),
            if (logs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No data for analysis yet.')))
            else
              ...AnimalType.values.map((type) {
                final animals = logs.where((l) => l.type == type).toList();
                if (animals.isEmpty) return const SizedBox.shrink();
                
                final totalWeight = animals.fold(0.0, (sum, a) => sum + a.weight);
                final totalYield = animals.fold(0.0, (sum, a) => sum + a.estimatedYield);
                final efficiency = (totalYield / totalWeight);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(type.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text('${(efficiency * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentGreen)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: efficiency,
                          minHeight: 10,
                          backgroundColor: AppColors.surfaceWhite,
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Sample size: ${animals.length} animals', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAnimalsCard(List<SlaughterLog> logs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Feedstocks', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.m),
            if (logs.isEmpty)
              const Text('No records.', style: TextStyle(fontSize: 12, color: AppColors.textLight))
            else
              ...logs.take(5).map((l) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryMaroon.withValues(alpha: 0.1),
                  radius: 16,
                  child: const Icon(Icons.pets, size: 14, color: AppColors.primaryMaroon),
                ),
                title: Text(l.animalId.substring(l.animalId.length - (l.animalId.length > 8 ? 8 : l.animalId.length)).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                subtitle: Text(l.type.displayName, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
                trailing: Text('${l.weight.toInt()} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveKPI({required String title, required String value, required IconData icon, required Color color, required Color bgColor}) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
