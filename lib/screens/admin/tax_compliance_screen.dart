import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/app_sidebar.dart';
import '../../services/menu_service.dart';
import '../../services/user_provider.dart';
import '../../services/sale_provider.dart';
import '../../services/expense_provider.dart';
import '../../services/report_service.dart';
import '../../models/sale_model.dart';

class TaxComplianceScreen extends ConsumerStatefulWidget {
  const TaxComplianceScreen({super.key});

  @override
  ConsumerState<TaxComplianceScreen> createState() => _TaxComplianceScreenState();
}

class _TaxComplianceScreenState extends ConsumerState<TaxComplianceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isQuarterly = true; // Default to quarterly as per user request

  int get _currentQuarter => ((_selectedDate.month - 1) / 3).floor() + 1;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    const currentRoute = '/admin/tax';
    final menuItems = ref.watch(menuItemsProvider);

    final allSales = ref.watch(saleHistoryProvider);
    final allExpenses = ref.watch(expenseProvider).records;

    // Filter by selected range (Month or Quarter)
    final monthlySales = allSales.where((s) {
      if (s.status == SaleStatus.cancelled) return false;
      if (s.timestamp.year != _selectedDate.year) return false;
      
      if (_isQuarterly) {
        final saleQuarter = ((s.timestamp.month - 1) / 3).floor() + 1;
        return saleQuarter == _currentQuarter;
      } else {
        return s.timestamp.month == _selectedDate.month;
      }
    }).toList();

    final monthlyExpenses = allExpenses.where((e) {
      if (e.date.year != _selectedDate.year) return false;
      
      if (_isQuarterly) {
        final expenseQuarter = ((e.date.month - 1) / 3).floor() + 1;
        return expenseQuarter == _currentQuarter;
      } else {
        return e.date.month == _selectedDate.month;
      }
    }).toList();

    final totalSales = monthlySales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalExpenses = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final grossProfit = totalSales - totalExpenses;

    // GRA Tax Breakdown Calculation
    // Total Amount = Base + 2.5% NHIL + 2.5% GETFund + 1.0% COVID + (15% VAT on (Base+NHIL+GET+COVID))
    // We reverse engineer this from the total sales to show how much tax IS INCLUDED or EXPECTED.
    // For meat shops, often they calculate tax on TOP of gross profit or per receipt.
    
    // We'll calculate it based on the Standard Rate formula for the whole month
    final double taxExclusiveBase = totalSales / 1.219;
    final double nhil = taxExclusiveBase * 0.025;
    final double getFund = taxExclusiveBase * 0.025;
    final double covid = taxExclusiveBase * 0.01;
    final double taxableValueForVat = taxExclusiveBase + nhil + getFund + covid;
    final double vat = taxableValueForVat * 0.15;
    final double totalTax = nhil + getFund + covid + vat;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const MainAppBar(title: 'GRA Tax Compliance'),
      drawer: isDesktop ? null : Drawer(
        child: AppSidebar(
          userId: user.id,
          userName: user.name,
          userRole: user.activePrimaryRole.name.toUpperCase(),
          currentRoute: currentRoute,
          items: menuItems,
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
              items: menuItems,
              onTap: (route) => MenuService.navigate(context, route, currentRoute),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: AppSpacing.xl),
                  _buildProfitSummary(theme, totalSales, totalExpenses, grossProfit),
                  const SizedBox(height: AppSpacing.xl),
                  _buildTaxBreakdown(theme, nhil, getFund, covid, vat, totalTax),
                  const SizedBox(height: AppSpacing.xl),
                  _buildNetProfitCard(theme, grossProfit, totalTax),
                  const SizedBox(height: AppSpacing.xl),
                  _buildActions(theme, totalSales, totalExpenses, grossProfit, {
                    'NHIL': nhil,
                    'GETFund': getFund,
                    'COVID': covid,
                    'VAT': vat,
                    'TOTAL': totalTax,
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final quarterLabel = 'Q$_currentQuarter ${_selectedDate.year}';
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GRA Tax Compliance', 
                    style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Automated analysis for quarterly tax filing', 
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isMobile) _buildFrequencyToggle(theme),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            if (isMobile) _buildFrequencyToggle(theme),
            if (isMobile) const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _selectMonth(context),
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text(_isQuarterly ? quarterLabel : monthLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyToggle(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('Monthly', !_isQuarterly, theme),
          _toggleBtn('Quarterly', _isQuarterly, theme),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, ThemeData theme) {
    return InkWell(
      onTap: () => setState(() => _isQuarterly = label == 'Quarterly'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.s - 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildProfitSummary(ThemeData theme, double sales, double expenses, double profit) {
    final isMobile = ResponsiveLayout.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Operational Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (isMobile)
          Column(
            children: [
              _statBox('Monthly Sales', '₵${sales.toStringAsFixed(2)}', Colors.blue, theme),
              const SizedBox(height: AppSpacing.s),
              _statBox('Monthly Expenses', '₵${expenses.toStringAsFixed(2)}', Colors.red, theme),
              const SizedBox(height: AppSpacing.s),
              _statBox('Gross Profit', '₵${profit.toStringAsFixed(2)}', Colors.green, theme),
            ],
          )
        else
          Row(
            children: [
              _statBox('Monthly Sales', '₵${sales.toStringAsFixed(2)}', Colors.blue, theme),
              const SizedBox(width: AppSpacing.m),
              _statBox('Monthly Expenses', '₵${expenses.toStringAsFixed(2)}', Colors.red, theme),
              const SizedBox(width: AppSpacing.m),
              _statBox('Gross Profit', '₵${profit.toStringAsFixed(2)}', Colors.green, theme),
            ],
          ),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color, ThemeData theme) {
    return Expanded(
      flex: ResponsiveLayout.isMobile(context) ? 0 : 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown, 
              child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxBreakdown(ThemeData theme, double nhil, double getFund, double covid, double vat, double total) {
    final isMobile = ResponsiveLayout.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.l : AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryMaroon.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: AppColors.primaryMaroon.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: AppColors.primaryMaroon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('GRA STANDARD RATE CALCULATION', 
                  style: TextStyle(
                    color: theme.colorScheme.primary, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 1.2, 
                    fontSize: isMobile ? 11 : 13
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _taxRow('National Health Insurance Levy (NHIL)', '2.5%', nhil, theme),
          _taxRow('Ghana Education Trust Fund (GETFund)', '2.5%', getFund, theme),
          _taxRow('COVID-19 Health Recovery Levy', '1.0%', covid, theme),
          const SizedBox(height: 8),
          _taxRow('VAT (Standard Rate)', '15.0%', vat, theme),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('TOTAL ESTIMATED TAX PAYABLE', 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('₵${total.toStringAsFixed(2)}', 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primaryMaroon)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taxRow(String label, String rate, double amount, ThemeData theme) {
    final isMobile = ResponsiveLayout.isMobile(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, 
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          if (!isMobile)
            Text(rate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text('₵${amount.toStringAsFixed(2)}', 
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetProfitCard(ThemeData theme, double gross, double tax) {
    final net = gross - tax;
    final isMobile = ResponsiveLayout.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.l : AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.wallet_rounded, color: Colors.white, size: isMobile ? 32 : 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isQuarterly ? 'ESTIMATED NET PROFIT (Q$_currentQuarter)' : 'NET PROFIT AFTER TAX', 
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('₵${net.toStringAsFixed(2)}', 
                    style: TextStyle(color: Colors.white, fontSize: isMobile ? 28 : 32, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme, double sales, double expenses, double profit, Map<String, double> breakdown) {
    final isMobile = ResponsiveLayout.isMobile(context);
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 55 : 60,
      child: ElevatedButton.icon(
        onPressed: () {
          ReportService.generateTaxComplianceReport(
            date: _selectedDate, 
            totalSales: sales, 
            totalExpenses: expenses, 
            grossProfit: profit, 
            taxBreakdown: breakdown,
            isQuarterly: _isQuarterly,
          );
        },
        icon: const Icon(Icons.print_rounded, size: 18),
        label: Text(
          isMobile 
            ? (_isQuarterly ? 'GENERATE Q-REPORT' : 'GENERATE MONTHLY') 
            : (_isQuarterly ? 'GENERATE QUARTERLY COMPLIANCE REPORT (PDF)' : 'GENERATE MONTHLY COMPLIANCE REPORT (PDF)'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      helpText: 'Select Month for Analysis',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month);
      });
    }
  }
}
