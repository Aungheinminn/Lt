class OpenAiException implements Exception {
  OpenAiException(this.message, {this.code});

  final String message;
  final String? code;

  bool get isAuth =>
      code == 'invalid_api_key' ||
      message.toLowerCase().contains('incorrect api key') ||
      message.toLowerCase().contains('invalid api key');

  @override
  String toString() => message;
}
