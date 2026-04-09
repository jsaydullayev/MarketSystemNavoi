import 'dart:convert';
import 'app_logger.dart';

class SaleFlowContext {
  final String correlationId;

  SaleFlowContext(this.correlationId);

  Map<String, dynamic> get baseContext => {
    'flow': 'SALE_FLOW',
    'correlation_id': correlationId,
  };
}

class SaleFlowLogger {
  static String generateCorrelationId() {
    return 'REQ-${DateTime.now().millisecondsSinceEpoch}-${(DateTime.now().microsecond % 10000).toString().padLeft(4, '0')}';
  }

  static Map<String, String> getCorrelationHeaders(String correlationId) {
    return {'X-Correlation-ID': correlationId};
  }

  static void logQuantityInput({
    required SaleFlowContext context,
    required String source,
    required String step,
    required dynamic value,
    required String type,
    String? rawText,
    String? additionalInfo,
  }) {
    appLogger.info(
      'Quantity input trace',
      context: {
        ...context.baseContext,
        'source': source,
        'step': step,
        'value': value.toString(),
        'type': type,
        if (rawText != null) 'raw_text': rawText,
        if (additionalInfo != null) 'info': additionalInfo,
      },
    );
  }

  static void logJsonPayload({
    required SaleFlowContext context,
    required String endpoint,
    required Map<String, dynamic> body,
  }) {
    appLogger.info(
      'JSON payload',
      context: {
        ...context.baseContext,
        'endpoint': endpoint,
        'quantity': body['quantity']?.toString(),
        'quantity_type': body['quantity']?.runtimeType.toString(),
        'body_json': jsonEncode(body),
      },
    );
  }

  static void logApiResponse({
    required SaleFlowContext context,
    required String endpoint,
    required int statusCode,
    String? body,
  }) {
    appLogger.info(
      'API response',
      context: {
        ...context.baseContext,
        'endpoint': endpoint,
        'status_code': statusCode,
        if (body != null && body.length <= 300) 'response_body': body,
      },
    );
  }
}
