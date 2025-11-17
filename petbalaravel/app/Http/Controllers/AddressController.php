<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Tymon\JWTAuth\Facades\JWTAuth;

class AddressController
{
    public function addAddress(Request $request)
    {
        // Accept JSON or form-encoded input
        $data = $request->json()->all();
        if (empty($data)) {
            $data = $request->all();
        }

        // Safely extract and sanitize input
        $altPhone  = $data['Altphone'] ?? null;
        $address   = $data['address'] ?? null;
        $city      = $data['city'] ?? null;
        $firstName = $data['first_name'] ?? null;
        $landmark  = $data['landmark'] ?? null;
        $company   = $data['company'] ?? null;
        $customField = $data['custom_field'] ?? null;
        $lastName  = $data['last_name'] ?? null;
        $locality  = $data['locality'] ?? null;
        $phone     = $data['phone'] ?? null;
        $pincode   = $data['pincode'] ?? null;
        $email     = $data['email'] ?? null;
        $token     = $data['token'] ?? null;
        $userId    = $data['customer_id'] ?? null;
        $state     = $data['state'] ?? null;
        $country   = $data['country'] ?? 'India';

        // Check if any required data is missing
        if (
            !$address ||
            !$city ||
            !$firstName ||
            !$lastName ||
            !$phone ||
            !$pincode ||
            !$email ||
            !$token ||
            !$userId ||
            !$state ||
            !$country
        ) {
            return response()->json(['error' => 'Missing required fields'], 400);
        }

        try {
            $userDetails = $this->internalUserDetails($email);

            if (!$userDetails) {
                return response()->json(['error' => 'User not found'], 404);
            }

            // The app uses a simple base64 token stored in the `token` column (not JWT).
            // Verify token by direct string comparison with the stored token on the customer record.
            if ($token === ($userDetails->token ?? null) && (string)$userId === (string)($userDetails->customer_id ?? '')) {
                $existingAddress = DB::table('oc_address')
                    ->where('customer_id', $userId)
                    ->where('address_1', $address)
                    ->where('postcode', $pincode)
                    ->count();

                if ($existingAddress === 0) {
                    $zoneId = $this->resolveZoneId($state);
                    $countryId = $this->resolveCountryId($country);

                    DB::table('oc_address')->insert([
                        'company'        => $company ?? '',
                        'custom_field'   => $customField ?? '',
                        'customer_id'    => $userId,
                        'firstname'      => $firstName,
                        'lastname'       => $lastName,
                        'postcode'       => $pincode,
                        'zone_id'        => $zoneId,
                        'country_id'     => $countryId,
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

            // Join with oc_country to fetch country name via country_id
            $addresses = DB::table('oc_address as a')
            ->leftJoin('oc_country as c', 'a.country_id', '=', 'c.country_id')
            ->where('a.customer_id', $id)
                ->select(
                'a.address_id as adrs_id',
                'a.customer_id',
                'a.company',
                'a.custom_field',
                'a.firstname as f_name',
                'a.lastname as l_name',
                'a.address_1 as address',
                'a.city',
                'a.postcode as pin',
                'a.address_2',
                'a.shipping_phone',
                'a.landmark',
                'a.alt_number',
                'a.country_id',
                'c.name as country'
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
            return Customer::where('email', $email)->first();
        } catch (\Exception $e) {
            return null;
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

    private function resolveZoneId(?string $stateName): int
    {
        if (!$stateName) {
            return 0;
        }

        $zone = DB::table('oc_zone')
            ->where('name', $stateName)
            ->orWhere('code', $stateName)
            ->first();

        return $zone->zone_id ?? 0;
    }

    private function resolveCountryId(?string $countryName): int
    {
        if (!$countryName) {
            return 0;
        }

        $country = DB::table('oc_country')
            ->where('name', $countryName)
            ->orWhere('iso_code_2', $countryName)
            ->orWhere('iso_code_3', $countryName)
            ->first();

        return $country->country_id ?? 0;
    }
}
