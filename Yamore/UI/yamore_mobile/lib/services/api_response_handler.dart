import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'session_controller.dart';

/// Central HTTP response handling: success codes, parsed API errors, and 401 session reset.
class ApiResponseHandler {
  ApiResponseHandler._();

  /// Parses Yamore API error payloads:
  /// - ExceptionFilter: `{ "errors": { "userError": ["..."] } }`
  /// - ValidationProblemDetails-style: `{ "title", "detail", "errors": { ... } }`
  static String? parseUserFacingMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) return null;
      final title = decoded['title'] as String?;
      final detail = decoded['detail'] as String?;
      final errors = decoded['errors'];
      if (errors is Map<String, dynamic>) {
        final userErr = errors['userError'];
        if (userErr is List && userErr.isNotEmpty) {
          final first = userErr.first;
          if (first is String && first.isNotEmpty) return first;
        }
        final buffer = <String>[];
        for (final entry in errors.entries) {
          final v = entry.value;
          if (v is List) {
            for (final item in v) {
              if (item is String && item.isNotEmpty) buffer.add(item);
            }
          } else if (v is String && v.isNotEmpty) {
            buffer.add(v);
          }
        }
        if (buffer.isNotEmpty) return buffer.join(' ');
      }
      // Stripe API error shape: { "error": { "message": "..." } } or { "message": "Invalid API Key ..." }
      if (decoded['error'] is Map<String, dynamic>) {
        final errMap = decoded['error'] as Map<String, dynamic>;
        final em = errMap['message'] as String?;
        if (em != null && em.trim().isNotEmpty) {
          return _stripKeyMaterial(em.trim());
        }
      }
      final topMessage = decoded['message'] as String?;
      if (topMessage != null && topMessage.trim().isNotEmpty) {
        return _stripKeyMaterial(topMessage.trim());
      }
      if (detail != null && detail.isNotEmpty) return detail;
      if (title != null && title.isNotEmpty) return title;
    } on FormatException {
      return null;
    }
    return null;
  }

  /// Masks `sk_…` / `pk_…` segments in user-facing error text (keys may appear in API messages).
  static String _stripKeyMaterial(String s) {
    return s
        .replaceAllMapped(
          RegExp(r'sk_(live|test)_[A-Za-z0-9_]{8,}'),
          (_) => 'sk_…',
        )
        .replaceAllMapped(
          RegExp(r'pk_(live|test)_[A-Za-z0-9_]{8,}'),
          (_) => 'pk_…',
        );
  }

  static void ensureSuccess(
    http.Response response, {
    bool allow201 = false,
  }) {
    final ok = <int>{200};
    if (allow201) ok.add(201);
    if (ok.contains(response.statusCode)) return;

    if (response.statusCode == 401) {
      SessionController.instance.handleUnauthorized();
    }

    final parsed = parseUserFacingMessage(response.body);
    final message = parsed ??
        (response.statusCode == 401
            ? 'Your session has expired. Please sign in again.'
            : 'Request failed (${response.statusCode}).');

    throw ApiException(
      response.statusCode,
      response.body,
      userMessage: message,
    );
  }
}
