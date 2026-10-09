import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/transaction.dart';
import '../constants/app_constants.dart';

/// Generates issue/return receipts and exportable reports as PDF.
class PdfService {
  PdfService._();

  static Future<void> printReceipt(LibraryTransaction transaction) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(AppConstants.collegeName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('${AppConstants.libraryName} — Transaction Receipt'),
                pw.Divider(),
                pw.SizedBox(height: 12),
                _row('Transaction ID', transaction.id),
                _row('Book', transaction.bookTitle),
                _row('Borrower', transaction.borrowerName),
                _row('Issue Date', transaction.issueDate.toString().split(' ').first),
                _row('Due Date', transaction.dueDate.toString().split(' ').first),
                if (transaction.returnDate != null) _row('Return Date', transaction.returnDate.toString().split(' ').first),
                if (transaction.fineAmount > 0) _row('Fine Amount', 'Rs. ${transaction.fineAmount.toStringAsFixed(0)}'),
                pw.SizedBox(height: 24),
                pw.Text('Thank you for using LibTrack.', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label), pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))],
      ),
    );
  }
}
