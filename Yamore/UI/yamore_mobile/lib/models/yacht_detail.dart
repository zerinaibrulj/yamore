class YachtDetail {
  final int? yachtId;
  int? ownerId;
  String name;
  String? description;
  int yearBuilt;
  double length;
  int capacity;
  int cabins;
  int? bathrooms;
  double pricePerDay;
  int locationId;
  int categoryId;
  bool? isActive;

  YachtDetail({
    this.yachtId,
    this.ownerId,
    required this.name,
    this.description,
    required this.yearBuilt,
    required this.length,
    required this.capacity,
    required this.cabins,
    this.bathrooms,
    required this.pricePerDay,
    required this.locationId,
    required this.categoryId,
    this.isActive,
  });

  factory YachtDetail.fromJson(Map<String, dynamic> json) {
    return YachtDetail(
      yachtId: json['yachtId'] as int?,
      ownerId: json['ownerId'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      yearBuilt: json['yearBuilt'] as int? ?? 0,
      length: (json['length'] as num?)?.toDouble() ?? 0,
      capacity: json['capacity'] as int? ?? 0,
      cabins: json['cabins'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int?,
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0,
      locationId: json['locationId'] as int? ?? 0,
      categoryId: json['categoryId'] as int? ?? 0,
      isActive: json['isActive'] as bool?,
    );
  }

  Map<String, dynamic> toJsonForSave() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'yearBuilt': yearBuilt,
      'length': length,
      'capacity': capacity,
      'cabins': cabins,
      'bathrooms': bathrooms,
      'pricePerDay': pricePerDay,
      'locationId': locationId,
      'categoryId': categoryId,
      'isActive': isActive ?? true,
    };
  }
}

