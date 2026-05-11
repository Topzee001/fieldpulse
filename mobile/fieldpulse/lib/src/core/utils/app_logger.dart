import 'dart:convert';

import 'package:flutter/foundation.dart';

class AppLogger {
  static const _divider = '─────────────────────────────────────────';

  static void log(String message) {
    if (kDebugMode) {
      print('[Found] $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[Found Error] $message');
      if (error != null) print(error);
      if (stackTrace != null) print(stackTrace);
    }
  }

  /// Logs network request details including URL, method, headers, and payload
  static void logNetworkRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    Map<String, dynamic>? payload,
  }) {
    if (kDebugMode) {
      print('\n$_divider');
      print('🌐 NETWORK REQUEST');
      print('Method: $method');
      print('URL: $url');

      if (headers != null && headers.isNotEmpty) {
        print('Headers:');
        headers.forEach((key, value) {
          print('  $key: $value');
        });
      }

      if (payload != null && payload.isNotEmpty) {
        print('Payload:');
        try {
          final prettyPayload = JsonEncoder.withIndent('  ').convert(payload);
          print(prettyPayload);
        } catch (e) {
          print(payload);
        }
      }

      print('$_divider\n');
    }
  }

  /// Logs network response details including status code, headers, and body
  static void logNetworkResponse({
    required String url,
    required int statusCode,
    Map<String, String>? headers,
    dynamic responseBody,
    Duration? duration,
  }) {
    if (kDebugMode) {
      final isSuccess = statusCode >= 200 && statusCode < 300;
      final icon = isSuccess ? '✅' : '❌';

      print('\n$_divider');
      print('$icon NETWORK RESPONSE');
      print('URL: $url');
      print('Status Code: $statusCode');

      if (duration != null) {
        print('Duration: ${duration.inMilliseconds}ms');
      }

      if (headers != null && headers.isNotEmpty) {
        print('Response Headers:');
        headers.forEach((key, value) {
          print('  $key: $value');
        });
      }

      if (responseBody != null) {
        print('Response Body:');
        try {
          dynamic jsonBody;
          if (responseBody is String) {
            jsonBody = jsonDecode(responseBody);
          } else {
            jsonBody = responseBody;
          }
          final prettyResponse = JsonEncoder.withIndent('  ').convert(jsonBody);
          print(prettyResponse);
        } catch (e) {
          print(responseBody);
        }
      }

      print('$_divider\n');
    }
  }

  /// Logs network error details
  static void logNetworkError({
    required String url,
    required String method,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      print('\n$_divider');
      print('⚠️  NETWORK ERROR');
      print('Method: $method');
      print('URL: $url');
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack Trace:');
        stackTrace.toString().split('\n').take(5).forEach((line) {
          print('  $line');
        });
      }
      print('$_divider\n');
    }
  }
}
