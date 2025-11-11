<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class RescuePetController
{
    public function updateRemoveRescuePetImage(Request $request)
    {
        $imgNumber = $request->input('imgNumber');
        $rescue_id = $request->input('rescue_id');
        $img = ""; // Since we are removing the image, it's set to an empty string.

        try {
            // Check if imgNumber is provided
            if ($imgNumber) {
                // Dynamically build the column name based on the imgNumber
                $column = 'img' . $imgNumber;

                // Update the corresponding image column with an empty string
                DB::table('rescuepet')
                    ->where('id', $rescue_id)
                    ->update([$column => $img]);

                return response()->json(['Image' => 'Removed in ' . $column]);
            } else {
                return response()->json(['error' => 'imgNumber not provided'], 400);
            }
        } catch (\PDOException $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function addRescueFields()
    {
        try {
            // Fetch all animals from the animal table
            $animals = DB::table('animal')
                ->select('animal_id', 'name')
                ->get();

            // Fetch all pet conditions from the petCondition table
            $petConditions = DB::table('petcondition')
                ->select('id', 'name')
                ->get();

            // Return the combined data as JSON
            return response()->json([
                'condition' => $petConditions,
                'animal_type' => $animals
            ]);
        } catch (\Exception $e) {
            // Return error response in case of exception
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function rescueList(Request $request)
    {
        try {
            $data = $request->json()->all();

            $c_id = $data['c_id'];
            $latitudeSelf = $data['latitude'];
            $longitudeSelf = $data['longitude'];
            $lastPet = $data['lastPet'] ?? null;
            $filter = $data['filter'];
            $sort = $data['sort'] ?? null;

            $limitis = 6;

            $conditions = $filter['condition'] ?? [];
            $animalType = $filter['animalType'] ?? [];
            $gender = $filter['gender'] ?? [];
            $city = $filter['city'] ?? [];

            $query = DB::table('rescuepet AS R')
                ->leftjoin('petcondition AS P', 'R.condition_id', '=', 'P.id')
                ->select(
                    'R.id',
                    'R.city',
                    'R.img1',
                    'R.address',
                    'R.latitude',
                    'R.longitude',
                    'R.conditionLevel_id',
                    'R.status',
                    'R.description',
                    DB::raw("(((radians(acos(sin(radians(?)) * sin(radians(R.latitude)) + cos(radians(?)) * cos(radians(R.latitude)) * cos(radians(? - R.longitude))))) * 60 * 1.1515) * 1.609344) AS Distance"),
                    'P.name as ConditionType',
                    'P.id as PID'
                )
                ->addBinding([$latitudeSelf, $latitudeSelf, $longitudeSelf], 'select');

            // Apply filters
            if (!empty($c_id)) {
                $query->where('R.customer_id', $c_id);
            }

            if (!empty($conditions)) {
                $query->whereIn('R.condition_id', $conditions);
            }

            if (!empty($animalType)) {
                $query->whereIn('R.animal_id', $animalType);
            }

            if (!empty($gender)) {
                $query->whereIn('R.gender', $gender);
            }

            if (!empty($city)) {
                $query->whereIn('R.city_id', $city);
            }

            if (!empty($lastPet)) {
                $query->offset($lastPet);
            }

            if (!empty($sort)) {
                if ($sort == '1') {
                    $query->orderBy('Distance', 'ASC');
                } elseif ($sort == '2') {
                    $query->orderBy('R.date_time', 'DESC');
                }
            }

            // Filter by distance (50km radius)
            $query->having('Distance', '<=', 50);

            $rescueList = $query->limit($limitis)->get();

            return response()->json(['rescueList' => $rescueList]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function addRescuePet(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|string',
            'city' => 'required|string',
            'city_id' => 'required|string',
            'address' => 'required|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'description' => 'required|string',
            'condition_id' => 'required|string',
            'img1' => 'nullable|string',
            'img2' => 'nullable|string',
            'img3' => 'nullable|string',
            'img4' => 'nullable|string',
            'img5' => 'nullable|string',
            'img6' => 'nullable|string',
            'gender' => 'required|string',
            'animalType' => 'required|string',
            'conditionLevel' => 'required|string',
        ]);

        $imageArray = [
            1 => $data['img1'],
            2 => $data['img2'],
            3 => $data['img3'],
            4 => $data['img4'],
            5 => $data['img5'],
            6 => $data['img6'],
        ];

        try {
            DB::beginTransaction();

            $img = [];
            foreach ($imageArray as $x => $value) {
                if ($value) {
                    $filename = 'mypet_rescue_' . $data['c_id'] . '_' . $x . '_' . time() . '.jpg';
                    $imagedata = str_replace(['data:image/jpeg;base64,', 'data:image/jpg;base64,', ' '], '', $value);
                    $imagedata = base64_decode($imagedata);
                    $path = public_path('adoptionImage/' . $filename);
                    if (!file_exists(dirname($path))) {
                        mkdir(dirname($path), 0755, true);
                    }
                    file_put_contents($path, $imagedata);
                    $img[$x] = '/api/adoptionImage/' . $filename;
                } else {
                    $img[$x] = '';
                }
            }

            $petId = DB::table('rescuepet')->insertGetId([
                'condition_id' => $data['condition_id'],
                'conditionLevel_id' => $data['conditionLevel'],
                'animal_id' => $data['animalType'],
                'gender' => $data['gender'],
                'customer_id' => $data['c_id'],
                'city' => $data['city'],
                'city_id' => $data['city_id'],
                'address' => $data['address'],
                'latitude' => $data['latitude'],
                'longitude' => $data['longitude'],
                'description' => $data['description'],
                    'img1' => $img[1] ?? null,
    'img2' => $img[2] ?? null,
    'img3' => $img[3] ?? null,
    'img4' => $img[4] ?? null,
    'img5' => $img[5] ?? null,
    'img6' => $img[6] ?? null,
            ]);

            foreach ($img as $x => $value) {
                if ($value) {
                    DB::table('rescuepet')->where('id', $petId)->update(['img' . $x => $value]);
                }
            }

            DB::commit();
            return response()->json(['addRescuePet' => ['id' => $petId]], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

   public function showRescuePet($id)
{
    try {
        // Retrieve pet data by ID
        $pet = DB::table('rescuepet')
            ->select(
                'id',
                'condition_id',
                'conditionLevel_id',
                'animal_id',
                'gender',
                'customer_id',
                'city',
                'city_id',
                'address',
                'latitude',
                'longitude',
                'description',
                'img1',
                'img2',
                'img3',
                'img4',
                'img5',
                'img6'
            )
            ->where('id', $id)
            ->first();

        if (!$pet) {
            return response()->json(['error' => 'Pet not found'], 404);
        }

        return response()->json(['showRescuePet' => $pet], 200);

    } catch (\Exception $e) {
        return response()->json(['error' => ['text' => $e->getMessage()]], 500);
    }
}


    public function editRescuePet(Request $request)
    {
        $data = $request->validate([
            'id' => 'required|integer',
            'city' => 'required|string',
            'address' => 'required|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'description' => 'required|string',
            'condition_id' => 'required|integer',
            'status' => 'required|string',
            'gender' => 'required|string',
            'animalType' => 'required|integer',
            'conditionLevel' => 'required|integer',
        ]);

        try {
            $affectedRows = DB::table('rescuepet')
                ->where('id', $data['id'])
                ->update([
                    'city' => $data['city'],
                    'address' => $data['address'],
                    'latitude' => $data['latitude'],
                    'longitude' => $data['longitude'],
                    'description' => $data['description'],
                    'status' => $data['status'],
                    'condition_id' => $data['condition_id'],
                    'gender' => $data['gender'],
                    'animal_id' => $data['animalType'],
                    'conditionLevel_id' => $data['conditionLevel'],
                ]);

            if ($affectedRows > 0) {
                return response()->json(['editRescuePet' => 'Updated'], 200);
            } else {
                return response()->json(['error' => 'No pet found to update'], 404);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function updateRescueImage(Request $request)
    {
        $data = $request->validate([
            'imgNumber' => 'required|integer',
            'id' => 'required|integer',
            'img' => 'required|string',
        ]);

        $imgNumber = $data['imgNumber'];
        $id = $data['id'];
        $image = $data['img'];

        try {
            if ($image) {
                // Create a unique file name
                $fileName = 'mypet_rescue_updated_' . $id . '_' . time() . '.jpg';

                // Decode the image data and save the file
                $imagedata = str_replace('data:image/jpeg;base64,', '', $image);
                $imagedata = str_replace('data:image/jpg;base64,', '', $imagedata);
                $imagedata = str_replace(' ', '+', $imagedata);
                $imagedata = base64_decode($imagedata);

                // Store the image in the public directory
                $path = public_path('adoptionImage/' . $fileName);
                if (!file_exists(dirname($path))) {
                    mkdir(dirname($path), 0755, true);
                }
                file_put_contents($path, $imagedata);

                // Create the URL for the stored image
                $imageURL = '/api/adoptionImage/' . $fileName;

                // Update the database with the new image URL
                DB::table('rescuepet')
                    ->where('id', $id)
                    ->update(['img' . $imgNumber => $imageURL]);

                return response()->json(['Image' => 'Upload Success'], 200);
            }
            return response()->json(['error' => 'Image data is missing'], 400);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

   public function deleteRescuePet(Request $request)
    {
        $data = $request->validate([
            'id' => 'required|integer',
        ]);

        $id = $data['id'];

        try {
            $deleted = DB::table('rescuepet')->where('id', $id)->delete();

            if ($deleted) {
                return response()->json(['deleteRescuePet' => 'Delete Success'], 200);
            } else {
                return response()->json(['error' => 'No rescue pet found with the given ID'], 404);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function addCitiesRescued(Request $request)
    {
        $data = $request->json()->all();
        $c_id = $data['c_id'];
        $rescueCities = $data['city'];

        try {
            foreach ($rescueCities as $city) {
                DB::table('rescue_customers')->insert([
                    'c_id' => $c_id,
                    'city_id' => $city['city_id']
                ]);
            }

            return response()->json(['Result' => 'Success']);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function addCitiesRescuedEdit(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|integer',
            'city_id' => 'required|integer',
        ]);

        try {
            $result = DB::table('rescue_customers')->insert([
                'c_id' => $data['c_id'],
                'city_id' => $data['city_id']
            ]);

            return $result
                ? response()->json(['Result' => 'Success'])
                : response()->json(['error' => 'Failed to add city'], 500);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function removeCitiesRescuedEdit(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|integer',
            'city_id' => 'required|integer',
        ]);

        try {
            $result = DB::table('rescue_customers')
                ->where('c_id', $data['c_id'])
                ->where('city_id', $data['city_id'])
                ->delete();

            if ($result) {
                return response()->json(['Result' => 'Success']);
            } else {
                return response()->json(['error' => 'No rows affected'], 404);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function getCitiesRescued(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|integer',
        ]);

        try {
            $cities = DB::table('rescue_customers')
                ->where('c_id', $data['c_id'])
                ->pluck('city_id');

            if ($cities->isNotEmpty()) {
                return response()->json(['cities' => $cities]);
            } else {
                return response()->json(['cities' => []]); // return empty array if none found
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function getRescuedCities(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|integer',
        ]);

        try {
            $cities = DB::table('rescue_customers as r')
                ->join('cities as c', 'c.city_id', '=', 'r.city_id')
                ->where('r.c_id', $data['c_id'])
                ->select('c.city', 'r.city_id')
                ->get();

            if ($cities->isNotEmpty()) {
                return response()->json(['cities' => $cities]);
            } else {
                return response()->json(['cities' => []]);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function rescueMarked(Request $request)
    {
        // Validate incoming request
        $data = $request->validate([
            'c_id' => 'required|integer',
        ]);

        try {
            // Optional: Enable query log for debugging
            DB::enableQueryLog();

            // Fetch marked rescue pets for the given customer
            $rescues = DB::table('rescuepet as R')
                ->select(
                    'R.id',
                    'R.img1',
                    'R.address',
                    'R.condition_id',
                    'R.status',
                    'P.name as ConditionType',
                    'P.id as PID'
                )
                ->leftjoin('petcondition as P', 'R.condition_id', '=', 'P.id') // Ensure correct column name
                ->leftjoin('rescue_check_later as C', 'C.rescue_id', '=', 'R.id')
                ->where('C.customer_id', $data['c_id'])
                ->get();

            // Return result
            if ($rescues->isNotEmpty()) {
                return response()->json(['rescueMarked' => $rescues]);
            } else {
                return response()->json(['rescueMarked' => []]); // Empty array if no matches
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }



    public function marked(Request $request)
    {
        // Validate incoming request
        $data = $request->validate([
            'c_id' => 'required|integer',
            'rescue_id' => 'required|integer',
            'flag' => 'required|boolean',
        ]);

        try {
            if ($data['flag']) {
                // Check if already marked to avoid duplicate entry
                $exists = DB::table('rescue_check_later')
                    ->where('customer_id', $data['c_id'])
                    ->where('rescue_id', $data['rescue_id'])
                    ->exists();

                if (!$exists) {
                    DB::table('rescue_check_later')->insert([
                        'customer_id' => $data['c_id'],
                        'rescue_id' => $data['rescue_id'],
                    ]);
                }

                return response()->json(['marked' => 'Marked', 'res' => true]);
            } else {
                // Remove marked record
                DB::table('rescue_check_later')
                    ->where('customer_id', $data['c_id'])
                    ->where('rescue_id', $data['rescue_id'])
                    ->delete();

                return response()->json(['marked' => 'Removed marked', 'res' => false]);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function toggleCheck(Request $request)
    {
        // Validate incoming request
        $data = $request->validate([
            'c_id' => 'required|integer',
            'rescue_id' => 'required|integer',
        ]);

        $c_id = $data['c_id'];
        $rescue_id = $data['rescue_id'];

        try {
            // Check if the entry exists in rescue_check_later
            $rescueCheck = DB::table('rescue_check_later')
                ->where('customer_id', $c_id)
                ->where('rescue_id', $rescue_id)
                ->first();

            if ($rescueCheck) {
                // Entry exists, so remove it (unmark)
                DB::table('rescue_check_later')
                    ->where('customer_id', $c_id)
                    ->where('rescue_id', $rescue_id)
                    ->delete();

                return response()->json([
                    'toggleCheck' => 'Removed',
                    'marked' => false,
                ]);
            } else {
                // Entry does not exist, so insert it (mark)
                DB::table('rescue_check_later')->insert([
                    'customer_id' => $c_id,
                    'rescue_id' => $rescue_id,
                ]);

                return response()->json([
                    'toggleCheck' => 'Added',
                    'marked' => true,
                ]);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

}
