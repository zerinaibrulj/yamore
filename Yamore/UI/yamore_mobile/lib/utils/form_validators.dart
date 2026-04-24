/// Server-aligned validation copy for user-facing forms (Yamore API + FluentValidation).
class FormValidators {
  FormValidators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phone = RegExp(r'^\+?[0-9\s\-()]{7,20}$');
  static final RegExp _username = RegExp(r'^[a-zA-Z0-9._-]{3,32}$');

  /// [trimmed] is already trimmed. Null error means valid.
  static String? firstNameError(String trimmed) {
    if (trimmed.isEmpty) {
      return 'First name is required (2–50 characters).';
    }
    if (trimmed.length < 2) {
      return 'First name must be at least 2 characters (max 50).';
    }
    if (trimmed.length > 50) {
      return 'First name must be at most 50 characters.';
    }
    return null;
  }

  static String? lastNameError(String trimmed) {
    if (trimmed.isEmpty) {
      return 'Last name is required (2–50 characters).';
    }
    if (trimmed.length < 2) {
      return 'Last name must be at least 2 characters (max 50).';
    }
    if (trimmed.length > 50) {
      return 'Last name must be at most 50 characters.';
    }
    return null;
  }

  /// Empty is allowed (optional field).
  static String? emailError(String trimmed) {
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 100) {
      return 'Email must be at most 100 characters.';
    }
    if (!_email.hasMatch(trimmed)) {
      return 'Enter a valid email (example: name@example.com).';
    }
    return null;
  }

  /// Empty is allowed.
  static String? phoneError(String trimmed) {
    if (trimmed.isEmpty) return null;
    if (!_phone.hasMatch(trimmed)) {
      return 'Enter a valid phone: 7–20 characters; you may use +, spaces, -, ().';
    }
    return null;
  }

  static String? usernameError(String trimmed) {
    if (trimmed.isEmpty) {
      return 'Username is required: 3–32 characters, letters, digits, . _ - only.';
    }
    if (!_username.hasMatch(trimmed)) {
      return 'Username: 3–32 characters, only letters, numbers, . _ - (no spaces).';
    }
    return null;
  }

  /// Empty = valid (no password change). Non-empty = must meet strength rules.
  static String? newPasswordError(String value) {
    if (value.isEmpty) return null;
    if (value.length < 8 || value.length > 128) {
      return 'New password: 8–128 characters, with upper, lower, digit, and special (e.g. !@#).';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'New password must include at least one lowercase letter (a–z).';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'New password must include at least one uppercase letter (A–Z).';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'New password must include at least one digit (0–9).';
    }
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
      return 'New password must include at least one special character (e.g. !@#\$%).';
    }
    return null;
  }

  /// For required password on user creation (empty invalid).
  static String? createPasswordError(String value) {
    if (value.isEmpty) {
      return 'Password is required: 8–128 characters, with upper, lower, digit, and special.';
    }
    return newPasswordError(value);
  }
}
