import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../services/butcher_service.dart';
import '../../services/product_service.dart';
import '../../models/butcher_models.dart';
import '../../models/product.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cutsAsync = ref.watch(recentCutsProvider);
    final productsAsync = ref.watch(productsFutureProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inventory Control', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Monitoring stock from slaughter to retail', style: TextStyle(color: AppColors.textLight)),
                ],
              ),
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primaryMaroon,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textLight,
                  tabs: const [
                    Tab(text: 'Slaughterhouse'),
                    Tab(text: 'Retail Store'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCutsView(cutsAsync),
                _buildRetailView(productsAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCutsView(AsyncValue<List<MeatCut>> cutsAsync) {
    return Column(
      children: [
        _buildStockAlerts('Monitoring Slaughterhouse: Records reflect most recent processed meat cuts.'),
        const SizedBox(height: AppSpacing.l),
        Expanded(
          child: cutsAsync.when(
            data: (cuts) {
              if (cuts.isEmpty) return const Center(child: Text('No internal inventory records found.'));
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: AppSpacing.m,
                  mainAxisSpacing: AppSpacing.m,
                  childAspectRatio: 1.2,
                ),
                itemCount: cuts.length,
                itemBuilder: (context, index) => _buildInventoryCard(cuts[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildRetailView(AsyncValue<List<Product>> productsAsync) {
    return Column(
      children: [
        _buildStockAlerts('Monitoring Retail: Real-time stock levels available at the POS terminal.'),
        const SizedBox(height: AppSpacing.l),
        Expanded(
          child: productsAsync.when(
            data: (products) {
              final activeProducts = products.where((p) => !p.isDeleted).toList();
              if (activeProducts.isEmpty) return const Center(child: Text('No retail products found.'));
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: AppSpacing.m,
                  mainAxisSpacing: AppSpacing.m,
                  childAspectRatio: 1.2,
                ),
                itemCount: activeProducts.length,
                itemBuilder: (context, index) => _buildProductInventoryCard(activeProducts[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildStockAlerts(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          const Text('Inventory Monitoring: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.orange))),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(MeatCut cut) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.inventory_2_outlined, color: AppColors.primaryMaroon, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('INTERNAL', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Spacer(),
            Text(cut.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('Batch: ${cut.batchId.substring(0, 8).toUpperCase()}', style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Weight', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                    Text('${cut.weight.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.history, size: 18), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInventoryCard(Product product) {
    final bool isLow = product.stockQuantity < 10;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.storefront_outlined, color: Colors.blue, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isLow ? Colors.red : Colors.blue).withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(isLow ? 'LOW STOCK' : 'RETAIL', 
                    style: TextStyle(color: isLow ? Colors.red : Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Spacer(),
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(product.category, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Stock', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                    Text('${product.stockQuantity.toStringAsFixed(1)} ${product.unit}', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLow ? Colors.red : AppColors.textDark)),
                  ],
                ),
                const Icon(Icons.trending_up, size: 18, color: AppColors.accentGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
