import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../core/utils.dart';
import 'package:intl/intl.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';

class InventoryControlScreen extends ConsumerWidget {
  const InventoryControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

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
                  _buildHeader(context, ref, productsAsync.value ?? []),
                  const SizedBox(height: AppSpacing.xl),
                  productsAsync.when(
                    data: (products) {
                      final activeProducts = products.where((p) => !p.isDeleted).toList();
                      return _buildProductGrid(activeProducts, ref);
                    },
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, List<Product> products) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Master Stock List', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Manage products, pricing, and stock levels', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showPromotionDialog(context, ref, products),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Manage Promotions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                side: BorderSide(color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPromotionDialog(BuildContext context, WidgetRef ref, List<Product> products) {
    final formKey = GlobalKey<FormState>();
    final percentageController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    PromoTarget selectedTarget = PromoTarget.both;
    PromoCustomerTarget selectedCustomerTarget = PromoCustomerTarget.all;
    final selectedIds = <String>{};
    // Initialize with all products selected as per request
    for (var p in products) {
      selectedIds.add(p.id);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final allSelected = selectedIds.length == products.length;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
            title: const Row(
              children: [
                Icon(Icons.campaign_outlined, color: Colors.orange),
                SizedBox(width: 12),
                Text('Run Promotion'),
              ],
            ),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: percentageController,
                        decoration: const InputDecoration(
                          labelText: 'Discount Percentage (%)',
                          hintText: 'e.g. 10',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = double.tryParse(v);
                          if (n == null || n <= 0 || n > 100) return 'Invalid % (1-100)';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.m),
                      DropdownButtonFormField<PromoTarget>(
                        value: selectedTarget,
                        decoration: const InputDecoration(labelText: 'Promotion Target', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: PromoTarget.both, child: Text('Both Retail & Wholesale')),
                          DropdownMenuItem(value: PromoTarget.retail, child: Text('Retail Only')),
                          DropdownMenuItem(value: PromoTarget.wholesale, child: Text('Wholesale Only')),
                        ],
                        onChanged: (v) => setState(() => selectedTarget = v!),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      DropdownButtonFormField<PromoCustomerTarget>(
                        value: selectedCustomerTarget,
                        decoration: const InputDecoration(labelText: 'Customer Eligibility', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: PromoCustomerTarget.all, child: Text('All Customers (Public)')),
                          DropdownMenuItem(value: PromoCustomerTarget.regularsOnly, child: Text('Regulars/Favorites Only')),
                        ],
                        onChanged: (v) => setState(() => selectedCustomerTarget = v!),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      InkWell(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: (startDate != null && endDate != null) 
                              ? DateTimeRange(start: startDate!, end: endDate!)
                              : DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 7))),
                          );
                          if (picked != null) {
                            setState(() {
                              startDate = picked.start;
                              endDate = picked.end;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: startDate == null ? Colors.grey : AppColors.primaryMaroon),
                            borderRadius: BorderRadius.circular(AppRadius.s),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                startDate == null 
                                  ? 'Select Promotion Dates (Required)' 
                                  : '${DateFormat('MMM dd').format(startDate!)} - ${DateFormat('MMM dd').format(endDate!)}',
                                style: TextStyle(
                                  color: startDate == null ? Colors.grey : Colors.black,
                                  fontWeight: startDate == null ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Select Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (allSelected) {
                                  selectedIds.clear();
                                } else {
                                  selectedIds.addAll(products.map((p) => p.id));
                                }
                              });
                            },
                            child: Text(allSelected ? 'Deselect All' : 'Select All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderGray),
                          borderRadius: BorderRadius.circular(AppRadius.s),
                        ),
                        child: ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final p = products[index];
                            return CheckboxListTile(
                              title: Text(p.name, style: const TextStyle(fontSize: 13)),
                              subtitle: Text('Current: ₵${p.retailPrice}', style: const TextStyle(fontSize: 10)),
                              value: selectedIds.contains(p.id),
                              onChanged: (val) {
                                setState(() {
                                  if (val!) {
                                    selectedIds.add(p.id);
                                  } else {
                                    selectedIds.remove(p.id);
                                  }
                                });
                              },
                              dense: true,
                              activeColor: AppColors.primaryMaroon,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(productsFutureProvider.notifier).clearPromotions();
                  Navigator.pop(context);
                },
                child: const Text('Clear All Promos', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: (selectedIds.isEmpty || startDate == null || endDate == null) ? null : () {
                  if (formKey.currentState!.validate()) {
                    final percentage = double.tryParse(percentageController.text) ?? 0;
                    ref.read(productsFutureProvider.notifier).applyPromotion(
                      percentage, 
                      startDate!, 
                      endDate!, 
                      selectedTarget,
                      selectedCustomerTarget,
                      selectedIds: selectedIds.toList()
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Apply to ${selectedIds.length} Products'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final retailPriceController = TextEditingController();
    final wholesalePriceController = TextEditingController();
    final stockController = TextEditingController();
    final otherCategoryController = TextEditingController();
    String selectedCategory = 'Beef';
    WeightUnit selectedUnit = WeightUnit.kg;
    final categories = ['Beef', 'Pork', 'Chicken', 'Lamb', 'Goat', 'Other'];
    
    Uint8List? imageBytes;
    String? imageName;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: const BoxDecoration(
              color: AppColors.primaryMaroon,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add New Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Enter product details for the shop catalog', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(AppSpacing.l),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker Section
                    Center(
                      child: InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setState(() {
                              imageBytes = bytes;
                              imageName = image.name;
                            });
                          }
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: imageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.m),
                                  child: Image.memory(imageBytes!, fit: BoxFit.cover),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, color: AppColors.textLight),
                                    SizedBox(height: 4),
                                    Text('Add Image', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    _buildFormTextField(
                      controller: nameController,
                      label: 'Product Name',
                      hint: 'e.g. T-Bone Steak',
                      icon: Icons.shopping_bag_outlined,
                      isName: true,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                        prefixIcon: const Icon(Icons.category_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    ),
                    if (selectedCategory == 'Other') ...[
                      const SizedBox(height: AppSpacing.m),
                      _buildFormTextField(
                        controller: otherCategoryController,
                        label: 'Custom Category Name',
                        hint: 'e.g. Rabbit',
                        icon: Icons.edit_note,
                        isName: true,
                        validator: (v) => (selectedCategory == 'Other' && (v == null || v.isEmpty)) ? 'Required' : null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormTextField(
                            controller: retailPriceController,
                            label: 'Retail Price',
                            prefix: '₵ ',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: _buildFormTextField(
                            controller: wholesalePriceController,
                            label: 'Wholesale Price',
                            prefix: '₵ ',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildFormTextField(
                            controller: stockController,
                            label: 'Initial Stock',
                            suffix: selectedUnit.name,
                            icon: Icons.inventory_2_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid qty';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: DropdownButtonFormField<WeightUnit>(
                            value: selectedUnit,
                            decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                            items: WeightUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.name.toUpperCase()))).toList(),
                            onChanged: (v) => setState(() => selectedUnit = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() => isUploading = true);
                  
                  String finalImageUrl = 'assets/images/meat_art.jpg';
                  
                  if (imageBytes != null && imageName != null) {
                    final uploadedUrl = await ref.read(productsFutureProvider.notifier).uploadImage(
                      imageBytes!, 
                      'prod_${DateTime.now().millisecondsSinceEpoch}_$imageName'
                    );
                    if (uploadedUrl != null) {
                      finalImageUrl = uploadedUrl;
                    }
                  }

                  final newProduct = Product(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    retailPrice: double.tryParse(retailPriceController.text) ?? 0.0,
                    wholesalePrice: double.tryParse(wholesalePriceController.text) ?? 0.0,
                    category: selectedCategory == 'Other' ? otherCategoryController.text : selectedCategory,
                    imageUrl: finalImageUrl,
                    stockQuantity: double.tryParse(stockController.text) ?? 0.0,
                    unit: selectedUnit.name,
                  );
                  await ref.read(productsFutureProvider.notifier).addProduct(newProduct);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
              ),
              child: isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, Product product) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product.name);
    final retailPriceController = TextEditingController(text: product.retailPrice.toString());
    final wholesalePriceController = TextEditingController(text: product.wholesalePrice.toString());
    final otherCategoryController = TextEditingController();
    String selectedCategory = product.category;
    final categories = ['Beef', 'Pork', 'Chicken', 'Lamb', 'Goat', 'Other'];

    if (!categories.contains(product.category)) {
      selectedCategory = 'Other';
      otherCategoryController.text = product.category;
    }
    
    Uint8List? imageBytes;
    String? imageName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: Text('Edit Product: ${product.name}'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker Section
                    Center(
                      child: InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setState(() {
                              imageBytes = bytes;
                              imageName = image.name;
                            });
                          }
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            child: imageBytes != null
                                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                                : (product.imageUrl.startsWith('http')
                                    ? Image.network(product.imageUrl, fit: BoxFit.cover)
                                    : Image.asset(product.imageUrl, fit: BoxFit.cover)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    _buildFormTextField(
                      controller: nameController, 
                      label: 'Product Name',
                      isName: true,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    ),
                    if (selectedCategory == 'Other') ...[
                      const SizedBox(height: 16),
                      _buildFormTextField(
                        controller: otherCategoryController,
                        label: 'Custom Category Name',
                        isName: true,
                        validator: (v) => (selectedCategory == 'Other' && (v == null || v.isEmpty)) ? 'Required' : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormTextField(
                            controller: retailPriceController, 
                            label: 'Retail Price', 
                            prefix: '₵ ',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFormTextField(
                            controller: wholesalePriceController, 
                            label: 'Wholesale Price', 
                            prefix: '₵ ',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() => isUploading = true);

                  String finalImageUrl = product.imageUrl;

                  if (imageBytes != null && imageName != null) {
                    final uploadedUrl = await ref.read(productsFutureProvider.notifier).uploadImage(
                      imageBytes!, 
                      'prod_${DateTime.now().millisecondsSinceEpoch}_$imageName'
                    );
                    if (uploadedUrl != null) {
                      finalImageUrl = uploadedUrl;
                    }
                  }

                  final updated = product.copyWith(
                    name: nameController.text,
                    retailPrice: double.tryParse(retailPriceController.text),
                    wholesalePrice: double.tryParse(wholesalePriceController.text),
                    category: selectedCategory == 'Other' ? otherCategoryController.text : selectedCategory,
                    imageUrl: finalImageUrl,
                  );
                  await ref.read(productsFutureProvider.notifier).updateProduct(updated);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
              child: isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefix,
    String? suffix,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isName = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: keyboardType,
      inputFormatters: [
        if (isName) FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]')),
        if (keyboardType == const TextInputType.numberWithOptions(decimal: true))
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      validator: validator,
    );
  }

  Widget _buildProductGrid(List<Product> products, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1));
      final aspectRatio = constraints.maxWidth > 500 ? 0.75 : 1.1;
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
          final isScheduled = product.isPromoScheduled;
          final hasPromo = isScheduled; // Show in admin grid if scheduled

          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      product.imageUrl.isEmpty
                          ? Container(color: AppColors.surfaceWhite, child: const Center(child: Icon(Icons.image, color: AppColors.borderGray)))
                          : product.imageUrl.startsWith('assets/')
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
                      if (hasPromo)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              product.promoCustomerTarget == PromoCustomerTarget.regularsOnly 
                                ? '-${product.discountPercentage.toInt()}% REGULARS' 
                                : '-${product.discountPercentage.toInt()}% PROMO', 
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                            ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                          IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () => _showEditProductDialog(context, ref, product), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        ],
                      ),
                      Text(product.category, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ret: ₵${product.retailPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, decoration: product.isPromoActiveFor(false, null, ignoreCustomerFilter: true) ? TextDecoration.lineThrough : null)),
                              if (product.isPromoActiveFor(false, null, ignoreCustomerFilter: true)) Text('₵${product.getPrice(false, ignoreCustomerFilter: true).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                              Text('Whl: ₵${product.wholesalePrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: AppColors.textLight, decoration: product.isPromoActiveFor(true, null, ignoreCustomerFilter: true) ? TextDecoration.lineThrough : null)),
                              if (product.isPromoActiveFor(true, null, ignoreCustomerFilter: true)) Text('₵${product.getPrice(true, ignoreCustomerFilter: true).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                          Text('${product.stockQuantity}${product.unit}', style: TextStyle(fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _showUpdateStockDialog(context, ref, product),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryMaroon),
                            foregroundColor: AppColors.primaryMaroon,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Update Stock', style: TextStyle(fontSize: 12)),
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
    final formKey = GlobalKey<FormState>();
    final stockController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
        title: Text('Update Stock: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.primaryMaroon.withOpacity(0.05),
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
              TextFormField(
                controller: stockController,
                decoration: InputDecoration(
                  labelText: 'Add/Remove Quantity',
                  helperText: 'Use negative value to reduce stock',
                  suffixText: product.unit,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                autofocus: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid quantity';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final quantity = double.tryParse(stockController.text) ?? 0.0;
                if (quantity != 0) {
                  ref.read(productsFutureProvider.notifier).updateStock(product.id, quantity);
                  Navigator.pop(context);
                }
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
