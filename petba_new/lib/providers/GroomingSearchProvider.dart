import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:petba_new/models/Places.dart';
import 'package:petba_new/providers/Config.dart';
import '../../services/google_places_service.dart';

class GroomingSearchProvider extends ChangeNotifier {
  GroomingSearchProvider() {
    // fetchGroomingData();
  }

  List<Places> groomerData = [];
  List<String> phone = [];
  bool isLoading = true;

  Future<void> fetchGroomingData() async {
    isLoading = true;
    notifyListeners();
    groomerData = [];
    phone = [];

    try {
      // Getting the data from the Google Places Api
      final searchResults = await GooglePlacesService.searchNearbyPlaces(
        lat: 15.2832,
        lng: 73.9862,
        radius: 2000,
        type: 'pet_store',
        keyword: 'Groomers',
      );

      // Process each search result (removed duplicate loop)
      for (var element in searchResults) {
        final location = element.geometry?.location;
        if (location == null) continue;

        String addressString = await getLocation(location.lat, location.lng);
        final placeDetails = await GooglePlacesService.getPlaceDetails(element.placeId);

        final place = Places(
          id: element.id ?? '',
          placeId: element.placeId,
          name: element.name ?? 'Un Named',
          lat: location.lat,
          lng: location.lng,
          photo: element.photos != null && element.photos!.isNotEmpty
              ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${element.photos![0].photoReference}&key=$googleMapsApiKey'
              : 'https://i.stack.imgur.com/y9DpT.jpg',
          address: addressString,
          formattedAddress: placeDetails.result.formattedAddress ?? '',
          timings: placeDetails.result.openingHours?.openNow == true ? 'Open' : 'Closed',
          phone: placeDetails.result.formattedPhoneNumber ??
              placeDetails.result.internationalPhoneNumber ?? '',
        );
        groomerData.add(place);
      }
    } catch (e) {
      print('Error fetching grooming data: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<String> getLocation(double lat, double lng) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      final place = placemarks.first;
      return "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
    } catch (e) {
      return "Address not available";
    }
  }

  void loadNextGroomerData() {
    // Function to load the next 6 set of Groomer Data
  }
}