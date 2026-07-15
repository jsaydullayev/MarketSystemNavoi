// Shared formatting helpers for the security journal screen.

import 'dart:convert';

import '../../../../core/utils/number_formatter.dart';

/// Compact, locale-neutral timestamp ("HH:mm · dd.MM.yyyy"). The audit
/// reviewer cares about precise time, not pretty "5 min ago" phrasing.
String formatTimestamp(DateTime when) {
  String two(int n) => n.toString().padLeft(2, '0');
  final local = when.isUtc ? when.toLocal() : when;
  return '${two(local.hour)}:${two(local.minute)} · '
      '${two(local.day)}.${two(local.month)}.${local.year}';
}

/// Human-readable label for a known audit-payload field. Raw IDs (GUIDs) mean
/// nothing to the reviewer, so this map only names the fields worth showing;
/// everything else (and any `*Id` key) is skipped by [readablePayloadRows].
const Map<String, String> _payloadLabels = {
  'itemcount': 'Soni',
  'quantity': 'Miqdor',
  'totalamount': 'Jami summa',
  'paidamount': "To'langan",
  'costprice': 'Tan narx',
  'amount': 'Summa',
  'invoicenumber': 'Nakladnoy',
  'status': 'Holat',
  'paymenttype': "To'lov turi",
  'totaldebt': 'Qarz',
  'remainingdebt': 'Qolgan qarz',
  'suppliername': 'Yetkazib beruvchi',
  'productname': 'Mahsulot',
  'customername': 'Mijoz',
  'username': 'Login',
  'statuscode': 'Status kod',
  'message': 'Xatolik',
  'path': 'Manzil',
  'method': 'Metod',
  'exceptiontype': 'Turi',
};

const Set<String> _moneyKeys = {
  'totalamount',
  'paidamount',
  'costprice',
  'amount',
  'totaldebt',
  'remainingdebt',
};

/// Parse an audit payload JSON into readable `(label, value)` rows. Raw IDs are
/// skipped (users don't understand GUIDs — they need the data). Money fields
/// are space-grouped. Returns an empty list when the payload isn't a JSON
/// object or carries nothing worth showing.
List<(String, String)> readablePayloadRows(String raw) {
  if (raw.trim().isEmpty) return const [];
  dynamic decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return const [];
  }
  if (decoded is! Map) return const [];

  final rows = <(String, String)>[];
  decoded.forEach((k, v) {
    final key = k.toString().toLowerCase();
    if (v == null) return;
    if (key.endsWith('id')) return; // skip raw GUIDs
    final label = _payloadLabels[key];
    if (label == null) return; // only known, meaningful fields
    String value;
    if (_moneyKeys.contains(key) && v is num) {
      value = "${NumberFormatter.format(v)} so'm";
    } else {
      value = v.toString();
    }
    if (value.isEmpty) return;
    rows.add((label, value));
  });
  return rows;
}
