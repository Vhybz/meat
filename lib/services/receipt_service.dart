import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale_model.dart';
import '../core/utils.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  static Future<void> printReceipt(SaleRecord sale) async {
    try {
      final doc = pw.Document();
      
      // Attempt to load fonts that support special characters
      // Fallback to standard fonts if network/loading fails
      pw.Font font;
      pw.Font boldFont;
      pw.Font italicFont;

      try {
        font = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
        italicFont = await PdfGoogleFonts.notoSansItalic();
      } catch (e) {
        debugPrint('Font loading failed, falling back to standard fonts: $e');
        font = pw.Font.helvetica();
        boldFont = pw.Font.helveticaBold();
        italicFont = pw.Font.helveticaOblique();
      }

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Mi CORAZON', style: pw.TextStyle(font: boldFont, fontSize: 18)),
                      pw.Text('FRESHMEAT BUTCHERY', style: pw.TextStyle(font: font)),
                      pw.Text('Location: New Town, Road linking From Water works Ltd. to Atronie Road', 
                        style: pw.TextStyle(font: font, fontSize: 7), textAlign: pw.TextAlign.center),
                      pw.Text('GPS: BS-0006-1566 | Tel: 0209276200', 
                        style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.SizedBox(height: 10),
                    ],
                  ),
                ),
                pw.Text('Invoice: ${sale.id}', style: pw.TextStyle(font: font, fontSize: 9)),
                pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.timestamp)}', style: pw.TextStyle(font: font, fontSize: 9)),
                pw.Text('Cashier: ${sale.cashierName}', style: pw.TextStyle(font: font, fontSize: 9)),
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Item', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.Text('Total', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 5),
                ...sale.items.map((item) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text('${item.product.name} (${WeightConverter.formatShort(item.quantity)})', 
                              style: pw.TextStyle(font: font, fontSize: 9)),
                          ),
                          pw.Text(item.total.toStringAsFixed(2), style: pw.TextStyle(font: font, fontSize: 9)),
                        ],
                      ),
                      if (item.discount > 0)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                          child: pw.Text(
                            'Original: ₵${(item.originalPrice * item.quantity).toStringAsFixed(2)} | Saved: ₵${item.discount.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: italicFont, fontSize: 7, color: PdfColors.grey700),
                          ),
                        ),
                    ],
                  )),
                pw.Divider(thickness: 0.5),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Qty: ${WeightConverter.formatShort(sale.totalQty)}', style: pw.TextStyle(font: font, fontSize: 8)),
                        pw.Text('Product Count: ${sale.productCount}', style: pw.TextStyle(font: font, fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (sale.totalDiscount > 0)
                          pw.Text('PROMO: ${sale.appliedPromo ?? "Applied"}', 
                            style: pw.TextStyle(font: boldFont, fontSize: 7, color: PdfColors.orange)),
                        
                        _receiptRow('Basic Amount', sale.basicAmount, font),
                        _receiptRow('GETFUND 2.5%', sale.getFund, font),
                        _receiptRow('NHIL 2.5%', sale.nhil, font),
                        _receiptRow('VAT 15%', sale.vat, font),
                        pw.Divider(thickness: 0.5),
                        _receiptRow('Sub Total', sale.subTotal, font),
                        _receiptRow('Net Invoice Value', sale.netInvoiceValue, font, isBold: true),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.5),

                ...sale.payments.map((p) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(p.method.name.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 9)),
                        pw.Text(p.amount.toStringAsFixed(2), style: pw.TextStyle(font: boldFont, fontSize: 9)),
                      ],
                    )),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Paid Amount', style: pw.TextStyle(font: boldFont, fontSize: 9)),
                    pw.Text(sale.amountPaid.toStringAsFixed(2), style: pw.TextStyle(font: boldFont, fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Change', style: pw.TextStyle(font: boldFont, fontSize: 9)),
                    pw.Text(sale.balance < 0 ? sale.balance.abs().toStringAsFixed(2) : '0.00', style: pw.TextStyle(font: boldFont, fontSize: 9)),
                  ],
                ),

                pw.SizedBox(height: 15),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'Mi CORAZON RECEIPT\n'
                          'ID: ${sale.id}\n'
                          'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.timestamp)}\n'
                          'Total: GHC ${sale.totalAmount.toStringAsFixed(2)}\n'
                          'Cashier: ${sale.cashierName}\n'
                          'Status: ${sale.balance <= 0 ? "PAID" : "PARTIAL"}',
                    width: 60,
                    height: 60,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Thank you for shopping with us!', style: pw.TextStyle(font: boldFont, fontSize: 9)),
                      pw.Text('Please come back again.', style: pw.TextStyle(font: font, fontSize: 9)),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              '"Give thanks to the Lord, for he is good; his love endures forever." - Ps 107:1',
                              style: pw.TextStyle(font: italicFont, fontSize: 7),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Barakallahu Feekum | Asaase Yaa, yɛda wo ase',
                              style: pw.TextStyle(font: italicFont, fontSize: 7),
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
    } catch (e) {
      debugPrint('Printing Error: $e');
    }
  }

  static pw.Widget _receiptRow(String label, double value, pw.Font font, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.SizedBox(width: 15),
          pw.Text(value.toStringAsFixed(2), style: pw.TextStyle(font: font, fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static Future<void> printSalesReport(List<SaleRecord> sales, {String title = 'Sales Report'}) async {
    try {
      final doc = pw.Document();
      final totalRevenue = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
      
      pw.Font font;
      pw.Font boldFont;

      try {
        font = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
      } catch (e) {
        font = pw.Font.helvetica();
        boldFont = pw.Font.helveticaBold();
      }

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
                    pw.Text('Mi CORAZON FRESHMEAT BUTCHERY', style: pw.TextStyle(font: boldFont)),
                    pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now()), style: pw.TextStyle(font: font)),
                  ],
                ),
              ),
              pw.Text(title, style: pw.TextStyle(fontSize: 18, font: boldFont)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Invoice ID', 'Date', 'Cashier', 'Total', 'Paid', 'Status'],
                data: sales.map((s) => [
                  s.id,
                  DateFormat('MMM dd, HH:mm').format(s.timestamp),
                  s.cashierName,
                  s.totalAmount.toStringAsFixed(2),
                  s.amountPaid.toStringAsFixed(2),
                  s.status.name.toUpperCase(),
                ]).toList(),
                headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF6B1111)),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Revenue: ', style: pw.TextStyle(font: boldFont)),
                  pw.Text('GHC ${totalRevenue.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont, fontSize: 16)),
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
    } catch (e) {
      debugPrint('Sales Report Printing Error: $e');
    }
  }
}
