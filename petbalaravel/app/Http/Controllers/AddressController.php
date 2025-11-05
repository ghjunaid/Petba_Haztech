<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Tymon\JWTAuth\Facades\JWTAuth;

class AddressController
{
    public function addAddress(Request $request)
    {
        $data = $request->json()->all();

        // Safely extract and sanitize input
        $altPhone  = $data['Altphone'] ?? null;
        $address   = $data['address'] ?? null;
        $city      = $data['city'] ?? null;
        $firstName = $data['first_name'] ?? null;
        $landmark  = $data['landmark'] ?? null;
        $lastName  = $data['last_name'] ?? null;
        $locality  = $data['locality'] ?? null;
        $phone     = $data['phone'] ?? null;
        $pincode   = $data['pincode'] ?? null;
        $email     = $data['email'] ?? null;
        $token     = $data['token'] ?? null;
        $userId    = $data['customer_id'] ?? null;

        $state = 1484; // You may want to make this dynamic later

        // Check if any required data is missing
        if (!$address || !$city || !$firstName || !$lastName || !$phone || !$pincode || !$email || !$token || !$userId) {
            return response()->json(['error' => 'Missing required fields'], 400);
        }

        try {
            $userDetails = internalUserDetails($email);

            if ($userId == $userDetails->customer_id && $token == $userDetails->token) {
                $existingAddress = DB::table('oc_address')
                    ->where('customer_id', $userId)
                    ->where('address_1', $address)
                    ->where('postcode', $pincode)
                    ->count();

                if ($existingAddress === 0) {
                    DB::table('oc_address')->insert([
                        'customer_id'    => $userId,
                        'firstname'      => $firstName,
                        'lastname'       => $lastName,
                        'postcode'       => $pincode,
                        'zone_id'        => $state,
                        'city'           => $city,
                        'address_1'      => $address,
                        'address_2'      => $locality,
                        'shipping_phone' => $phone,
                        'landmark'       => $landmark,
                        'alt_number'     => $altPhone,
                    ]);

                    return response()->json(['address' => 'Added to address list']);
                }

                return response()->json(['address' => 'This address is already added by you']);
            }

            return response()->json(['error' => 'Invalid token or user ID']);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()]);
        }
    }


    // Function to list address
    public function addressList(Request $request)
    {
        $data = $request->input('userData');

        $id = $data['customer_id'] ?? null;
        $email = $data['email'] ?? null;
        $token = $data['token'] ?? null;

        if (!$id || !$email || !$token) {
            return response()->json(['error' => 'Missing credentials'], 400);
        }

        try {
            $userDetails = internalUserDetails($email);

            if ($id != $userDetails->customer_id || $token != $userDetails->token) {
                return response()->json(['error' => 'Unauthorized'], 401);
            }

            $addresses = DB::table('oc_address')
            ->where('customer_id', $id)
            ->select(
                'address_id as adrs_id',
                'customer_id',
                'firstname as f_name',
                'lastname as l_name',
                'address_1 as address',
                'city',
                'postcode as pin',
                'address_2',
                'shipping_phone',
                'landmark',
                'alt_number'
            )
            ->get();


            return response()->json(['address' => $addresses]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }


    // Function to list states
    public function stateList(Request $request)
    {
        $data = $request->input('userData');

        $id = $data['customer_id'];
        $email = $data['email'];
        $token = $data['token'];

        try {
            $userDetails = internalUserDetails($email);
            $ckId = $userDetails->customer_id;
            $ckToken = $userDetails->token;

            if ($id == $ckId && $token == $ckToken) {
                $states = DB::table('oc_zone')
                    ->where('country_id', 99)
                    ->get();

                return response()->json(['stateList' => $states]);
            } else {
                return response()->json(['error' => 'Invalid token or user ID']);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()]);
        }
    }

    private function internalUserDetails($email) {
        try {
            // Fetch customer details by email
            $customer = Customer::where('email', $email)->first();
    
            // Check if the customer exists
            if ($customer) {
                // Generate token (Assuming apiToken is a helper function)
                $customer->token = $this->apiToken($customer->customer_id);
                return $customer; // Return customer object with token
            } else {
                return null; // Return null if no customer is found
            }
        } catch (\Exception $e) {
            // Handle the exception and return null or error message
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function apiToken($userId) {
        // Get user by ID and generate token
        $user = \App\Models\Customer::find($userId);
        
        if ($user) {
            // Generate and return token
            return JWTAuth::fromUser($user);
        }
    
        return null;
    }
}
