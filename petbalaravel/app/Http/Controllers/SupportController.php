<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\InformationDescription;

class SupportController
{
    public function getSupport()
    {
        try {
            $categories = InformationDescription::all();
            return response()->json(['data' => $categories]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function getSupportPage(Request $request)
    {
        $id = $request->input('id');

        try {
            $category = InformationDescription::find($id);
            if ($category) {
                return response()->json(['data' => $category]);
            } else {
                return response()->json(['data' => 'null']);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }
}
