# TODO: Fix LocationProvider to save city_id when selecting city

## Pending Tasks
- [x] Modify LocationProvider.dart to change onLocationSelected callback to include cityId (Function(String, int?))
- [x] Update LocationPickerBottomSheet to pass cityId when selecting a city
- [x] Save city_id in UserDataService when selecting a city
- [x] Update HomePage.dart to accept the new callback signature (ignore cityId in the callback)
- [ ] Test the changes to ensure rescue pets update correctly when changing location via LocationProvider

# TODO: Update Product Image in CartPage.dart

- [x] Edit CartTile widget in petba_new/lib/screens/CartPage.dart to update product image handling with URL processing, encoding, and errorBuilder.
