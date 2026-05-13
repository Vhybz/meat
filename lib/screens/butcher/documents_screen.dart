import 'package:flutter/material.dart';
import '../../core/constants.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth < 600 ? (constraints.maxWidth - 48) / 2 : (constraints.maxWidth - 64) / 4;
              return Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  _buildCategoryCard('Compliance', Icons.verified_user, Colors.green, cardWidth),
                  _buildCategoryCard('Permits', Icons.article, Colors.blue, cardWidth),
                  _buildCategoryCard('Invoices', Icons.receipt_long, Colors.orange, cardWidth),
                  _buildCategoryCard('Logbooks', Icons.book, Colors.purple, cardWidth),
                ],
              );
            }
          ),
          const Text('Standard Operating Procedures & Permits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSpacing.m),
          Card(
            child: Column(
              children: [
                _buildDocItem('Health Inspection Certificate 2024', 'PDF • 1.2 MB', 'Verified', Colors.green),
                const Divider(height: 1),
                _buildDocItem('Standard Slaughter SOP v2.1', 'PDF • 850 KB', 'Active', Colors.blue),
                const Divider(height: 1),
                _buildDocItem('Butcher Hygiene & Safety Guide', 'PDF • 3.4 MB', 'Guide', Colors.orange),
                const Divider(height: 1),
                _buildDocItem('Equipment Maintenance Log - May', 'PDF • 450 KB', 'Recent', Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocItem(String title, String subtitle, String tag, Color tagColor) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.download, size: 20, color: AppColors.textLight),
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
              Text(title == 'Compliance' ? 'Verified' : 'Access', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
