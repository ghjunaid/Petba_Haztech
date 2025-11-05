class DashboardProduct {
  final int productId;
  final String model;
  final String name;
  final String description;
  final int quantity;
  final String image;
  final String price;
  final String? specialprice;
  final String? discount;
  final String category;
  final String brand;

  DashboardProduct({
    required this.productId,
    required this.model,
    required this.name,
    required this.description,
    required this.quantity,
    required this.image,
    required this.price,
    this.specialprice,
    this.discount,
    required this.category,
    required this.brand,
  });

  factory DashboardProduct.fromJson(Map<String, dynamic> json) {
    return DashboardProduct(
      productId: json['product_id'] ?? 0,
      model: json['model'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      image: json['image'] ?? '',
      price: json['price'] ?? '0',
      specialprice: json['specialprice'],
      discount: json['discount'],
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
    );
  }
}

class BannerItem {
  final int id;
  final int flag;
  final int productId;
  final String imgLink;

  BannerItem({
    required this.id,
    required this.flag,
    required this.productId,
    required this.imgLink,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] ?? 0,
      flag: json['flag'] ?? 0,
      productId: json['product_id'] ?? 0,
      imgLink: json['imgLink'] ?? '',
    );
  }
}

class RescuePet {
  final int id;
  final String img1;
  final String address;
  final String conditionType;
  final int conditionStatus;
  final int gender;
  final double distance;

  RescuePet({
    required this.id,
    required this.img1,
    required this.address,
    required this.conditionType,
    required this.conditionStatus,
    required this.gender,
    required this.distance,
  });

  factory RescuePet.fromJson(Map<String, dynamic> json) {
    return RescuePet(
      id: json['id'] ?? 0,
      img1: json['img1'] ?? '',
      address: json['address'] ?? '',
      conditionType:
          json['conditionType'] ?? json['ConditionType'] ?? 'Minor Injury',
      conditionStatus: json['conditionStatus'] ?? 1,
      gender: json['gender'] ?? 1,
      distance: (json['Distance'] ?? 0).toDouble(),
    );
  }
}
