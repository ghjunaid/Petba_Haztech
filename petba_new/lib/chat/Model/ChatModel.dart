class PetModel {
  final int id;
  final String name;
  final String breed;
  final int age;
  final String gender;
  final String description;
  final String imageUrl;
  final int ownerId;
  final String ownerName;
  final bool isAvailableForAdoption;
  final String petType; // dog, cat, bird, etc.
  final List<String> vaccinations;
  final String location;
  final DateTime createdAt;

  PetModel({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.description,
    required this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.isAvailableForAdoption,
    required this.petType,
    this.vaccinations = const [],
    required this.location,
    required this.createdAt,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'],
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      gender: json['gender'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      ownerId: json['ownerId'],
      ownerName: json['ownerName'],
      isAvailableForAdoption: json['isAvailableForAdoption'],
      petType: json['petType'],
      vaccinations: List<String>.from(json['vaccinations'] ?? []),
      location: json['location'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
      'gender': gender,
      'description': description,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'isAvailableForAdoption': isAvailableForAdoption,
      'petType': petType,
      'vaccinations': vaccinations,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final String location;
  final List<PetModel> pets;
  final String profileImageUrl;
  final DateTime createdAt;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.location,
    this.pets = const [],
    required this.profileImageUrl,
    required this.createdAt,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      location: json['location'],
      pets: (json['pets'] as List?)?.map((pet) => PetModel.fromJson(pet)).toList() ?? [],
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'location': location,
      'pets': pets.map((pet) => pet.toJson()).toList(),
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}