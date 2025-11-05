class ServiceModel {
  final int id;
  final String name;
  final String provider;
  final int rating;
  final String time;
  final String price;
  final String location;
  final String imageUrl;
  final String? phoneNumber;
  final String? address;
  final bool isPaid;
  final bool isVerified;
  final String? clinic;
  final String? doctor;
  final String? owner;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final double? fee;

  ServiceModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.rating,
    required this.time,
    required this.price,
    required this.location,
    required this.imageUrl,
    this.phoneNumber,
    this.address,
    this.isPaid = false,
    this.isVerified = false,
    this.clinic,
    this.doctor,
    this.owner,
    this.latitude,
    this.longitude,
    this.distance,
    this.fee,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json, int serviceType) {
    switch (serviceType) {
      case 1: // Vet
        return ServiceModel(
          id: json['id'] ?? 0,
          name: json['clinic'] ?? 'Unknown Clinic',
          provider: json['doctor'] ?? 'Unknown Doctor',
          rating: json['rating'] ?? 4,
          time:
              '${json['open_time'] ?? '08:00 AM'} - ${json['close_time'] ?? '10:00 PM'}',
          price: '₹${json['fee'] ?? 600}',
          location: json['city'] ?? 'Unknown Location',
          imageUrl: json['img']?.isNotEmpty == true
              ? json['img']
              : 'images/default_vet.jpg',
          phoneNumber: json['phoneNumber'],
          clinic: json['clinic'],
          doctor: json['doctor'],
          latitude: json['latitude']?.toDouble(),
          longitude: json['longitude']?.toDouble(),
          fee: json['fee']?.toDouble(),
        );

      case 2: // Shelter
        return ServiceModel(
          id: json['id'] ?? 0,
          name: json['name'] ?? 'Unknown Shelter',
          provider: json['owner'] ?? 'Unknown Owner',
          rating: json['rating'] ?? 3,
          time:
              '${json['open_time'] ?? '07:30 AM'} - ${json['close_time'] ?? '05:00 PM'}',
          price: '₹${json['fee'] ?? 1200}',
          location: json['city'] ?? 'Unknown Location',
          imageUrl: json['img1']?.isNotEmpty == true
              ? json['img1']
              : 'images/default_shelter.jpg',
          phoneNumber: json['phoneNumber'],
          owner: json['owner'],
          latitude: json['latitude']?.toDouble(),
          longitude: json['longitude']?.toDouble(),
          distance: json['Distance']?.toDouble(),
          fee: json['fee']?.toDouble(),
        );

      case 3: // Groomer
        return ServiceModel(
          id: json['id'] ?? 0,
          name: json['name'] ?? 'Unknown Groomer',
          provider: json['groomer'] ?? json['provider'] ?? 'Unknown Provider',
          rating: (json['rating'] ?? 4).toInt(),
          time:
              '${json['open_time'] ?? '09:00 AM'}-${json['close_time'] ?? '06:00 PM'}',
          price: '₹${json['fee'] ?? json['price'] ?? 800}.00',
          location: json['city'] ?? json['location'] ?? 'Unknown Location',
          imageUrl: json['img']?.isNotEmpty == true
              ? json['img']
              : 'images/default.jpg',
          phoneNumber: json['phone'] ?? json['phoneNumber'],
          address: json['address'] ?? json['full_address'],
        );

      case 4: // Trainer
        return ServiceModel(
          id: json['id'] ?? 0,
          name: json['name'] ?? 'Unknown Trainer',
          provider: json['trainer'] ?? 'Unknown Provider',
          rating: (json['rating'] ?? 4).toInt(),
          time:
              '${json['open_time'] ?? '09:00 AM'}-${json['close_time'] ?? '06:00 PM'}',
          price: '₹${json['fee'] ?? 800}.00',
          location: json['city'] ?? 'Unknown Location',
          imageUrl: json['img']?.isNotEmpty == true
              ? json['img']
              : 'images/default.jpg',
          phoneNumber: json['phone'] ?? json['phoneNumber'],
          address: json['address'] ?? json['full_address'],
        );

      case 5: // Foster
        return ServiceModel(
          id: json['id'] ?? 0,
          name: json['name'] ?? 'Unknown Foster Home',
          provider: json['foster'] ?? 'Unknown Foster',
          rating: (json['rating'] ?? 4).toInt(),
          time:
              '${json['open_time'] ?? '09:00 AM'} - ${json['close_time'] ?? '06:00 PM'}',
          price: '₹${json['fee'] ?? 0}',
          location: json['city'] ?? 'Unknown Location',
          imageUrl: json['img']?.isNotEmpty == true
              ? json['img']
              : 'images/default.jpg',
          phoneNumber: json['phoneNumber'],
          address: json['address'],
          latitude: json['latitude']?.toDouble(),
          longitude: json['longitude']?.toDouble(),
          distance: json['Distance']?.toDouble(),
          fee: json['fee']?.toDouble(),
          isPaid: (json['paid'] ?? 0) == 1,
          isVerified: (json['verified'] ?? 0) == 1,
        );

      default:
        throw Exception('Invalid service type');
    }
  }
}

class ServiceDetailsModel {
  final int id;
  final String name;
  final String provider;
  final int rating;
  final String time;
  final String price;
  final String location;
  final String imageUrl;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? description;
  final String? experience;
  final String? about;
  final String? details;
  final String? gender;
  final String? qualification;
  final String? doctor;
  final String? owner;
  final String? doctorImage;
  final String? doctorDescription;
  final int reviewCount;
  final List<String> services;
  final List<String> additionalImages;
  final List<Review> reviews;
  final bool isPaid;
  final bool isVerified;

  ServiceDetailsModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.rating,
    required this.time,
    required this.price,
    required this.location,
    required this.imageUrl,
    this.phoneNumber,
    this.email,
    this.address,
    this.description,
    this.experience,
    this.about,
    this.details,
    this.gender,
    this.qualification,
    this.doctor,
    this.owner,
    this.doctorImage,
    this.doctorDescription,
    this.reviewCount = 0,
    this.services = const [],
    this.additionalImages = const [],
    this.reviews = const [],
    this.isPaid = false,
    this.isVerified = false,
  });

  factory ServiceDetailsModel.fromJson(
    Map<String, dynamic> json,
    int serviceType,
  ) {
    switch (serviceType) {
      case 1: // Vet
        final vetData = json['Vet'] ?? json;
        final reviewsData = json['reviews'] ?? [];

        List<Review> reviewsList = [];
        for (var review in reviewsData) {
          reviewsList.add(Review.fromJson(review));
        }

        List<String> images = [];
        ['img1', 'img2', 'img3', 'img4'].forEach((key) {
          if (vetData[key] != null && vetData[key].toString().isNotEmpty) {
            images.add(vetData[key].toString());
          }
        });

        return ServiceDetailsModel(
          id: vetData['id'] ?? 0,
          name: vetData['name'] ?? 'Unknown Clinic',
          provider: vetData['doctor'] ?? 'Unknown Doctor',
          rating: (vetData['rating'] ?? 4).toInt(),
          time:
              '${vetData['open_time'] ?? '09:00 AM'} - ${vetData['close_time'] ?? '06:00 PM'}',
          price: '₹${vetData['fee'] ?? 600}.00',
          location: vetData['city'] ?? 'Unknown Location',
          imageUrl: vetData['img1']?.isNotEmpty == true
              ? vetData['img1']
              : 'images/default.jpg',
          phoneNumber: vetData['phoneNumber'],
          address: vetData['address'],
          description: vetData['description'],
          experience: vetData['experience'],
          about: vetData['about'],
          details: vetData['details'],
          doctor: vetData['doctor'],
          doctorImage: vetData['doc_img'],
          doctorDescription: vetData['d_description'],
          qualification: vetData['qualification'],
          gender: vetData['gender']?.toString(),
          reviewCount: reviewsList.length,
          reviews: reviewsList,
          additionalImages: images,
        );

      case 2: // Shelter
      final shelterData = json['shelterDetails'] ?? json;
        return ServiceDetailsModel(
          id: shelterData['id'] ?? 0,
          name: shelterData['name'] ?? 'Unknown Shelter',
          provider: shelterData['owner'] ?? 'Unknown Owner',
          rating: (shelterData['rating'] ?? 3).toInt(),
          time:
              '${shelterData['open_time'] ?? '07:30 AM'} - ${shelterData['close_time'] ?? '05:00 PM'}',
          price: '₹${shelterData['fee'] ?? 1200}.00',
          location: shelterData['city'] ?? 'Unknown Location',
          imageUrl: shelterData['img1']?.isNotEmpty == true
              ? shelterData['img1']
              : 'images/default.jpg',
          phoneNumber: shelterData['phoneNumber'],
          address: shelterData['address'],
          description: shelterData['description'],
          about: shelterData['about'],
          owner: shelterData['owner'],
        );

      case 3: // Groomer
        final groomerData = json['groomingDetails'] ?? json;

        List<String> servicesList = [];
        if (groomerData['services'] != null) {
          if (groomerData['services'] is String) {
            servicesList = groomerData['services']
                .split(',')
                .map((s) => s.trim())
                .toList();
          } else if (groomerData['services'] is List) {
            servicesList = List<String>.from(groomerData['services']);
          }
        }

        List<String> images = [];
        ['img1', 'img2', 'img3', 'img4'].forEach((key) {
          if (groomerData[key] != null &&
              groomerData[key].toString().isNotEmpty) {
            images.add(groomerData[key].toString());
          }
        });

        return ServiceDetailsModel(
          id: groomerData['id'] ?? 0,
          name: groomerData['name'] ?? 'Unknown Groomer',
          provider:
              groomerData['groomer'] ??
              groomerData['provider'] ??
              'Unknown Provider',
          rating: (groomerData['rating'] ?? 4).toInt(),
          time:
              '${groomerData['open_time'] ?? '09:00 AM'} - ${groomerData['close_time'] ?? '06:00 PM'}',
          price: '₹${groomerData['fee'] ?? groomerData['price'] ?? 800}.00',
          location:
              groomerData['city'] ??
              groomerData['location'] ??
              'Unknown Location',
          imageUrl: groomerData['groomer_img']?.isNotEmpty == true
              ? groomerData['groomer_img']
              : (groomerData['img']?.isNotEmpty == true
                    ? groomerData['img']
                    : 'images/default.jpg'),
          phoneNumber: groomerData['phone'] ?? groomerData['phoneNumber'],
          email: groomerData['email'],
          address: groomerData['address'] ?? groomerData['full_address'],
          description: groomerData['description'],
          experience: groomerData['experience'],
          about: groomerData['about'],
          details: groomerData['details'],
          gender: groomerData['gender']?.toString(),
          reviewCount: groomerData['review_count'] ?? 0,
          services: servicesList,
          additionalImages: images,
        );

      case 4: // Trainer
        final trainerData = json['trainerDetails'] ?? json;
        return ServiceDetailsModel(
          id: trainerData['id'] ?? 0,
          name: trainerData['name'] ?? 'Unknown Trainer',
          provider: trainerData['trainer'] ?? 'Unknown Provider',
          rating: (trainerData['rating'] ?? 4).toInt(),
          time:
              '${trainerData['open_time'] ?? '09:00 AM'} - ${trainerData['close_time'] ?? '06:00 PM'}',
          price: '₹${trainerData['fee'] ?? 800}.00',
          location: trainerData['city'] ?? 'Unknown Location',
          imageUrl: trainerData['img']?.isNotEmpty == true
              ? trainerData['img']
              : 'images/default.jpg',
          phoneNumber: trainerData['phone'] ?? trainerData['phoneNumber'],
          address: trainerData['address'] ?? trainerData['full_address'],
          description: trainerData['description'],
          experience: trainerData['experience'],
          about: trainerData['about'],
        );

      case 5: // Foster
        final fosterData = json['fosterDetails'] ?? json;
        final reviewsData = json['reviews'] ?? [];

        List<Review> reviewsList = [];
        for (var review in reviewsData) {
          reviewsList.add(Review.fromJson(review));
        }

        List<String> images = [];
        ['img1', 'img2', 'img3', 'img4'].forEach((key) {
          if (fosterData[key] != null && fosterData[key].toString().isNotEmpty) {
            images.add(fosterData[key].toString());
          }
        });

        List<String> servicesList = [];
        if (json['filters'] != null) {
          if (json['filters'] is List) {
            servicesList = (json['filters'] as List)
                .map((f) => f['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList();
          }
        }

        return ServiceDetailsModel(
          id: fosterData['id'] ?? 0,
          name: fosterData['name'] ?? 'Unknown Foster Home',
          provider: fosterData['foster'] ?? 'Unknown Foster',
          rating: (fosterData['rating'] ?? 4).toInt(),
          time:
              '${fosterData['open_time'] ?? '09:00 AM'} - ${fosterData['close_time'] ?? '06:00 PM'}',
          price: '₹${fosterData['fee'] ?? 0}',
          location: fosterData['city'] ?? 'Unknown Location',
          imageUrl: fosterData['foster_img']?.isNotEmpty == true
              ? fosterData['foster_img']
              : (fosterData['img1']?.isNotEmpty == true
                    ? fosterData['img1']
                    : 'images/default.jpg'),
          phoneNumber: fosterData['phoneNumber'],
          address: fosterData['address'],
          description: fosterData['description'],
          experience: fosterData['experience'],
          about: fosterData['about'],
          details: fosterData['details'],
          gender: fosterData['gender']?.toString(),
          reviewCount: fosterData['review_count'] ?? reviewsList.length,
          reviews: reviewsList,
          additionalImages: images,
          services: servicesList,
          isPaid: (fosterData['paid'] ?? 0) == 1,
          isVerified: (fosterData['verified'] ?? 0) == 1,
        );

      default:
        throw Exception('Invalid service type');
    }
  }
}

class Review {
  final int id;
  final String name;
  final int rating;
  final String review;
  final String time;

  Review({
    required this.id,
    required this.name,
    required this.rating,
    required this.review,
    required this.time,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Anonymous',
      rating: json['rating'] ?? 5,
      review: json['review'] ?? '',
      time: json['time'] ?? '',
    );
  }
}
