import 'dart:convert';
import '../models/cash_register_model.dart';
import 'http_service.dart';
import '../../core/constants/api_constants.dart';

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
      print('Error getting cash register: $e');
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
      print('Error getting today sales: $e');
      return null;
    }
  }

  Future<bool> withdrawCash(double amount, String comment,
      [String withdrawType = 'cash']) async {
    try {
      print('=== WITHDRAW CASH ===');
      print('Amount: $amount');
      print('Comment: $comment');
      print('Type: $withdrawType');
      print('==================');

      final response = await _httpService.post(
        '${ApiConstants.cashRegister}/withdraw',
        body: {
          'amount': amount,
          'comment': comment,
          'withdrawType': withdrawType,
        },
      );

      print('Response Status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error withdrawing cash: $e');
      return false;
    }
  }

  Future<bool> addCash(double amount) async {
    try {
      final response = await _httpService.post(
        '${ApiConstants.cashRegister}/add',
        body: amount.toString(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error adding cash: $e');
      return false;
    }
  }
}
