import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import 'admin_menu_items.dart';

class InventoryControlScreen extends ConsumerWidget {
  const InventoryControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsFutureProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/stock';

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: const MainAppBar(title: 'Inventory Control', showMenuButton: true),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AppSidebar(
                userName: 'Admin User',
                userRole: 'Administrator',
                currentRoute: currentRoute,
                items: getAdminMenuItems(),
                onTap: (route) => navigateAdmin(context, route, currentRoute),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              userName: 'Admin User',
              userRole: 'Administrator',
              currentRoute: currentRoute,
              items: getAdminMenuItems(),
              onTap: (route) => navigateAdmin(context, route, currentRoute),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  productsAsync.when(
                    data: (products) => _buildProductGrid(products),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context, ref),
        backgroundColor: AppColors.primaryMaroon,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New Product', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String selectedCategory = 'Beef';
    String selectedUnit = 'kg';
    final categories = ['Beef', 'Pork', 'Chicken', 'Lamb', 'Goat', 'Other'];
    final units = ['kg', 'lb'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Product', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Enter product details for the catalog', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textLight)),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        hintText: 'e.g. T-Bone Steak',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: priceController,
                            decoration: InputDecoration(
                              labelText: 'Price',
                              prefixText: '₵ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                            ),
                            items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (v) => setState(() => selectedUnit = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: stockController,
                      decoration: InputDecoration(
                        labelText: 'Initial Stock',
                        suffixText: selectedUnit,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  final newProduct = Product(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0.0,
                    category: selectedCategory,
                    imageUrl: 'assets/images/meat_art.jpg', // Default placeholder
                    stockQuantity: double.tryParse(stockController.text) ?? 0.0,
                    unit: selectedUnit,
                  );
                  ref.read(productsFutureProvider.notifier).addProduct(newProduct);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${newProduct.name} added to inventory'),
                      backgroundColor: AppColors.accentGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
              ),
              child: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Master Stock List', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('Manage products, pricing, and stock levels', style: TextStyle(color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1));
      final aspectRatio = constraints.maxWidth > 500 ? 0.8 : 1.2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.m,
          mainAxisSpacing: AppSpacing.m,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          final isLowStock = product.stockQuantity < 10;

          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      product.imageUrl.startsWith('assets/')
                          ? Image.asset(product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                          : Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image)),
                      if (isLowStock)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                            child: const Text('LOW STOCK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(product.category, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GHS ${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                          Text('${product.stockQuantity}${product.unit}', style: TextStyle(fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Consumer(
                          builder: (context, ref, _) => OutlinedButton(
                            onPressed: () => _showUpdateStockDialog(context, ref, product),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryMaroon),
                              foregroundColor: AppColors.primaryMaroon,
                            ),
                            child: const Text('Update Stock'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  void _showUpdateStockDialog(BuildContext context, WidgetRef ref, Product product) {
    final stockController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
        title: Text('Update Stock: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: AppColors.primaryMaroon),
                  const SizedBox(width: AppSpacing.m),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Inventory', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      Text('${product.stockQuantity} ${product.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryMaroon)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            TextField(
              controller: stockController,
              decoration: InputDecoration(
                labelText: 'Add/Remove Quantity',
                helperText: 'Use negative value to reduce stock',
                suffixText: product.unit,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(stockController.text) ?? 0.0;
              if (quantity != 0) {
                ref.read(productsFutureProvider.notifier).updateStock(product.id, quantity);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stock updated for ${product.name}'),
                    backgroundColor: AppColors.primaryMaroon,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
