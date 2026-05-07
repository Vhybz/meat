import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/product_card.dart';
import '../../widgets/cart_item_tile.dart';
import '../../widgets/main_app_bar.dart';
import '../../services/cart_provider.dart';
import '../../services/product_service.dart';
import '../../services/transfer_provider.dart';
import '../../services/sale_provider.dart';
import '../../models/transfer_models.dart';
import '../../models/sale_model.dart';
import '../../models/product.dart';
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
  final List<String> _categories = ['All', 'Beef', 'Pork', 'Chicken', 'Others'];

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final transfers = ref.watch(transferProvider);
    final pendingTransfers = transfers.where((t) => t.status == TransferStatus.pending).toList();

    return Scaffold(
      appBar: MainAppBar(
        title: _currentView == POSView.sales ? 'Retail POS' : 'Sales History',
        actions: [
          _buildNotificationBadge(pendingTransfers),
        ],
      ),
      drawer: isDesktop ? null : _buildSidebar(context),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context),
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

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 70,
      color: AppColors.primaryMaroon,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.m),
          const Icon(Icons.restaurant_menu, color: Colors.white, size: 30),
          const SizedBox(height: AppSpacing.xl),
          _buildSidebarIcon(Icons.point_of_sale_rounded, 'POS', _currentView == POSView.sales, () {
            setState(() => _currentView = POSView.sales);
          }),
          _buildSidebarIcon(Icons.history_rounded, 'History', _currentView == POSView.history, () {
            setState(() => _currentView = POSView.history);
          }),
          const Spacer(),
          _buildSidebarIcon(Icons.logout_rounded, 'Logout', false, () {
            Navigator.pushReplacementNamed(context, '/');
          }),
          const SizedBox(height: AppSpacing.m),
        ],
      ),
    );
  }

  Widget _buildSidebarIcon(IconData icon, String tooltip, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: IconButton(
        icon: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 24),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildProductSection(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsFutureProvider);
    int crossAxisCount = ResponsiveLayout.isMobile(context) ? 2 : (ResponsiveLayout.isTablet(context) ? 3 : 4);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          _buildSearchAndFilter(),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products.where((p) => _selectedCategory == 'All' || p.category == _selectedCategory).toList();
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
                    return ProductCard(
                      name: product.name,
                      price: '₵${product.price} / kg',
                      imageUrl: 'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=200',
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

  void _showWeightInputDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductWeightDialog(
        product: product,
        onAdd: (weight) => ref.read(cartProvider.notifier).addItem(product, weight),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
              contentPadding: EdgeInsets.zero,
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
            ),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
        ),
      ],
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
                      weight: '${item.quantity}kg',
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

  Widget _buildCartSummary(WidgetRef ref) {
    final subtotal = ref.watch(cartProvider.notifier).subtotal;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      color: AppColors.surfaceWhite,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('₵${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: subtotal > 0 ? () => _showPaymentDialog(ref) : null,
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

  void _showPaymentDialog(WidgetRef ref) {
    final total = ref.read(cartProvider.notifier).subtotal;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        totalAmount: total,
        onComplete: (payments) => _completeSale(ref, payments),
      ),
    );
  }

  void _completeSale(WidgetRef ref, List<PaymentDetail> payments) {
    final cartItems = ref.read(cartProvider);
    final total = ref.read(cartProvider.notifier).subtotal;

    final sale = SaleRecord(
      id: 'INV-${DateTime.now().millisecond}',
      items: cartItems.map((item) => SaleItem(
        product: item.product,
        quantity: item.quantity,
        priceAtSale: item.product.price,
      )).toList(),
      totalAmount: total,
      payments: payments,
      timestamp: DateTime.now(),
      cashierName: 'Maria Santos',
    );

    ref.read(saleHistoryProvider.notifier).addSale(sale);
    ref.read(cartProvider.notifier).clear();

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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: history.isEmpty
              ? const Center(child: Text('No transactions recorded yet.'))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final sale = history[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: AppColors.surfaceWhite, child: Icon(Icons.receipt_long, color: AppColors.primaryMaroon)),
                        title: Text('Sale ${sale.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
        child: Container(
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
                              Text(sale.cashierName, style: const TextStyle(fontSize: 14)),
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
                            Text('${item.quantity}kg x ₵${item.priceAtSale.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                            const SizedBox(width: 16),
                            Text('₵${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SUBTOTAL', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                          Text('₵${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      const Divider(height: 32),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(AppRadius.s),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL PAID', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('₵${sale.amountPaid.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                              ],
                            ),
                            if (sale.balance > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('BALANCE DUE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  Text('₵${sale.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
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
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: AppColors.textLight)),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    ElevatedButton.icon(
                      onPressed: () => ReceiptService.printReceipt(sale),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print Receipt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                      ),
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

  void _showIncomingStockDialog(BuildContext context, WidgetRef ref, List<StockTransfer> transfers) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        child: Container(
          width: 500,
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
                    const Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.white),
                        SizedBox(width: AppSpacing.m),
                        Text(
                          'Incoming Stock Transfers',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.all(AppSpacing.m),
                child: transfers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 48, color: AppColors.borderGray),
                            SizedBox(height: 16),
                            Text('No pending transfers.', style: TextStyle(color: AppColors.textLight)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: transfers.length,
                        itemBuilder: (context, index) {
                          final t = transfers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.m),
                            elevation: 0,
                            color: AppColors.surfaceWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                              side: const BorderSide(color: AppColors.borderGray),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryMaroon.withOpacity(0.1),
                                    child: const Icon(Icons.restaurant_menu, color: AppColors.primaryMaroon, size: 20),
                                  ),
                                  const SizedBox(width: AppSpacing.m),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${t.meatType} (${t.weight}kg)', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(
                                          'From Butcher Unit • ${DateFormat('hh:mm a').format(t.transferTime)}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      ref.read(transferProvider.notifier).markAsReceived(t.id);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Stock received successfully'),
                                          backgroundColor: AppColors.accentGreen,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                                    ),
                                    child: const Text('Receive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: AppColors.textLight)),
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

class ProductWeightDialog extends StatefulWidget {
  final Product product;
  final Function(double) onAdd;

  const ProductWeightDialog({super.key, required this.product, required this.onAdd});

  @override
  State<ProductWeightDialog> createState() => _ProductWeightDialogState();
}

class _ProductWeightDialogState extends State<ProductWeightDialog> {
  late TextEditingController _weightController;
  late TextEditingController _qtyController;
  double _weight = 1.0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: _weight.toStringAsFixed(1));
    _qtyController = TextEditingController(text: _quantity.toString());
    _weightController.addListener(_onWeightChanged);
    _qtyController.addListener(_onQtyChanged);
  }

  void _onWeightChanged() {
    final val = double.tryParse(_weightController.text);
    if (val != null && val != _weight) {
      setState(() {
        _weight = val;
      });
    }
  }

  void _onQtyChanged() {
    final val = int.tryParse(_qtyController.text);
    if (val != null && val != _quantity) {
      setState(() {
        _quantity = val;
      });
    }
  }

  void _updateWeight(double delta) {
    setState(() {
      _weight = (_weight + delta).clamp(0.1, 100.0);
      _weightController.text = _weight.toStringAsFixed(1);
    });
  }

  void _updateQty(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(1, 100);
      _qtyController.text = _quantity.toString();
    });
  }

  void _setWeight(double value) {
    setState(() {
      _weight = value;
      _weightController.text = _weight.toStringAsFixed(1);
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _weight * widget.product.price * _quantity;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: Container(
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
                children: [
                  const Icon(Icons.scale, color: Colors.white),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('₵${widget.product.price.toStringAsFixed(2)} / kg', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Weight (kg)', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _adjustButton(Icons.remove, () => _updateWeight(-0.1)),
                                Expanded(
                                  child: TextField(
                                    controller: _weightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                                    decoration: const InputDecoration(border: InputBorder.none),
                                  ),
                                ),
                                _adjustButton(Icons.add, () => _updateWeight(0.1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.l),
                      Container(width: 1, height: 60, color: AppColors.borderGray),
                      const SizedBox(width: AppSpacing.l),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Quantity (pcs)', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _adjustButton(Icons.remove, () => _updateQty(-1)),
                                Expanded(
                                  child: TextField(
                                    controller: _qtyController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                                    decoration: const InputDecoration(border: InputBorder.none),
                                  ),
                                ),
                                _adjustButton(Icons.add, () => _updateQty(1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),
                  const Text('Quick Weight Select', style: TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [0.5, 1.0, 1.5, 2.0, 5.0].map((w) => ChoiceChip(
                      label: Text('${w}kg'),
                      selected: _weight == w,
                      onSelected: (selected) { if (selected) _setWeight(w); },
                      selectedColor: AppColors.primaryMaroon.withOpacity(0.1),
                      labelStyle: TextStyle(color: _weight == w ? AppColors.primaryMaroon : AppColors.textDark, fontSize: 11),
                    )).toList(),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Weight', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                            Text('${(_weight * _quantity).toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amount Payable', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('₵${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  ElevatedButton(
                    onPressed: () {
                      widget.onAdd(_weight * _quantity);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adjustButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.primaryMaroon,
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          side: const BorderSide(color: AppColors.borderGray),
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
  final List<PaymentDetail> _payments = [];
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _amountController = TextEditingController();
  final _refController = TextEditingController();

  double get _paidSoFar => _payments.fold(0, (sum, p) => sum + p.amount);
  double get _remaining => widget.totalAmount - _paidSoFar;

  @override
  void initState() {
    super.initState();
    _amountController.text = _remaining.toStringAsFixed(2);
  }

  void _addPayment() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() {
      _payments.add(PaymentDetail(
        method: _selectedMethod,
        amount: amount,
        reference: _refController.text.isEmpty ? null : _refController.text,
      ));
      _amountController.text = _remaining.toStringAsFixed(2);
      _refController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  children: [
                    _buildBalanceCard(),
                    if (_remaining > 0) ...[
                      const SizedBox(height: AppSpacing.l),
                      _buildPaymentMethodSelector(),
                      const SizedBox(height: AppSpacing.l),
                      _buildAmountInput(),
                    ],
                    const SizedBox(height: AppSpacing.l),
                    _buildPaymentList(),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: const BoxDecoration(
        color: AppColors.primaryMaroon,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_outlined, color: Colors.white),
              SizedBox(width: AppSpacing.m),
              Text(
                'Payment Collection',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        children: [
          _summaryRow('Total Bill', widget.totalAmount, isBold: true),
          const SizedBox(height: 8),
          _summaryRow('Total Paid', _paidSoFar, color: AppColors.accentGreen),
          const Divider(height: 24),
          _summaryRow(
            _remaining <= 0 ? 'Change' : 'Remaining Balance',
            _remaining.abs(),
            color: _remaining <= 0 ? AppColors.accentGreen : Colors.red,
            isBold: true,
            largeText: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false, Color? color, bool largeText = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.textLight)),
        Text(
          '₵${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: largeText ? 24 : 14,
            color: color ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            _methodButton(PaymentMethod.cash, Icons.money, 'Cash'),
            const SizedBox(width: 8),
            _methodButton(PaymentMethod.mobileMoney, Icons.smartphone, 'Mobile'),
            const SizedBox(width: 8),
            _methodButton(PaymentMethod.card, Icons.credit_card, 'Card'),
          ],
        ),
      ],
    );
  }

  Widget _methodButton(PaymentMethod method, IconData icon, String label) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryMaroon : Colors.transparent,
            border: Border.all(color: isSelected ? AppColors.primaryMaroon : AppColors.borderGray),
            borderRadius: BorderRadius.circular(AppRadius.s),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.textLight, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textLight, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₵ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedMethod == PaymentMethod.cash ? 'Notes' : 'Reference ID', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _refController,
                decoration: InputDecoration(
                  hintText: 'Optional',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: ElevatedButton(
            onPressed: _addPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
            ),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentList() {
    if (_payments.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Applied Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 12),
        ..._payments.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.s),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(
            children: [
              Icon(_getIconForMethod(p.method), size: 16, color: AppColors.primaryMaroon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.method.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    if (p.reference != null)
                      Text(p.reference!, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
              ),
              Text('₵${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                onPressed: () => setState(() => _payments.remove(p)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  IconData _getIconForMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Icons.money;
      case PaymentMethod.mobileMoney: return Icons.smartphone;
      case PaymentMethod.card: return Icons.credit_card;
    }
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderGray)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _payments.isEmpty ? null : () {
              widget.onComplete(_payments);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
            ),
            child: Text(_remaining <= 0 ? 'COMPLETE SALE' : 'SAVE PARTIAL'),
          ),
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSendingSms = false;

  void _handlePrintOnly() {
    ReceiptService.printReceipt(widget.sale);
    Navigator.pop(context);
  }

  Future<void> _handlePrintAndSms() async {
    if (_phoneController.text.isEmpty) return;

    setState(() => _isSendingSms = true);

    final updatedSale = SaleRecord(
      id: widget.sale.id,
      items: widget.sale.items,
      totalAmount: widget.sale.totalAmount,
      payments: widget.sale.payments,
      timestamp: widget.sale.timestamp,
      cashierName: widget.sale.cashierName,
      customerName: _nameController.text.isEmpty ? null : _nameController.text,
      customerPhone: _phoneController.text,
    );

    // Update history with customer info
    widget.ref.read(saleHistoryProvider.notifier).updateSale(updatedSale);

    // Send SMS
    await SmsService.sendReceiptSms(updatedSale);
    
    // Print
    ReceiptService.printReceipt(updatedSale);

    if (mounted) {
      setState(() => _isSendingSms = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt printed and SMS sent!'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: Container(
        width: 450,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: const BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: AppSpacing.m),
                  Text(
                    'Transaction Successful',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  children: [
                    _buildReceiptSummary(),
                    const Divider(height: 40),
                    _buildCustomerInfoFields(),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSummary() {
    return Column(
      children: [
        const Text('RECEIPT SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
        const SizedBox(height: 12),
        Text('₵${widget.sale.totalAmount.toStringAsFixed(2)}', 
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
        Text('Order ID: ${widget.sale.id}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 16),
        ...widget.sale.items.take(3).map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.product.name, style: const TextStyle(fontSize: 12)),
              Text('₵${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        )),
        if (widget.sale.items.length > 3)
          const Text('...and more items', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppRadius.s),
            border: Border.all(color: AppColors.borderGray, style: BorderStyle.solid),
          ),
          child: const Column(
            children: [
              Text(
                '“Give thanks to the Lord, for he is good; his love endures forever.”',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text('- Psalm 107:1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Details (Optional for SMS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Customer Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'e.g. 0540000000',
            prefixIcon: const Icon(Icons.phone_android_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderGray)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSendingSms ? null : _handlePrintOnly,
                  icon: const Icon(Icons.print),
                  label: const Text('Print Only'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primaryMaroon),
                    foregroundColor: AppColors.primaryMaroon,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isSendingSms || _phoneController.text.isEmpty) ? null : _handlePrintAndSms,
                  icon: _isSendingSms 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_to_mobile),
                  label: const Text('Print & SMS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close without printing', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
