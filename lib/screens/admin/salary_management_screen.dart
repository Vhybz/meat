import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../services/user_provider.dart';
import '../../services/sms_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
import '../../widgets/role_pop_scope.dart';

class SalaryManagementScreen extends ConsumerWidget {
  const SalaryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final users = ref.watch(userProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/salaries';

    final now = DateTime.now();
    
    // Filter users who are due for salary
    final pendingPayments = users.where((u) {
      if (u.isDeleted || u.status != AccountStatus.approved) return false;
      if (u.salaryAmount == null || u.salaryDay == null) return false;
      
      // If today is past or on the salary day
      if (now.day >= u.salaryDay!) {
        // Check if already paid this month
        if (u.lastSalaryDate == null) return true;
        
        final lastPaid = u.lastSalaryDate!;
        if (lastPaid.month != now.month || lastPaid.year != now.year) {
          return true;
        }
      }
      return false;
    }).toList();

    return RolePopScope(
      currentRoute: currentRoute,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: const MainAppBar(title: 'Salary Management', showMenuButton: true),
        drawer: isDesktop ? null : Drawer(
          child: AppSidebar(
            userId: user.id,
            userName: user.name,
            userRole: user.activePrimaryRole.name.toUpperCase(),
            currentRoute: currentRoute,
            items: MenuService.getMenuItemsForUser(user),
            onTap: (route) => MenuService.navigate(context, route, currentRoute),
          ),
        ),
        body: Row(
          children: [
            if (isDesktop)
              AppSidebar(
                userId: user.id,
                userName: user.name,
                userRole: user.activePrimaryRole.name.toUpperCase(),
                currentRoute: currentRoute,
                items: MenuService.getMenuItemsForUser(user),
                onTap: (route) => MenuService.navigate(context, route, currentRoute),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme, pendingPayments.length),
                    const SizedBox(height: AppSpacing.xl),
                    if (pendingPayments.isEmpty)
                      _buildEmptyState(theme)
                    else
                      _buildPaymentGrid(context, ref, pendingPayments),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payroll Tasks',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        Text(
          count == 0 
            ? 'All staff salaries for this period have been settled.' 
            : 'You have $count pending salary payments to confirm.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.assignment_turned_in_rounded, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
            'No Pending Salaries',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text('Check back on the next scheduled pay day.'),
        ],
      ),
    );
  }

  Widget _buildPaymentGrid(BuildContext context, WidgetRef ref, List<UserAccount> pending) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final staff = pending[index];
            return _buildSalaryCard(context, ref, staff);
          },
        );
      },
    );
  }

  Widget _buildSalaryCard(BuildContext context, WidgetRef ref, UserAccount staff) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(staff.firstName[0], style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(staff.role.name.toUpperCase(), style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SALARY AMOUNT', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('₵${staff.salaryAmount?.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('DUE DAY', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('Day ${staff.salaryDay}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmPayment(context, ref, staff),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('CONFIRM PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPayment(BuildContext context, WidgetRef ref, UserAccount staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Salary Payment'),
        content: Text('Are you sure you have settled the payment of ₵${staff.salaryAmount?.toStringAsFixed(2)} to ${staff.name}?\n\nAn automated confirmation SMS and notification will be sent to the employee.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              // 1. Update DB/State
              await ref.read(userProvider.notifier).updateSalary(
                staff.id,
                lastPaid: DateTime.now(),
              );
              
              // 2. Send SMS
              try {
                await SmsService.sendCustomSms(
                  staff.phone ?? '', 
                  'Hello ${staff.firstName}, your salary of GHS ${staff.salaryAmount?.toStringAsFixed(2)} for ${DateFormat('MMMM yyyy').format(DateTime.now())} has been settled. Thank you!'
                );
              } catch (e) {
                debugPrint('SMS Failed: $e');
              }

              // 3. Add Notification
              ref.read(notificationProvider.notifier).addNotification(
                'Salary Settled',
                'Your salary for ${DateFormat('MMMM yyyy').format(DateTime.now())} has been confirmed by Admin.',
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment confirmed for ${staff.name}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('CONFIRM SETTLED'),
          ),
        ],
      ),
    );
  }
}
