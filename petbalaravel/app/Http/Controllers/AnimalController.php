<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnimalController
{
    public function animalBreed(Request $request)
    {
        try {
            $animals = DB::table('animal')
                ->select('animal_id', 'name')
                ->get();

            return response()->json(['animalbreed' => $animals], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function breed(Request $request)
    {
        $id = $request->input('id');

        try {
            if ($id !== null) {
                // If ID is provided
                $breeds = DB::table('breed')
                    ->where('animal_id', $id)
                    ->orderBy('name', 'ASC')
                    ->get();
            } else {
                // If no ID is provided, fetch all breeds
                $breeds = DB::table('breed')
                    ->orderBy('name', 'ASC')
                    ->get();
            }

            return response()->json(['breed' => $breeds], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    // breed2() equivalent function
    public function breed2(Request $request)
    {
        $id = $request->input('id');

        try {
            if ($id !== null && is_array($id)) {
                // If ID array is provided
                $breeds = DB::table('breed')
                    ->whereIn('animal_id', $id)
                    ->orderBy('name', 'ASC')
                    ->get();
            } else {
                // If no ID array is provided, fetch all breeds
                $breeds = DB::table('breed')
                    ->orderBy('name', 'ASC')
                    ->get();
            }

            return response()->json(['breed' => $breeds], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }
}
