class UgreenQrCode {
  final String qrCode;
  final String url;

  const UgreenQrCode({required this.qrCode, required this.url});
}

enum UgreenQrStatus { waiting, scanned, success, expired, rejected, failed }

class UgreenQrPollResult {
  final UgreenQrStatus status;
  final Map<String, dynamic>? linkParams;
  final String? message;
  final int? code;

  const UgreenQrPollResult({
    required this.status,
    this.linkParams,
    this.message,
    this.code,
  });
}
