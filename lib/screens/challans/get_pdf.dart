import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/animation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../models/challan.dart';
import '../../utils/exceptions.dart';

Future<String> makePdf(Challan challan, int pages) async {
  var pdf = await preparePdf(challan, pages);

  var documentsDirectory = await getApplicationDocumentsDirectory();
  var fileName =
      "${challan.number}_${challan.session}_${challan.buyer.name}.pdf";

  Directory challansDirectory;

  if (Platform.isWindows) {
    challansDirectory =
        Directory("${documentsDirectory.path}/CrsManager/Challans");
  } else {
    // Android
    // Check perms first
    var status = await Permission.storage.status;
    if (status.isDenied) {
      await Permission.storage.request();
    }
    status = await Permission.storage.status;
    // If still denied, return failure
    if (status.isDenied) {
      return throw PermissionDenied();
    }

    challansDirectory = await getApplicationDocumentsDirectory();
  }

  if (!await challansDirectory.exists()) {
    await challansDirectory.create(recursive: true);
  }

  final path = "${challansDirectory.path}/$fileName";

  // If file exists, delete it and then write it
  if (await File(path).exists()) {
    await File(path).delete();
  }

  File(path).writeAsBytes(await pdf.save());
  pdf.dispose();
  return path;
}

Future<PdfDocument> preparePdf(Challan challan, int pages) async {
  var pdf = PdfDocument();
  pdf.pageSettings.margins.all = 5;
  PdfPen pen = PdfPen(
    PdfColor.fromCMYK(0, 0, 0, 100),
  );
  var normalFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

  // Unicode font
  final data = await rootBundle.load("assets/helvetica.ttf");
  final Uint8List unicodeFontData =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  // File("assets/helvetica.ttf").readAsBytesSync();
  var normalFontUnicode = PdfTrueTypeFont(unicodeFontData, 12);

  var boldFont =
      PdfStandardFont(PdfFontFamily.timesRoman, 13, style: PdfFontStyle.bold);
  var boldCRSFont =
      PdfStandardFont(PdfFontFamily.timesRoman, 35, style: PdfFontStyle.bold);
  var underlinedNormalFont = PdfStandardFont(PdfFontFamily.helvetica, 11,
      style: PdfFontStyle.underline);
  var underlinedBoldFont = PdfStandardFont(PdfFontFamily.helvetica, 12,
      multiStyle: [PdfFontStyle.underline, PdfFontStyle.bold]);
  var finePrintFont = PdfStandardFont(PdfFontFamily.helvetica, 6);

  var bigBoldCRSFont =
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

  DateFormat formatter = DateFormat('dd-MMMM-yyyy');
  String formattedTime = formatter.format(challan.createdAt);

  for (int i = 0; i < pages; i++) {
    var page = pdf.pages.add();
    // Draw the outer most box
    page.graphics
        .drawRectangle(pen: pen, bounds: const Rect.fromLTWH(10, 35, 565, 762));

    // Draw Header Text

    page.graphics.drawString('GSTIN : 07AFUPG3557P1ZM', normalFont,
        bounds: const Rect.fromLTWH(15, 40, 200, 200));

    page.graphics.drawString('Delivery Challan Book', boldFont,
        bounds: const Rect.fromLTWH(240, 40, 200, 200));

    page.graphics.drawString('State Code : 07', normalFont,
        bounds: const Rect.fromLTWH(484, 40, 200, 200));

    page.graphics.drawString('Computer Rental Services', boldCRSFont,
        bounds: const Rect.fromLTWH(95, 47, 500, 200));

    page.graphics.drawString(
        '208 D-3C, SAVITRI NAGAR, NEW DELHI - 110017', normalFont,
        bounds: const Rect.fromLTWH(169, 87, 400, 200));

    page.graphics.drawString(
        'Phone: 01126014629 / 46605081 Mobile No. : 9999362600', normalFont,
        bounds: const Rect.fromLTWH(145, 100, 400, 200));

    page.graphics.drawLine(pen, const Offset(10, 115), const Offset(575, 115));

    // Draw buyer info and challan info

    page.graphics.drawString('M/s ', underlinedNormalFont,
        bounds: const Rect.fromLTWH(14, 118, 500, 100));

    final PdfGrid buyerInfoGrid = PdfGrid();
    buyerInfoGrid.style.cellPadding = PdfPaddings(left: 28, top: 3, bottom: -2);

    buyerInfoGrid.columns.add(count: 1);
    PdfGridRow nameRow = buyerInfoGrid.rows.add();
    nameRow.cells[0].value = challan.buyer.name;

    PdfGridCellStyle cellStyle = PdfGridCellStyle();
    cellStyle.borders.bottom.color = PdfColor(0, 0, 255, 0);
    cellStyle.borders.top.color = PdfColor(0, 0, 255, 0);

    nameRow.style = PdfGridRowStyle(font: normalFont);
    // nameRow.cells[0].style = cellStyle;
    nameRow.cells[0].stringFormat = PdfStringFormat(lineSpacing: 5);

    PdfGridRow addressRow = buyerInfoGrid.rows.add();
    addressRow.cells[0].value = challan.buyer.address;
    addressRow.style = PdfGridRowStyle(font: normalFont);
    // addressRow.cells[0].style = cellStyle;
    addressRow.cells[0].stringFormat = PdfStringFormat(lineSpacing: 5);

    PdfGridRow gstRow = buyerInfoGrid.rows.add();
    gstRow.cells[0].value = "GST No. : ${challan.buyer.gst}";
    gstRow.style = PdfGridRowStyle(font: normalFont);
    gstRow.cells[0].style = cellStyle;

    buyerInfoGrid.draw(
        page: page, bounds: const Rect.fromLTWH(10, 115, 415, 500));

    // Line between Buyer info and challan info
    page.graphics.drawLine(pen, const Offset(415, 115), const Offset(415, 720));

    page.graphics.drawString(
        "Challan No. : ${challan.number.toString()} / ${challan.session.replaceAll("-20", "-")}",
        normalFont,
        bounds: const Rect.fromLTWH(419, 130, 500, 100));

    page.graphics.drawString("Date : $formattedTime", normalFont,
        bounds: const Rect.fromLTWH(419, 160, 500, 100));

    page.graphics.drawString("Original for Recipient", normalFont,
        bounds: const Rect.fromLTWH(419, 190, 500, 100));
    page.graphics.drawString("Duplicate for Supplier", normalFont,
        bounds: const Rect.fromLTWH(419, 210, 500, 100));
    page.graphics.drawString("Triplicate for Transporter", normalFont,
        bounds: const Rect.fromLTWH(419, 230, 500, 100));

    page.graphics
        .drawRectangle(pen: pen, bounds: const Rect.fromLTWH(555, 190, 14, 15));
    page.graphics
        .drawRectangle(pen: pen, bounds: const Rect.fromLTWH(555, 209, 14, 15));
    page.graphics
        .drawRectangle(pen: pen, bounds: const Rect.fromLTWH(555, 228, 14, 15));

    // Page 1
    if (i == 0) {
      // Tick mark
      page.graphics.drawLine(
          pen, const Offset(555, 190 + 8), const Offset(555 + 6, 190 + 15));
      page.graphics.drawLine(pen, const Offset(555 + 6, 190 + 15),
          const Offset(555 + 14, 190 + 1));

      // Cross mark on box 2

      page.graphics.drawLine(
          pen, const Offset(555, 209), const Offset(555 + 14, 209 + 15));
      page.graphics.drawLine(
          pen, const Offset(555, 209 + 15), const Offset(555 + 14, 209));

      // Cross mark on box 3

      page.graphics.drawLine(
          pen, const Offset(555, 228), const Offset(555 + 14, 228 + 15));
      page.graphics.drawLine(
          pen, const Offset(555, 228 + 15), const Offset(555 + 14, 228));
    } else if (i == 1) {
      // Cross mark on box 1
      page.graphics.drawLine(
        pen,
        const Offset(555, 190),
        const Offset(555 + 14, 190 + 15),
      );
      page.graphics.drawLine(
        pen,
        const Offset(555, 190 + 15),
        const Offset(555 + 14, 190),
      );
      // Tick mark on box 2
      page.graphics.drawLine(
          pen, const Offset(555, 209 + 8), const Offset(555 + 6, 209 + 15));
      page.graphics.drawLine(pen, const Offset(555 + 6, 209 + 15),
          const Offset(555 + 14, 209 + 1));

      // Cross mark on box 3

      page.graphics.drawLine(
          pen, const Offset(555, 228), const Offset(555 + 14, 228 + 15));
      page.graphics.drawLine(
          pen, const Offset(555, 228 + 15), const Offset(555 + 14, 228));
    } else {
      // Cross mark on box 1
      page.graphics.drawLine(
        pen,
        const Offset(555, 190),
        const Offset(555 + 14, 190 + 15),
      );
      page.graphics.drawLine(
        pen,
        const Offset(555, 190 + 15),
        const Offset(555 + 14, 190),
      );
      // Cross mark on box 2
      page.graphics.drawLine(
        pen,
        const Offset(555, 209),
        const Offset(555 + 14, 209 + 15),
      );
      page.graphics.drawLine(
        pen,
        const Offset(555, 209 + 15),
        const Offset(555 + 14, 209),
      );
      // Tick mark on box 3
      page.graphics.drawLine(
          pen, const Offset(555, 228 + 8), const Offset(555 + 6, 228 + 15));
      page.graphics.drawLine(pen, const Offset(555 + 6, 228 + 15),
          const Offset(555 + 14, 228 + 1));
    }

    page.graphics.drawLine(pen, const Offset(10, 250), const Offset(575, 250));

    // Line between # and description columns
    page.graphics.drawLine(pen, const Offset(36, 250), const Offset(36, 720));

    // Line between serial and quantity columns
    page.graphics.drawLine(pen, const Offset(515, 250), const Offset(515, 720));

    var productsFont = PdfStandardFont(PdfFontFamily.helvetica, 14);

    final PdfGrid grid = PdfGrid();
    grid.style.cellPadding = PdfPaddings(left: 5, top: 5);
    grid.style.font = productsFont;
    grid.columns.add(count: 4);
    grid.columns[0].width = 26;
    grid.columns[0].format =
        PdfStringFormat(alignment: PdfTextAlignment.center);

    grid.columns[1].width = 379;
    grid.columns[2].width = 100;

    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = '#';
    headerRow.cells[1].value = 'Product Description';
    headerRow.cells[2].value = 'Serial';
    headerRow.cells[3].value = 'Quantity';

    headerRow.cells[1].stringFormat.alignment = PdfTextAlignment.center;
    headerRow.cells[2].stringFormat.alignment = PdfTextAlignment.center;
    headerRow.cells[3].stringFormat.alignment = PdfTextAlignment.center;

    headerRow.style.font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    headerRow.style.backgroundBrush = PdfSolidBrush(PdfColor(191, 191, 191));

    int totalProducts = 0;
    for (Product product in challan.products) {
      int index = challan.products.indexOf(product);
      PdfGridRow row = grid.rows.add();
      row.cells[0].value = '${index + 1}';
      row.cells[1].value = product.description;
      row.cells[2].value = product.serial;
      row.cells[3].value =
          "${product.quantity} ${product.quantityUnit}"; // product.quantity.toString();
      row.cells[3].stringFormat.alignment = PdfTextAlignment.center;

      row.style.font = PdfStandardFont(PdfFontFamily.helvetica, 12);

      PdfGridCellStyle cellStyle = PdfGridCellStyle();
      cellStyle.borders.bottom.color = PdfColor(0, 0, 255, 0);
      cellStyle.borders.top.color = PdfColor(0, 0, 255, 0);

      row.cells[0].style = cellStyle;
      row.cells[1].style = cellStyle;
      row.cells[2].style = cellStyle;
      row.cells[3].style = cellStyle;

      totalProducts += product.quantity;
    }

    grid.draw(page: page, bounds: const Rect.fromLTWH(10, 250, 575, 600));

    // Stuff below Products

    // Horizontal Lines just below products
    page.graphics.drawLine(pen, const Offset(10, 720), const Offset(575, 720));
    page.graphics.drawString(
        'Vehicle Number : ${challan.vehicleNumber}', normalFont,
        bounds: const Rect.fromLTWH(50, 705, 200, 100));
    page.graphics.drawString('Delivered By :', normalFont,
        bounds: const Rect.fromLTWH(250, 705, 200, 100));
    page.graphics.drawString(challan.deliveredBy, underlinedBoldFont,
        bounds: const Rect.fromLTWH(330, 705, 200, 100));
    page.graphics.drawLine(pen, const Offset(10, 703), const Offset(575, 703));

    page.graphics.drawString('Total', normalFont,
        bounds: const Rect.fromLTWH(450, 705, 200, 100));

    page.graphics.drawString(totalProducts.toString(), normalFont,
        bounds: const Rect.fromLTWH(540, 705, 200, 100));

    page.graphics.drawString('''
1. CHECKED THE ABOVE CONFIGURATION
2. The system mentioned would be supplied without any software. The hired party will be entirely responsible for the uses of any kind of software installed on the machines. Whether legal or pirated in any circumstances COMPUTER RENTAL SERVICES should not be help responsible for this.
3. You are not allowed to break the seal. Also you are not allowed to open the machine.
        ''', finePrintFont,
        bounds: const Rect.fromLTWH(15, 725, 345, 100),
        format: PdfStringFormat(lineSpacing: 2));

    var numberFormatter = NumberFormat('#,##,000');
    if (challan.productsValue > 0) {
      page.graphics.drawString(
          "To whomsoever this may concern, the value of the above mentioned items does not exceed \u{20B9}${numberFormatter.format(challan.productsValue)}/-",
          normalFontUnicode,
          bounds: const Rect.fromLTWH(50, 620, 300, 100));
    }
    page.graphics.drawString('Received By : ', normalFont,
        bounds: const Rect.fromLTWH(50, 660, 100, 100));
    page.graphics.drawLine(pen, const Offset(360, 720), const Offset(360, 798));
    page.graphics.drawString('For', normalFont,
        bounds: const Rect.fromLTWH(366, 730, 30, 30));
    page.graphics.drawString('Computer Rental Services', bigBoldCRSFont,
        bounds: const Rect.fromLTWH(388, 728, 300, 100));
    page.graphics.drawString('Authorised Signatory', normalFont,
        bounds: const Rect.fromLTWH(450, 780, 200, 100));

    if (challan.cancelled) {
      var data = await rootBundle.load('assets/images/cancelled.png');
      final Uint8List imageData =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final PdfBitmap image = PdfBitmap(imageData);

      page.graphics.drawImage(image, const Rect.fromLTWH(0, 300, 500, 300));
    }
  }

  return pdf;
}
