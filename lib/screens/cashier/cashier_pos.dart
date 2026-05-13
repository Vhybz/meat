import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/product_card.dart';
import '../../widgets/cart_item_tile.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/cart_provider.dart';
import '../../services/product_service.dart';
import '../../services/transfer_provider.dart';
import '../../services/sale_provider.dart';
import '../../services/customer_provider.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../models/transfer_models.dart';
import '../../models/sale_model.dart';
import '../../models/product.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/receipt_service.dart';
import '../../services/sms_service.dart';
import '../../widgets/role_pop_scope.dart';

enum POSView { sales, history }

class CashierPOS extends ConsumerStatefulWidget {
  const CashierPOS({super.key});

  @override
  ConsumerState<CashierPOS> createState() => _CashierPOSState();
}

class _CashierPOSState extends ConsumerState<CashierPOS> {
  POSView _currentView = POSView.sales;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Beef', 'Pork', 'Chicken', 'Goat', 'Others'];
  
  String _productSearchQuery = '';
  String _historySearchQuery = '';
  DateTime? _historyFilterDate;

  // Selected customer for the current sale
  Customer? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    // Instant Permission Guard: Redirect if access is revoked
    final roles = user.activeRoles;
    final hasAccess = roles.contains(UserRole.cashier) || roles.contains(UserRole.superAdmin) || user.enabledPermissions.contains('/cashier');
    
    if (!hasAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final transfers = ref.watch(transferProvider);
    final pendingTransfers = transfers.where((t) => t.status == TransferStatus.pending).toList();
    final isWholesale = ref.watch(isWholesaleProvider);
    final menuItems = ref.watch(menuItemsProvider);

    return RolePopScope(
      currentRoute: '/cashier',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentView != POSView.sales) {
            setState(() => _currentView = POSView.sales);
          } else {
            // Already on Sales (Home), stay here instead of showing exit dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Use the menu to logout or switch accounts'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: MainAppBar(
            title: _currentView == POSView.sales 
                ? 'POS System (${isWholesale ? "Wholesale" : "Retail"})' 
                : 'Sales History',
            actions: [
              _buildNotificationBadge(pendingTransfers),
            ],
          ),
        drawer: isDesktop ? null : Drawer(child: _buildSidebar(context, user, menuItems)),
        body: Row(
          children: [
            if (isDesktop) _buildSidebar(context, user, menuItems),
            Expanded(
              child: _currentView == POSView.sales 
                ? _buildPOSLayout(isMobile, isDesktop)
                : _buildHistoryLayout(),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(child: _buildFooter()),
        floatingActionButton: (isMobile && _currentView == POSView.sales)
            ? SafeArea(
                child: FloatingActionButton.extended(
                  onPressed: () => _showMobileCart(),
                  label: const Text('View Cart'),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart),
                      if (ref.watch(cartProvider).isNotEmpty)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.red,
                            child: Text(
                              '${ref.watch(cartProvider).length}',
                              style: const TextStyle(color: Colors.white, fontSize: 8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                ),
              )
            : null,
      ),
    ),
    );
  }

  void _showMobileCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: _buildCartSection(context, ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBadge(List<StockTransfer> pendingTransfers) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.inventory_2_outlined),
          onPressed: () => _showIncomingStockDialog(context, ref, pendingTransfers),
        ),
        if (pendingTransfers.isNotEmpty)
          Positioned(
            right: 4,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '${pendingTransfers.length}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPOSLayout(bool isMobile, bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: _buildProductSection(context, ref),
          ),
        ),
        if (!isMobile)
          Container(
            width: isDesktop ? 400 : 300,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: isDark ? const Color(0xFF2C2C2C) : AppColors.borderGray)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            child: _buildCartSection(context, ref),
          ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context, UserAccount user, List<SidebarItem> menuItems) {
    const currentRoute = '/cashier';
    return AppSidebar(
      userId: user.id,
      userName: user.name,
      userRole: user.activePrimaryRole.name.toUpperCase(),
      currentRoute: currentRoute,
      items: menuItems,
      onTap: (route) => MenuService.navigate(context, route, currentRoute),
    );
  }

  Widget _buildProductSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsFutureProvider);
    final isWholesale = ref.watch(isWholesaleProvider);
    int crossAxisCount = ResponsiveLayout.isMobile(context) ? 2 : (ResponsiveLayout.isTablet(context) ? 3 : 4);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          _buildPOSControls(),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products
                    .where((p) => !p.isDeleted)
                    .where((p) => _selectedCategory == 'All' || p.category == _selectedCategory)
                    .where((p) => p.name.toLowerCase().contains(_productSearchQuery.toLowerCase()))
                    .toList();
                
                if (filtered.isEmpty) {
                  return Center(child: Text(_productSearchQuery.isEmpty ? 'No items in this category' : 'No products match "$_productSearchQuery"', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.s,
                    mainAxisSpacing: AppSpacing.s,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final hasPromo = product.isPromoActiveFor(isWholesale, _selectedCustomer);
                    final currentPrice = product.getPrice(isWholesale, customer: _selectedCustomer);

                    return ProductCard(
                      name: product.name,
                      category: product.category,
                      price: '₵${currentPrice.toStringAsFixed(2)}/${product.unit}',
                      originalPrice: hasPromo ? '₵${(isWholesale ? product.wholesalePrice : product.retailPrice).toStringAsFixed(2)}' : null,
                      promoLabel: hasPromo ? '${product.discountPercentage.toInt()}% OFF' : null,
                      imageUrl: product.imageUrl,
                      onTap: () => _showWeightInputDialog(product),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPOSControls() {
    final isWholesale = ref.watch(isWholesaleProvider);
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 45,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(child: _modeButton('Retail', !isWholesale)),
                    Expanded(child: _modeButton('Wholesale', isWholesale)),
                  ],
                ),
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: AppSpacing.m),
              SizedBox(
                width: 200,
                child: _buildCategoryDropdown(),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: TextField(
                  onChanged: (v) => setState(() => _productSearchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                ),
              ),
            ),
            if (isMobile) ...[
              const SizedBox(width: AppSpacing.s),
              SizedBox(
                width: 120,
                child: _buildCategoryDropdown(),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) => setState(() {
        _selectedCategory = v!;
        _productSearchQuery = ''; 
      }),
    );
  }

  Widget _modeButton(String label, bool isSelected) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        final newMode = label == 'Wholesale';
        if (ref.read(cartProvider).isNotEmpty) {
          _confirmModeChange(newMode);
        } else {
          ref.read(isWholesaleProvider.notifier).state = newMode;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.m - 4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _confirmModeChange(bool newMode) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Sale Mode?'),
        content: const Text('Changing the mode (Retail/Wholesale) will CLEAR your current cart because prices vary. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              ref.read(isWholesaleProvider.notifier).state = newMode;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
            child: const Text('Clear Cart & Change'),
          ),
        ],
      ),
    );
  }

  void _showWeightInputDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductWeightDialog(
        product: product,
        customer: _selectedCustomer,
        onAdd: (weight, price, original) {
          ref.read(cartProvider.notifier).addItemWithCustomPrice(product, weight, price, original);
        },
      ),
    );
  }

  Widget _buildCartSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cartItems = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_outlined),
              const SizedBox(width: 8),
              const Text('Current Sale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              if (cartItems.isNotEmpty)
                IconButton(
                  onPressed: () => notifier.clear(),
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        // Customer Selection
        ListTile(
          dense: true,
          leading: const Icon(Icons.person_outline, size: 20),
          title: Text(_selectedCustomer?.name ?? 'Select Customer', 
            style: TextStyle(fontWeight: _selectedCustomer != null ? FontWeight.bold : FontWeight.normal, color: theme.colorScheme.onSurface)),
          subtitle: _selectedCustomer != null ? Text(_selectedCustomer!.phone, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)) : null,
          trailing: IconButton(
            icon: Icon(_selectedCustomer == null ? Icons.add_circle_outline : Icons.edit, size: 18),
            onPressed: () => _showCustomerDialog(),
          ),
          onTap: () => _showCustomerDialog(),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Expanded(
          child: cartItems.isEmpty
              ? Center(child: Text('Cart is empty', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return CartItemTile(
                      name: item.product.name,
                      qty: '1',
                      weight: WeightConverter.formatShort(item.quantity),
                      amount: '₵${item.total.toStringAsFixed(2)}',
                      onDelete: () => notifier.removeItem(index),
                    );
                  },
                ),
        ),
        _buildCartSummary(ref),
      ],
    );
  }

  void _showCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomerSelectionDialog(
        onSelected: (customer) {
          setState(() {
            _selectedCustomer = customer;
          });
        },
      ),
    );
  }

  Widget _buildCartSummary(WidgetRef ref) {
    final theme = Theme.of(context);
    final cartItems = ref.watch(cartProvider);
    final isWholesale = ref.watch(isWholesaleProvider);
    final subtotal = ref.watch(cartProvider.notifier).subtotal;

    // Promotion Logic
    double discountPercentage = 0;
    String promoLabel = '';
    
    if (isWholesale && subtotal > 0) {
      final totalWeight = cartItems.fold(0.0, (sum, item) => sum + item.quantity);
      final bool isFavorite = _selectedCustomer?.isFavorite ?? false;
      
      if (isFavorite) {
        discountPercentage = 0.10;
        promoLabel = 'Favorite Customer Reward (10% OFF)';
      } else if (totalWeight >= 10) {
        discountPercentage = 0.05;
        promoLabel = 'Bulk Purchase Reward (5% OFF)';
      }
    }

    final discount = subtotal * discountPercentage;
    final total = subtotal - discount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          if (discount > 0) ...[
            _summaryRow('Subtotal', '₵${subtotal.toStringAsFixed(2)}', fontSize: 13),
            _summaryRow(promoLabel, '-₵${discount.toStringAsFixed(2)}', color: Colors.green, fontSize: 12),
            const SizedBox(height: 8),
          ],
          _summaryRow('TOTAL DUE', '₵${total.toStringAsFixed(2)}', isBold: true, fontSize: 20, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: cartItems.isEmpty ? null : () => _showPaymentDialog(total, discount, promoLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
              ),
              child: const Text('PROCEED TO PAYMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, double fontSize = 14, Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, 
              style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: theme.colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color ?? theme.colorScheme.onSurface)),
        ],
      ),
    );
  }

  void _showPaymentDialog(double finalTotal, double discount, String promo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        totalAmount: finalTotal,
        onComplete: (payments) => _completeSale(ref, payments, finalTotal, discount, promo),
      ),
    );
  }

  void _completeSale(WidgetRef ref, List<PaymentDetail> payments, double finalTotal, double discount, String promo) async {
    final cartItems = ref.read(cartProvider);
    final currentUser = ref.read(currentUserProvider);
    
    final double amountPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final double balance = finalTotal - amountPaid;

    // Debt Enforcement: If there's a balance, a customer MUST be selected
    if (balance > 0.01 && _selectedCustomer == null) {
      final proceed = await _showDebtCustomerRequiredDialog();
      if (!proceed) return;
      
      // If they registered/selected a customer, _selectedCustomer will be non-null now
      if (_selectedCustomer == null) return; 
    }

    final sale = SaleRecord(
      id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      items: cartItems.map((item) => SaleItem(
        product: item.product,
        quantity: item.quantity,
        priceAtSale: item.priceAtSale,
        originalPrice: item.originalPrice,
      )).toList(),
      totalAmount: finalTotal,
      totalDiscount: discount,
      appliedPromo: promo.isEmpty ? null : promo,
      payments: payments,
      timestamp: DateTime.now(),
      cashierName: currentUser != null ? '${currentUser.firstName} ${currentUser.surname}' : 'Unknown Cashier',
      cashierId: currentUser?.id ?? 'N/A',
      customerName: _selectedCustomer?.name,
      customerPhone: _selectedCustomer?.phone,
    );

    await ref.read(saleHistoryProvider.notifier).addSale(sale);
    ref.read(cartProvider.notifier).clear();
    
    // Send SMS 
    SmsService.sendReceiptSms(sale, discountAmount: discount);

    setState(() {
      _selectedCustomer = null;
    });

    _showPrintConfirmation(sale);
  }

  Future<bool> _showDebtCustomerRequiredDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Customer Required'),
          ],
        ),
        content: const Text(
          'This transaction has an outstanding balance (Debt). \n\n'
          'To track this debt, you must select or register a customer before completing the sale.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel Sale'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              _showCustomerDialog();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
            child: const Text('Register / Select Customer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showPrintConfirmation(SaleRecord sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReceiptSuccessDialog(
        sale: sale,
        ref: ref,
      ),
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _footerAction(Icons.point_of_sale, 'New Sale', _currentView == POSView.sales, () => setState(() => _currentView = POSView.sales)),
          _footerAction(Icons.history, 'Transaction History', _currentView == POSView.history, () => setState(() => _currentView = POSView.history)),
        ],
      ),
    );
  }

  Widget _footerAction(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
          Text(label, style: TextStyle(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          )),
        ],
      ),
    );
  }

  Widget _buildHistoryLayout() {
    final theme = Theme.of(context);
    final salesHistory = ref.watch(saleHistoryProvider);
    final filteredHistory = salesHistory.where((s) {
      final matchesSearch = s.id.toLowerCase().contains(_historySearchQuery.toLowerCase());
      final matchesDate = _historyFilterDate == null || 
        (s.timestamp.day == _historyFilterDate!.day && s.timestamp.month == _historyFilterDate!.month);
      return matchesSearch && matchesDate;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Recent Transactions', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () => ReceiptService.printSalesReport(filteredHistory, title: 'Cashier Daily Sales Report'),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print Report', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 45,
                  child: TextField(
                    onChanged: (v) => setState(() => _historySearchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search Receipt #...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _historyFilterDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _historyFilterDate == null ? 'Date' : DateFormat('MMM dd').format(_historyFilterDate!),
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
              ),
              if (_historyFilterDate != null || _historySearchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20), 
                  onPressed: () => setState(() { _historyFilterDate = null; _historySearchQuery = ''; }),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: filteredHistory.isEmpty 
              ? Center(child: Text('No transactions found.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
              : ListView.builder(
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final sale = filteredHistory[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.receipt_long, color: theme.colorScheme.primary, size: 20),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(sale.id, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                                overflow: TextOverflow.ellipsis
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('₵${sale.totalAmount.toStringAsFixed(2)}', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${DateFormat('HH:mm').format(sale.timestamp)} • ${sale.items.length} items', style: const TextStyle(fontSize: 10)),
                            Text('Cust: ${sale.customerName ?? "Walk-in"}', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => _showSaleDetails(sale),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _showSaleDetails(SaleRecord sale) {
    bool isPrinting = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
            backgroundColor: theme.colorScheme.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450, maxHeight: 650),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Transaction Details',
                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                sale.id,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('STATUS', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(sale.status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      sale.status.name.toUpperCase(),
                                      style: TextStyle(color: _getStatusColor(sale.status), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('DATE', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(DateFormat('MMM dd, yyyy HH:mm').format(sale.timestamp), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: AppColors.textLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CUSTOMER', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                                    Text(sale.customerName ?? 'Walk-in Customer', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('CASHIER', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                                    Text(sale.cashierName.split(' ')[0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Text('ITEMS', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...sale.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product.name, 
                                        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text('${WeightConverter.formatShort(item.quantity)} x ₵${item.priceAtSale.toStringAsFixed(2)}', 
                                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text('₵${item.total.toStringAsFixed(2)}', 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 13)
                                ),
                              ],
                            ),
                          )),
                          const Divider(height: 32),
                          if (sale.totalDiscount > 0) ...[
                            _detailRow('Gross Amount', '₵${sale.baseTotal.toStringAsFixed(2)}'),
                            _detailRow('Total Discount', '-₵${sale.totalDiscount.toStringAsFixed(2)}', color: Colors.green),
                            const SizedBox(height: 4),
                          ],
                          _detailRow('NET INVOICE VALUE', '₵${sale.netInvoiceValue.toStringAsFixed(2)}', isBold: true, color: theme.colorScheme.primary),
                          const Divider(height: 32),
                          Text('PAYMENT HISTORY', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...sale.payments.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(p.method == PaymentMethod.cash ? Icons.money : Icons.smartphone, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    Text(p.method.name.toUpperCase(), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface)),
                                    if (p.reference != null)
                                      Text(' (${p.reference})', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                                Text('₵${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )),
                          if (sale.balance > 0.01) ...[
                             const SizedBox(height: 8),
                             _detailRow('BALANCE DUE', '₵${sale.balance.toStringAsFixed(2)}', color: Colors.red, isBold: true),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(top: BorderSide(color: theme.dividerColor)),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.l)),
                    ),
                    child: OverflowBar(
                      alignment: MainAxisAlignment.end,
                      spacing: 8,
                      overflowSpacing: 8,
                      children: [
                        if (sale.status == SaleStatus.completed)
                          TextButton.icon(
                            onPressed: () => _showReportErrorDialog(sale),
                            icon: const Icon(Icons.report_problem_outlined, color: Colors.orange, size: 16),
                            label: const Text('Report Error', style: TextStyle(color: Colors.orange, fontSize: 11)),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(context), 
                          child: Text('Close', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12))
                        ),
                        ElevatedButton.icon(
                          onPressed: isPrinting ? null : () async {
                            setState(() => isPrinting = true);
                            try {
                              await ReceiptService.printReceipt(sale);
                            } finally {
                              if (mounted) setState(() => isPrinting = false);
                            }
                          },
                          icon: isPrinting 
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.print, size: 14),
                          label: const Text('REPRINT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOrange, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _showReportErrorDialog(SaleRecord sale) {
    final theme = Theme.of(context);
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Report Sale Error'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please describe the error (e.g., wrong weight). This will notify the Admin for rectification.', 
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter reason here...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                ref.read(saleHistoryProvider.notifier).updateSale(
                  sale.copyWith(
                    status: SaleStatus.pendingCorrection,
                    correctionReason: reasonController.text,
                  )
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error reported to Administrator.'), backgroundColor: Colors.orange),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed: return Colors.green;
      case SaleStatus.rectified: return Colors.blue;
      case SaleStatus.pendingCorrection: return Colors.orange;
      case SaleStatus.cancelled: return Colors.red;
    }
  }

  void _showIncomingStockDialog(BuildContext context, WidgetRef ref, List<StockTransfer> transfers) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        title: Row(
          children: [
            Icon(Icons.inventory_2, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Incoming Stock'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: transfers.isEmpty
              ? const Padding(padding: EdgeInsets.all(20), child: Text('No pending stock transfers.', textAlign: TextAlign.center))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: transfers.length,
                  itemBuilder: (context, index) {
                    final t = transfers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m), side: BorderSide(color: theme.dividerColor)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text(t.meatType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Weight: ${WeightConverter.formatShort(t.weight)} • Batch: ${t.batchId.substring(0, 8).toUpperCase()}', 
                          style: const TextStyle(fontSize: 10)),
                        trailing: ElevatedButton(
                          onPressed: () {
                            ref.read(transferProvider.notifier).markAsReceived(t.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Received ${t.weight}kg of ${t.meatType}')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary, 
                            foregroundColor: Colors.white, 
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                          ),
                          child: const Text('RECEIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(value, 
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? theme.colorScheme.onSurface)
            ),
          ),
        ],
      ),
    );
  }
}

class ProductWeightDialog extends StatefulWidget {
  final Product product;
  final Customer? customer;
  final Function(double weight, double price, double original) onAdd;

  const ProductWeightDialog({super.key, required this.product, this.customer, required this.onAdd});

  @override
  State<ProductWeightDialog> createState() => _ProductWeightDialogState();
}

class _ProductWeightDialogState extends State<ProductWeightDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  WeightUnit _unit = WeightUnit.kg;
  double _weight = 0;
  int _quantity = 1;

  void _toggleUnit(WeightUnit unit) {
    if (_unit == unit) return;
    setState(() {
      if (_unit != WeightUnit.unit && unit != WeightUnit.unit) {
        if (unit == WeightUnit.kg) {
          _weight = WeightConverter.toKg(_weight);
        } else {
          _weight = WeightConverter.toLb(_weight);
        }
      }
      _unit = unit;
      _weightController.text = _weight.toStringAsFixed(2);
    });
  }

  @override
  void initState() {
    super.initState();
    _unit = WeightUnit.values.firstWhere(
      (u) => u.name == widget.product.unit, 
      orElse: () => WeightUnit.kg
    );
    // If product is defined as units, disable the KG/LB toggle UI or similar
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final isWholesale = ref.watch(isWholesaleProvider);
        final isPcs = _unit == WeightUnit.unit;
        
        final kgWeight = isPcs ? _weight : (_unit == WeightUnit.kg ? _weight : WeightConverter.toKg(_weight));
        final currentPrice = widget.product.getPrice(isWholesale, weight: kgWeight, customer: widget.customer);
        final hasPromo = widget.product.isPromoActiveFor(isWholesale, widget.customer);
        final basePrice = isWholesale ? (widget.product.wholesalePrice) : (widget.product.retailPrice);
        
        double comparisonPrice = basePrice;
        final brackets = isWholesale ? widget.product.wholesaleBrackets : widget.product.retailBrackets;
        if (kgWeight > 0 && brackets != null && brackets.isNotEmpty) {
          for (var bracket in brackets) {
            if (kgWeight >= bracket.minWeight && kgWeight <= bracket.maxWeight) {
              comparisonPrice = bracket.price;
              break;
            }
          }
        }

        final total = isPcs ? (_weight * currentPrice * _quantity) : (kgWeight * currentPrice * _quantity);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          child: Container(
            width: 360,
            height: 380, // Slightly taller to fit info
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    widget.product.category.toUpperCase(),
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  Text(
                    widget.product.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  if (!isPcs)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('KG', style: TextStyle(fontSize: 11)), 
                          selected: _unit == WeightUnit.kg, 
                          onSelected: (_) => _toggleUnit(WeightUnit.kg)
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('LB', style: TextStyle(fontSize: 11)), 
                          selected: _unit == WeightUnit.lb, 
                          onSelected: (_) => _toggleUnit(WeightUnit.lb)
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('PRICED PER UNIT/PCS', style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: isPcs ? 'Quantity' : 'Weight',
                            suffixText: isPcs ? 'pcs' : _unit.name,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          onChanged: (v) => setState(() => _weight = double.tryParse(v) ?? 0),
                          validator: (v) => (v == null || (double.tryParse(v) ?? 0) <= 0) ? '!' : null,
                        ),
                      ),
                      if (!isPcs) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _qtyController,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'Packs',
                              suffixText: 'qty',
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) => setState(() => _quantity = int.tryParse(v) ?? 1),
                            validator: (v) => (v == null || (int.tryParse(v) ?? 0) <= 0) ? '!' : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasPromo) ...[
                            Text('₵${comparisonPrice.toStringAsFixed(2)}', 
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, decoration: TextDecoration.lineThrough, fontSize: 12)),
                            const SizedBox(width: 6),
                          ],
                          Text('₵${currentPrice.toStringAsFixed(2)}/${isPcs ? "unit" : "kg"}', 
                            style: TextStyle(color: hasPromo ? Colors.orange.shade800 : theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Text(
                        'Total: ₵${total.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final isWholesale = ref.read(isWholesaleProvider);
                          final effectiveWeight = isPcs ? _weight : (_unit == WeightUnit.kg ? _weight : WeightConverter.toKg(_weight));
                          final currentPrice = widget.product.getPrice(isWholesale, weight: effectiveWeight, customer: widget.customer);
                          double comparisonPrice = isWholesale ? (widget.product.wholesalePrice) : (widget.product.retailPrice);
                          widget.onAdd(effectiveWeight * (isPcs ? 1 : _quantity), currentPrice, comparisonPrice);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                      ),
                      child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

class CustomerSelectionDialog extends ConsumerStatefulWidget {
  final Function(Customer) onSelected;
  const CustomerSelectionDialog({super.key, required this.onSelected});

  @override
  ConsumerState<CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends ConsumerState<CustomerSelectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isNewCustomer = false;

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider);
    final theme = Theme.of(context);
    final filtered = customers.where((c) => 
      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      c.phone.contains(_searchQuery)
    ).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: Container(
        width: 380,
        height: 480, // Keeping it slightly taller but constrained
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isNewCustomer ? 'REGISTER CUSTOMER' : 'SELECT CUSTOMER',
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                IconButton(
                  icon: Icon(_isNewCustomer ? Icons.group_rounded : Icons.person_add_alt_1_rounded, color: theme.colorScheme.primary),
                  onPressed: () => setState(() => _isNewCustomer = !_isNewCustomer),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (!_isNewCustomer) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search name or phone...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                  ? const Center(child: Text('No matches found.', style: TextStyle(color: AppColors.textLight, fontSize: 12)))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final c = filtered[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(c.isFavorite ? Icons.star : Icons.person,
                                color: c.isFavorite ? Colors.orange : theme.colorScheme.primary, size: 20),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${c.phone}${c.location != null ? " • ${c.location}" : ""}', style: const TextStyle(fontSize: 11)),
                          onTap: () {
                            widget.onSelected(c);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
              ),
            ] else ...[
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                          validator: (v) => v!.length != 10 ? 'Invalid' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'Location / Area', prefixIcon: Icon(Icons.location_on_outlined)),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                                final String suffix = timestamp.substring(timestamp.length - 12);
                                final String validUuid = '00000000-0000-0000-0000-$suffix';

                                final newCustomer = Customer(
                                  id: validUuid,
                                  name: _nameController.text,
                                  phone: _phoneController.text,
                                  location: _locationController.text,
                                );
                                
                                try {
                                  final saved = await ref.read(customerProvider.notifier).addCustomer(newCustomer);
                                  if (saved != null) {
                                    widget.onSelected(saved);
                                  }
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to save customer: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary, 
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Register & Select', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('DISMISS', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(List<PaymentDetail>) onComplete;

  const PaymentDialog({super.key, required this.totalAmount, required this.onComplete});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<PaymentDetail> _payments = [];
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _amountController = TextEditingController();
  final _refController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount.toStringAsFixed(2);
  }

  void _addPayment() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) return;

      setState(() {
        _payments.add(PaymentDetail(
          method: _selectedMethod,
          amount: amount,
          reference: _refController.text.isEmpty ? null : _refController.text,
        ));
        final paid = _payments.fold(0.0, (sum, p) => sum + p.amount);
        final remaining = (widget.totalAmount - paid).clamp(0.0, widget.totalAmount);
        _amountController.text = remaining > 0 ? remaining.toStringAsFixed(2) : '0.00';
        _refController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paid = _payments.fold(0.0, (sum, p) => sum + p.amount);
    final remaining = (widget.totalAmount - paid).clamp(0.0, widget.totalAmount);
    final bool isMoMo = _selectedMethod == PaymentMethod.mobileMoney;

    // Lock amount for MoMo
    if (isMoMo && double.tryParse(_amountController.text) != remaining) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _amountController.text = remaining.toStringAsFixed(2));
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: Container(
        width: 440,
        height: 600, // Balanced height
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.payments_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'COLLECT PAYMENT',
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Compact Summary Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.m),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          _billRow(context, 'Net Bill', '₵${widget.totalAmount.toStringAsFixed(2)}', theme),
                          const SizedBox(height: 4),
                          _billRow(context, 'Balance Due', '₵${remaining.toStringAsFixed(2)}', theme, 
                            color: remaining > 0 ? Colors.red : Colors.green, isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Compact Method Selector
                    Row(
                      children: PaymentMethod.values.map((m) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setState(() => _selectedMethod = m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedMethod == m ? theme.colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.s),
                                border: Border.all(color: _selectedMethod == m ? theme.colorScheme.primary : theme.dividerColor),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    m == PaymentMethod.cash ? Icons.money_rounded : Icons.smartphone_rounded,
                                    color: _selectedMethod == m ? Colors.white : theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  Text(
                                    m.name.toUpperCase(),
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _selectedMethod == m ? Colors.white : theme.colorScheme.onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _amountController, 
                            readOnly: isMoMo,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: isMoMo ? 'Amount (Locked)' : 'Amount Received', 
                              prefixText: '₵ ', 
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => setState(() {}),
                            validator: (v) => (v == null || (double.tryParse(v) ?? 0) <= 0) ? '!' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _refController,
                            decoration: InputDecoration(
                              labelText: isMoMo ? 'MoMo Number' : 'Note (Optional)',
                              prefixIcon: Icon(isMoMo ? Icons.phone_iphone_rounded : Icons.note_alt_outlined),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                            keyboardType: isMoMo ? TextInputType.phone : TextInputType.text,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addPayment,
                        icon: Icon(isMoMo ? Icons.send_to_mobile : Icons.add_circle_outline, size: 18),
                        label: Text(isMoMo ? 'INITIATE PULL' : 'APPLY PAYMENT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    if (_payments.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      ..._payments.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.s),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(p.method == PaymentMethod.cash ? Icons.money : Icons.smartphone, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p.method.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Text('₵${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 16), 
                              onPressed: () => setState(() => _payments.remove(p))
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _payments.isEmpty ? null : () {
                      Navigator.pop(context);
                      widget.onComplete(_payments);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary, 
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('COMPLETE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _billRow(BuildContext context, String label, String value, ThemeData theme, {bool isTotal = false, Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, 
              style: TextStyle(
                fontSize: isTotal ? 13 : 12, 
                color: isTotal ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(
            fontSize: isTotal ? 16 : 14, 
            fontWeight: (isTotal || isBold) ? FontWeight.bold : FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          )),
        ],
      ),
    );
  }
}

class ReceiptSuccessDialog extends StatefulWidget {
  final SaleRecord sale;
  final WidgetRef ref;

  const ReceiptSuccessDialog({super.key, required this.sale, required this.ref});

  @override
  State<ReceiptSuccessDialog> createState() => _ReceiptSuccessDialogState();
}

class _ReceiptSuccessDialogState extends State<ReceiptSuccessDialog> {
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: Container(
        width: 380,
        height: 520, // Compact but fits details
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('SALE SUCCESSFUL', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Digital Receipt Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.s),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const Text('Mi CORAZON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                    const Text('Digital Copy', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const Divider(height: 24),
                    _receiptPreviewRow('Invoice ID', widget.sale.id.substring(widget.sale.id.length - 8).toUpperCase()),
                    _receiptPreviewRow('Cashier', widget.sale.cashierName.split(' ')[0]),
                    const Divider(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.sale.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.sale.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(child: Text(item.product.name, style: const TextStyle(fontSize: 11))),
                                Text('₵${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        Text('₵${widget.sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                      ],
                    ),
                    if (widget.sale.balance > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('AMOUNT PAID', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('₵${widget.sale.amountPaid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('BALANCE DUE (DEBT)', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                          Text('₵${widget.sale.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.red)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPrinting ? null : () async {
                  setState(() => _isPrinting = true);
                  try {
                    await ReceiptService.printReceipt(widget.sale);
                  } finally {
                    if (mounted) setState(() => _isPrinting = false);
                  }
                },
                icon: _isPrinting 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.print_rounded, size: 20),
                label: const Text('PRINT RECEIPT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('CLOSE WINDOW', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, 
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
