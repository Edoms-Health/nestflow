import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:nestflow/nestflow.dart';

class InvoicePdfGenerator {
  static const _orange = PdfColor.fromInt(0xFFFF751F);
  static const _blue = PdfColor.fromInt(0xFF004AAD);
  static const _grey = PdfColor.fromInt(0xFF5F6368);
  static const _lightGrey = PdfColor.fromInt(0xFFF5F7FA);

  static Future<File> generate({
    required BusinessInvoiceModel invoice,
    required BusinessModel business,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(business.name,
                        style: pw.TextStyle(font: fontBold, fontSize: 22,
                            color: _blue)),
                    if (business.address != null)
                      pw.Text(business.address!,
                          style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
                    if (business.phone != null)
                      pw.Text('Tel: ${business.phone}',
                          style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
                    if (business.email != null)
                      pw.Text(business.email!,
                          style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
                    if (business.tin != null)
                      pw.Text('TIN: ${business.tin}',
                          style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE',
                        style: pw.TextStyle(font: fontBold, fontSize: 28,
                            color: _orange)),
                    pw.Text(invoice.invoiceNumber,
                        style: pw.TextStyle(font: fontBold, fontSize: 14,
                            color: _blue)),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: _statusColor(invoice.status),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(invoice.status.toUpperCase(),
                          style: pw.TextStyle(font: fontBold, fontSize: 10,
                              color: PdfColors.white)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Divider(color: _orange, thickness: 2),
            pw.SizedBox(height: 16),

            // ── Bill To + Dates ──────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILL TO',
                          style: pw.TextStyle(font: fontBold, fontSize: 10,
                              color: _orange)),
                      pw.SizedBox(height: 4),
                      pw.Text(invoice.client?.name ?? 'Client',
                          style: pw.TextStyle(font: fontBold, fontSize: 13)),
                      if (invoice.client?.phone != null)
                        pw.Text(invoice.client!.phone!,
                            style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
                      if (invoice.client?.email != null)
                        pw.Text(invoice.client!.email!,
                            style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
                      if (invoice.client?.address != null)
                        pw.Text(invoice.client!.address!,
                            style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _dateRow('Issue Date:', dateFmt.format(invoice.issuedAt), font, fontBold),
                      _dateRow('Due Date:', dateFmt.format(invoice.dueAt), font, fontBold),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // ── Items Table ──────────────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _blue),
                  children: ['ITEM', 'UNIT', 'QTY', 'UNIT PRICE', 'TOTAL']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(h,
                                style: pw.TextStyle(font: fontBold,
                                    fontSize: 9, color: PdfColors.white)),
                          ))
                      .toList(),
                ),
                // Item rows
                ...invoice.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color: i.isEven ? _lightGrey : PdfColors.white),
                    children: [
                      _cell(item.name, font),
                      _cell(item.unit, font, align: pw.TextAlign.center),
                      _cell(fmt.format(item.qty), font, align: pw.TextAlign.center),
                      _cell('${business.currency} ${fmt.format(item.unitPrice)}',
                          font, align: pw.TextAlign.right),
                      _cell('${business.currency} ${fmt.format(item.total)}',
                          fontBold, align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Totals ───────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 220,
                  child: pw.Column(children: [
                    _totalRow('Subtotal', invoice.subtotal, business.currency, font, fontBold, fmt),
                    if (invoice.discountPercent > 0)
                      _totalRow('Discount (${invoice.discountPercent}%)',
                          -invoice.discountAmount, business.currency, font, fontBold, fmt),
                    if (invoice.taxPercent > 0)
                      _totalRow('Tax (${invoice.taxPercent}%)',
                          invoice.taxAmount, business.currency, font, fontBold, fmt),
                    pw.Divider(color: _orange),
                    _totalRow('TOTAL', invoice.total, business.currency, fontBold, fontBold, fmt,
                        highlight: true),
                  ]),
                ),
              ],
            ),

            // ── Notes ────────────────────────────────────────────
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text('Notes:', style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.notes!,
                  style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
            ],

            pw.Spacer(),
            pw.Divider(color: _grey),
            pw.Center(
              child: pw.Text('Thank you for your business!',
                  style: pw.TextStyle(font: fontBold, fontSize: 10, color: _orange)),
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _cell(String text, pw.Font font,
      {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(font: font, fontSize: 9)),
      );

  static pw.Widget _dateRow(String label, String value,
      pw.Font font, pw.Font fontBold) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
          pw.SizedBox(width: 8),
          pw.Text(value,
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
        ],
      );

  static pw.Widget _totalRow(String label, double amount, String currency,
      pw.Font font, pw.Font fontBold, NumberFormat fmt,
      {bool highlight = false}) =>
      pw.Container(
        color: highlight ? _orange : null,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(font: fontBold, fontSize: 10,
                    color: highlight ? PdfColors.white : null)),
            pw.Text('$currency ${fmt.format(amount)}',
                style: pw.TextStyle(font: fontBold, fontSize: 10,
                    color: highlight ? PdfColors.white : null)),
          ],
        ),
      );

  static PdfColor _statusColor(String status) {
    switch (status) {
      case 'paid': return const PdfColor.fromInt(0xFF1abc9c);
      case 'sent': return _blue;
      case 'overdue': return const PdfColor.fromInt(0xFFD32F2F);
      default: return _grey;
    }
  }
}
