import 'package:flutter/material.dart';
import '../../core/constants.dart';

class WasteManagementScreen extends StatelessWidget {
  const WasteManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Text('Waste & By-Product Control', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Recording and monitoring slaughterhouse disposal', style: TextStyle(color: AppColors.textLight)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Record Waste'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildWasteDashboard(),
          const SizedBox(height: AppSpacing.l),
          _buildRecentDisposals(),
        ],
      ),
    );
  }

  Widget _buildWasteDashboard() {
    return Row(
      children: [
        _wasteStatCard('Total Waste (Mo)', '245.8 kg', '↑ 12%', Colors.red),
        _wasteStatCard('Recycled', '120.4 kg', '↓ 5%', Colors.green),
        _wasteStatCard('Disposal Cost', 'P12,450', 'Stable', Colors.blue),
      ],
    );
  }

  Widget _wasteStatCard(String title, String value, String trend, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(trend, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDisposals() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Records', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.m),
            ...List.generate(4, (index) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surfaceWhite, shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
              title: Text('Bone Trimmings - Batch #10$index'),
              subtitle: const Text('May 12, 2024 • Organic Waste'),
              trailing: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('12.5 kg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Disposed', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
