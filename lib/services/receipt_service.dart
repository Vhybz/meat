import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale_model.dart';
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
                    pw.Text('MEAT SHOP MS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text('Management System Receipt'),
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
                      pw.Text('${item.product.name} (${item.quantity}kg)'),
                      pw.Text('GH₵${item.total.toStringAsFixed(2)}'),
                    ],
                  )),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('GH₵${sale.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('Payments:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ...sale.payments.map((p) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(p.method.name.toUpperCase(), style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('GH₵${p.amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  )),
              if (sale.balance > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('BALANCE DUE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                    pw.Text('GH₵${sale.balance.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
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
                      child: pw.Text(
                        '"Give thanks to the Lord, for he is good; his love endures forever."',
                        style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Text('- Psalm 107:1', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
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
}
