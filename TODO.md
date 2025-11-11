# TODO: Fix LocationProvider to save city_id when selecting city

## Pending Tasks
- [ ] Modify LocationProvider.dart to change onLocationSelected callback to include cityId (Function(String, int?))
- [ ] Update LocationPickerBottomSheet to pass cityId when selecting a city
- [ ] Save city_id in UserDataService when selecting a city
- [ ] Update HomePage.dart to accept the new callback signature (ignore cityId in the callback)
- [ ] Test the changes to ensure rescue pets update correctly when changing location via LocationProvider
