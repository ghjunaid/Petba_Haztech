# TODO: Modify featuredProducts function in DashboardController

## Tasks
- [x] Modify `featuredProducts` function in `petbalaravel/app/Http/Controllers/DashboardController.php`
  - [x] Remove `Request $request` parameter from function signature
  - [x] Remove code getting product IDs from request input
  - [x] Add DB query to `oc_module` table where `code = 'featured'`
  - [x] Decode JSON setting and extract 'product' array
  - [x] Use extracted product IDs in `whereIn('p.product_id', $ids)`
  - [x] Add error handling for missing module or empty product IDs
  - [x] Update call in dashboard method to remove $request parameter

## Followup steps
- [x] Test the dashboard API to ensure featured products load correctly
- [ ] Verify frontend displays featured products properly
