import 'dart:developer' as dev;

class LogEntry {
  final String timestamp;
  final String level;
  final String message;
  final Map<String, dynamic>? context;
  final String? correlationId;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.context,
    this.correlationId,
  });

  String get formattedString {
    var buf = StringBuffer();
    buf.write('[$level] $timestamp');

    if (correlationId != null) {
      buf.write(' | correlation_id: $correlationId');
    }

    buf.write(': $message');

    if (context != null && context!.isNotEmpty) {
      buf.write(' | context: $context');
    }

    return buf.toString();
  }
}

class AppLogger {
  void info(String message, {Map<String, dynamic>? context}) {
    final logMessage = context != null ? '$message | $context' : message;
    dev.log(logMessage, name: 'AppLogger');
  }

  void debug(String message, {Map<String, dynamic>? context}) {
    final logMessage = context != null ? '$message | $context' : message;
    dev.log(logMessage, name: 'AppLogger', level: 500); // Level 500 = FINE
  }

  void warn(String message, {Map<String, dynamic>? context}) {
    final logMessage = context != null ? '$message | $context' : message;
    dev.log(logMessage, name: 'AppLogger', level: 900); // Level 900 = WARNING
  }

  void error(String message, {Map<String, dynamic>? context}) {
    final logMessage = context != null ? '$message | $context' : message;
    dev.log(logMessage, name: 'AppLogger', level: 1000); // Level 1000 = SEVERE
  }

  void startSpan(String name, {String? correlationId}) {
    dev.log('[$name] START', name: 'AppLogger');
  }

  void endSpan(String name, {String? correlationId}) {
    dev.log('[$name] END', name: 'AppLogger');
  }
}

// Global appLogger instance
final AppLogger appLogger = AppLogger();
