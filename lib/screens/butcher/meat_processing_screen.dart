import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/status_chip.dart';

class MeatProcessingScreen extends StatelessWidget {
  const MeatProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveCarcasses(),
          const SizedBox(height: AppSpacing.l),
          _buildCutProductionList(),
        ],
      ),
    );
  }

  Widget _buildActiveCarcasses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Carcasses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => Container(
              width: 300,
              margin: const EdgeInsets.only(right: AppSpacing.m),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ID: ANM-2024-0$index', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const StatusChip(label: 'IN PROGRESS', color: Colors.blue),
                        ],
                      ),
                      const Divider(),
                      const Text('Type: Whole Cow', style: TextStyle(fontSize: 12)),
                      const Text('Start Weight: 450.0 kg', style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      const LinearProgressIndicator(value: 0.6, backgroundColor: AppColors.surfaceWhite, color: AppColors.primaryMaroon),
                      const SizedBox(height: 8),
                      const Text('60% Processed', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCutProductionList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Cut Production', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.m),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: AppColors.surfaceWhite),
                  children: [
                    Padding(padding: EdgeInsets.all(12), child: Text('Cut Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(12), child: Text('Batch ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(12), child: Text('Weight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(12), child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                ...List.generate(5, (index) => TableRow(
                  children: [
                    const Padding(padding: EdgeInsets.all(12), child: Text('Beef Ribeye', style: TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(12), child: Text('BCH-0$index', style: const TextStyle(fontSize: 12))),
                    const Padding(padding: EdgeInsets.all(12), child: Text('12.5 kg', style: TextStyle(fontSize: 12))),
                    const Padding(padding: EdgeInsets.all(12), child: Text('10:24 AM', style: TextStyle(fontSize: 12))),
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
