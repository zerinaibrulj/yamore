class YachtDocument {
  final int yachtDocumentId;
  final int yachtId;
  final String documentType;
  final String verificationStatus;
  final String? contentType;
  final String? fileName;
  final DateTime? dateUploaded;
  final String? rejectionReason;

  YachtDocument({
    required this.yachtDocumentId,
    required this.yachtId,
    required this.documentType,
    required this.verificationStatus,
    this.contentType,
    this.fileName,
    this.dateUploaded,
    this.rejectionReason,
  });

  static dynamic _v(Map<String, dynamic> json, String name) {
    final lower = name.toLowerCase();
    for (final k in json.keys) {
      if (k.toLowerCase() == lower) return json[k];
    }
    return null;
  }

  /// Human-readable label for API document type values (e.g. SafetyCertificate).
  static String displayLabelForType(String documentType) {
    switch (documentType) {
      case 'SafetyCertificate':
        return 'Safety Certificate';
      default:
        return documentType;
    }
  }

  factory YachtDocument.fromJson(Map<String, dynamic> json) {
    final uploaded = _v(json, 'dateUploaded');
    return YachtDocument(
      yachtDocumentId:
          (_v(json, 'yachtDocumentId') as num?)?.toInt() ?? 0,
      yachtId: (_v(json, 'yachtId') as num?)?.toInt() ?? 0,
      documentType: _v(json, 'documentType')?.toString() ?? '',
      verificationStatus:
          _v(json, 'verificationStatus')?.toString() ?? 'Pending',
      contentType: _v(json, 'contentType')?.toString(),
      fileName: _v(json, 'fileName')?.toString(),
      dateUploaded: uploaded != null ? DateTime.tryParse(uploaded.toString()) : null,
      rejectionReason: _v(json, 'rejectionReason')?.toString(),
    );
  }
}
