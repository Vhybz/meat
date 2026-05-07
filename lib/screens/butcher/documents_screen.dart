import 'package:flutter/material.dart';
import '../../core/constants.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCategoryCard('Compliance', Icons.verified_user, Colors.green),
              _buildCategoryCard('Permits', Icons.article, Colors.blue),
              _buildCategoryCard('Invoices', Icons.receipt_long, Colors.orange),
              _buildCategoryCard('Logbooks', Icons.book, Colors.purple),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          const Text('Recent Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: 8,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text('Health Inspection Report - May ${index + 1}, 2024'),
                  subtitle: const Text('PDF • 2.4 MB • Uploaded by Admin'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.download), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.visibility), onPressed: () {}),
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

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Text('12 Files', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
