class YachtDocument {
  final int yachtDocumentId;
  final int yachtId;
  final String? yachtName;
  final String documentType;
  final String verificationStatus;
  final String? contentType;
  final String? fileName;
  final DateTime? dateUploaded;
  final String? rejectionReason;

  YachtDocument({
    required this.yachtDocumentId,
    required this.yachtId,
    this.yachtName,
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

  /// Parses API timestamps (stored as UTC, often without a `Z` suffix).
  static DateTime? parseApiDateTime(dynamic raw) {
    if (raw == null) return null;
    final t = raw.toString().trim();
    if (t.isEmpty) return null;
    if (t.endsWith('Z')) {
      return DateTime.tryParse(t)?.toUtc();
    }
    if (RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(t)) {
      return DateTime.tryParse(t)?.toUtc();
    }
    if (t.contains('T') && t.length > 10) {
      final asUtc = DateTime.tryParse('${t}Z');
      if (asUtc != null) return asUtc.toUtc();
    }
    final parsed = DateTime.tryParse(t);
    if (parsed == null) return null;
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  /// Formats an API upload time for display in local time (`DD.MM.YYYY. HH:mm`).
  static String formatUploadedLocal(DateTime? value) {
    if (value == null) return '—';
    final utc = value.isUtc
        ? value
        : DateTime.utc(
            value.year,
            value.month,
            value.day,
            value.hour,
            value.minute,
            value.second,
            value.millisecond,
            value.microsecond,
          );
    final local = utc.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year;
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy. $hh:$min';
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
      yachtName: _v(json, 'yachtName')?.toString() ??
          _v(json, 'YachtName')?.toString(),
      documentType: _v(json, 'documentType')?.toString() ?? '',
      verificationStatus:
          _v(json, 'verificationStatus')?.toString() ?? 'Pending',
      contentType: _v(json, 'contentType')?.toString(),
      fileName: _v(json, 'fileName')?.toString(),
      dateUploaded: parseApiDateTime(uploaded),
      rejectionReason: _v(json, 'rejectionReason')?.toString(),
    );
  }
}
