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
    return YachtImageModel(
      yachtImageId: json['yachtImageId'] as int,
      yachtId: json['yachtId'] as int,
      contentType: json['contentType'] as String? ?? 'image/jpeg',
      fileName: json['fileName'] as String?,
      isThumbnail: json['isThumbnail'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
