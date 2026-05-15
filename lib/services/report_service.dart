import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/sale_model.dart';
import '../models/product.dart';
import '../models/butcher_models.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';

class ReportService {
  static const _primaryMaroon = PdfColor.fromInt(0xFF6B1111);

  static Future<void> generateDailySalesReport(List<SaleRecord> sales, DateTime date) async {
    final doc = pw.Document();
    final todaySales = sales.where((s) => 
      s.timestamp.year == date.year && 
      s.timestamp.month == date.month && 
      s.timestamp.day == date.day
    ).toList();

    final totalRevenue = todaySales.fold(0.0, (sum, s) => sum + s.totalAmount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Daily Sales Report', date),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection({
            'Total Transactions': todaySales.length.toString(),
            'Gross Revenue': 'GHS ${totalRevenue.toStringAsFixed(2)}',
          }),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _primaryMaroon),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Time', 'Invoice ID', 'Customer', 'Items', 'Total (GHS)'],
            data: todaySales.map((s) => [
              DateFormat('HH:mm').format(s.timestamp),
              s.id.substring(s.id.length - 8).toUpperCase(),
              s.customerName ?? 'Walk-in',
              s.items.length.toString(),
              s.totalAmount.toStringAsFixed(2),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Daily_Sales_${DateFormat('yyyyMMdd').format(date)}');
  }

  static Future<void> generateMonthlyRevenueSummary(List<SaleRecord> sales, DateTime date) async {
    final doc = pw.Document();
    final monthlySales = sales.where((s) => 
      s.timestamp.year == date.year && 
      s.timestamp.month == date.month
    ).toList();

    final totalRevenue = monthlySales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalDiscounts = monthlySales.fold(0.0, (sum, s) => sum + s.totalDiscount);
    
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Monthly Revenue Summary - ${DateFormat('MMMM yyyy').format(date)}', DateTime.now()),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection({
            'Total Orders': monthlySales.length.toString(),
            'Gross Revenue': 'GHS ${totalRevenue.toStringAsFixed(2)}',
            'Promo Savings': 'GHS ${totalDiscounts.toStringAsFixed(2)}',
          }),
          pw.SizedBox(height: 20),
          pw.Text('Revenue Breakdown by Day', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _primaryMaroon),
            headers: ['Date', 'Transactions', 'Daily Total (GHS)'],
            data: _groupSalesByDay(monthlySales).entries.map((e) => [
              e.key,
              e.value['count'].toString(),
              e.value['total'].toStringAsFixed(2),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Monthly_Revenue_${DateFormat('yyyyMM').format(date)}');
  }

  static Future<void> generateInventoryAudit(List<Product> products) async {
    final doc = pw.Document();
    
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Inventory Audit Report', DateTime.now()),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection({
            'Total Products': products.length.toString(),
            'Low Stock Items': products.where((p) => p.stockQuantity <= p.lowStockThreshold).length.toString(),
          }),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _primaryMaroon),
            headers: ['Category', 'Product Name', 'Current Stock', 'Unit', 'Retail Price'],
            data: products.map((p) => [
              p.category,
              p.name,
              p.stockQuantity.toStringAsFixed(1),
              p.unit,
              p.retailPrice.toStringAsFixed(2),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Inventory_Audit_${DateFormat('yyyyMMdd').format(DateTime.now())}');
  }

  static Future<void> generateSlaughterLogReport(List<SlaughterLog> logs) async {
    final doc = pw.Document();
    
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Slaughter & Yield Log', DateTime.now()),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _primaryMaroon),
            headers: ['Date', 'Animal Type', 'Intake (kg)', 'Yield (kg)', 'Waste (kg)', 'Status'],
            data: logs.map((l) => [
              DateFormat('MMM dd').format(l.slaughterTime ?? DateTime.now()),
              l.type.displayName,
              l.weight.toStringAsFixed(1),
              l.estimatedYield.toStringAsFixed(1),
              (l.weight - l.estimatedYield).toStringAsFixed(1),
              l.status.name.toUpperCase(),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Slaughter_Log_${DateFormat('yyyyMMdd').format(DateTime.now())}');
  }

  static Future<void> generateExpenseLedger(List<ExpenseRecord> expenses) async {
    final doc = pw.Document();
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Business Expense Ledger', DateTime.now()),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection({
            'Total Expenses': 'GHS ${total.toStringAsFixed(2)}',
            'Entries': expenses.length.toString(),
          }),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _primaryMaroon),
            headers: ['Date', 'Category', 'Description', 'Amount (GHS)'],
            data: expenses.map((e) => [
              DateFormat('yyyy-MM-dd').format(e.date),
              e.category,
              e.title,
              e.amount.toStringAsFixed(2),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Expense_Ledger');
  }

  static Future<void> generateCustomerDebtStatement(List<SaleRecord> sales) async {
    final doc = pw.Document();
    final debtSales = sales.where((s) => s.balance > 0).toList();
    final totalDebt = debtSales.fold(0.0, (sum, s) => sum + s.balance);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Customer Debt Statement', DateTime.now()),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection({
            'Total Outstanding': 'GHS ${totalDebt.toStringAsFixed(2)}',
            'Pending Invoices': debtSales.length.toString(),
          }),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _primaryMaroon),
            headers: ['Customer', 'Phone', 'Invoice Date', 'Total', 'Owed (GHS)'],
            data: debtSales.map((s) => [
              s.customerName ?? 'N/A',
              s.customerPhone ?? 'N/A',
              DateFormat('yyyy-MM-dd').format(s.timestamp),
              s.totalAmount.toStringAsFixed(2),
              s.balance.toStringAsFixed(2),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Debt_Statement');
  }

  static Future<void> generateMeatBreakdownAnalysis(List<MeatCut> cuts) async {
    final doc = pw.Document();
    
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Meat Breakdown & Cut Analysis', DateTime.now()),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Text('Detailed listing of all meat parts processed by the workstation.', style: pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _primaryMaroon),
            headers: ['Processed Date', 'Batch ID', 'Cut/Part Name', 'Weight (kg)'],
            data: cuts.map((c) => [
              DateFormat('MMM dd, HH:mm').format(c.processedAt),
              c.batchId.substring(c.batchId.length - 8).toUpperCase(),
              c.name,
              c.weight.toStringAsFixed(1),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Breakdown_Analysis');
  }

  static Future<void> generateStaffPerformanceReport(List<SaleRecord> sales, List<UserAccount> staff) async {
    final doc = pw.Document();
    
    final Map<String, Map<String, dynamic>> performance = {};
    for (final s in sales) {
      final name = s.cashierName;
      performance.putIfAbsent(name, () => {'total': 0.0, 'count': 0});
      performance[name]!['total'] += s.totalAmount;
      performance[name]!['count'] += 1;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Staff Performance Metrics', DateTime.now()),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _primaryMaroon),
            headers: ['Staff Member', 'Sales Count', 'Total Generated (GHS)', 'Avg/Sale'],
            data: performance.entries.map((e) => [
              e.key,
              e.value['count'].toString(),
              e.value['total'].toStringAsFixed(2),
              (e.value['total'] / e.value['count']).toStringAsFixed(2),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Staff_Performance');
  }

  static Map<String, Map<String, dynamic>> _groupSalesByDay(List<SaleRecord> sales) {
    final Map<String, Map<String, dynamic>> groups = {};
    for (final s in sales) {
      final day = DateFormat('yyyy-MM-dd').format(s.timestamp);
      groups[day] = groups[day] ?? {'count': 0, 'total': 0.0};
      groups[day]!['count'] += 1;
      groups[day]!['total'] += s.totalAmount;
    }
    return groups;
  }

  static pw.Widget _buildHeader(String title, DateTime date) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Mi CORAZON FRESHMEAT BUTCHERY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: _primaryMaroon)),
                pw.Text('Quality Meat Service • Ghana', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text('Report Date: ${DateFormat('yyyy-MM-dd').format(date)}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: _primaryMaroon),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated by MS Management System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(Map<String, String> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: data.entries.map((e) => pw.Column(
          children: [
            pw.Text(e.key, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(e.value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        )).toList(),
      ),
    );
  }
}

