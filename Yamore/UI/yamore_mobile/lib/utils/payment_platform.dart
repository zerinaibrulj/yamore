import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// True only on **native** iOS/Android — the "mobile app" in the product sense.
/// Excludes: Flutter **web** (any browser) and **Windows / macOS / Linux** desktop targets.
/// Stripe card checkout is only supported there (Stripe SDK + product rule).
bool get isStripeCardPaymentAvailable {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
}

/// Sent on every API request; the server requires `mobile` for Stripe PaymentIntent calls.
String get yamoreClientKindHeaderValue =>
    isStripeCardPaymentAvailable ? 'mobile' : 'other';
