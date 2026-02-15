import 'dart:convert';
import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

class ReportsService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  ReportsService({required this.authProvider}) {
    _httpService = HttpService();
  }

  // Kunlik hisobot
  Future<Map<String, dynamic>> getDailyReport(DateTime date) async {
    // Format date as yyyy-MM-dd for API (backend will handle UTC conversion)
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _httpService.get('${ApiConstants.reports}/GetDailyReport?date=$dateStr');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Avtorizatsiya xatosi: Tizimga qayta kiring (401)');
    } else if (response.statusCode == 403) {
      throw Exception('Ruxsat yo\'q: Faqat Admin va Owner foydalanuvchilari hisobotlarni ko\'rishi mumkin (403)');
    } else if (response.statusCode == 500) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Server xatosi: ${errorBody['message'] ?? 'Noma\'lum xato'} (500)');
    } else {
      throw Exception('Kunlik hisobotni yuklashda xatolik: ${response.statusCode} - ${response.body}');
    }
  }

  // Davriy hisobot
  Future<Map<String, dynamic>> getPeriodReport(DateTime start, DateTime end) async {
    // Format dates as yyyy-MM-dd for API (backend will handle UTC conversion)
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final response = await _httpService.get('${ApiConstants.reports}/GetPeriodReport?start=$startStr&end=$endStr');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Avtorizatsiya xatosi: Tizimga qayta kiring (401)');
    } else if (response.statusCode == 403) {
      throw Exception('Ruxsat yo\'q: Faqat Admin va Owner foydalanuvchilari hisobotlarni ko\'rishi mumkin (403)');
    } else if (response.statusCode == 500) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Server xatosi: ${errorBody['message'] ?? 'Noma\'lum xato'} (500)');
    } else {
      throw Exception('Davriy hisobotni yuklashda xatolik: ${response.statusCode} - ${response.body}');
    }
  }

  // Keng qamrovli hisobot
  Future<Map<String, dynamic>> getComprehensiveReport(DateTime date) async {
    // Format date as yyyy-MM-dd for API (backend will handle UTC conversion)
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _httpService.get('${ApiConstants.reports}/GetComprehensiveReport?date=$dateStr');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Avtorizatsiya xatosi: Tizimga qayta kiring (401)');
    } else if (response.statusCode == 403) {
      throw Exception('Ruxsat yo\'q: Faqat Admin va Owner foydalanuvchilari hisobotlarni ko\'rishi mumkin (403)');
    } else if (response.statusCode == 500) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Server xatosi: ${errorBody['message'] ?? 'Noma\'lum xato'} (500)');
    } else {
      throw Exception('Keng qamrovli hisobotni yuklashda xatolik: ${response.statusCode} - ${response.body}');
    }
  }

  // Excelga export (download)
  Future<String> exportToExcel(DateTime start, DateTime end) async {
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    // Return full URL for download
    return 'http://10.0.2.2:5137${ApiConstants.reports}/ExportToExcel?start=$startStr&end=$endStr';
  }

  // Keng hisobotni Excelga export
  Future<String> exportComprehensiveToExcel(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Return full URL for download
    return 'http://10.0.2.2:5137${ApiConstants.reports}/ExportComprehensiveToExcel?date=$dateStr';
  }

  // Kunlik savdo detallari - shu kuni sotilgan barcha tovarlar ro'yxati
  Future<List<Map<String, dynamic>>> getDailySaleItems(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _httpService.get('${ApiConstants.reports}/GetDailySaleItems?date=$dateStr');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['saleItems'] as List<dynamic>;
      return items.map((item) => item as Map<String, dynamic>).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Avtorizatsiya xatosi: Tizimga qayta kiring (401)');
    } else if (response.statusCode == 403) {
      throw Exception('Ruxsat yo\'q: Faqat Admin va Owner foydalanuvchilari hisobotlarni ko\'rishi mumkin (403)');
    } else if (response.statusCode == 500) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Server xatosi: ${errorBody['message'] ?? 'Noma\'lum xato'} (500)');
    } else {
      throw Exception('Kunlik savdo detallarini yuklashda xatolik: ${response.statusCode} - ${response.body}');
    }
  }
}
