import 'dart:convert';
import '../../core/providers/auth_provider.dart';
import 'http_service.dart';
import '../../core/constants/api_constants.dart';

class DebtService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  DebtService({required this.authProvider}) {
    _httpService = HttpService();
  }

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
      throw Exception('Failed to load debts: ${response.statusCode}');
    }
  }

  // Get customer debts
  Future<List<dynamic>> getCustomerDebts(String customerId) async {
    final response = await _httpService.get(
      '${ApiConstants.debts}/customer/$customerId',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body);
      if (data == null) return [];
      return List<dynamic>.from(data);
    } else {
      throw Exception('Failed to load customer debts: ${response.statusCode}');
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
      throw Exception('Failed to load customer total debt: ${response.statusCode}');
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
      body: {
        'paymentType': paymentType,
        'amount': amount,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to pay debt: ${response.body}');
    }
  }
}
