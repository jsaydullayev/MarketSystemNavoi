import 'dart:convert';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/cash_register_model.dart';
import 'http_service.dart';

class CashRegisterService {
  final HttpService _httpService;

  CashRegisterService({required HttpService httpService})
      : _httpService = httpService;

  Future<CashRegisterModel?> getCashRegister() async {
    try {
      final response = await _httpService.get(ApiConstants.cashRegister);
      if (response.statusCode == 200) {
        return CashRegisterModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<TodaySalesSummaryModel?> getTodaySales() async {
    try {
      final response =
          await _httpService.get('${ApiConstants.cashRegister}/today-sales');
      if (response.statusCode == 200) {
        return TodaySalesSummaryModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Withdraw cash from the till. G5 — throws [ApiException] on any
  /// non-2xx so callers can branch on the structured `code`. The K2 Xmin
  /// guard the backend just added surfaces concurrent withdrawals as a
  /// 409 `DbUpdateConcurrencyException`; the previous `return statusCode
  /// == 200` collapsed every failure into a generic snackbar.
  Future<void> withdrawCash(double amount, String comment,
      [String withdrawType = 'cash']) async {
    final response = await _httpService.post(
      '${ApiConstants.cashRegister}/withdraw',
      body: {
        'amount': amount,
        'comment': comment,
        'withdrawType': withdrawType,
      },
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
  }

  /// Add cash to the till. Same G5 semantics as [withdrawCash] — throws
  /// [ApiException] on non-2xx so the caller can render a 409-aware UX.
  Future<void> addCash(double amount) async {
    final response = await _httpService.post(
      '${ApiConstants.cashRegister}/add',
      body: amount.toString(),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
  }
}
