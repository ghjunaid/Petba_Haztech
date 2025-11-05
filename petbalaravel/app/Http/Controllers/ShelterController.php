<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ShelterController
{
public function shelterList(Request $request)
{
    $data = $request->json()->all();
    $c_id = $data['c_id'];
    $tab = $data['tab'];
    $lastPet = $data['offset'] ?? 0;
    $latitude = $data['latitude'];
    $longitude = $data['longitude'];
    $locationSort = $data['locationSort'] ?? false;
    $rateSort = $data['rateSort'] ?? false;
    $alphaSort = $data['alphaSort'] ?? false;
    $city_id = $data['city_id'] ?? null;
    $filters = $data['filter'] ?? [];

    try {
        if ($tab == 'a') {
            $query = DB::table('shelter as a')
                ->select(
                    'a.id',
                    'a.name',
                    'a.img1',
                    'a.phoneNumber',
                    'a.latitude',
                    'a.longitude',
                    'a.fee',
                    'a.rating',
                    'a.open_time',
                    'a.close_time',
                    'a.owner',
                    'c.city'
                )
                ->join('cities as c', 'a.city_id', '=', 'c.city_id');

            // Apply filters if present
            if ($filters && $city_id) {
                $query->leftJoin('shelter_to_filter', 'shelter_to_filter.shelter_id', '=', 'a.id')
                    ->whereIn('shelter_to_filter.filter_id', $filters)
                    ->where('a.city_id', $city_id);
            } elseif ($filters) {
                $query->leftJoin('shelter_to_filter', 'shelter_to_filter.shelter_id', '=', 'a.id')
                    ->whereIn('shelter_to_filter.filter_id', $filters);
            } elseif ($city_id) {
                $query->where('a.city_id', $city_id);
            }

            // Sorting logic
            if ($locationSort) {
                $query->selectRaw("
                    a.*,
                    c.city,
                    (6371 * acos(
                        cos(radians(?)) * cos(radians(a.latitude)) *
                        cos(radians(a.longitude) - radians(?)) +
                        sin(radians(?)) * sin(radians(a.latitude))
                    )) AS Distance
                ", [$latitude, $longitude, $latitude])
                ->orderBy('Distance', 'ASC');
            } elseif ($rateSort) {
                $query->orderBy('a.rating', 'DESC');
            } elseif ($alphaSort) {
                $query->orderBy('a.name', 'ASC');
            } else {
                // Default sorting by distance if locationSort is not set but we need distance
                $query->selectRaw("
                    a.*,
                    c.city,
                    (6371 * acos(
                        cos(radians(?)) * cos(radians(a.latitude)) *
                        cos(radians(a.longitude) - radians(?)) +
                        sin(radians(?)) * sin(radians(a.latitude))
                    )) AS Distance
                ", [$latitude, $longitude, $latitude])
                ->orderBy('Distance', 'ASC');
            }

            // Pagination: limit 6, offset from request
            $shelters = $query->distinct()->limit(6)->offset($lastPet)->get();

            return response()->json(['shelterlist' => $shelters]);
        }
        elseif ($tab == 'b') {
            // Your existing code for tab b (no change)
            $limit = 6;

            $sql = "SELECT id, name, img1 as img, address, paid, phoneNumber, verified,
                    (((RADIANS(ACOS(SIN(RADIANS(?)) * SIN(RADIANS(latitude)) + COS(RADIANS(?)) * COS(RADIANS(latitude)) * COS(RADIANS(? - longitude))))) * 60 * 1.1515) * 1.609344) AS Distance
                    FROM shelter
                    WHERE c_id = ?
                    ORDER BY Distance ASC
                    LIMIT $limit OFFSET ?";

            $bindings = [$latitude, $latitude, $longitude, $c_id, $lastPet];

            $shelters = DB::select($sql, $bindings);

            return response()->json(['myShelter' => $shelters]);
        }
    } catch (\PDOException $e) {
        return response()->json(['error' => ['text' => $e->getMessage()]]);
    }
}



    public function shelterDetails(Request $request)
    {
        $data = $request->validate([
            'id' => 'required|integer',
        ]);

        $id = $data['id'];

        try {
            // Get shelter details with review count using a subquery in select
            $shelter = DB::table('shelter as a')
                ->select(
                    'a.*',
                    'c.city',
                    DB::raw("(SELECT COUNT(*) FROM shelter_reviews WHERE shelter_id = {$id}) as review_count")
                )
                ->where('a.id', $id)
                ->leftjoin('cities as c', 'a.city_id', '=', 'c.city_id')
                ->first();

            // Get latest 2 reviews for the shelter
            $reviews = DB::table('shelter_reviews')
                ->where('shelter_id', $id)
                ->orderBy('time', 'DESC')
                ->limit(2)
                ->get();

            // Get all filters linked to this shelter
            $filters = DB::table('shelterfilters as f')
                ->join('shelter_to_filter as sf', 'f.filter_id', '=', 'sf.filter_id')
                ->where('sf.shelter_id', $id)
                ->select('f.*')
                ->get();

            // Get all filter groups (independent)
            $filterGroups = DB::table('shelterfiltergroup')->get();

            return response()->json([
                'shelterDetails' => $shelter,
                'reviews' => $reviews,
                'filters' => $filters,
                'filterGroups' => $filterGroups,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function addShelter(Request $request)
{
    $data = $request->validate([
        'c_id' => 'required|integer',
        'name' => 'required|string',
        'address' => 'required|string',
        'latitude' => 'required|numeric',
        'longitude' => 'required|numeric',
        'description' => 'nullable|string',
        'paid' => 'required|boolean',
        'acceptlimit' => 'nullable|integer',
        'phoneNumber' => 'nullable|string',
        'owner' => 'required|string',   // ✅ added validation for owner
        'img1' => 'nullable|string',
        'img2' => 'nullable|string',
        'img3' => 'nullable|string',
        'img4' => 'nullable|string',
    ]);

    $imageArray = [
        1 => $data['img1'] ?? null,
        2 => $data['img2'] ?? null,
        3 => $data['img3'] ?? null,
        4 => $data['img4'] ?? null,
    ];

    try {
        // Prepare the shelter data (including owner now ✅)
        $shelterData = [
            'c_id' => $data['c_id'],
            'name' => $data['name'],
            'address' => $data['address'],
            'paid' => $data['paid'],
            'phoneNumber' => $data['phoneNumber'] ?? null,
            'latitude' => $data['latitude'],
            'longitude' => $data['longitude'],
            'acceptlimit' => $data['acceptlimit'] ?? null,
            'description' => $data['description'] ?? null,
            'owner' => $data['owner'],   // ✅ include owner in insert
        ];

        // Insert shelter data and get the new ID
        $shelterId = DB::table('shelter')->insertGetId($shelterData);

        // Process and save images if provided
        $imgUpdates = [];
        foreach ($imageArray as $index => $imageData) {
            if ($imageData) {
                // Remove base64 prefix and decode
                $cleanedImage = preg_replace('/^data:image\/\w+;base64,/', '', $imageData);
                $decodedImage = base64_decode($cleanedImage);

                // Build a unique file path
                $fileName = 'shelter_Pet_' . $data['c_id'] . '_' . $index . '_' . time() . '.jpg';
                $targetPath = 'adoptionImage/' . $fileName;

                // Save the image file using Laravel Storage
                Storage::put($targetPath, $decodedImage);

                // Prepare image URL for DB update
                $imgUpdates['img' . $index] = '/petbaopencart/api/' . $targetPath;
            }
        }

        // Update the shelter record with image URLs if any images were saved
        if (!empty($imgUpdates)) {
            DB::table('shelter')->where('id', $shelterId)->update($imgUpdates);
        }

        return response()->json(['addShelter' => [
            'success' => true,
            'id' => $shelterId,
            'data' => $data
        ]]);
    } catch (\Exception $e) {
        return response()->json(['error' => ['text' => $e->getMessage()]], 500);
    }
}


}