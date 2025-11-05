<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GroomingController
{
    public function loadGroomingDetails(Request $request)
    {
        // Validate request input
        $data = $request->validate([
            'id' => 'required|integer',
        ]);
        $id = $data['id'];

        try {
            // Fetch grooming main details along with groomer info and count of reviews
            $groomingDetails = DB::table('grooming as a')
                ->select(
                    'a.name',
                    'a.img1',
                    'a.img2',
                    'a.img3',
                    'a.img4',
                    'a.address',
                    'a.description',
                    'a.d_description',
                    'a.open_time',
                    'a.close_time',
                    'a.rating',
                    'a.fee',
                    'a.phoneNumber',
                    'a.longitude',
                    'a.latitude',
                    'b.name as groomer',
                    'b.gender',
                    'b.details',
                    'b.experience',
                    'b.about',
                    'b.img as groomer_img',
                    'c.city',
                    // Subquery to count grooming reviews for this grooming id
                    DB::raw("(SELECT COUNT(*) FROM grooming_reviews WHERE grooming_id = {$id}) as review_count")
                )
                ->leftjoin('groomers as b', 'a.groomer_id', '=', 'b.id')
                ->leftjoin('cities as c', 'a.city_id', '=', 'c.city_id')
                ->where('a.id', $id)
                ->first();

            // Fetch latest 2 reviews for this grooming id
            $reviews = DB::table('grooming_reviews')
                ->where('grooming_id', $id)
                ->latest('id')
                ->limit(2)
                ->get();

            // Fetch filters linked to this grooming id
            $filters = DB::table('groomingfilters as a')
                ->leftjoin('grooming_to_filter as b', 'a.filter_id', '=', 'b.filter_id')
                ->where('b.grooming_id', $id)
                ->select('a.name')
                ->get();

            // Fetch all filter groups
            $filterGroups = DB::table('groomingfiltergroup')->get();

            return response()->json([
                'groomingDetails' => $groomingDetails,
                'reviews' => $reviews,
                'filters' => $filters,
                'filterGroups' => $filterGroups,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function loadReviews(Request $request)
    {
        // Validate input
        $data = $request->validate([
            'id' => 'required|integer',
            'type' => 'required|in:1,2,3,4,5',
            'offset' => 'nullable|integer|min:0',
        ]);

        $id = $data['id'];
        $type = $data['type'];
        $offset = $data['offset'] ?? 0;

        // Map types to tables and foreign keys
        $reviewTables = [
            '1' => ['table' => 'vet_reviews', 'foreign_key' => 'vet_id'],
            '2' => ['table' => 'trainer_reviews', 'foreign_key' => 'trainer_id'],
            '3' => ['table' => 'grooming_reviews', 'foreign_key' => 'grooming_id'],
            '4' => ['table' => 'shelter_reviews', 'foreign_key' => 'shelter_id'],
            '5' => ['table' => 'foster_reviews', 'foreign_key' => 'foster_id'],
        ];

        try {
            if (!isset($reviewTables[$type])) {
                return response()->json(['error' => ['text' => 'Invalid review type']], 400);
            }

            $table = $reviewTables[$type]['table'];
            $foreignKey = $reviewTables[$type]['foreign_key'];

            $reviews = DB::table($table)
                ->where($foreignKey, $id)
                ->orderBy('time', 'DESC')
                ->limit(10)
                ->offset($offset)
                ->get();

            return response()->json(['reviews' => $reviews]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function listGrooming(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|integer',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'offset' => 'nullable|integer',
            'locationSort' => 'nullable|boolean',
            'rateSort' => 'nullable|boolean',
            'alphaSort' => 'nullable|boolean',
            'city_id' => 'nullable|integer',
            'filter' => 'nullable|array',
        ]);

        $latitude = $data['latitude'];
        $longitude = $data['longitude'];
        $offset = $data['offset'] ?? 0;
        $locationSort = $data['locationSort'] ?? false;
        $rateSort = $data['rateSort'] ?? false;
        $alphaSort = $data['alphaSort'] ?? false;
        $city_id = $data['city_id'] ?? null;
        $filter = $data['filter'] ?? [];

        $query = DB::table('grooming as a')
            ->select(
                'a.id',
                'a.name',
                'b.img',
                'a.phoneNumber',
                'a.latitude',
                'a.longitude',
                'a.fee',
                'a.rating',
                'a.open_time',
                'a.close_time',
                'b.gender',
                'b.name as groomer',
                'b.details',
                'c.city'
            )
            ->leftjoin('groomers as b', 'a.groomer_id', '=', 'b.id')
            ->leftjoin('cities as c', 'a.city_id', '=', 'c.city_id');

        // Apply filters if present
        if ($filter && $city_id) {
            $query->leftJoin('grooming_to_filter', 'grooming_to_filter.grooming_id', '=', 'a.id')
                ->whereIn('grooming_to_filter.filter_id', $filter)
                ->where('a.city_id', $city_id);
        } elseif ($filter) {
            $query->leftJoin('grooming_to_filter', 'grooming_to_filter.grooming_id', '=', 'a.id')
                ->whereIn('grooming_to_filter.filter_id', $filter);
        } elseif ($city_id) {
            $query->where('a.city_id', $city_id);
        }

        // Sorting logic
        if ($locationSort) {
            $query->selectRaw("
                a.*,
                b.img,
                b.gender,
                b.name as groomer,
                b.details,
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
            // Default sorting by distance
            $query->selectRaw("
                a.*,
                b.img,
                b.gender,
                b.name as groomer,
                b.details,
                c.city,
                (6371 * acos(
                    cos(radians(?)) * cos(radians(a.latitude)) *
                    cos(radians(a.longitude) - radians(?)) +
                    sin(radians(?)) * sin(radians(a.latitude))
                )) AS Distance
            ", [$latitude, $longitude, $latitude])
            ->orderBy('Distance', 'ASC');
        }

        $query->offset($offset)->limit(6);

        $results = $query->get();

        return response()->json(['listgrooming' => $results]);
    }

}
