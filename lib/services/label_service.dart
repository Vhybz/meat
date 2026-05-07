import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transfer_models.dart';
import 'package:intl/intl.dart';

class LabelService {
  static Future<void> printTransferLabel(StockTransfer transfer) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm), // Small label size
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(transfer.meatType.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Weight: ${transfer.weight}kg', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('ID: ${transfer.id}', style: const pw.TextStyle(fontSize: 6)),
                pw.Text('Dest: ${transfer.destination}', style: const pw.TextStyle(fontSize: 6)),
                pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(transfer.transferTime), style: const pw.TextStyle(fontSize: 6)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Label_${transfer.id}',
    );
  }
}
