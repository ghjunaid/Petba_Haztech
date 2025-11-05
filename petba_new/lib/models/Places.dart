import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../services/google_places_service.dart';
import 'package:petba_new/providers/Config.dart';


// Updated Places class
class Places {
  Places({
    required this.id,
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.photo,
    required this.address,
    required this.formattedAddress,
    required this.timings,
    required this.phone,
  });

  String id, placeId, name, photo, address, formattedAddress, phone, timings;
  double lat, lng;

  static Places fromResults(
      PlacesSearchResult result,
      Placemark location,
      PlacesDetailsResponse placeDetails
      ) {
    String baseUrl = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=';
    return Places(
      id: result.id ?? '',
      placeId: result.placeId,
      name: result.name ?? 'Un Named',
      lat: result.geometry?.location.lat ?? 0.0,
      lng: result.geometry?.location.lng ?? 0.0,
      photo: result.photos == null || result.photos!.isEmpty
          ? 'https://i.stack.imgur.com/y9DpT.jpg'
          : baseUrl +
          result.photos![0].photoReference +
          '&key=' +
          googleMapsApiKey,
      address: location.locality ?? '',
      formattedAddress: placeDetails.result.formattedAddress ?? '',
      phone: placeDetails.result.internationalPhoneNumber ??
          placeDetails.result.formattedPhoneNumber ??
          ' ',
      timings: placeDetails.result.openingHours == null
          ? 'Timings Unavailable'
          : placeDetails.result.openingHours?.openNow == true
          ? 'Open'
          : 'Closed',
    );
  }
}