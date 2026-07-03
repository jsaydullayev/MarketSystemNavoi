import 'dart:convert';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';
import 'http_service.dart';

class DebtService {
  final AuthProvider authProvider;
  final HttpService _httpService;

  DebtService({required this.authProvider, HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  // Get all debts
  Future<List<dynamic>> getAllDebts({String? status}) async {
    String url = '${ApiConstants.debts}/GetAllDebts';

    if (status != null) {
      url += '?status=$status';
    }

    final response = await _httpService.get(url);

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data ?? []);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load debts',
      );
    }
  }

  // Get customer debts
  Future<List<dynamic>> getCustomerDebts(String customerId) async {
    final response = await _httpService.get(
      '${ApiConstants.debts}/GetCustomerDebts/$customerId',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body);
      if (data == null) return [];
      return List<dynamic>.from(data);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load customer debts',
      );
    }
  }

  // Get customer total debt
  Future<double> getCustomerTotalDebt(String customerId) async {
    final response = await _httpService.get(
      '${ApiConstants.debts}/customer/$customerId/total',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return 0.0;
      }
      return double.tryParse(response.body) ?? 0.0;
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load customer total debt',
      );
    }
  }

  // Pay debt
  Future<dynamic> payDebt({
    required String debtId,
    required String paymentType,
    required double amount,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.debts}/$debtId/pay',
      body: {'paymentType': paymentType, 'amount': amount},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    // G5 — K3 added Xmin on Debt.RemainingDebt; two callers paying the same
    // debt concurrently see the loser as 409. Surface the structured envelope
    // so the bottomsheet can branch on `isConflict` and render
    // `concurrentChangeError` with a quiet refresh, instead of dumping
    // `Exception: Failed to pay debt: {"message":"..."}` into a snackbar.
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to pay debt',
    );
  }

  // Qarz to'lov muddatini (due date) yangilash. dueDate ISO-8601 satr yoki
  // null (muddatni olib tashlash uchun).
  Future<dynamic> updateDueDate({
    required String debtId,
    required String? dueDate,
  }) async {
    final response = await _httpService.put(
      '${ApiConstants.debts}/$debtId/due-date',
      body: {'dueDate': dueDate},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to update due date',
    );
  }
}
