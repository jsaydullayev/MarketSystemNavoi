import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Sends raw PDF bytes to the OS print dialog.
///
/// Uses [Printing.layoutPdf], which opens the system print window every time
/// (Windows / desktop / mobile / web) so the operator selects the printer
/// there — the app keeps no printer configuration of its own. This is the
/// single entry point reused by every "Pechat" action (invoice, sales list)
/// so the print logic is not duplicated across screens.
Future<void> printPdfBytes(List<int> bytes, {String name = 'document'}) {
  return Printing.layoutPdf(
    name: name,
    onLayout: (_) async => Uint8List.fromList(bytes),
  );
}
