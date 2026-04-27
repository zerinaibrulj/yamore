import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/api_response_handler.dart';

/// Shows a dialog when delete fails (FK / in use / server error). Never throws.
Future<void> showDeleteBlockedDialog({
  required BuildContext context,
  required String dialogTitle,
  required String itemDisplayName,
  required ApiException e,
  required String fallbackLinkedData,
}) async {
  late String message;
  try {
    message = buildDeleteFailureMessage(
      e: e,
      itemDisplayName: itemDisplayName,
      fallbackLinkedData: fallbackLinkedData,
    );
  } catch (err, stack) {
    debugPrint('buildDeleteFailureMessage failed: $err\n$stack');
    message = fallbackLinkedData;
  }

  if (!context.mounted) return;
  try {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } catch (err, stack) {
    debugPrint('showDeleteBlockedDialog UI failed: $err\n$stack');
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(fallbackLinkedData),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Builds user-facing copy for failed DELETE calls (constraint, 409/500, API messages).
String buildDeleteFailureMessage({
  required ApiException e,
  required String itemDisplayName,
  required String fallbackLinkedData,
}) {
  final status = e.statusCode;
  final body = e.body;
  String bodyLower;
  try {
    bodyLower = body.toLowerCase();
  } catch (_) {
    bodyLower = '';
  }

  String? parsed;
  try {
    parsed = ApiResponseHandler.parseUserFacingMessage(body);
  } catch (_) {
    parsed = null;
  }
  final parsedLower = (parsed ?? '').toLowerCase();

  bool looksLikeReferentialConflict() {
    if (status == 409 || status == 500) return true;
    if (bodyLower.contains('constraint') ||
        bodyLower.contains('reference') ||
        bodyLower.contains('foreign') ||
        bodyLower.contains('conflict')) {
      return true;
    }
    if (parsedLower.contains('constraint') ||
        parsedLower.contains('reference') ||
        parsedLower.contains('foreign') ||
        parsedLower.contains('conflict')) {
      return true;
    }
    return false;
  }

  if (status == 404) {
    return '“$itemDisplayName” no longer exists or was already removed.';
  }

  // Controller returns BusinessException as HTTP 400 + errors.userError — show that text first.
  if ((status == 400 || status == 409) &&
      parsed != null &&
      parsed.trim().isNotEmpty) {
    return parsed.trim();
  }

  if (looksLikeReferentialConflict()) {
    return fallbackLinkedData;
  }

  if (parsed != null && parsed.trim().isNotEmpty) {
    return parsed.trim();
  }

  return 'The item could not be deleted. Please try again in a moment.';
}
