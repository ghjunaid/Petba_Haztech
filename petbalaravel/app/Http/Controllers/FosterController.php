<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FosterController
{
    public function fosterdetails(Request $request)
    {
        // Validate request input
        $data = $request->validate([
            'id' => 'required|integer',
        ]);
        $id = $data['id'];

        try {
            // Fetch foster main details along with foster caretaker info and count of reviews
            $fosterDetails = DB::table('foster as a')
                ->select(
                    'a.name',
                    'a.img1',
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
                    'a.acceptlimit',
                    'a.verified',
                    'a.paid',
                    'b.name as foster',
                    'b.gender',
                    'b.details',
                    'b.experience',
                    'b.about',
                    'b.img as foster_img',
                    'c.city',
                    // Subquery to count foster reviews for this foster id
                    DB::raw("(SELECT COUNT(*) FROM foster_reviews WHERE foster_id = {$id}) as review_count")
                )
                ->leftjoin('fosters as b', 'a.foster_id', '=', 'b.id')
                ->leftjoin('cities as c', 'a.city_id', '=', 'c.city_id')
                ->where('a.id', $id)
                ->first();

            // Fetch latest 2 reviews for this foster id
            $reviews = DB::table('foster_reviews')
                ->where('foster_id', $id)
                ->latest('id')
                ->limit(2)
                ->get();

            // Fetch filters linked to this foster id
            $filters = DB::table('fosterfilters as a')
                ->leftjoin('foster_to_filter as b', 'a.filter_id', '=', 'b.filter_id')
                ->where('b.foster_id', $id)
                ->select('a.name')
                ->get();

            // Fetch all filter groups
            $filterGroups = DB::table('fosterfiltergroup')->get();

            return response()->json([
                'fosterDetails' => $fosterDetails,
                'reviews' => $reviews,
                'filters' => $filters,
                'filterGroups' => $filterGroups,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function fosterList(Request $request)
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

        $query = DB::table('foster as a')
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
                'a.acceptlimit',
                'a.verified',
                'a.paid',
                'b.gender',
                'b.name as foster',
                'b.details',
                'c.city'
            )
            ->leftjoin('fosters as b', 'a.foster_id', '=', 'b.id')
            ->leftjoin('cities as c', 'a.city_id', '=', 'c.city_id');

        // Apply filters if present
        if ($filter && $city_id) {
            $query->leftJoin('foster_to_filter', 'foster_to_filter.foster_id', '=', 'a.id')
                ->whereIn('foster_to_filter.filter_id', $filter)
                ->where('a.city_id', $city_id);
        } elseif ($filter) {
            $query->leftJoin('foster_to_filter', 'foster_to_filter.foster_id', '=', 'a.id')
                ->whereIn('foster_to_filter.filter_id', $filter);
        } elseif ($city_id) {
            $query->where('a.city_id', $city_id);
        }

        // Sorting logic
        if ($locationSort) {
            $query->selectRaw("
                a.*,
                b.img,
                b.gender,
                b.name as foster,
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
                b.name as foster,
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

        return response()->json(['fosterlist' => $results]);
    }

}

