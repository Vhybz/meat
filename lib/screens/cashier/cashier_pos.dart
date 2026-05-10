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
  
  String _historySearchQuery = '';
  DateTime? _historyFilterDate;

  // Selected customer for the current sale
  Customer? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final transfers = ref.watch(transferProvider);
    final pendingTransfers = transfers.where((t) => t.status == TransferStatus.pending).toList();
    final isWholesale = ref.watch(isWholesaleProvider);

    return Scaffold(
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
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildProductSection(context, ref),
        ),
        if (!isMobile)
          Container(
            width: isDesktop ? 400 : 300,
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.borderGray)),
              color: Colors.white,
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
                final activeProducts = products.where((p) => !p.isDeleted).toList();
                final filtered = activeProducts.where((p) => _selectedCategory == 'All' || p.category == _selectedCategory).toList();
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: AppSpacing.m,
                    mainAxisSpacing: AppSpacing.m,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final currentPrice = product.getPrice(isWholesale, customer: _selectedCustomer);
                    final hasPromo = product.isPromoActiveFor(isWholesale, _selectedCustomer);
                    
                    return ProductCard(
                      name: product.name,
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
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPOSControls() {
    final isWholesale = ref.watch(isWholesaleProvider);
    
    return Row(
      children: [
        Container(
          height: 45,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(
            children: [
              _modeButton('Retail', !isWholesale),
              _modeButton('Wholesale', isWholesale),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
        ),
      ],
    );
  }

  Widget _modeButton(String label, bool isSelected) {
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
          color: isSelected ? AppColors.primaryMaroon : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.m - 4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _confirmModeChange(bool newMode) {
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
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
        onAdd: (weight, price) {
          ref.read(cartProvider.notifier).addItemWithCustomPrice(product, weight, price);
        },
      ),
    );
  }

  Widget _buildCartSection(BuildContext context, WidgetRef ref) {
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
        const Divider(height: 1),
        // Customer Selection
        ListTile(
          dense: true,
          leading: const Icon(Icons.person_outline, size: 20),
          title: Text(_selectedCustomer?.name ?? 'Select Customer', 
            style: TextStyle(fontWeight: _selectedCustomer != null ? FontWeight.bold : FontWeight.normal)),
          subtitle: _selectedCustomer != null ? Text(_selectedCustomer!.phone, style: const TextStyle(fontSize: 10)) : null,
          trailing: IconButton(
            icon: Icon(_selectedCustomer == null ? Icons.add_circle_outline : Icons.edit, size: 18),
            onPressed: () => _showCustomerDialog(),
          ),
          onTap: () => _showCustomerDialog(),
        ),
        const Divider(height: 1),
        Expanded(
          child: cartItems.isEmpty
              ? const Center(child: Text('Cart is empty', style: TextStyle(color: AppColors.textLight)))
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
        promoLabel = 'Bulk Volume Discount (5% OFF)';
      }
    }

    final discountValue = subtotal * discountPercentage;
    final netValue = subtotal - discountValue;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          if (discountPercentage > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.s),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      promoLabel,
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Text('-₵${discountValue.toStringAsFixed(2)}', 
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('₵${netValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: netValue > 0 ? () {
                if (isWholesale && _selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer details are compulsory for Wholesale sales.'), backgroundColor: Colors.orange),
                  );
                  _showCustomerDialog();
                } else {
                  _showPaymentDialog(ref, netValue, discountValue, promoLabel);
                }
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Checkout', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(WidgetRef ref, double finalTotal, double discount, String promo) {
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

    ReceiptService.printReceipt(sale);
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

  Widget _buildHistoryLayout() {
    final history = ref.watch(saleHistoryProvider);
    
    final filteredHistory = history.where((sale) {
      final matchesSearch = sale.id.toLowerCase().contains(_historySearchQuery.toLowerCase());
      final matchesDate = _historyFilterDate == null || 
          DateFormat('yyyy-MM-dd').format(sale.timestamp) == DateFormat('yyyy-MM-dd').format(_historyFilterDate!);
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
              const Text('Recent Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => ReceiptService.printSalesReport(filteredHistory, title: 'Cashier Daily Sales Report'),
                icon: const Icon(Icons.print),
                label: const Text('Print Filtered Report'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                    contentPadding: EdgeInsets.zero,
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
                  icon: const Icon(Icons.calendar_month),
                  label: Text(_historyFilterDate == null ? 'Select Date' : DateFormat('MMM dd').format(_historyFilterDate!)),
                ),
              ),
              if (_historyFilterDate != null || _historySearchQuery.isNotEmpty)
                IconButton(onPressed: () => setState(() { _historyFilterDate = null; _historySearchQuery = ''; }), icon: const Icon(Icons.clear)),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: filteredHistory.isEmpty
              ? const Center(child: Text('No transactions found.'))
              : ListView.builder(
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final sale = filteredHistory[index];
                    Color statusColor = AppColors.primaryMaroon;
                    IconData statusIcon = Icons.receipt_long;
                    
                    if (sale.status == SaleStatus.pendingCorrection) {
                      statusColor = Colors.orange;
                      statusIcon = Icons.warning_amber_rounded;
                    } else if (sale.status == SaleStatus.rectified) {
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle_outline;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.1),
                          child: Icon(statusIcon, color: statusColor),
                        ),
                        title: Row(
                          children: [
                            Text('Sale ${sale.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (sale.status != SaleStatus.completed) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  sale.status == SaleStatus.pendingCorrection ? 'PENDING ERROR' : 'RECTIFIED',
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(DateFormat('MMM dd, hh:mm a').format(sale.timestamp)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₵${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                            if (sale.balance > 0)
                              Text('Unpaid: ₵${sale.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.red)),
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: const BoxDecoration(
                  color: AppColors.primaryMaroon,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CASHIER', style: TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                              Text('${sale.cashierName} (${sale.cashierId})', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('DATE', style: TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                              Text(DateFormat('MMM dd, yyyy HH:mm').format(sale.timestamp), style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text('ITEMS', style: TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...sale.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.product.name)),
                            Text('${WeightConverter.formatShort(item.quantity)} x ₵${item.priceAtSale.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                            const SizedBox(width: 16),
                            Text('₵${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                      const Divider(height: 32),
                      _detailRow('NET INVOICE VALUE', '₵${sale.netInvoiceValue.toStringAsFixed(2)}', isBold: true, color: AppColors.primaryMaroon),
                      const Divider(height: 32),
                      const Text('PAYMENTS', style: TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
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
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.borderGray)),
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
                      onPressed: () => ReceiptService.printReceipt(sale),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print Receipt'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportErrorDialog(SaleRecord sale) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Sale Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the error (e.g., wrong weight, incorrect item). This will notify the Admin for rectification.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Correction',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                final updatedSale = sale.copyWith(
                  status: SaleStatus.pendingCorrection,
                  correctionReason: reasonController.text,
                );
                ref.read(saleHistoryProvider.notifier).updateSale(updatedSale);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close sale details
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error reported. Admin has been notified.'), backgroundColor: Colors.orange),
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

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
      ],
    );
  }

  void _showIncomingStockDialog(BuildContext context, WidgetRef ref, List<StockTransfer> transfers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incoming Stock'),
        content: SizedBox(
          width: 400,
          child: transfers.isEmpty 
            ? const Text('No pending transfers.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: transfers.length,
                itemBuilder: (context, index) {
                  final t = transfers[index];
                  return ListTile(
                    title: Text('${t.meatType} (${t.weight}kg)'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        ref.read(transferProvider.notifier).markAsReceived(t.id);
                        Navigator.pop(context);
                      },
                      child: const Text('Receive'),
                    ),
                  );
                },
              ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.borderGray)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Terminal: CASH-01', style: TextStyle(fontSize: 10)),
          Text('Online', style: TextStyle(fontSize: 10, color: AppColors.accentGreen)),
        ],
      ),
    );
  }
}

// --- Supporting Dialog Widgets ---

class ProductWeightDialog extends StatefulWidget {
  final Product product;
  final Customer? customer;
  final Function(double weight, double price) onAdd;

  const ProductWeightDialog({super.key, required this.product, this.customer, required this.onAdd});

  @override
  State<ProductWeightDialog> createState() => _ProductWeightDialogState();
}

class _ProductWeightDialogState extends State<ProductWeightDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _weightController;
  late TextEditingController _qtyController;
  double _weight = 1.0;
  int _quantity = 1;
  WeightUnit _unit = WeightUnit.kg;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: _weight.toStringAsFixed(1));
    _qtyController = TextEditingController(text: _quantity.toString());
  }

  void _toggleUnit(WeightUnit unit) {
    if (_unit == unit) return;
    setState(() {
      _weight = unit == WeightUnit.lb ? WeightConverter.toLb(_weight) : WeightConverter.toKg(_weight);
      _unit = unit;
      _weightController.text = _weight.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text('Add ${widget.product.name}'),
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
                        decoration: InputDecoration(labelText: 'Weight (${_unit.name})', border: const OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'Quantity (pcs)', border: OutlineInputBorder()),
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
                        style: const TextStyle(color: AppColors.textLight, decoration: TextDecoration.lineThrough, fontSize: 14)),
                      const SizedBox(width: 8),
                    ],
                    Text('Rate: ₵${currentPrice.toStringAsFixed(2)}/kg', 
                      style: TextStyle(color: hasPromo ? Colors.orange.shade800 : AppColors.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (hasPromo)
                  Text('${widget.product.discountPercentage.toInt()}% Promotion Applied (${widget.product.promoCustomerTarget == PromoCustomerTarget.regularsOnly ? "Regulars Only" : "Public"})',
                    style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Total: ₵${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onAdd(kgWeight * _quantity, currentPrice);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider);
    final filteredCustomers = customers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      title: const Text('Select Customer'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isNewCustomer) ...[
              const Text('Search or select from regulars', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search name or phone...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: filteredCustomers.isEmpty 
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No matches found.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final c = filteredCustomers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryMaroon.withValues(alpha: 0.1),
                            child: Icon(c.isFavorite ? Icons.star : Icons.person_outline, 
                              color: c.isFavorite ? Colors.orange : AppColors.primaryMaroon, size: 20),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(c.phone, style: const TextStyle(fontSize: 12)),
                          onTap: () {
                            widget.onSelected(c);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
              ),
              const Divider(),
              TextButton.icon(
                onPressed: () => setState(() => _isNewCustomer = true),
                icon: const Icon(Icons.person_add),
                label: const Text('Add New Customer'),
              ),
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController, 
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController, 
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => setState(() => _isNewCustomer = false), child: const Text('Back')),
                  const SizedBox(width: 8),
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
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
                    child: const Text('Add & Select'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isNewCustomer)
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
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
    final paid = _payments.fold(0.0, (sum, p) => sum + p.amount);
    final remaining = widget.totalAmount - paid;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      title: const Row(
        children: [
          Icon(Icons.payments, color: AppColors.primaryMaroon),
          SizedBox(width: 12),
          Text('Payment Collection'),
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
                  color: AppColors.primaryMaroon.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: AppColors.primaryMaroon.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bill:', style: TextStyle(color: AppColors.textLight)),
                        Text('₵${widget.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                      selectedColor: AppColors.primaryMaroon,
                      labelStyle: TextStyle(color: _selectedMethod == m ? Colors.white : AppColors.primaryMaroon),
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
                      decoration: const InputDecoration(labelText: 'Amount to Pay', prefixText: '₵ ', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null || double.tryParse(v)! <= 0) return 'Invalid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_selectedMethod == PaymentMethod.mobileMoney) ...[
                      TextFormField(
                        controller: _refController,
                        decoration: const InputDecoration(
                          labelText: 'MoMo Number',
                          prefixIcon: Icon(Icons.phone_iphone),
                          hintText: '10 digits',
                          border: OutlineInputBorder(),
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
                      const Text('A prompt will be sent to the customer.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textLight)),
                    ] else ...[
                      TextFormField(controller: _refController, decoration: const InputDecoration(labelText: 'Ref/Note (Optional)', border: OutlineInputBorder())),
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
                const Align(alignment: Alignment.centerLeft, child: Text('Applied Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const Divider(),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _payments.isEmpty ? null : () => widget.onComplete(_payments),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon, 
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Complete Sale'),
        ),
      ],
    );
  }
}

class ReceiptSuccessDialog extends StatelessWidget {
  final SaleRecord sale;
  final WidgetRef ref;

  const ReceiptSuccessDialog({super.key, required this.sale, required this.ref});

  @override
  Widget build(BuildContext context) {
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
          const Text('The sale has been successfully recorded.'),
          const SizedBox(height: 16),
          _detailRow('Invoice ID', sale.id),
          _detailRow('Total Amount', '₵${sale.totalAmount.toStringAsFixed(2)}'),
          _detailRow('Cashier', '${sale.cashierName} (${sale.cashierId})'),
          _detailRow('Customer', sale.customerName ?? 'Walk-in'),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => ReceiptService.printReceipt(sale),
          child: const Text('Print Receipt'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
