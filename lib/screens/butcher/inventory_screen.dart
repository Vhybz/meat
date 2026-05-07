import 'package:flutter/material.dart';
import '../../core/constants.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Slaughterhouse Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Current stock of processed cuts & carcasses', style: TextStyle(color: AppColors.textLight)),
                ],
              ),
              const Spacer(),
              _buildFilterChip('All', true),
              _buildFilterChip('Beef', false),
              _buildFilterChip('Pork', false),
              _buildFilterChip('Other', false),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildStockAlerts(),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: AppSpacing.m,
                mainAxisSpacing: AppSpacing.m,
                childAspectRatio: 1.2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) => _buildInventoryCard(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textDark, fontSize: 12)),
        selected: isSelected,
        onSelected: (v) {},
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryMaroon,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s), side: const BorderSide(color: AppColors.borderGray)),
      ),
    );
  }

  Widget _buildStockAlerts() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 12),
          Text('Low Stock Alert: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          Text('Beef Ribs and Pork Belly are below threshold.', style: TextStyle(color: Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(int index) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.inventory_2_outlined, color: AppColors.primaryMaroon, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('BEEF', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Spacer(),
            const Text('Ribeye Steak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Text('Batch: BCH-042', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('In Stock', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                    Text('45.2 kg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.history, size: 18), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
