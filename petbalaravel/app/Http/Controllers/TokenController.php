<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TokenController
{
    public function saveToken(Request $request)
    {
        $data = $request->json()->all();
        $c_id = $data['c_id'];
        $d_id = $data['d_id'];

        try {
            if (!is_null($d_id) && $d_id != '') {
                DB::table('oc_customer')
                    ->where('customer_id', $c_id)
                    ->update(['token' => $d_id]);

                return response()->json(['Token Update Status' => '200 OK']);
            } else {
                return response()->json(['error' => 'Invalid token'], 400);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }
}
