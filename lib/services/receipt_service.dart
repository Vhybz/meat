import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale_model.dart';
import '../core/utils.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  static Future<void> printReceipt(SaleRecord sale) async {
    await printInvoices([sale]);
  }

  static Future<void> printInvoices(List<SaleRecord> sales) async {
    if (sales.isEmpty) return;
    try {
      final doc = pw.Document();
      
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

      for (var sale in sales) {
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
                        pw.Text('Mi~CORAZON', style: pw.TextStyle(font: boldFont, fontSize: 18)),
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
                  if (sale.customerName != null)
                    pw.Text('Customer: ${sale.customerName} ${sale.customerPhone != null ? "(${sale.customerPhone})" : ""}', 
                      style: pw.TextStyle(font: font, fontSize: 9)),
                  
                  if (sale.status == SaleStatus.awaitingDeposit)
                    pw.Container(
                      width: double.infinity,
                      margin: const pw.EdgeInsets.symmetric(vertical: 8),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.red, width: 2),
                        color: PdfColors.red50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text('*** AWAITING BANK DEPOSIT ***', style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.red)),
                          pw.Divider(color: PdfColors.red, thickness: 0.5),
                          pw.SizedBox(height: 5),
                          pw.Text('Please pay into the account below:', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.red)),
                          pw.SizedBox(height: 4),
                          pw.Text('Bank: UMB (Universal Merchant Bank)', style: pw.TextStyle(font: boldFont, fontSize: 8)),
                          pw.Text('Branch: Sunyani', style: pw.TextStyle(font: font, fontSize: 8)),
                          pw.Text('Account Name: Mi-Corazon Enterprise', style: pw.TextStyle(font: font, fontSize: 8)),
                          pw.Text('Account Number: 1111069263015', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                          pw.SizedBox(height: 5),
                          pw.Text('VALID ONLY AFTER BANK VERIFICATION', style: pw.TextStyle(font: boldFont, fontSize: 7, color: PdfColors.red)),
                        ],
                      ),
                    ),
                  
                  if (sale.isVerified && sale.bankReceiptUrl != null)
                    pw.Container(
                      width: double.infinity,
                      margin: const pw.EdgeInsets.symmetric(vertical: 8),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: PdfColors.green, width: 1),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text('PAYMENT VERIFIED', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.green)),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          if (sale.bankReceiptId != null)
                            pw.Text('Bank Ref: ${sale.bankReceiptId}', style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.green)),
                          pw.Text('Receipt Uploaded & Confirmed', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.green700)),
                        ],
                      ),
                    ),
                    
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
                          
                          _receiptRow('Basic Amount', sale.taxExclusiveAmount, font),
                          _receiptRow('GETFUND 2.5%', sale.getFundAmount, font),
                          _receiptRow('NHIL 2.5%', sale.nhilAmount, font),
                          _receiptRow('VAT 15%', sale.vatAmount, font),
                          pw.Divider(thickness: 0.5),
                          _receiptRow('Sub Total', sale.totalAmount, font),
                          _receiptRow('Net Invoice Value', sale.netInvoiceValue, font, isBold: true),
                        ],
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 0.5),

                  pw.Text('PAYMENT BREAKDOWN', style: pw.TextStyle(font: boldFont, fontSize: 8)),
                  pw.SizedBox(height: 4),

                  ...sale.payments.map((p) => pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('METHOD: ${_formatMethod(p.method)}', style: pw.TextStyle(font: font, fontSize: 9)),
                          pw.Text('₵ ${p.amount.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont, fontSize: 9)),
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
                  
                  if (sale.balance > 0.01)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('BALANCE DUE (DEBT)', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.red)),
                        pw.Text(sale.balance.toStringAsFixed(2), style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.red)),
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
                            'Status: ${sale.status == SaleStatus.awaitingDeposit ? "AWAITING DEPOSIT" : (sale.balance <= 0 ? "PAID" : "PARTIAL")}',
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
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: sales.length == 1 ? 'Receipt_${sales[0].id}' : 'Batch_Receipts_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    } catch (e) {
      debugPrint('Printing Error: $e');
    }
  }

  static String _formatMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return 'CASH';
      case PaymentMethod.mobileMoney: return 'MOMO';
      case PaymentMethod.bankDeposit: return 'BANK';
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

  static Future<void> printSalesReport(List<SaleRecord> sales, {String title = 'Sales Report', double totalExpenses = 0.0}) async {
    try {
      final doc = pw.Document();
      final totalRevenue = sales.where((s) => s.status != SaleStatus.cancelled).fold(0.0, (sum, s) => sum + s.totalAmount);
      final netProfit = totalRevenue - totalExpenses;
      
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
                    pw.Text('Mi~CORAZON FRESHMEAT BUTCHERY', style: pw.TextStyle(font: boldFont)),
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
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Total Revenue: ', style: pw.TextStyle(font: boldFont)),
                          pw.Text('₵ ${totalRevenue.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont)),
                        ],
                      ),
                      if (totalExpenses > 0)
                        pw.Row(
                          children: [
                            pw.Text('Total Expenses: ', style: pw.TextStyle(font: boldFont, color: PdfColors.red)),
                            pw.Text('₵ ${totalExpenses.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont, color: PdfColors.red)),
                          ],
                        ),
                      pw.SizedBox(width: 150, child: pw.Divider()),
                      pw.Row(
                        children: [
                          pw.Text('Estimated Profit: ', style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.green)),
                          pw.Text('₵ ${netProfit.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.green)),
                        ],
                      ),
                    ],
                  ),
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

  static Future<void> printDebtReport(List<SaleRecord> sales) async {
    try {
      final doc = pw.Document();
      final totalDebt = sales.fold(0.0, (sum, s) => sum + s.balance);
      
      // Calculate max debt to determine thresholds
      double maxDebt = 0;
      for (var s in sales) {
        if (s.balance > maxDebt) maxDebt = s.balance;
      }

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
                    pw.Text('Mi~CORAZON FRESHMEAT BUTCHERY', style: pw.TextStyle(font: boldFont)),
                    pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now()), style: pw.TextStyle(font: font)),
                  ],
                ),
              ),
              pw.Text('OUTSTANDING DEBT REPORT', style: pw.TextStyle(fontSize: 18, font: boldFont)),
              pw.SizedBox(height: 20),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF6B1111)),
                    children: [
                      _tableHeader('Customer', boldFont),
                      _tableHeader('Phone', boldFont),
                      _tableHeader('Invoice ID', boldFont),
                      _tableHeader('Date', boldFont),
                      _tableHeader('Total', boldFont),
                      _tableHeader('Balance', boldFont),
                    ],
                  ),
                  // Data Rows with conditional coloring
                  ...sales.map((s) {
                    PdfColor bgColor = PdfColors.white;
                    PdfColor textColor = PdfColors.black;

                    if (maxDebt > 0) {
                      if (s.balance >= maxDebt * 0.7) {
                        bgColor = PdfColors.red50;
                        textColor = PdfColors.red900;
                      } else if (s.balance >= maxDebt * 0.3) {
                        bgColor = PdfColors.yellow50;
                        textColor = PdfColors.yellow900;
                      } else {
                        bgColor = PdfColors.green50;
                        textColor = PdfColors.green900;
                      }
                    }

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bgColor),
                      children: [
                        _tableCell(s.customerName ?? 'Walk-in', font, color: textColor),
                        _tableCell(s.customerPhone ?? 'N/A', font, color: textColor),
                        _tableCell(s.id, font, color: textColor),
                        _tableCell(DateFormat('MMM dd, yyyy').format(s.timestamp), font, color: textColor),
                        _tableCell('₵${s.totalAmount.toStringAsFixed(2)}', font, color: textColor),
                        _tableCell('₵${s.balance.toStringAsFixed(2)}', boldFont, color: textColor),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL OUTSTANDING DEBT: ', style: pw.TextStyle(font: boldFont)),
                  pw.Text('₵${totalDebt.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.red)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(width: 10, height: 10, color: PdfColors.red50),
                  pw.SizedBox(width: 4),
                  pw.Text('Critical (>70%)', style: pw.TextStyle(fontSize: 8, font: font)),
                  pw.SizedBox(width: 12),
                  pw.Container(width: 10, height: 10, color: PdfColors.yellow50),
                  pw.SizedBox(width: 4),
                  pw.Text('Warning (30-70%)', style: pw.TextStyle(fontSize: 8, font: font)),
                  pw.SizedBox(width: 12),
                  pw.Container(width: 10, height: 10, color: PdfColors.green50),
                  pw.SizedBox(width: 4),
                  pw.Text('Minor (<30%)', style: pw.TextStyle(fontSize: 8, font: font)),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text('Report Generated by Mi~Corazon Management System', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Debt_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    } catch (e) {
      debugPrint('Debt Report Printing Error: $e');
    }
  }

  static pw.Widget _tableHeader(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(font: font, color: PdfColors.white, fontSize: 9)),
    );
  }

  static pw.Widget _tableCell(String text, pw.Font font, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8, color: color)),
    );
  }

  static Future<void> printPaidInvoicesReport(List<SaleRecord> sales) async {
    try {
      final doc = pw.Document();
      final totalPaid = sales.fold(0.0, (sum, s) => sum + s.amountPaid);
      
      // Calculate max paid to determine thresholds
      double maxPaid = 0;
      for (var s in sales) {
        if (s.amountPaid > maxPaid) maxPaid = s.amountPaid;
      }

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
                    pw.Text('Mi~CORAZON FRESHMEAT BUTCHERY', style: pw.TextStyle(font: boldFont)),
                    pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now()), style: pw.TextStyle(font: font)),
                  ],
                ),
              ),
              pw.Text('FULLY PAID INVOICES REPORT', style: pw.TextStyle(fontSize: 18, font: boldFont)),
              pw.SizedBox(height: 20),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF28A745)), // Green header
                    children: [
                      _tableHeader('Customer', boldFont),
                      _tableHeader('Invoice ID', boldFont),
                      _tableHeader('Date', boldFont),
                      _tableHeader('Cashier', boldFont),
                      _tableHeader('Total Amount', boldFont),
                    ],
                  ),
                  // Data Rows with conditional coloring
                  ...sales.map((s) {
                    PdfColor bgColor = PdfColors.white;
                    PdfColor textColor = PdfColors.black;

                    if (maxPaid > 0) {
                      if (s.amountPaid >= maxPaid * 0.7) {
                        bgColor = PdfColor.fromInt(0xFFFFEBEE); // Light Red for Highest
                        textColor = PdfColor.fromInt(0xFFB71C1C);
                      } else if (s.amountPaid >= maxPaid * 0.3) {
                        bgColor = PdfColor.fromInt(0xFFFFFDE7); // Light Yellow for Mid
                        textColor = PdfColor.fromInt(0xFFF57F17);
                      } else {
                        bgColor = PdfColor.fromInt(0xFFE8F5E9); // Light Green for Least
                        textColor = PdfColor.fromInt(0xFF1B5E20);
                      }
                    }

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bgColor),
                      children: [
                        _tableCell(s.customerName ?? 'Walk-in', font, color: textColor),
                        _tableCell(s.id, font, color: textColor),
                        _tableCell(DateFormat('MMM dd, yyyy').format(s.timestamp), font, color: textColor),
                        _tableCell(s.cashierName.split(' ')[0], font, color: textColor),
                        _tableCell('₵${s.totalAmount.toStringAsFixed(2)}', boldFont, color: textColor),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL PAID REVENUE: ', style: pw.TextStyle(font: boldFont)),
                  pw.Text('₵${totalPaid.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.green)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(width: 10, height: 10, color: const PdfColor.fromInt(0xFFFFEBEE)),
                  pw.SizedBox(width: 4),
                  pw.Text('High Value (>70%)', style: pw.TextStyle(fontSize: 8, font: font)),
                  pw.SizedBox(width: 12),
                  pw.Container(width: 10, height: 10, color: const PdfColor.fromInt(0xFFFFFDE7)),
                  pw.SizedBox(width: 4),
                  pw.Text('Mid Value (30-70%)', style: pw.TextStyle(fontSize: 8, font: font)),
                  pw.SizedBox(width: 12),
                  pw.Container(width: 10, height: 10, color: const PdfColor.fromInt(0xFFE8F5E9)),
                  pw.SizedBox(width: 4),
                  pw.Text('Standard (<30%)', style: pw.TextStyle(fontSize: 8, font: font)),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text('Report Generated by Mi~Corazon Management System', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Paid_Invoices_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    } catch (e) {
      debugPrint('Paid Invoices Report Printing Error: $e');
    }
  }
}
