<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\File;
use App\Models\Adopt;
use App\Models\AdoptImage;

class AdoptionController
{
    public function adoptionInterest(Request $request)
    {
        $email = $request->input('email');
        $token = $request->input('token');
        $cId = $request->input('c_id');

        try {
            $out = internalUserDetails($email); // Token validation helper
            $ck_id = $out->customer_id;
            $ck_tkn = $out->token;

            if ($cId == $ck_id && $token == $ck_tkn) {
                // Fetch adopt records with interested count (including zero) for given c_id
                $adoptionWithInterest = DB::table('adopt')
                    ->leftJoin(DB::raw('(SELECT p_id, COUNT(id) as t FROM interested GROUP BY p_id) as a'), 'a.p_id', '=', 'adopt.adopt_id')
                    ->leftJoin('adopt_images', function($join) {
                        $join->on('adopt.adopt_id', '=', 'adopt_images.adopt_id')
                             ->where('adopt_images.image_order', '=', 1);
                    })
                    ->select('adopt.adopt_id', 'adopt.c_id', 'adopt.name', 'adopt.gender', 'adopt.dob', 'adopt_images.image_path as img1', 'adopt.breed', DB::raw('COALESCE(a.t, 0) as t'), 'adopt.city')
                    ->where('adopt.c_id', '=', $cId)
                    ->get();

                // Fetch adopt records where c_id doesn't match
                $adoptionWithoutInterest = DB::table('adopt')
                    ->leftJoin('adopt_images', function($join) {
                        $join->on('adopt.adopt_id', '=', 'adopt_images.adopt_id')
                             ->where('adopt_images.image_order', '=', 1);
                    })
                    ->select('adopt.adopt_id', 'adopt.c_id', 'adopt.name', 'adopt.gender', 'adopt.dob', 'adopt_images.image_path as img1', 'adopt.breed')
                    ->where('adopt.c_id', '!=', $cId)
                    ->get();

                return response()->json([
                    'adoptionInterest' => $adoptionWithInterest,
                    'adoptionWithoutInterest' => $adoptionWithoutInterest
                ]);
            } else {
                return response()->json(['error' => 'Invalid user credentials'], 401);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }



   public function listAdoption(Request $request)
    {
        $cityId = $request->input('city_id');
        $lastPet = $request->input('lastPet', 0);
        $ageSort = $request->input('ageSort', false);
        $locationSort = $request->input('locationSort', false);
        $newSort = $request->input('newSort', false);
        $latitudeSelf = $request->input('latitude');
        $longitudeSelf = $request->input('longitude');
        $animalTypeName = $request->input('animalTypeName');
        $breed = $request->input('breed');
        $genderArray = $request->input('gender');
        $color = $request->input('color');
        $cId = $request->input('c_id');

        // Always return all results (no pagination)
        $showAll = true;

        // Base query
        $query = DB::table('adopt as a')
            ->leftJoin('animal as b', 'a.animal_typ', '=', 'b.animal_id')
            ->leftJoin('breed as c', 'a.breed', '=', 'c.id')  // Use c.id based on your schema
            ->leftJoin('adopt_images', function($join) {
                $join->on('a.adopt_id', '=', 'adopt_images.adopt_id')
                     ->where('adopt_images.image_order', '=', 1);
            })
            ->select(
                'a.adopt_id',
                'a.c_id',
                'a.name',
                'a.gender',
                'a.dob',
                'adopt_images.image_path as img1',
                'a.city',
                'b.name as animalName',
                'c.name as breed',
                'a.note'
            )
            ->where('a.petFlag', 2);
            
        // Exclude current user's pets if c_id is provided
        if ($cId) {
            $query->where('a.c_id', '!=', $cId);
        }

        // Filters

        if ($genderArray && is_array($genderArray) && count($genderArray) > 0) {
            $query->whereIn('a.gender', $genderArray);
        }

        if ($animalTypeName && is_array($animalTypeName) && count($animalTypeName) > 0) {
            $query->whereIn('a.animal_typ', $animalTypeName);
        }

        if ($breed && is_array($breed) && count($breed) > 0) {
            $query->whereIn('a.breed', $breed);
        }

        if ($color && is_array($color) && count($color) > 0) {
            // Left join colors only if filtering by color
            $query->leftJoin('colors as co', 'co.id', '=', 'a.color')
                ->whereIn('co.id', $color);
        }

        // Only filter by city if latitude/longitude are not provided
        if (!$latitudeSelf || !$longitudeSelf) {
            if ($cityId) {
                $query->where('a.city_id', $cityId);
            }
        }

        // Sorting & location filtering
        if ($latitudeSelf && $longitudeSelf) {
            // Add distance calculation and filter within 50km
            $query->addSelect(DB::raw("(((radians(acos(sin(radians($latitudeSelf)) * sin(radians(a.latitude)) + cos(radians($latitudeSelf)) * cos(radians(a.latitude)) * cos(radians($longitudeSelf - a.longitude))))) * 60 * 1.1515) * 1.609344) AS Distance"));
            $query->having('Distance', '<=', 50);
            $query->orderBy('Distance', 'ASC');
        } else if ($newSort) {
            $query->orderByDesc('a.adopt_id');
        } else if ($ageSort) {
            $query->orderByDesc('a.dob');
        } else {
            $query->orderByDesc('a.adopt_id');
        }

        // No limit/offset applied: return all matching rows
        try {
            $results = $query->get();
            return response()->json(['listadopt' => $results]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function listMyAdoption(Request $request)
    {
        $email = $request->input('email');
        $token = $request->input('token');
        $cId = $request->input('c_id');

        try {
            $out = internalUserDetails($email); // Token validation helper
            $ck_id = $out->customer_id;
            $ck_tkn = $out->token;

            if ($cId == $ck_id && $token == $ck_tkn) {
                $query = DB::table('adopt as a')
                    ->leftJoin('animal as b', 'a.animal_typ', '=', 'b.animal_id')
                    ->leftJoin('breed as c', 'c.id', '=', 'a.breed')
                    ->leftJoin('colors as d', 'd.id', '=', 'a.color')
                    ->leftJoin('adopt_images', function($join) {
                        $join->on('a.adopt_id', '=', 'adopt_images.adopt_id')
                             ->where('adopt_images.image_order', '=', 1);
                    })
                    ->select(
                        'a.adopt_id',
                        'a.c_id',
                        'adopt_images.image_path as img1',
                        'a.name',
                        DB::raw("IF(a.animal_typ = 0, a.animalTypeName, b.name) AS animalTypeName"),
                        'b.name as animalName',
                        'a.gender',
                        'a.dob',
                        DB::raw("IF(a.breed = 0, a.breedName, c.name) AS breed"),
                        'a.city'
                    )
                    ->where('a.petFlag', '=', 2)
                    ->where('a.c_id', '=', $cId)
                    ->get();

                return response()->json(['listMyadoption' => $query]);
            } else {
                return response()->json(['error' => 'Invalid user credentials'], 401);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }




    public function addPetAdoption(Request $request)
    {
        $data = $request->all();

        $email = $data['email'];
        $token = $data['token'];
        $c_id = $data['c_id'];

        try {
            $out = internalUserDetails($email); // Token validation
            $ck_id = $out->customer_id;
            $ck_tkn = $out->token;

            if ($c_id == $ck_id && $token == $ck_tkn) {

                $name = $data['name'];
                $animal = $data['animal'];
                $animalName = $data['animalName'] ?? null;
                $gender = $data['gender'];
                $color = $data['color'];
                $breed = $data['breed'];
                $breedName = $data['breedName'] ?? null;
                $note = $data['note'] ?? null;
                $city = $data['city'];
                $city_id = $data['city_id'];
                $longitude = $data['long'];
                $latitude = $data['lat'];
                $anti_rbs = $data['anti_rbs'] ?? null;
                $viral = $data['viral'] ?? null;
                $petFlag = 2;
                $DoB = $data['dob'];

                $images = [
                    'img1' => $data['img1'] ?? null,
                    'img2' => $data['img2'] ?? null,
                    'img3' => $data['img3'] ?? null,
                    'img4' => $data['img4'] ?? null,
                    'img5' => $data['img5'] ?? null,
                    'img6' => $data['img6'] ?? null,
                ];

                $imgPaths = [];

                foreach ($images as $key => $img) {
                    if (!empty($img)) {
                        $filename = 'mypet_' . $c_id . '_' . $key . '_' . time() . '.jpg';
                        $img = str_replace(['data:image/jpeg;base64,', 'data:image/jpg;base64,'], '', $img);
                        $imgData = base64_decode($img);
                        $path = public_path('adoptionImage/' . $filename);
                        if (!file_exists(dirname($path))) {
                            mkdir(dirname($path), 0755, true);
                        }
                        file_put_contents($path, $imgData);
                        $imgPaths[$key] = 'adoptionImage/' . $filename;
                    } else {
                        $imgPaths[$key] = '';
                    }
                }

                $adoptData = [
                    'c_id' => $c_id,
                    'petFlag' => $petFlag,
                    'name' => $name,
                    'animal_typ' => $animal,
                    'gender' => $gender,
                    'dob' => $DoB,
                    'breed' => $breed,
                    'color' => $color,
                    'anti_rbs' => $anti_rbs,
                    'viral' => $viral,
                    'note' => $note,
                    'city' => $city,
                    'city_id' => $city_id,
                    'longitude' => $longitude,
                    'latitude' => $latitude,
                    'animalTypeName' => $animalName,
                    'breedName' => $breedName,
                ];

                $adopt = Adopt::create($adoptData);

                // Insert images into the new normalized table
                $order = 1;
                foreach ($imgPaths as $path) {
                    if (!empty($path)) {
                        AdoptImage::create([
                            'adopt_id' => $adopt->adopt_id,
                            'image_path' => $path,
                            'image_order' => $order,
                        ]);
                        $order++;
                    }
                }

                return response()->json(['adopt' => 'added to db successfully'], 200);
            } else {
                return response()->json(['error' => 'Invalid user credentials'], 401);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }


   public function petAdoptionDetails(Request $request)
{
    $data = $request->all();

    $email = $data['email'];
    $token = $data['token'];
    $c_id = $data['c_id'];
    $adopt_id = $data['adopt_id'];

    try {
        $out = internalUserDetails($email); // Token validation
        $ck_id = $out->customer_id;
        $ck_tkn = $out->token;

        if ($c_id == $ck_id && $token == $ck_tkn) {

            $adoptionDetails = DB::table('adopt as a')
                ->leftJoin('animal as b', 'a.animal_typ', '=', 'b.animal_id')
                ->leftJoin('breed as c', 'c.id', '=', 'a.breed')
                ->leftJoin('colors as d', 'd.id', '=', 'a.color')
                ->leftJoin('oc_customer as cust', 'a.c_id', '=', 'cust.customer_id')
                ->select(
                    'a.adopt_id',
                    'a.c_id',
                    'a.petFlag',
                    'a.name',
                    'cust.telephone',
                    DB::raw("IF(a.animal_typ != '0', b.name, a.animalTypeName) as animalTypeName"),
                    'a.gender',
                    'a.dob',
                    DB::raw("IF(a.breed != '0', c.name, a.breedName) as breed"),
                    'd.color',
                    'a.anti_rbs',
                    'a.viral',
                    'a.note',
                    'a.city',
                    'a.longitude',
                    'a.latitude',
                    'a.date_added'
                )
                ->where('a.adopt_id', $adopt_id)
                ->first();

            // Get images from the new normalized table
            if ($adoptionDetails) {
                $images = DB::table('adopt_images')
                    ->where('adopt_id', $adopt_id)
                    ->orderBy('image_order')
                    ->pluck('image_path')
                    ->toArray();
                
                // Add images to the response in the expected format
                $adoptionDetails->img1 = $images[0] ?? '';
                $adoptionDetails->img2 = $images[1] ?? '';
                $adoptionDetails->img3 = $images[2] ?? '';
                $adoptionDetails->img4 = $images[3] ?? '';
                $adoptionDetails->img5 = $images[4] ?? '';
                $adoptionDetails->img6 = $images[5] ?? '';
            }

            return response()->json(['adoptdetails' => $adoptionDetails], 200);

        } else {
            return response()->json(['error' => 'Invalid user credentials'], 401);
        }

    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
}




    public function updatePetAdoption(Request $request)
    {
        $data = $request->all();

        $email = $data['email'];
        $token = $data['token'];
        $c_id = $data['c_id'];

        try {
            $out = internalUserDetails($email); // Token validation
            $ck_id = $out->customer_id;
            $ck_tkn = $out->token;

            if ($c_id == $ck_id && $token == $ck_tkn) {
                $city_id = $data['city_id'];
                $name = $data['name'];
                $animal_typ = $data['animal_typ'];
                $animalTypeName = $data['animalTypeName'];
                $gender = $data['gender'];
                $color = $data['color'];
                $breed = $data['breed'];
                $breedName = $data['breedName'];
                $note = $data['note'];
                $dob = $data['dob'];
                $adopt_id = $data['adopt_id'];
                $viral = $data['viral'];
                $anti_rbs = $data['anti_rbs'];
                $latitude = $data['latitude'];
                $longitude = $data['longitude'];
                $city = $data['city'];

                $ss = "";

                if (!is_null($longitude) && !is_null($latitude)) {
                    $ss .= ", longitude='" . $longitude . "', latitude='" . $latitude . "'";
                }

                if (is_numeric($breed)) {
                    if ($breed == '0') {
                        $ss .= ", breed='" . $breed . "', breedName='" . $breedName . "'";
                    } else {
                        $ss .= ", breed='" . $breed . "'";
                    }
                }

                if (is_numeric($animal_typ)) {
                    if ($animal_typ == '0') {
                        $ss .= ", animal_typ='" . $animal_typ . "', animalTypeName='" . $animalTypeName . "'";
                    } else {
                        $ss .= ", animal_typ='" . $animal_typ . "'";
                    }
                }

                if (is_numeric($color)) {
                    $ss .= ", color='" . $color . "'";
                }

                $sql = "UPDATE adopt SET c_id=:c_id, name=:name, gender=:gender, dob=:dob, city=:city, city_id=:city_id" . $ss . ", note=:note, viral=:viral, anti_rbs=:anti_rbs WHERE adopt_id=:adopt_id";

                DB::update($sql, [
                    'c_id' => $c_id,
                    'name' => $name,
                    'gender' => $gender,
                    'dob' => $dob,
                    'city' => $city,
                    'city_id' => $city_id,
                    'note' => $note,
                    'viral' => $viral,
                    'anti_rbs' => $anti_rbs,
                    'adopt_id' => $adopt_id,
                ]);

                return response()->json(['updateadopt' => $data], 200);

            } else {
                return response()->json(['error' => 'Invalid user credentials'], 401);
            }

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }



    public function deleteAdoptPet(Request $request)
    {
        $data = $request->all();

        $email = $data['email'];
        $token = $data['token'];
        $adopt_id = $data['adopt_id'];
        $c_id = $data['c_id'];

        try {
            $out = internalUserDetails($email); // Token validation
            $ck_id = $out->customer_id;
            $ck_token = $out->token;

            if ($c_id == $ck_id && $token == $ck_token) {

                $deleted = DB::table('adopt')
                    ->where('adopt_id', $adopt_id)
                    ->where('c_id', $c_id)
                    ->delete();

                if ($deleted) {
                    return response()->json(['deleteadoptpet' => 'Deleted successfully'], 200);
                } else {
                    return response()->json(['error' => 'Record not found'], 404);
                }

            } else {
                return response()->json(['error' => 'Invalid user credentials'], 401);
            }

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function updatePetAdoptionImage(Request $request)
    {
        $data = $request->all();
        $imgNumber = $data['imgNumber'];
        $adopt_id = $data['adopt_id'];
        $image = $data['img'];
        $token = $data['token'] ?? null;
        $customer_id = $data['customer_id'] ?? null;
        $email = $data['email'] ?? null;

        try {
            // Token validation
            if (!$token || !$customer_id) {
                return response()->json(['error' => 'Token and customer_id are required'], 400);
            }

            $user = internalUserDetails($email); // your existing method
            if (!$user || $user->token !== $token) {
                return response()->json(['error' => 'Unauthorized access - invalid token'], 401);
            }

            // Ownership check: only allow if user owns the adoption post
            $adoption = DB::table('adopt')
                ->where('adopt_id', $adopt_id)
                ->first();

            if (!$adoption) {
                return response()->json(['error' => 'Adoption post not found'], 404);
            }

            if ((int) $adoption->c_id !== (int) $customer_id) {
                return response()->json(['error' => 'Unauthorized access - not the owner'], 403);
            }

            // save the image
            if ($image) {
                $filename = 'mypet_' . $adopt_id . '_' . time() . '.jpg';

                $imageData = str_replace(['data:image/jpeg;base64,', 'data:image/jpg;base64,'], '', $image);
                $imageData = str_replace(' ', '+', $imageData); // fix base64 format
                $imageData = base64_decode($imageData);

                $path = public_path('adoptionImage/' . $filename);
                if (!file_exists(dirname($path))) {
                    mkdir(dirname($path), 0755, true);
                }
                file_put_contents($path, $imageData);

                if ($imgNumber) {
                    // Check if image already exists for this adopt_id and image_order
                    $existingImage = DB::table('adopt_images')
                        ->where('adopt_id', $adopt_id)
                        ->where('image_order', $imgNumber)
                        ->first();

                    if ($existingImage) {
                        // Update existing image
                        $updated = DB::table('adopt_images')
                            ->where('adopt_id', $adopt_id)
                            ->where('image_order', $imgNumber)
                            ->update(['image_path' => 'adoptionImage/' . $filename]);
                    } else {
                        // Insert new image
                        $updated = DB::table('adopt_images')->insert([
                            'adopt_id' => $adopt_id,
                            'image_path' => 'adoptionImage/' . $filename,
                            'image_order' => $imgNumber,
                        ]);
                    }

                    if ($updated) {
                        return response()->json(['Image' => 'Uploaded in img' . $imgNumber], 200);
                    } else {
                        return response()->json(['error' => 'No rows updated'], 400);
                    }
                }
            } else {
                return response()->json(['error' => 'Image not provided'], 400);
            }

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    
    public function updateRemovePetAdoptionImage(Request $request)
    {
        $data = $request->all();
        $imgNumber = $data['imgNumber'];
        $adopt_id = $data['adopt_id'];

        try {
            if ($imgNumber) {
                // Remove the image from the normalized table
                $affectedRows = DB::table('adopt_images')
                    ->where('adopt_id', $adopt_id)
                    ->where('image_order', $imgNumber)
                    ->delete();

                if ($affectedRows) {
                    return response()->json(['Image' => 'Removed from img' . $imgNumber], 200);
                } else {
                    return response()->json(['error' => 'No rows updated'], 400);
                }
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function adoptionName(Request $request)
    {
        // Validate incoming request
        $data = $request->validate([
            'p_id' => 'required|string',
        ]);

        $p_id = $data['p_id'];

        try {
            // Fetch adoption details with first image
            $adoption = DB::table('adopt')
                ->leftJoin('adopt_images', function($join) {
                    $join->on('adopt.adopt_id', '=', 'adopt_images.adopt_id')
                         ->where('adopt_images.image_order', '=', 1);
                })
                ->select('adopt_images.image_path as img1', 'adopt.name')
                ->where('adopt.adopt_id', $p_id)
                ->first();

            // Return JSON response
            return response()->json(['adoptionname' => $adoption]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    

    public function addForAdoption(Request $request)
    {
        // Validate the incoming JSON body
        $data = $request->validate([
            'petId' => 'required|integer',
            'petFlag' => 'required|string'
        ]);

        try {
            DB::table('adopt')
                ->where('adopt_id', $data['petId'])
                ->update(['petFlag' => $data['petFlag']]);

            return response()->json(['Updated' => 'Pet has been updated']);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function getInterestedPeople(Request $request)
    {
        $data = $request->all();

        $email = $data['email'];
        $token = $data['token'];
        $c_id = $data['c_id'];
        $adopt_id = $data['adopt_id'];

        try {
            $out = internalUserDetails($email); // Token validation
            $ck_id = $out->customer_id;
            $ck_tkn = $out->token;

            if ($c_id == $ck_id && $token == $ck_tkn) {

                // 1. Get the specific adoption post (optional, not used in this response)
                $adoptPost = DB::table('adopt')
                    ->where('adopt_id', $adopt_id)
                    ->first();

                // 2. Get the interested people who match that post
                $interestedPeople = DB::table('oc_customer as a')
                    ->join('interested as b', 'a.customer_id', '=', 'b.c_id')
                    ->where('b.p_id', $adopt_id)
                    ->select('a.customer_id', 'a.email', 'a.token', 'a.telephone', 'b.p_id')
                    ->get();

                return response()->json([
                    'interested' => $interestedPeople,
                    // 'adopt_post' => $adoptPost // Uncomment if needed
                ], 200);

            } else {
                return response()->json(['error' => 'Invalid user credentials'], 401);
            }

        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch interested people',
                'message' => $e->getMessage()
            ], 500);
        }
    }


}
