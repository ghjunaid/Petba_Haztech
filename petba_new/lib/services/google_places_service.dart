// services/google_places_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:petba_new/providers/Config.dart';

// These classes replace the google_maps_webservice classes
class PlaceGeometry {
  final PlaceLocation location;
  PlaceGeometry({required this.location});

  factory PlaceGeometry.fromJson(Map<String, dynamic> json) {
    return PlaceGeometry(
      location: PlaceLocation.fromJson(json['location']),
    );
  }
}

class PlaceLocation {
  final double lat;
  final double lng;
  PlaceLocation({required this.lat, required this.lng});

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      lat: json['lat']?.toDouble() ?? 0.0,
      lng: json['lng']?.toDouble() ?? 0.0,
    );
  }
}

class PlacePhoto {
  final String photoReference;
  PlacePhoto({required this.photoReference});

  factory PlacePhoto.fromJson(Map<String, dynamic> json) {
    return PlacePhoto(photoReference: json['photo_reference'] ?? '');
  }
}

class PlacesSearchResult {
  final String? id;
  final String placeId;
  final String? name;
  final PlaceGeometry? geometry;
  final List<PlacePhoto>? photos;
  final String? vicinity;

  PlacesSearchResult({
    this.id,
    required this.placeId,
    this.name,
    this.geometry,
    this.photos,
    this.vicinity,
  });

  factory PlacesSearchResult.fromJson(Map<String, dynamic> json) {
    return PlacesSearchResult(
      id: json['id'],
      placeId: json['place_id'] ?? '',
      name: json['name'],
      vicinity: json['vicinity'],
      geometry: json['geometry'] != null
          ? PlaceGeometry.fromJson(json['geometry'])
          : null,
      photos: json['photos'] != null
          ? (json['photos'] as List)
          .map((photo) => PlacePhoto.fromJson(photo))
          .toList()
          : null,
    );
  }
}

class PlaceOpeningHours {
  final bool? openNow;
  final List<String>? weekdayText;

  PlaceOpeningHours({this.openNow, this.weekdayText});

  factory PlaceOpeningHours.fromJson(Map<String, dynamic> json) {
    return PlaceOpeningHours(
      openNow: json['open_now'],
      weekdayText: json['weekday_text'] != null
          ? List<String>.from(json['weekday_text'])
          : null,
    );
  }
}

class PlaceDetailsResult {
  final String? formattedAddress;
  final String? internationalPhoneNumber;
  final String? formattedPhoneNumber;
  final PlaceOpeningHours? openingHours;

  PlaceDetailsResult({
    this.formattedAddress,
    this.internationalPhoneNumber,
    this.formattedPhoneNumber,
    this.openingHours,
  });

  factory PlaceDetailsResult.fromJson(Map<String, dynamic> json) {
    return PlaceDetailsResult(
      formattedAddress: json['formatted_address'],
      internationalPhoneNumber: json['international_phone_number'],
      formattedPhoneNumber: json['formatted_phone_number'],
      openingHours: json['opening_hours'] != null
          ? PlaceOpeningHours.fromJson(json['opening_hours'])
          : null,
    );
  }
}

class PlacesDetailsResponse {
  final PlaceDetailsResult result;
  PlacesDetailsResponse({required this.result});

  factory PlacesDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PlacesDetailsResponse(
      result: PlaceDetailsResult.fromJson(json['result']),
    );
  }
}

// Service class for Google Places API calls
class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  static Future<List<PlacesSearchResult>> searchPlaces(String query) async {
    final url = '$_baseUrl/textsearch/json?query=$query&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results
              .map((result) => PlacesSearchResult.fromJson(result))
              .toList();
        } else {
          throw Exception('API Error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching places: $e');
    }
  }

  static Future<List<PlacesSearchResult>> searchNearbyPlaces({
    required double lat,
    required double lng,
    required int radius,
    String? type,
    String? keyword,
  }) async {
    String url = '$_baseUrl/nearbysearch/json?location=$lat,$lng&radius=$radius&key=$googleMapsApiKey';

    if (type != null) {
      url += '&type=$type';
    }
    if (keyword != null) {
      url += '&keyword=$keyword';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results
              .map((result) => PlacesSearchResult.fromJson(result))
              .toList();
        } else {
          throw Exception('API Error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to search nearby places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching nearby places: $e');
    }
  }

  static Future<PlacesDetailsResponse> getPlaceDetails(String placeId) async {
    final url = '$_baseUrl/details/json?place_id=$placeId&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlacesDetailsResponse.fromJson(data);
        } else {
          throw Exception('API Error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to get place details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting place details: $e');
    }
  }
}