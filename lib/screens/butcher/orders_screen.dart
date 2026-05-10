import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../widgets/status_chip.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Current time for demonstration
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Processing Orders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Manage pre-orders and bulk requirements', style: TextStyle(color: AppColors.textLight)),
          const SizedBox(height: AppSpacing.l),
          _buildOrderTabs(),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) => _buildOrderCard(index, now.subtract(Duration(hours: index))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTabs() {
    return Row(
      children: [
        _tabItem('Active (4)', true),
        _tabItem('Pending (12)', false),
        _tabItem('Completed', false),
      ],
    );
  }

  Widget _tabItem(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: isSelected ? AppColors.primaryMaroon : AppColors.textLight,
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            if (isSelected) Container(height: 2, width: 20, color: AppColors.primaryMaroon, margin: const EdgeInsets.only(top: 4)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(int index, DateTime time) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 60,
                decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(AppRadius.s)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('MMM').format(time), style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                    Text(DateFormat('dd').format(time), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(DateFormat('HH:mm').format(time), style: const TextStyle(fontSize: 8, color: AppColors.textLight)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Order #MS-ORD-10$index', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const StatusChip(label: 'PREPARING', color: Colors.blue),
                      ],
                    ),
                    const Text('Client: Prime Steakhouse Inc.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    const SizedBox(height: 4),
                    const Text('Items: 5x Beef Sirloin (10kg), 2x Ribs', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              const VerticalDivider(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Total Wt.', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                  const Text('12.5 kg', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), minimumSize: const Size(60, 30)),
                    child: const Text('Update', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
