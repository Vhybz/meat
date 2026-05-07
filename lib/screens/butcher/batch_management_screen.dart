import 'package:flutter/material.dart';
import '../../core/constants.dart';

class BatchManagementScreen extends StatelessWidget {
  const BatchManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.m,
                mainAxisSpacing: AppSpacing.m,
                childAspectRatio: 1.5,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('BCH-00${index+1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Icon(Icons.qr_code, size: 20),
                        ],
                      ),
                      const Divider(),
                      const Text('Type: Beef Brisket', style: TextStyle(fontSize: 12)),
                      const Text('Weight: 42.5 kg', style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      Row(
                        children: [
                          const Text('Status: ', style: TextStyle(fontSize: 12)),
                          const Text('Ready', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.print, size: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
