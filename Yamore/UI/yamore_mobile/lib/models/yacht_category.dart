class YachtCategoryModel {
  final int categoryId;
  final String name;

  YachtCategoryModel({
    required this.categoryId,
    required this.name,
  });

  factory YachtCategoryModel.fromJson(Map<String, dynamic> json) {
    return YachtCategoryModel(
      categoryId: json['categoryId'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

