import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale_model.dart';
import '../core/utils.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  static Future<void> printReceipt(SaleRecord sale) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Standard receipt width
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Mi CORAZON', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text('FRESHMEAT BUTCHERY'),
                    pw.Text('Location: New Town, Road linking From Water works Ltd. to Atronie Road', style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('GPS: BS-0006-1566 | Tel: 0209276200', style: const pw.TextStyle(fontSize: 7)),
                    pw.SizedBox(height: 10),
                  ],
                ),
              ),
              pw.Text('Invoice: ${sale.id}'),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.timestamp)}'),
              pw.Text('Cashier: ${sale.cashierName}'),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 5),
              ...sale.items.map((item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${item.product.name} (${WeightConverter.formatShort(item.quantity)})'),
                      pw.Text('${item.total.toStringAsFixed(2)}'),
                    ],
                  )),
              pw.Divider(),
              
              // Financial Breakdown as per image
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Qty: ${WeightConverter.formatShort(sale.totalQty)}', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('SKU Count: ${sale.skuCount}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _receiptRow('Discount', 0.0),
                      _receiptRow('Basic Amount', sale.basicAmount),
                      _receiptRow('GETFUND 2.5%', sale.getFund),
                      _receiptRow('NHIL 2.5%', sale.nhil),
                      _receiptRow('VAT 15%', sale.vat),
                      pw.SizedBox(width: 100, child: pw.Divider()),
                      _receiptRow('Sub Total', sale.subTotal),
                      _receiptRow('Net Invoice Value', sale.netInvoiceValue, isBold: true),
                    ],
                  ),
                ],
              ),
              pw.Divider(),

              ...sale.payments.map((p) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(p.method.name.toLowerCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(p.amount.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ],
                  )),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Paid Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(sale.amountPaid.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Change', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(sale.balance < 0 ? sale.balance.abs().toStringAsFixed(2) : '0.00', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Thank you for shopping with us!', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Please come back again.', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 15),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            '"Give thanks to the Lord, for he is good; his love endures forever." - Psalm 107:1',
                            style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Barakallahu Feekum - May Allah bless your sustenance.',
                            style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Asaase Yaa, yɛda wo ase - Mother Earth, we thank you for this bounty.',
                            style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Allah ya sa albarka - May Allah bless this transaction.',
                            style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Receipt_${sale.id}',
    );
  }

  static pw.Widget _receiptRow(String label, double value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.SizedBox(width: 20),
          pw.Text(value.toStringAsFixed(2), style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static Future<void> printSalesReport(List<SaleRecord> sales, {String title = 'Sales Report'}) async {
    final doc = pw.Document();
    final totalRevenue = sales.fold(0.0, (sum, s) => sum + s.totalAmount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Mi CORAZON FRESHMEAT BUTCHERY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
                ],
              ),
            ),
            pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Invoice ID', 'Date', 'Cashier', 'Total', 'Paid', 'Status'],
              data: sales.map((s) => [
                s.id,
                DateFormat('MMM dd, HH:mm').format(s.timestamp),
                s.cashierName,
                s.totalAmount.toStringAsFixed(2),
                s.amountPaid.toStringAsFixed(2),
                s.status.name.toUpperCase(),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total Revenue: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('GHS ${totalRevenue.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Sales_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }
}
