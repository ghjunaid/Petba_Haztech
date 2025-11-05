<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class VetController
{
    
    public function listVets(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|integer',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'locationSort' => 'nullable|boolean',
            'rateSort' => 'nullable|boolean',
            'alphaSort' => 'nullable|boolean',
            'city_id' => 'nullable|integer',
            'filter' => 'nullable|array',
            'offset' => 'nullable|integer',
        ]);

        $filters = $data['filter'] ?? null;
        $offset = $data['offset'] ?? 0;

        $query = DB::table('vets')
            ->select(
                'vets.name as clinic',
                'vets.city',
                'vets.latitude',
                'vets.longitude',
                'vets.phoneNumber',
                'vets.fee',
                'vets.id',
                'vets.rating',
                'vets.open_time',
                'vets.close_time',
                'vet_doctors.img',
                'vet_doctors.name as doctor'
            )
            ->leftjoin('vet_doctors', 'vets.doc_id', '=', 'vet_doctors.id');

        // Apply filters if present
        if ($filters && isset($data['city_id']) && $data['city_id']) {
            $query->leftjoin('vets_to_filter', 'vets_to_filter.vet_id', '=', 'vets.id')
                ->whereIn('vets_to_filter.filter_id', $filters)
                ->where('vets.city_id', $data['city_id']);
        } elseif ($filters) {
            $query->leftjoin('vets_to_filter', 'vets_to_filter.vet_id', '=', 'vets.id')
                ->whereIn('vets_to_filter.filter_id', $filters);
        } elseif (isset($data['city_id']) && $data['city_id']) {
            $query->where('vets.city_id', $data['city_id']);
        }

        // Sorting logic
        if (!empty($data['locationSort']) && $data['latitude'] && $data['longitude']) {
            $lat = $data['latitude'];
            $lng = $data['longitude'];

            $query->selectRaw("
                vets.*,
                vet_doctors.img,
                vet_doctors.name as doctor,
                (6371 * acos(
                    cos(radians(?)) * cos(radians(vets.latitude)) *
                    cos(radians(vets.longitude) - radians(?)) +
                    sin(radians(?)) * sin(radians(vets.latitude))
                )) AS Distance
            ", [$lat, $lng, $lat])
            ->orderBy('Distance', 'ASC');
        } elseif (!empty($data['rateSort'])) {
            $query->orderBy('rating', 'DESC');
        } elseif (!empty($data['alphaSort'])) {
            $query->orderBy('clinic', 'ASC');
        }

        // Pagination: limit 6, offset from request
        $vets = $query->distinct()->limit(6)->offset($offset)->get();

        return response()->json(['listvets' => $vets]);
    }


   public function loadVetDetails(Request $request)
    {
        $data = $request->validate([
            'id' => 'required|integer',
        ]);

        $id = $data['id'];

        try {
            // Fetch vet details
            $vetDetails = DB::table('vets')
                ->leftjoin('vet_doctors', 'vets.doc_id', '=', 'vet_doctors.id')
                ->select(
                    'vets.*',
                    'vet_doctors.name as doctor',
                    'vet_doctors.img as doc_img',
                    'vet_doctors.gender',
                    'vet_doctors.qualification',
                    'vet_doctors.experience',
                    'vet_doctors.about'
                )
                ->where('vets.id', $id)
                ->first();

            // Fetch vet reviews
            $vetReviews = DB::table('vet_reviews')
                ->where('vet_id', $id)
                ->limit(2)
                ->get();

            // Fetch vet timing
            $vetTiming = DB::table('vet_timming')
                ->where('vet_id', $id)
                ->first();

            // Fetch filters (updated join)
            $filters = DB::table('vetfilters as a')
    ->leftJoin('vets_to_filter as b', 'a.filter_id', '=', 'b.filter_id')
    ->where('b.vet_id', '=', 1)
    ->select('a.*')
    ->get();

                

            // Fetch filter groups
            $filterGroups = DB::table('vetfiltergroup')->get();

            return response()->json([
                'Vet' => $vetDetails,
                'reviews' => $vetReviews,
                'time' => $vetTiming,
                'filters' => $filters,
                'filterGroup' => $filterGroups,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function sendVetReview(Request $request)
    {
        $data = $request->validate([
            'id' => 'required|integer',
            'type' => 'required|in:1,2,3,4,5', // Only allow valid types
            'name' => 'required|string|max:255',
            'rating' => 'required|numeric|min:1|max:5',
            'review' => 'required|string',
            'time' => 'required|string|max:50',
        ]);

        try {
            $id = $data['id'];
            $type = $data['type'];
            $name = $data['name'];
            $rating = $data['rating'];
            $review = $data['review'];
            $time = $data['time'];

            $tables = [
                '1' => ['table' => 'vet_reviews', 'foreign_key' => 'vet_id', 'target_table' => 'vets'],
                '2' => ['table' => 'shelter_reviews', 'foreign_key' => 'shelter_id', 'target_table' => 'shelter'],
                '3' => ['table' => 'grooming_reviews', 'foreign_key' => 'grooming_id', 'target_table' => 'grooming'],
                '4' => ['table' => 'trainer_reviews', 'foreign_key' => 'trainer_id', 'target_table' => 'trainer'],
                '5' => ['table' => 'foster_reviews', 'foreign_key' => 'foster_id', 'target_table' => 'foster'],
            ];

            $config = $tables[$type];

            // Insert review
            DB::table($config['table'])->insert([
                'name' => $name,
                'rating' => $rating,
                'review' => $review,
                $config['foreign_key'] => $id,
                'time' => $time,
            ]);

            // Recalculate average rating
            $average = DB::table($config['table'])
                ->where($config['foreign_key'], $id)
                ->avg('rating');

            // Update average rating in main table
            DB::table($config['target_table'])
                ->where('id', $id)
                ->update(['rating' => round($average, 1)]);

            return response()->json(['message' => 'Review added successfully.', 'rating' => round($average, 1)]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }
}
