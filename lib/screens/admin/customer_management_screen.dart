import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/customer_provider.dart';
import '../../models/customer_model.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';

class CustomerManagementScreen extends ConsumerWidget {
  const CustomerManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final customers = ref.watch(customerProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/customers';

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: const MainAppBar(title: 'Customer Directory'),
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
                  _buildHeader(context, ref),
                  const SizedBox(height: AppSpacing.xl),
                  _buildCustomerGrid(context, ref, customers),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Regulars', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Maintain a directory of favorite and wholesale customers', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddCustomerDialog(context, ref),
          icon: const Icon(Icons.person_add),
          label: const Text('Add Customer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerGrid(BuildContext context, WidgetRef ref, List<Customer> customers) {
    if (customers.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No customers in directory yet.')));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1));
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: customers.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.m,
          mainAxisSpacing: AppSpacing.m,
          childAspectRatio: 2.5,
        ),
        itemBuilder: (context, index) {
          final c = customers[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryMaroon.withOpacity(0.1),
                child: Icon(c.isFavorite ? Icons.star : Icons.person, color: c.isFavorite ? Colors.orange : AppColors.primaryMaroon),
              ),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(c.phone, style: const TextStyle(fontSize: 12)),
              trailing: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'fav') {
                    ref.read(customerProvider.notifier).toggleFavorite(c.id);
                  } else if (val == 'del') {
                    ref.read(customerProvider.notifier).deleteCustomer(c.id);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'fav', child: Text(c.isFavorite ? 'Remove Favorite' : 'Mark as Favorite')),
                  const PopupMenuItem(value: 'del', child: Text('Delete Record', style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: const Text('Add Regular Customer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController, 
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController, 
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), hintText: '10 digits'), 
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length != 10) return 'Exactly 10 digits required';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newCustomer = Customer(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  phone: phoneController.text,
                );
                ref.read(customerProvider.notifier).addCustomer(newCustomer);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }
}
