<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use App\Models\Adopt;
use App\Models\AdoptImage;

class PetController
{
    public function addPet(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|integer',
            'name' => 'required|string',
            'animal' => 'required|string',
            'animalName' => 'nullable|string',
            'gender' => 'required|string',
            'color' => 'required|string',
            'breed' => 'required|string',
            'breedName' => 'nullable|string',
            'note' => 'nullable|string',
            'city' => 'required|string',
            'city_id' => 'required|integer',
            'long' => 'required',
            'lat' => 'required',
            'anti_rbs' => 'nullable|string',
            'viral' => 'nullable|string',
            'dob' => 'required|date',
            'img1' => 'nullable|string',
            'img2' => 'nullable|string',
            'img3' => 'nullable|string',
            'img4' => 'nullable|string',
            'img5' => 'nullable|string',
            'img6' => 'nullable|string',
        ]);

        $petFlag = 1;
        $imgPaths = [];

        foreach (range(1, 6) as $index) {
            $image = $data["img$index"] ?? '';
            if (!empty($image)) {
                $targetPath = 'adoptionImage/mypet_' . $data['c_id'] . '_' . $index . '_' . time() . '.jpg';
                $imageData = base64_decode(preg_replace('#^data:image/\w+;base64,#i', '', $image));
                file_put_contents(public_path($targetPath), $imageData);
                $imgPaths["img$index"] = $targetPath;
            } else {
                $imgPaths["img$index"] = '';
            }
        }

        try {
            // Insert into adopt table
            $insertData = [
                'c_id' => $data['c_id'],
                'petFlag' => $petFlag,
                'name' => $data['name'],
                'animal_typ' => $data['animal'],
                'gender' => $data['gender'],
                'dob' => $data['dob'],
                'breed' => $data['breed'],
                'color' => $data['color'],
                'city' => $data['city'],
                'city_id' => $data['city_id'],
                'longitude' => $data['long'],
                'latitude' => $data['lat'],
                'anti_rbs' => $data['anti_rbs'] ?? null,
                'viral' => $data['viral'] ?? null,
                'note' => $data['note'] ?? null,
            ];

            // Add animalTypeName and breedName to insert data
            $insertData['animalTypeName'] = $data['animalName'] ?? null;
            $insertData['breedName'] = $data['breedName'] ?? null;

            $adopt = Adopt::create($insertData);

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

            // Insert into my_pets table
            $myPetsData = [
                'pet_id' => $adopt->adopt_id, // link to adopt table record
                'c_id' => $data['c_id'],
                'name' => $data['name'],
                'DoB' => $data['dob'],
                'image' => $imgPaths['img1'] ?? '',  // first image or empty string
                'gender' => $data['gender'],
                'color' => $data['color'],
                'breed' => $data['breed'],
                'anti_rbs' => $data['anti_rbs'] ?? null,
                'viral' => $data['viral'] ?? null,
                'note' => $data['note'] ?? null,
            ];

            DB::table('my_pets')->insert($myPetsData);

            return response()->json(['adopt' => 'added to db', 'my_pets' => 'added to db'], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }



    public function listPet(Request $request)
    {
        $data = $request->json()->all();
        $c_id = $data['c_id'];

        try {
            $pets = DB::table('adopt as a')
                ->leftJoin('animal as b', 'a.animal_typ', '=', 'b.animal_id')
                ->leftJoin('breed as c', 'a.breed', '=', 'c.id')
                ->leftJoin('colors as d', 'a.color', '=', 'd.id')
                ->leftJoin('adopt_images as ai', function($join) {
                    $join->on('a.adopt_id', '=', 'ai.adopt_id')
                         ->where('ai.image_order', '=', 1);
                })
                ->select(
                    'a.adopt_id',
                    'a.c_id',
                    DB::raw('COALESCE(ai.image_path, "") as img1'),
                    'a.name',
                    DB::raw("IF(b.animal_id = '0', a.animalTypeName, b.name) as animalTypeName"),
                    'b.name as animalName',
                    'a.gender',
                    'a.dob',
                    DB::raw("IF(c.animal_id = '0', a.breedName, c.name) as breed"),
                    'a.city'
                )
                ->where('a.petFlag', 1)
                ->where('a.c_id', $c_id)
                ->get();

            return response()->json(['listpet' => $pets], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function viewPet(Request $request)
    {
        $adopt_id = $request->input('adopt_id');

        try {
            $pet = DB::table('adopt as a')
                ->leftJoin('animal as b', 'a.animal_typ', '=', 'b.animal_id')
                ->leftJoin('breed as c', 'a.breed', '=', 'c.id')
                ->leftJoin('colors as D', 'a.color', '=', 'D.id')
                ->select(
                    'a.adopt_id',
                    'a.c_id',
                    'a.petFlag',
                    'a.name',
                    DB::raw("IF(b.name = 'other', a.animalTypeName, b.name) as animalTypeName"),
                    'a.gender',
                    'a.dob',
                    DB::raw("IF(c.name = 'other', a.breedName, c.name) as breed"),
                    'D.color',
                    'a.anti_rbs',
                    'a.viral',
                    'a.note',
                    'a.city',
                    'a.longitude',
                    'a.latitude',
                    'a.date_added'
                )
                ->where('a.adopt_id', $adopt_id)
                ->first(); // No GROUP BY needed when fetching single row

            // Attach images from normalized table
            if ($pet) {
                $images = DB::table('adopt_images')
                    ->where('adopt_id', $adopt_id)
                    ->orderBy('image_order')
                    ->pluck('image_path')
                    ->toArray();

                $pet->img1 = $images[0] ?? '';
                $pet->img2 = $images[1] ?? '';
                $pet->img3 = $images[2] ?? '';
                $pet->img4 = $images[3] ?? '';
                $pet->img5 = $images[4] ?? '';
                $pet->img6 = $images[5] ?? '';
            }

            return response()->json(['viewpet' => $pet], 200);
        } catch (\Exception $e) {
            return response()->json(['error_from_ViewPet' => ['text' => $e->getMessage()]], 500);
        }
    }


    // Function to get edit pet details
    public function getEditPet(Request $request)
    {
        $p_id = $request->input('p_id');
        $c_id = $request->input('c_id');

        \Log::info('getEditPet inputs:', ['p_id' => $p_id, 'c_id' => $c_id]);

        try {
            $pet = DB::table('my_pets')
                ->where('pet_id', $p_id)
                ->where('c_id', $c_id)
                ->first();

            \Log::info('getEditPet result:', ['pet' => $pet]);

            return response()->json(['geteditpet' => $pet], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    // Function to update pet details
    public function updatePet(Request $request)
    {
        $validatedData = $request->validate([
            'pet_id' => 'required|string',
            'c_id' => 'required|string',
            'name' => 'required|string',
            'DoB' => 'required|date',
            'image' => 'nullable|string',
            'gender' => 'required|string',
            'color' => 'required|string',
            'breed' => 'required|string',
            'anti_rbs' => 'required|string',
            'viral' => 'required|string',
            'note' => 'nullable|string',
        ]);

        try {
            $exists = DB::table('my_pets')
                ->where('pet_id', $validatedData['pet_id'])
                ->where('c_id', $validatedData['c_id'])
                ->exists();

            if (!$exists) {
                return response()->json(['updated' => 'no matching record found'], 404);
            }

            // Handle image upload if provided
            $ImageURL = null;
            if (!empty($validatedData['image'])) {
                $targetPath = 'adoptionImage/mypet_' . time() . '.jpg';
                $imageData = base64_decode(preg_replace('#^data:image/\w+;base64,#i', '', $validatedData['image']));
                file_put_contents(public_path($targetPath), $imageData);
                $ImageURL = $targetPath;
            }

            $updateData = [
                'name' => $validatedData['name'],
                'DoB' => $validatedData['DoB'],
                'gender' => $validatedData['gender'],
                'color' => $validatedData['color'],
                'breed' => $validatedData['breed'],
                'anti_rbs' => $validatedData['anti_rbs'],
                'viral' => $validatedData['viral'],
                'note' => $validatedData['note'],
            ];

            if ($ImageURL) {
                $updateData['image'] = $ImageURL;
            }

            DB::table('my_pets')
                ->where('pet_id', $validatedData['pet_id'])
                ->where('c_id', $validatedData['c_id'])
                ->update($updateData);

            return response()->json(['updated' => 'successful'], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }



    // Function to delete a pet
    public function deletePet(Request $request)
    {
        $p_id = $request->input('pet_id');
        $c_id = $request->input('c_id');

        try {
            $deleted = DB::table('my_pets')
                ->where('pet_id', $p_id)
                ->where('c_id', $c_id)
                ->delete();

            if ($deleted) {
                return response()->json(['deletepet' => 'Deleted successfully'], 200);
            } else {
                return response()->json(['deletepet' => 'No matching record found'], 404);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


   public function deleteMyPet(Request $request)
    {
        $adopt_id = (int) $request->input('adopt_id');
        $c_id = (int) $request->input('c_id');
        $email = $request->input('email');
        $token = $request->input('token');

        try {
            $out = internalUserDetails($email); // Token validation
            $ck_id = $out->customer_id;
            $ck_token = $out->token;

            if ($c_id == $ck_id && $token == $ck_token) {

                $pet = DB::table('adopt')
                    ->where('adopt_id', $adopt_id)
                    ->where('c_id', $c_id)
                    ->first();

                if (!$pet) {
                    return response()->json(['message' => 'No matching record found to delete'], 404);
                }

                if ($pet->petFlag == 3) {
                    return response()->json(['message' => 'Pet already marked as deleted'], 200);
                }

                DB::table('adopt')
                    ->where('adopt_id', $adopt_id)
                    ->where('c_id', $c_id)
                    ->update(['petFlag' => 3]);

                return response()->json(['message' => 'Pet marked as deleted successfully'], 200);

            } else {
                return response()->json(['error' => 'Invalid user credentials'], 401);
            }

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    
    
   public function allPetCateg(Request $request)
{
    $data = $request->json()->all();
    $userData = $data['userData'];
    $id = $userData['customer_id'];
    $email = $userData['email'];
    $token = $userData['token'];
    
    try {
        $userDetails = internalUserDetails($email);
        $ck_id = $userDetails->customer_id;
        $ck_tkn = $userDetails->token;
        
        if ($id == $ck_id && $token == $ck_tkn) {
            // Fetch pet categories
            $tocateg = DB::table('pet_cate')->get();

            // Fetch cart total
            $totalCart = $this->cartTotal($id);

            return response()->json([
                'petcatg' => $tocateg,
                'total'   => $totalCart
            ]);
        } else {
            return response()->json(['error' => 'Invalid user credentials'], 401);
        }
    } catch (\Exception $e) {
        return response()->json(['error' => ['text' => $e->getMessage()]], 500);
    }
}






    public function showPetDetails(Request $request)
    {
        $petID = $request->input('petID');

        if (!$petID) {
            return response()->json(['error' => 'petID is required'], 400);
        }

        try {
           $categ = DB::table('adopt as a')
            ->select(
                'a.adopt_id',
                'a.c_id',
                'a.petFlag',
                'a.name',
                'a.animal_typ',
                DB::raw('IF(a.animalTypeName = "", b.name, a.animalTypeName) AS animalTypeName'),
                'a.gender',
                'a.dob',
                'a.breed',
                DB::raw('IF(a.breedName = "", c.name, a.breedName) AS breedName'),
                'a.color as color_id',
                'D.color as color_name',
                'a.anti_rbs',
                'a.viral',
                'a.note',
                'a.city',
                'a.date_added'
            )
            ->leftjoin('animal as b', 'a.animal_typ', '=', 'b.animal_id')
            ->leftJoin('breed as c', 'a.breed', '=', 'c.id')
            ->leftJoin('colors as D', 'D.id', '=', 'a.color')
            ->where('a.adopt_id', $petID)
            ->first();

            if ($categ) {
                $images = DB::table('adopt_images')
                    ->where('adopt_id', $petID)
                    ->orderBy('image_order')
                    ->pluck('image_path')
                    ->toArray();

                $categ->img1 = $images[0] ?? '';
                $categ->img2 = $images[1] ?? '';
                $categ->img3 = $images[2] ?? '';
                $categ->img4 = $images[3] ?? '';
                $categ->img5 = $images[4] ?? '';
                $categ->img6 = $images[5] ?? '';
            }
            if (!$categ) {
                return response()->json(['error' => 'Pet not found'], 404);
            }

            return response()->json(['showPetDetails' => $categ], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function petChatInfo(Request $request)
    {
        $data = json_decode($request->getContent());
        $adopt_id = $data->petId;

        try {
           $categ = DB::table('adopt as a')
            ->select(
                'a.adopt_id',
                'a.c_id as owner_id',
                DB::raw('CONCAT(C.firstname, " ", C.lastname) as owner_name'),
                'a.name',
                DB::raw('COALESCE(ai1.image_path, "") as img1'),
                DB::raw('COALESCE(ai2.image_path, "") as img2'),
                DB::raw('COALESCE(ai3.image_path, "") as img3'),
                DB::raw('COALESCE(ai4.image_path, "") as img4'),
                DB::raw('COALESCE(ai6.image_path, "") as img6'),
                DB::raw('COALESCE(ai5.image_path, "") as img5'),
                'C.telephone'
            )
            ->join('oc_customer as C', 'a.c_id', '=', 'C.customer_id')
            ->leftJoin('adopt_images as ai1', function($join) { $join->on('a.adopt_id','=','ai1.adopt_id')->where('ai1.image_order','=',1); })
            ->leftJoin('adopt_images as ai2', function($join) { $join->on('a.adopt_id','=','ai2.adopt_id')->where('ai2.image_order','=',2); })
            ->leftJoin('adopt_images as ai3', function($join) { $join->on('a.adopt_id','=','ai3.adopt_id')->where('ai3.image_order','=',3); })
            ->leftJoin('adopt_images as ai4', function($join) { $join->on('a.adopt_id','=','ai4.adopt_id')->where('ai4.image_order','=',4); })
            ->leftJoin('adopt_images as ai5', function($join) { $join->on('a.adopt_id','=','ai5.adopt_id')->where('ai5.image_order','=',5); })
            ->leftJoin('adopt_images as ai6', function($join) { $join->on('a.adopt_id','=','ai6.adopt_id')->where('ai6.image_order','=',6); })
            ->where('a.adopt_id', $adopt_id)
            ->first();

            return response()->json(['result' => $categ]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

public function cartTotal($customerId)
{
    $total = DB::table('oc_cart as c')
        ->join('oc_product as p', 'c.product_id', '=', 'p.product_id')
        ->where('c.customer_id', $customerId)
        ->sum(DB::raw('p.price * c.quantity'));

    return $total;
}


}
