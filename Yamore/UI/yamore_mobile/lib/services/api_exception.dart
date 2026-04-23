class ApiException implements Exception {
  final int statusCode;
  final String body;
  final String? userMessage;

  ApiException(this.statusCode, this.body, {this.userMessage});

  String get displayMessage => userMessage ?? body;

  @override
  String toString() => 'ApiException: $statusCode ${userMessage ?? body}';
}
