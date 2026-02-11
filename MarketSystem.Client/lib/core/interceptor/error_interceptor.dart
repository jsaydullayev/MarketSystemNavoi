/// Error Interceptor
/// Handles API errors and shows appropriate messages
library;

import 'package:dio/dio.dart';

import '../handlers/navigation_handler.dart';

/// Error Interceptor class
class ErrorInterceptor extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Handle different error types
    final errorMessage = _getErrorMessage(err);

    // Show error message to user
    if (err.type != DioExceptionType.cancel) {
      NavigationHandler.showSnackBar(
        message: errorMessage,
        backgroundColor: const Color(0xFFE53935), // Error red color
      );
    }

    super.onError(err, handler);
  }

  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Internet bilan aloqa yo\'q. Iltimos, keyinroq urinib ko\'ring.';

      case DioExceptionType.connectionError:
        return 'Internetga ulanish imkonsiz. Iltimos, internetingizni tekshiring.';

      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode);

      case DioExceptionType.cancel:
        return 'So\'rov bekor qilindi';

      case DioExceptionType.badCertificate:
        return 'Xavfsizlik xatosi. Sertifikat noto\'g\'ri';

      case DioExceptionType.unknown:
      default:
        return 'Xatolik yuz berdi. Iltimos, qaytadan urinib ko\'ring.';
    }
  }

  String _handleHttpError(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Noto\'g\'ri so\'rov. Ma\'lumotlarni tekshiring';
      case 401:
        return 'Tizimga kirish uchun qayta autentifikatsiyadan o\'ting';
      case 403:
        return 'Sizda bu amalni bajarish huquqi yo\'q';
      case 404:
        return 'Ma\'lumot topilmadi';
      case 500:
        return 'Server xatosi. Iltimos, keyinroq urinib ko\'ring';
      case 503:
        return 'Server vaqtincha ishlamayapti';
      default:
        return 'Xatolik yuz berdi (Kod: $statusCode)';
    }
  }
}
