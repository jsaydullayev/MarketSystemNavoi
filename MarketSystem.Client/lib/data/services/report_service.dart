import 'dart:convert';
import 'package:intl/intl.dart';

import '../../core/providers/auth_provider.dart';
import 'http_service.dart';
import '../../core/constants/api_constants.dart';

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
}
