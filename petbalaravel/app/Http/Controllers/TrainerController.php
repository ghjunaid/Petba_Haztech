<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TrainerController
{
    public function loadTrainingDetails(Request $request)
    {
        $data = $request->validate([
            'id' => 'required|integer'
        ]);
        $id = $data['id'];

        try {
            // Trainer main details
            $trainerDetails = DB::table('trainer as a')
                ->leftjoin('trainers as b', 'a.trainer_id', '=', 'b.id')
                ->leftjoin('cities as c', 'a.city_id', '=', 'c.city_id')
                ->where('a.id', $id)
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
                    'b.name as trainer',
                    'b.gender',
                    'b.details',
                    'b.experience',
                    'b.about',
                    'b.img as trainer_img',
                    'c.city'
                )
                ->first();

            // Get review count separately
            $reviewCount = DB::table('trainer_reviews')
                ->where('trainer_id', $id)
                ->count();

            // Get latest 2 reviews
            $reviews = DB::table('trainer_reviews')
                ->where('trainer_id', $id)
                ->latest('id')
                ->limit(2)
                ->get();

            // Filters associated with the trainer (fix: filter_name was wrong, changed to name)
            $filters = DB::table('trainerfilters as a')
                ->leftjoin('trainer_to_filter as b', 'a.filter_id', '=', 'b.filter_id')
                ->where('b.trainer_id', $id)
                ->select('a.filter_id', 'a.name as filter_name', 'b.trainer_id')
                ->get();

            // Filter groups
            $filterGroups = DB::table('trainerfiltergroup')->get();

            return response()->json([
                'trainerDetails' => $trainerDetails,
                'reviewCount' => $reviewCount,
                'reviews' => $reviews,
                'filters' => $filters,
                'filterGroup' => $filterGroups,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function listTrainer(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $c_id = $data['c_id'] ?? null;
        $latitude = $data['latitude'] ?? null;
        $longitude = $data['longitude'] ?? null;
        $lastPet = $data['offset'] ?? 0;

        $locationSort = $data['locationSort'] ?? false;
        $rateSort = $data['rateSort'] ?? false;
        $alphaSort = $data['alphaSort'] ?? false;
        $city_id = $data['city_id'] ?? null;
        $filter = $data['filter'] ?? [];

        try {
            $query = DB::table('trainer as a')
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
                    'b.name as trainer',
                    'b.details',
                    'c.city',
                    DB::raw("(((radians(acos(sin(radians(?)) * sin(radians(a.latitude)) + cos(radians(?)) * cos(radians(a.latitude)) * cos(radians(? - a.longitude))))) * 60 * 1.1515) * 1.609344) AS Distance")
                )
                ->leftjoin('trainers as b', 'a.trainer_id', '=', 'b.id')
                ->leftjoin('cities as c', 'a.city_id', '=', 'c.city_id')
                ->setBindings([$latitude, $latitude, $longitude])
                ->distinct();

            // Apply filter joins and conditions
            if (!empty($filter)) {
                $query->leftjoin('trainer_to_filter as tf', 'tf.trainer_id', '=', 'a.id')
                    ->whereIn('tf.filter_id', $filter);
            }

            if ($city_id) {
                $query->where('a.city_id', $city_id);
            }

            // Apply sorting
            if ($locationSort) {
                $query->orderBy('Distance', 'asc');
            } elseif ($rateSort) {
                $query->orderBy('a.rating', 'desc');
            } elseif ($alphaSort) {
                $query->orderBy('a.name', 'asc');
            }

            // Pagination / offset and limit
            $query->offset($lastPet)->limit(6);

            $res = $query->get();

            return response()->json(['listtrainer' => $res]);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


}
