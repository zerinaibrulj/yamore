import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_exception.dart';

/// Parses `errors.userError` from a JSON ProblemDetails-style API body (HTTP 400).
String? userErrorMessageFromApiBody(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    final errors = decoded['errors'];
    if (errors is! Map<String, dynamic>) return null;
    final userError = errors['userError'];
    if (userError is List && userError.isNotEmpty) {
      final first = userError.first;
      if (first is String && first.isNotEmpty) return first;
    }
  } catch (_) {}
  return null;
}

/// Same contract as admin service deletes: prefer API `userError`, then FK/constraint hints, then [fallbackLinkedData].
Future<void> showDeleteBlockedDialog({
  required BuildContext context,
  required String dialogTitle,
  required String itemDisplayName,
  required ApiException e,
  required String fallbackLinkedData,
}) async {
  final apiMessage = userErrorMessageFromApiBody(e.body);
  final lower = e.body.toLowerCase();
  final isLikelyInUse = e.statusCode == 500 ||
      e.statusCode == 409 ||
      lower.contains('constraint') ||
      lower.contains('reference') ||
      lower.contains('foreign') ||
      lower.contains('yacht') ||
      lower.contains('reservation') ||
      lower.contains('user') ||
      lower.contains('review');

  String message;
  if (e.statusCode == 400 && apiMessage != null && apiMessage.isNotEmpty) {
    message = apiMessage;
  } else if (e.statusCode == 404) {
    message = '“$itemDisplayName” no longer exists or was already removed.';
  } else if (isLikelyInUse) {
    message = fallbackLinkedData;
  } else {
    message = 'The item could not be deleted. Please try again in a moment.';
  }

  if (!context.mounted) return;
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
}
