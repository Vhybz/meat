import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transfer_models.dart';
import '../core/utils.dart';
import 'package:intl/intl.dart';

class LabelService {
  static Future<void> printTransferLabel(StockTransfer transfer) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 35 * PdfPageFormat.mm), // Small label size
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(transfer.meatType.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Weight: ${WeightConverter.formatShort(transfer.weight)}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 2),
                pw.Container(
                  height: 12,
                  width: 40,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: transfer.id,
                    drawText: false,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text('ID: ${transfer.id.length > 12 ? transfer.id.substring(transfer.id.length - 12) : transfer.id}', style: const pw.TextStyle(fontSize: 5)),
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

  static Future<void> printSlaughterLabel(dynamic log) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 35 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('SLAUGHTER LOG', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text(log.type.name.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Weight: ${WeightConverter.formatShort(log.weight)}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 2),
                pw.Container(
                  height: 12,
                  width: 40,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: log.id,
                    drawText: false,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text('ID: ${log.id.length > 12 ? log.id.substring(log.id.length - 12) : log.id}', style: const pw.TextStyle(fontSize: 5)),
                pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(log.slaughterTime ?? DateTime.now()), style: const pw.TextStyle(fontSize: 6)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Slaughter_${log.id}',
    );
  }

  static Future<void> printCutLabel(dynamic cut) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 35 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('MEAT CUT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text(cut.name.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Weight: ${WeightConverter.formatShort(cut.weight)}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 2),
                pw.Container(
                  height: 12,
                  width: 40,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: cut.id,
                    drawText: false,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text('Batch: ${cut.batchId.length > 8 ? cut.batchId.substring(0, 8) : cut.batchId}', style: const pw.TextStyle(fontSize: 5)),
                pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(cut.processedAt), style: const pw.TextStyle(fontSize: 6)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Cut_${cut.id}',
    );
  }

  static Future<void> printBatchLabel(dynamic batch) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 35 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('MEAT BATCH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text(batch.meatType.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Weight: ${WeightConverter.formatShort(batch.weight)}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 2),
                pw.Container(
                  height: 12,
                  width: 40,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: batch.id,
                    drawText: false,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text('ID: ${batch.id.length > 12 ? batch.id.substring(batch.id.length - 12) : batch.id}', style: const pw.TextStyle(fontSize: 5)),
                pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(batch.createdAt), style: const pw.TextStyle(fontSize: 6)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Batch_${batch.id}',
    );
  }
}
