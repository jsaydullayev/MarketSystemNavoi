import 'dart:convert';
import '../models/cash_register_model.dart';
import 'http_service.dart';

class CashRegisterService {
  final HttpService _httpService;

  CashRegisterService({required HttpService httpService}) : _httpService = httpService;

  Future<CashRegisterModel?> getCashRegister() async {
    try {
      final response = await _httpService.get('/CashRegister');

      if (response.statusCode == 200) {
        return CashRegisterModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error getting cash register: $e');
      return null;
    }
  }

  Future<bool> withdrawCash(double amount, String comment) async {
    try {
      final response = await _httpService.post(
        '/CashRegister/withdraw',
        body: {
          'amount': amount,
          'comment': comment,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error withdrawing cash: $e');
      return false;
    }
  }

  Future<bool> addCash(double amount) async {
    try {
      final response = await _httpService.post(
        '/CashRegister/add',
        body: amount.toString(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error adding cash: $e');
      return false;
    }
  }
}
