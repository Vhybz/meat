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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MainAppBar(
        title: _currentView == POSView.sales 
            ? 'POS System (${isWholesale ? "Wholesale" : "Retail"})' 
            : 'Sales History',
        actions: [
          _buildNotificationBadge(pendingTransfers),
        ],
      ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(context, user)),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, user),
          Expanded(
            child: _currentView == POSView.sales 
              ? _buildPOSLayout(isMobile, isDesktop)
              : _buildHistoryLayout(),
          ),
        ],
      ),
      bottomNavigationBar: _buildFooter(),
      floatingActionButton: (isMobile && _currentView == POSView.sales)
          ? FloatingActionButton.extended(
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
            )
          : null,
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

  Widget _buildSidebar(BuildContext context, UserAccount user) {
    const currentRoute = '/cashier';
    return AppSidebar(
      userId: user.id,
      userName: user.name,
      userRole: user.activePrimaryRole.name.toUpperCase(),
      currentRoute: currentRoute,
      items: MenuService.getMenuItemsForUser(user),
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
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: theme.colorScheme.onSurfaceVariant)),
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

  void _completeSale(WidgetRef ref, List<PaymentDetail> payments, double finalTotal, double discount, String promo) {
    final cartItems = ref.read(cartProvider);
    final currentUser = ref.read(currentUserProvider);

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

    ref.read(saleHistoryProvider.notifier).addSale(sale);
    ref.read(cartProvider.notifier).clear();
    
    // Send SMS 
    SmsService.sendReceiptSms(sale, discountAmount: discount);

    setState(() {
      _selectedCustomer = null;
    });

    _showPrintConfirmation(sale);
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
      height: 60,
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
              Text('Recent Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              ElevatedButton.icon(
                onPressed: () => ReceiptService.printSalesReport(filteredHistory, title: 'Cashier Daily Sales Report'),
                icon: const Icon(Icons.print),
                label: const Text('Print Filtered Report'),
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (v) => setState(() => _historySearchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search Receipt #...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
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
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_historyFilterDate == null ? 'Filter Date' : DateFormat('MMM dd, yyyy').format(_historyFilterDate!)),
                ),
              ),
              if (_historyFilterDate != null || _historySearchQuery.isNotEmpty)
                IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _historyFilterDate = null; _historySearchQuery = ''; })),
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
                          child: Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                        ),
                        title: Text(sale.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${DateFormat('HH:mm').format(sale.timestamp)} • ${sale.items.length} items • ${sale.customerName ?? "Walk-in"}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₵${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: Colors.white),
                            const SizedBox(width: AppSpacing.m),
                            Text(
                              'Transaction ${sale.id}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CASHIER', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                                    Text('${sale.cashierName} (${sale.cashierId})', 
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('DATE', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                                  Text(DateFormat('MMM dd, yyyy HH:mm').format(sale.timestamp), style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Text('ITEMS', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...sale.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(item.product.name, 
                                    style: TextStyle(color: theme.colorScheme.onSurface),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: Text('${WeightConverter.formatShort(item.quantity)} x ₵${item.priceAtSale.toStringAsFixed(2)}', 
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('₵${item.total.toStringAsFixed(2)}', 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)
                                ),
                              ],
                            ),
                          )),
                          const Divider(height: 32),
                          _detailRow('NET INVOICE VALUE', '₵${sale.netInvoiceValue.toStringAsFixed(2)}', isBold: true, color: theme.colorScheme.primary),
                          const Divider(height: 32),
                          Text('PAYMENTS', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...sale.payments.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p.method.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                                Text('₵${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: theme.dividerColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (sale.status == SaleStatus.completed)
                          TextButton.icon(
                            onPressed: () => _showReportErrorDialog(sale),
                            icon: const Icon(Icons.report_problem_outlined, color: Colors.orange, size: 18),
                            label: const Text('Report Error', style: TextStyle(color: Colors.orange)),
                          ),
                        const Spacer(),
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: isPrinting ? null : () async {
                            setState(() => isPrinting = true);
                            await ReceiptService.printReceipt(sale);
                            setState(() => isPrinting = false);
                          },
                          icon: isPrinting 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.print, size: 18),
                          label: const Text('Print Receipt'),
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
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
        title: const Text('Report Sale Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please describe the error (e.g., wrong weight, incorrect item). This will notify the Admin for rectification.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason here...',
              ),
            ),
          ],
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
              ? const Padding(padding: EdgeInsets.all(20), child: Text('No pending stock transfers.'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: transfers.length,
                  itemBuilder: (context, index) {
                    final t = transfers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(t.meatType, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Weight: ${WeightConverter.formatShort(t.weight)} • Batch: ${t.batchId.substring(0, 8).toUpperCase()}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            ref.read(transferProvider.notifier).markAsReceived(t.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Received ${t.weight}kg of ${t.meatType}')),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                          child: const Text('RECEIVE', style: TextStyle(fontSize: 10)),
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
      if (unit == WeightUnit.kg) {
        _weight = WeightConverter.toKg(_weight);
      } else {
        _weight = WeightConverter.toLb(_weight);
      }
      _unit = unit;
      _weightController.text = _weight.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final isWholesale = ref.watch(isWholesaleProvider);
        final kgWeight = _unit == WeightUnit.kg ? _weight : WeightConverter.toKg(_weight);
        final currentPrice = widget.product.getPrice(isWholesale, weight: kgWeight, customer: widget.customer);
        final hasPromo = widget.product.isPromoActiveFor(isWholesale, widget.customer);
        final basePrice = isWholesale ? (widget.product.wholesalePrice) : (widget.product.retailPrice);
        
        // Handle brackets for base price comparison if weight is provided
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

        final total = kgWeight * currentPrice * _quantity;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.product.category.toUpperCase(),
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Text(widget.product.name),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(label: const Text('KG'), selected: _unit == WeightUnit.kg, onSelected: (_) => _toggleUnit(WeightUnit.kg)),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text('LB'), selected: _unit == WeightUnit.lb, onSelected: (_) => _toggleUnit(WeightUnit.lb)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(labelText: 'Weight (${_unit.name})'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        onChanged: (v) => setState(() => _weight = double.tryParse(v) ?? _weight),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Req';
                          if (double.tryParse(v) == null || double.tryParse(v)! <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _qtyController,
                        decoration: const InputDecoration(labelText: 'Quantity (pcs)'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (v) => setState(() => _quantity = int.tryParse(v) ?? _quantity),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Req';
                          if (int.tryParse(v) == null || int.tryParse(v)! <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasPromo) ...[
                      Text('₵${comparisonPrice.toStringAsFixed(2)}', 
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, decoration: TextDecoration.lineThrough, fontSize: 14)),
                      const SizedBox(width: 8),
                    ],
                    Text('Rate: ₵${currentPrice.toStringAsFixed(2)}/kg', 
                      style: TextStyle(color: hasPromo ? Colors.orange.shade800 : theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (hasPromo)
                  Text('${widget.product.discountPercentage.toInt()}% Promotion Applied (${widget.product.promoCustomerTarget == PromoCustomerTarget.regularsOnly ? "Regulars Only" : "Public"})',
                    style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Total: ₵${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final isWholesale = ref.read(isWholesaleProvider);
                  final kgWeight = _unit == WeightUnit.kg ? _weight : WeightConverter.toKg(_weight);
                  
                  final currentPrice = widget.product.getPrice(isWholesale, weight: kgWeight, customer: widget.customer);
                  double comparisonPrice = isWholesale ? (widget.product.wholesalePrice) : (widget.product.retailPrice);
                  final brackets = isWholesale ? widget.product.wholesaleBrackets : widget.product.retailBrackets;
                  if (kgWeight > 0 && brackets != null && brackets.isNotEmpty) {
                    for (var bracket in brackets) {
                      if (kgWeight >= bracket.minWeight && kgWeight <= bracket.maxWeight) {
                        comparisonPrice = bracket.price;
                        break;
                      }
                    }
                  }

                  widget.onAdd(kgWeight * _quantity, currentPrice, comparisonPrice);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
              child: const Text('Add to Cart'),
            ),
          ],
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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Select Customer'),
          IconButton(
            icon: Icon(_isNewCustomer ? Icons.list : Icons.person_add, color: theme.colorScheme.primary),
            onPressed: () => setState(() => _isNewCustomer = !_isNewCustomer),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isNewCustomer) ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by name or phone...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Text('No customers found.'))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(c.isFavorite ? Icons.star : Icons.person, color: c.isFavorite ? Colors.orange : theme.colorScheme.primary),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(c.phone),
                        onTap: () {
                          widget.onSelected(c);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController, 
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController, 
                      decoration: const InputDecoration(labelText: 'Phone Number', hintText: '10 digits'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      validator: (v) => v!.length != 10 ? 'Invalid' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final newCustomer = Customer(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: _nameController.text,
                            phone: _phoneController.text,
                          );
                          ref.read(customerProvider.notifier).addCustomer(newCustomer);
                          widget.onSelected(newCustomer);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
                      child: const Text('Add & Select'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isNewCustomer)
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
      ],
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
        final remaining = widget.totalAmount - paid;
        _amountController.text = remaining > 0 ? remaining.toStringAsFixed(2) : '0.00';
        _refController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paid = _payments.fold(0.0, (sum, p) => sum + p.amount);
    final remaining = widget.totalAmount - paid;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      title: Row(
        children: [
          Icon(Icons.payments, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Payment Collection'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Bill:', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        Text('₵${widget.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Remaining:', style: TextStyle(color: remaining > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                        Text('₵${remaining.toStringAsFixed(2)}', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: remaining > 0 ? Colors.red : Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: PaymentMethod.values.map((m) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(m.name.toUpperCase(), style: const TextStyle(fontSize: 10)), 
                      selected: _selectedMethod == m, 
                      onSelected: (_) => setState(() => _selectedMethod = m),
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(color: _selectedMethod == m ? Colors.white : theme.colorScheme.primary),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _amountController, 
                      decoration: const InputDecoration(
                        labelText: 'Amount Received from Customer', 
                        prefixText: '₵ ', 
                        helperText: 'Enter the actual amount handed over by the customer',
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (v) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null || double.tryParse(v)! <= 0) return 'Invalid amount';
                        return null;
                      },
                    ),
                    if (double.tryParse(_amountController.text) != null && double.tryParse(_amountController.text)! > remaining) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Change to Give:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                            Text('₵${(double.tryParse(_amountController.text)! - remaining).toStringAsFixed(2)}', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_selectedMethod == PaymentMethod.mobileMoney) ...[
                      TextFormField(
                        controller: _refController,
                        decoration: const InputDecoration(
                          labelText: 'MoMo Number',
                          prefixIcon: Icon(Icons.phone_iphone),
                          hintText: '10 digits',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required for MoMo';
                          if (v.length != 10) return 'Exactly 10 digits required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('A prompt will be sent to the customer.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
                    ] else ...[
                      TextFormField(controller: _refController, decoration: const InputDecoration(labelText: 'Ref/Note (Optional)')),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addPayment,
                  icon: Icon(_selectedMethod == PaymentMethod.mobileMoney ? Icons.send_to_mobile : Icons.add),
                  label: Text(_selectedMethod == PaymentMethod.mobileMoney ? 'Initiate MoMo Pull' : 'Add Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (_payments.isNotEmpty) ...[
                const SizedBox(height: 24),
                Align(alignment: Alignment.centerLeft, child: Text('Applied Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurface))),
                Divider(color: theme.dividerColor),
                ..._payments.map((p) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  title: Text(p.method.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: p.reference != null ? Text(p.reference!) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('₵${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18), onPressed: () => setState(() => _payments.remove(p))),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
        ElevatedButton(
          onPressed: _payments.isEmpty ? null : () {
            Navigator.pop(context); // Close Payment Dialog first
            widget.onComplete(_payments);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary, 
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Complete Sale'),
        ),
      ],
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
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Transaction Complete'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The sale has been successfully recorded.', style: TextStyle(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          _detailRow('Invoice ID', widget.sale.id),
          _detailRow('Total Amount', '₵${widget.sale.totalAmount.toStringAsFixed(2)}'),
          _detailRow('Cashier', '${widget.sale.cashierName} (${widget.sale.cashierId})'),
          _detailRow('Customer', widget.sale.customerName ?? 'Walk-in'),
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: _isPrinting ? null : () async {
            setState(() => _isPrinting = true);
            try {
              await ReceiptService.printReceipt(widget.sale);
            } finally {
              if (mounted) setState(() => _isPrinting = false);
            }
          },
          icon: _isPrinting 
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Icon(Icons.print, size: 18),
          label: const Text('Print Receipt'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}
