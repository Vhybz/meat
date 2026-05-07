import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/kpi_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(child: KPICard(title: 'Avg. Yield Rate', value: '72.4%', icon: Icons.auto_graph, iconColor: Colors.green, iconBgColor: Color(0xFFE8F5E9))),
              SizedBox(width: AppSpacing.m),
              Expanded(child: KPICard(title: 'Processing Time', value: '45m/Animal', icon: Icons.timer, iconColor: Colors.blue, iconBgColor: Color(0xFFE3F2FD))),
              SizedBox(width: AppSpacing.m),
              Expanded(child: KPICard(title: 'Waste Ratio', value: '12%', icon: Icons.delete_outline, iconColor: Colors.red, iconBgColor: Color(0xFFFFEBEE))),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Yield Trend', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.l),
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(AppRadius.m),
                          ),
                          child: const Center(child: Text('Yield Chart Placeholder', style: TextStyle(color: AppColors.textLight))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.l),
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recent Exports', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.m),
                        ...List.generate(4, (index) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.table_view, color: Colors.green),
                          title: Text('Yield_Report_W${index + 1}.csv'),
                          subtitle: const Text('Generated May 12'),
                          trailing: const Icon(Icons.download, size: 18),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
