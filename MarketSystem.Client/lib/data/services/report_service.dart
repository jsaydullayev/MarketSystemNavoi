import 'dart:convert';
import 'package:intl/intl.dart';

import '../../core/providers/auth_provider.dart';
import 'http_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/profit_model.dart';

class ReportService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  ReportService({required this.authProvider}) {
    _httpService = HttpService();
  }

  // Get comprehensive report
  Future<Map<String, dynamic>> getComprehensiveReport(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await _httpService.get(
      '${ApiConstants.reports}/GetComprehensiveReport?date=$formattedDate',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load report: ${response.statusCode}');
    }
  }

  // Export comprehensive report to Excel
  Future<void> exportComprehensiveToExcel(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final response = await _httpService.get(
      '${ApiConstants.reports}/ExportComprehensiveToExcel?date=$formattedDate',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export report: ${response.statusCode}');
    }
    // File is downloaded automatically by browser
  }

  // Get daily report
  Future<dynamic> getDailyReport(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await _httpService.get(
      '${ApiConstants.reports}/GetDailyReport?date=$formattedDate',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load daily report: ${response.statusCode}');
    }
  }

  // Get period report
  Future<dynamic> getPeriodReport(DateTime start, DateTime end) async {
    final startDate = DateFormat('yyyy-MM-dd').format(start);
    final endDate = DateFormat('yyyy-MM-dd').format(end);

    final response = await _httpService.get(
      '${ApiConstants.reports}/GetPeriodReport?start=$startDate&end=$endDate',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load period report: ${response.statusCode}');
    }
  }

  // Export period report to Excel
  Future<void> exportPeriodReportToExcel(DateTime start, DateTime end) async {
    final startDate = DateFormat('yyyy-MM-dd').format(start);
    final endDate = DateFormat('yyyy-MM-dd').format(end);

    final response = await _httpService.get(
      '${ApiConstants.reports}/ExportToExcel?start=$startDate&end=$endDate',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export report: ${response.statusCode}');
    }
    // File is downloaded automatically by browser
  }

  // New methods for role-based access control

  // Get profit summary - Owner only
  Future<ProfitSummaryModel> getProfitSummary() async {
    final response = await _httpService.get(
      '${ApiConstants.reports}/GetProfitSummary',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('Empty response body');
      }
      final decoded = jsonDecode(response.body);
      if (decoded == null) {
        throw Exception('Null response body');
      }
      return ProfitSummaryModel.fromJson(decoded as Map<String, dynamic>);
    } else if (response.statusCode == 403) {
      throw Exception('Sizga bu ma\'lumotni ko\'rish huquqi yo\'q');
    } else {
      throw Exception('Failed to load profit summary: ${response.statusCode}');
    }
  }

  // Get cash balance - Owner only
  Future<CashBalanceModel> getCashBalance() async {
    final response = await _httpService.get(
      '${ApiConstants.reports}/GetCashBalance',
    );

    if (response.statusCode == 200) {
      return CashBalanceModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 403) {
      throw Exception('Sizga bu ma\'lumotni ko\'rish huquqi yo\'q');
    } else {
      throw Exception('Failed to load cash balance: ${response.statusCode}');
    }
  }

  // Get daily sales list - Role-based filtering
  Future<DailySalesListModel> getDailySalesList(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await _httpService.get(
      '${ApiConstants.reports}/GetDailySalesList?date=$formattedDate',
    );

    if (response.statusCode == 200) {
      return DailySalesListModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load daily sales list: ${response.statusCode}');
    }
  }

  // Kunlik savdo detallari - shu kuni sotilgan barcha tovarlar ro'yxati
  Future<List<Map<String, dynamic>>> getDailySaleItems(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await _httpService.get(
      '${ApiConstants.reports}/GetDailySaleItems?date=$formattedDate',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) return [];
      final items = data['saleItems'] as List<dynamic>? ?? [];
      return items.map((item) => item as Map<String, dynamic>).toList();
    } else if (response.statusCode == 403) {
      throw Exception('Ruxsat yo\'q: Faqat Admin va Owner foydalanuvchilari hisobotlarni ko\'rishi mumkin');
    } else if (response.statusCode == 401) {
      throw Exception('Avtorizatsiya xatosi: Tizimga qayta kiring');
    } else {
      throw Exception('Kunlik savdo detallarini yuklashda xatolik: ${response.statusCode}');
    }
  }
}
