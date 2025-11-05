<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InterestController
{
    public function addInterested(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
            'c_id' => 'required|integer',
            'adopt_id' => 'required|integer',
        ]);

        $email = $validated['email'];
        $token = $validated['token'];
        $c_id = $validated['c_id'];
        $p_id = $validated['adopt_id'];

        try {
            $out = internalUserDetails($email);
            $ck_id = $out->customer_id;
            $ck_token = $out->token;

            if ($c_id == $ck_id && $token == $ck_token) {
                $exists = DB::table('interested')
                    ->where('c_id', $c_id)
                    ->where('p_id', $p_id)
                    ->exists();

                if (!$exists) {
                    DB::table('interested')->insert([
                        'c_id' => $c_id,
                        'p_id' => $p_id,
                    ]);

                    return response()->json(['status' => true, 'message' => 'Interest added']);
                }

                return response()->json(['status' => false, 'message' => 'Already interested']);
            } else {
                return response()->json(['status' => false, 'message' => 'Invalid credentials'], 401);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

   public function deleteUsr(Request $request)
    {
        $validated = $request->validate([
            'p_id' => 'required|integer',
            'customer_id' => 'required|integer',
        ]);

        $p_id = $validated['p_id'];
        $c_id = $validated['customer_id'];

        try {
            $deleted = DB::table('interested')
                ->where('c_id', $c_id)
                ->where('p_id', $p_id)
                ->delete();

            if ($deleted) {
                return response()->json([
                    'status' => true,
                    'message' => 'Interest entry deleted successfully'
                ]);
            } else {
                return response()->json([
                    'status' => false,
                    'message' => 'No matching record found to delete'
                ]);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

}
