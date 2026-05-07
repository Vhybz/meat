import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';
import '../../services/user_provider.dart';
import '../../models/user_model.dart';

class SuperAdminScreen extends ConsumerWidget {
  const SuperAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingUsers = ref.watch(userProvider.notifier).getPendingUsers();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B), // Cyber/Dark theme for Super Admin
      appBar: MainAppBar(
        title: 'ROOT ACCESS: SUPER ADMIN', 
        showMenuButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(context),
            const SizedBox(height: AppSpacing.xl),
            if (pendingUsers.isNotEmpty) ...[
              _buildPendingApprovalSection(context, ref, pendingUsers),
              const SizedBox(height: AppSpacing.xl),
            ],
            _buildSystemHealth(context),
            const SizedBox(height: AppSpacing.xl),
            _buildControlPanel(),
            const SizedBox(height: AppSpacing.xl),
            _buildGlobalLogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovalSection(BuildContext context, WidgetRef ref, List<UserAccount> pending) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.orange),
              SizedBox(width: AppSpacing.m),
              Text('Pending Account Approvals', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          ...pending.map((user) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: Text(user.name[0], style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${user.role.name.toUpperCase()} • ${user.email}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => ref.read(userProvider.notifier).approveUser(user.id),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => ref.read(userProvider.notifier).deleteUser(user.id),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: Colors.red, size: 24),
                  SizedBox(width: AppSpacing.s),
                  Text('Elevated Privileges Active', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              const Text('You have total control over the MS Management System.', style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: AppSpacing.s),
              const Text('ID: SU-ROOT-001', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
            ],
          )
        : const Row(
            children: [
              Icon(Icons.security, color: Colors.red, size: 32),
              SizedBox(width: AppSpacing.m),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Elevated Privileges Active', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('You have total control over the MS Management System.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Spacer(),
              Text('ID: SU-ROOT-001', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
            ],
          ),
    );
  }

  Widget _buildSystemHealth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = width < 600 ? 1 : (width < 900 ? 2 : 3);
    double aspectRatio = width < 600 ? 4.0 : 2.5;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.m,
      mainAxisSpacing: AppSpacing.m,
      childAspectRatio: aspectRatio,
      children: [
        _healthCard('Database Server', '99.9% Uptime', Colors.green),
        _healthCard('SMS Gateway', 'GHS 42.50 Bal', Colors.blue),
        _healthCard('Memory Usage', '248MB / 1GB', Colors.orange),
      ],
    );
  }

  Widget _healthCard(String title, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Global Control Panel', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.m,
          children: [
            _controlBtn('Purge Cache', Icons.cleaning_services, Colors.orange),
            _controlBtn('Database Backup', Icons.backup, Colors.blue),
            _controlBtn('Reset Passwords', Icons.lock_reset, Colors.purple),
            _controlBtn('Broadcast Message', Icons.campaign, Colors.green),
            _controlBtn('System Lockdown', Icons.gpp_maybe, Colors.red),
            _controlBtn('View Source', Icons.code, Colors.white60),
          ],
        ),
      ],
    );
  }

  Widget _controlBtn(String label, IconData icon, Color color) {
    return SizedBox(
      width: 180,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1E),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          padding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildGlobalLogs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Master Activity Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.m),
          _logEntry('Admin', 'Updated Inventory Pricing', '2 mins ago'),
          _logEntry('Cashier #1', 'Completed Sale INV-902', '5 mins ago'),
          _logEntry('Butcher', 'Started Batch #49', '12 mins ago'),
          _logEntry('System', 'Daily Backup Completed', '1 hour ago'),
        ],
      ),
    );
  }

  Widget _logEntry(String user, String action, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('[$time]', style: const TextStyle(color: Colors.white30, fontSize: 10, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Text(user, style: const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              action, 
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
