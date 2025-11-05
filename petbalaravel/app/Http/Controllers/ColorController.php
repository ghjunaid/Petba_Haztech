<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ColorController
{
    public function getColors(Request $request) {
        try {
            // Fetch all colors from the colors table, ordered by color ascending
            $colors = DB::table('colors')
                        ->select('id', 'color')
                        ->orderBy('color', 'ASC')
                        ->get();
    
            // Return the response as JSON
            return response()->json(['color' => $colors]);
            
        } catch (\Exception $e) {
            // Return the error response
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }
}
