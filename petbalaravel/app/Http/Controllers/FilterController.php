<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Customer;
use App\Models\FilterGroup;
use App\Models\FilterDescription;
use App\Models\ProductOptionValue;
use Illuminate\Support\Facades\DB;

class FilterController
{
   public function filter(Request $request)
    {
        $data = $request->json()->all();
        $userData = $data['userData'];

        $id = $userData['customer_id'];
        $email = $userData['email'];
        $token = $userData['token'];
        $cate_id = $userData['cate_id'];

        $user = Customer::where('email', $email)->first();

        if ($user && $user->token === $token && $user->customer_id === $id) {
            // Get all product IDs for the given category
            $productIds = DB::table('oc_product_to_category')
                ->where('category_id', $cate_id)
                ->pluck('product_id');

            // Get all filter IDs for those products
            $filterIds = DB::table('oc_product_filter')
                ->whereIn('product_id', $productIds)
                ->pluck('filter_id');

            // Get all filter group IDs associated with those filter IDs
            $filterGroupIds = DB::table('oc_filter_description')
                ->whereIn('filter_id', $filterIds)
                ->pluck('filter_group_id');

            // Fetch filter groups
            $filterGroups = FilterGroup::whereIn('filter_group_id', $filterGroupIds)->get();

            // Attach filters to each group
            foreach ($filterGroups as $group) {
                $group->filters = FilterDescription::where('filter_group_id', $group->filter_group_id)
                    ->whereIn('filter_id', $filterIds)
                    ->get();
            }

            // Optional options for filtering (if you have this implemented)
            $options = $this->optionfrfiltr($cate_id);

            return response()->json([
                'filter' => $filterGroups,
                'option' => $options,
            ]);
        }

        return response()->json(['error' => 'Unauthorized'], 401);
    }



    private function optionfrfiltr($input)
    {
        $filterListArray = [];

        try {
            // Step 1: Get distinct option groups
            $optionGroups = DB::table('oc_product_option_value')
                ->join('oc_option_description', 'oc_product_option_value.option_id', '=', 'oc_option_description.option_id')
                ->select('oc_product_option_value.option_id', 'oc_option_description.name as o_name')
                ->whereIn('oc_product_option_value.product_id', function ($query) use ($input) {
                    $query->select('product_id')
                        ->from('oc_product_to_category')
                        ->where('category_id', $input);
                })
                ->groupBy('oc_product_option_value.option_id', 'oc_option_description.name')
                ->get();

            // Step 2: For each option group, get its filter values
            foreach ($optionGroups as $group) {
                $filters = DB::table('oc_product_option_value')
                    ->join('oc_option_value_description', 'oc_product_option_value.option_value_id', '=', 'oc_option_value_description.option_value_id')
                    ->select('oc_product_option_value.option_value_id', 'oc_option_value_description.name')
                    ->whereIn('oc_product_option_value.product_id', function ($query) use ($input) {
                        $query->select('product_id')
                            ->from('oc_product_to_category')
                            ->where('category_id', $input);
                    })
                    ->where('oc_product_option_value.option_id', $group->option_id)
                    ->groupBy('oc_product_option_value.option_value_id', 'oc_option_value_description.name')
                    ->get();

                $group->filters = $filters;
                $filterListArray[] = $group;
            }

            return $filterListArray;
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function adoptionFilter() {
        try {
            // Get data from adoptionfilter table
            $adoptionFilters = DB::table('adoptionfilter')
                                 ->select('id', 'name')
                                 ->get();
    
            return response()->json(['adoptionFilter' => $adoptionFilters]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }
    
    public function getFilters(Request $request)
    {
        $validated = $request->validate([
            'type' => 'required|in:1,2,3,4,5'
        ]);

        $type = $validated['type'];

        try {
            $filterGroup = collect();
            $filters = collect();

            switch ($type) {
                case '1':
                    $filterGroup = DB::table('vetfiltergroup')->get();
                    $filters = DB::table('vetfilters')->get();
                    break;
                case '2':
                    $filterGroup = DB::table('shelterfiltergroup')->get();
                    $filters = DB::table('shelterfilters')->get();
                    break;
                case '3':
                    $filterGroup = DB::table('groomingfiltergroup')->get();
                    $filters = DB::table('groomingfilters')->get();
                    break;
                case '4':
                    $filterGroup = DB::table('trainerfiltergroup')->get();
                    $filters = DB::table('trainerfilters')->get();
                    break;
                case '5':
                    $filterGroup = DB::table('fosterfiltergroup')->get();
                    $filters = DB::table('fosterfilters')->get();
                    break;
            }

            return response()->json([
                'FilterGroup' => $filterGroup,
                'Filters' => $filters
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    
    public function rescueFilter()
    {
        try {
            // Get unique cities from rescue pets
            $cities = DB::table('rescuepet')
                ->join('cities', 'rescuepet.city_id', '=', 'cities.city_id')
                ->select('rescuepet.city_id', 'cities.city')
                ->distinct()
                ->get();

            // Get pet conditions
            $petConditions = DB::table('petCondition')
                ->select('id', 'name')
                ->get();

            // Get animal types
            $animalTypes = DB::table('animal')
                ->select('animal_id', 'name')
                ->get();

            return response()->json([
                'condition' => $petConditions,
                'city' => $cities,
                'animal_type' => $animalTypes
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => ['text' => $e->getMessage()]
            ], 500);
        }
    }

    
    public function rescueFilters() {
        try {
            // Get distinct cities associated with rescue pets
            $cities = DB::table('rescuepet as a')
                        ->join('cities as b', 'a.city_id', '=', 'b.city_id')
                        ->select('a.city_id as id', 'b.city as name')
                        ->distinct()
                        ->get();
    
            // Get pet conditions
            $petConditions = DB::table('petCondition')->select('id', 'name')->get();
    
            // Get animal types
            $animalTypes = DB::table('animal')->select('animal_id as id', 'name')->get();
    
            return response()->json([
                'condition' => $petConditions,
                'city' => $cities,
                'animalType' => $animalTypes,
                'gender' => [
                    ['id' => '1', 'name' => 'Male'],
                    ['id' => '2', 'name' => 'Female']
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function getOptions(Request $request)
    {
        $c_id = $request->input('c_id');

        try {
            // animal list (you were binding c_id, but not using it in SQL – removed the unused bind)
            $animalList = DB::table('animal')
                ->select('animal_id', 'name')
                ->get();

            // colors list
            $colorList = DB::table('colors')
                ->select('id', 'color')
                ->orderBy('color', 'asc')
                ->get();

            // breed list
            $breedList = DB::table('breed')
                ->orderBy('name', 'asc')
                ->get();

            return response()->json([
                'animalbreed' => $animalList,
                'color' => $colorList,
                'breed' => $breedList
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'getOptions failed',
                'message' => $e->getMessage()
            ], 500);
        }
    }

}
