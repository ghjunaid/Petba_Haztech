<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CityController
{
    private const DEFAULT_COUNTRY = 'India';

    public function loadCities(Request $request)
    {
        $data = $request->validate([
            'offset' => 'required|integer|min:0',
            'district' => 'required|string|max:100',
        ]);

        $offset = $data['offset'];
        $district = $data['district'];

        try {
            $cities = DB::table('cities')
                ->where('district', $district)
                ->orderBy('city', 'asc')
                ->offset($offset)
                ->limit(300)
                ->get(['city_id', 'city']);

            return response()->json(['searchitems' => $cities]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    // ✅ Load distinct states with pagination (from `cities` table, not rescue_states)
    public function loadState(Request $request)
    {
        $data = $request->validate([
            'offset' => 'required|integer|min:0',
        ]);

        $offset = $data['offset'];

        try {
            $states = DB::table('cities')
                ->select('state')
                ->groupBy('state')
                ->offset($offset)
                ->limit(15)
                ->get();

            // ✅ Debugging output


            return response()->json(['searchitems' => $states]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    // Load cities by state code (still uses rescue_cities table for backward compatibility)
    public function loadCity(Request $request)
    {
        $data = $request->validate([
            'state_code' => 'required|string|max:10', // Adjust max length as per your DB schema
        ]);

        $state_code = $data['state_code'];

        try {
            $cities = DB::table('rescue_cities')
                ->where('state_code', $state_code)
                ->get(['id', 'city_name']);

            return response()->json(['loadcity' => $cities]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function loadMyCity(Request $request)
    {
        $customer_id = $request->input('c_id');

        try {
            $preferences = DB::table('rescue_customer_preference as r')
                ->leftjoin('rescue_cities as c', 'r.city_id', '=', 'c.id')
                ->leftjoin('rescue_states as s', 's.state_code', '=', 'c.state_code')
                ->where('r.customer_id', $customer_id)
                ->select(
                    'r.rcp_id',
                    'r.city_id',
                    'c.city_name',
                    DB::raw('RIGHT(s.state_name, 4) AS state')
                )
                ->get();

            return response()->json(['loadmycity' => $preferences]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    // ✅ Load distinct districts by state
    public function loadDistrict(Request $request)
    {
        $offset = $request->input('offset', 0); // Default to 0 if not provided
        $state = $request->input('state');

        try {
            $districts = DB::table('cities')
                ->where('state', $state)
                ->select('district')
                ->distinct()
                ->orderBy('district', 'asc')
                ->offset($offset)
                ->limit(20)
                ->pluck('district');

            return response()->json(['searchitems' => $districts]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    // Keep this rescue_states loader intact
    public function loadStates(Request $request)
    {
        try {
            $states = DB::table('rescue_states')->get();

            return response()->json(['loadstates' => $states]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function searchCity(Request $request)
    {
        $offset = $request->input('off', 0); // Default to 0 if not provided
        $search = $request->input('search');

        try {
            if ($search) {
                $searchTerm = $search . '%';

                $cities = DB::table('cities')
                    ->select('city', 'district', 'state', 'city_id')
                    ->where('city', 'LIKE', $searchTerm)
                    ->orderBy('city', 'asc')
                    ->limit(20)
                    ->offset($offset)
                    ->get();

                return response()->json(['searchitems' => $cities]);
            } else {
                return response()->json(['error' => 'Search term is missing'], 400);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function addCitiesLink(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|string',
            'city' => 'required|array',
            'flag' => 'required|string'
        ]);

        $c_id = $data['c_id'];
        $cities = $data['city'];
        $flag = $data['flag'];

        try {
            foreach ($cities as $cityId) {
                // Check if entry already exists
                $exists = DB::table('rescue_customer_preference')
                    ->where('customer_id', $c_id)
                    ->where('city_id', $cityId)
                    ->exists();

                if (!$exists) {
                    DB::table('rescue_customer_preference')->insert([
                        'customer_id' => $c_id,
                        'city_id' => $cityId,
                        'name' => '',
                        'latitude' => 0.0,
                        'longitude' => 0.0
                    ]);
                }
            }

            // Update notification flag for the customer
            DB::table('oc_customer')->where('customer_id', $c_id)->update(['notification_flag' => $flag]);

            return response()->json(['Success' => "Linked cities for c_id=$c_id with flag=$flag"]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function deleteCity(Request $request)
    {
        $data = $request->validate([
            'id' => 'required|string',
        ]);

        $id = $data['id'];

        try {
            // Delete the city from rescue_customer_preference
            $deleted = DB::table('rescue_customer_preference')->where('rcp_id', $id)->delete();

            if ($deleted) {
                return response()->json(['deletecity' => 'Delete Success']);
            } else {
                return response()->json(['deletecity' => 'No record found to delete'], 404);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    /**
     * Fetch states and top cities for a given country.
     */
    public function fetchStatesByCountry(Request $request)
{
    $validated = $request->validate([
        'country' => 'required|string|max:100',
    ]);

    if (strtolower($validated['country']) !== 'india') {
        return response()->json(['error' => 'Country not supported'], 422);
    }

    // Fetch only states belonging to India (country_id = 99)
    $states = DB::table('oc_zone')
        ->select('zone_id', 'name as state_name')
        ->where('country_id', 99)
        ->where('status', 1)
        ->orderBy('name', 'ASC')
        ->get();

    return response()->json([
        'country' => 'India',
        'states'  => $states,
    ]);
}



}
