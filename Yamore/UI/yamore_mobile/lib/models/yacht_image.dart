class YachtImageModel {
  final int yachtImageId;
  final int yachtId;
  final String contentType;
  final String? fileName;
  final bool isThumbnail;
  final int sortOrder;

  YachtImageModel({
    required this.yachtImageId,
    required this.yachtId,
    required this.contentType,
    this.fileName,
    required this.isThumbnail,
    required this.sortOrder,
  });

  factory YachtImageModel.fromJson(Map<String, dynamic> json) {
    int readInt(String camel, String pascal) {
      final v = json[camel] ?? json[pascal];
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }
    String? readString(String camel, String pascal) =>
        json[camel] as String? ?? json[pascal] as String?;
    final isThumb = json['isThumbnail'] as bool? ?? json['IsThumbnail'] as bool? ?? false;
    final order = (json['sortOrder'] as num?)?.toInt() ?? (json['SortOrder'] as num?)?.toInt() ?? 0;
    return YachtImageModel(
      yachtImageId: readInt('yachtImageId', 'YachtImageId'),
      yachtId: readInt('yachtId', 'YachtId'),
      contentType: readString('contentType', 'ContentType') ?? 'image/jpeg',
      fileName: readString('fileName', 'FileName'),
      isThumbnail: isThumb,
      sortOrder: order,
    );
  }
}
