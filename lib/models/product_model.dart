class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final String vendorId;
  final String vendorName;
  final int stock;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.vendorId,
    required this.vendorName,
    this.stock = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      stock: map['stock'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'stock': stock,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
