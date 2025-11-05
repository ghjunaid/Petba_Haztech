class AdoptionPet {
  final int adoptId;
  final int cId;
  final String name;
  final int gender; // 1 = Male, 2 = Female
  final String dob;
  final String img1;
  final String city;
  final String animalName;
  final String breed;
  final String note;

  AdoptionPet({
    required this.adoptId,
    required this.cId,
    required this.name,
    required this.gender,
    required this.dob,
    required this.img1,
    required this.city,
    required this.animalName,
    required this.breed,
    required this.note,
  });

  factory AdoptionPet.fromJson(Map<String, dynamic> json) {
    return AdoptionPet(
      adoptId: json['adopt_id'] ?? 0,
      cId: json['c_id'] ?? 0,
      name: json['name'] ?? '',
      gender: json['gender'] ?? 1,
      dob: json['dob'] ?? '',
      img1: json['img1'] ?? '',
      city: json['city'] ?? '',
      animalName: json['animalName'] ?? '',
      breed: json['breed'] ?? '',
      note: json['note'] ?? '',
    );
  }
}
