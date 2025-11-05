<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Tymon\JWTAuth\Facades\JWTAuth;

class WishlistController
{
    public function wishlist(Request $request)
    {
        $data = $request->input('userData');
        $id = $data['customer_id'] ?? null;
        $email = $data['email'] ?? null;
        $token = $data['token'] ?? null;

        if (!$id || !$email || !$token) {
            return response()->json(['error' => 'Missing credentials'], 400);
        }

        $out = internalUserDetails($email);

        if ($id != $out->customer_id || $token != $out->token) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        $productIds = DB::table('oc_customer_wishlist')
            ->where('customer_id', $id)
            ->pluck('product_id');

        if ($productIds->isEmpty()) {
            return response()->json(['wishProducts' => [], 'total' => 0]);
        }

        $products = DB::table('oc_product as p')
            ->join('oc_product_description as pd', function ($join) {
                $join->on('p.product_id', '=', 'pd.product_id')
                    ->where('pd.language_id', '=', 1); // adjust language_id
            })
            ->leftJoin('oc_product_to_category as pc', 'p.product_id', '=', 'pc.product_id')
            ->leftJoin('oc_category_description as cd', function ($join) {
                $join->on('pc.category_id', '=', 'cd.category_id')
                    ->where('cd.language_id', '=', 1); // adjust language_id
            })
            ->leftJoin('oc_manufacturer', 'p.manufacturer_id', '=', 'oc_manufacturer.manufacturer_id')
            ->leftJoin(DB::raw('
                (SELECT product_id, MIN(price) as discount
                FROM oc_product_discount
                WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
                GROUP BY product_id) as dis
            '), 'p.product_id', '=', 'dis.product_id')
            ->leftJoin(DB::raw('
                (SELECT product_id, MIN(price) as specialprice
                FROM oc_product_special
                WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
                GROUP BY product_id) as special
            '), 'p.product_id', '=', 'special.product_id')
            ->whereIn('p.product_id', $productIds)
            ->select(
                'p.product_id',
                'p.model',
                'pd.name',
                'pd.description',
                'p.quantity',
                'p.image',
                'p.price',
                'special.specialprice',
                'dis.discount',
                'cd.name as category',
                'oc_manufacturer.name as brand'
            )
            ->get();

        $cartTotal = $this->cartTotal($id);

        return response()->json([
            'wishProducts' => $products,
            'total' => $cartTotal,
        ]);
    }



   public function makewish(Request $request)
    {
        $data = $request->input('userData');

        $id = $data['customer_id'] ?? null;
        $email = $data['email'] ?? null;
        $token = $data['token'] ?? null;
        $product_id = $data['product_id'] ?? null;

        if (!$id || !$email || !$token || !$product_id) {
            return response()->json(['error' => 'Missing required fields'], 400);
        }

        $out = internalUserDetails($email);

        if ($id != $out->customer_id || $token != $out->token) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        $exists = DB::table('oc_customer_wishlist')
            ->where('product_id', $product_id)
            ->where('customer_id', $id)
            ->exists();

        if (!$exists) {
            DB::table('oc_customer_wishlist')->insert([
                'customer_id' => $id,
                'product_id' => $product_id,
                'date_added' => now(), // Recommended to track
            ]);

            return response()->json(['message' => 'Added to wishlist'], 201);
        }

        return response()->json(['message' => 'Product already in wishlist'], 200);
    }


    public function deleteWishedItem(Request $request)
    {
        $data = $request->input('userData');

        // Safely extract data
        $customerId = $data['customer_id'] ?? null;
        $email = $data['email'] ?? null;
        $token = $data['token'] ?? null;
        $productId = $data['product_id'] ?? null;

        // Validate inputs
        if (!$customerId || !$email || !$token || !$productId) {
            return response()->json(['error' => 'Missing required fields'], 400);
        }

        // Authenticate user
        $user = internalUserDetails($email);
        if (!$user || $user->customer_id != $customerId || $user->token != $token) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        // Delete item from wishlist
        $deleted = DB::table('oc_customer_wishlist')
            ->where('customer_id', $customerId)
            ->where('product_id', $productId)
            ->delete();

        if ($deleted) {
            return response()->json(['message' => 'Product removed from wishlist'], 200);
        } else {
            return response()->json(['message' => 'Product not found in wishlist'], 404);
        }
    }


    public function searchItems(Request $request)
    {
        $data = $request->input('userData');

        // Check if userData exists
        if (!$data) {
            return response()->json(['error' => 'No userData provided'], 400);
        }

        $customerId = $data['customer_id'] ?? null;
        $email = $data['email'] ?? null;
        $token = $data['token'] ?? null;
        $search = $data['search'] ?? '';
        $lastCreated = $data['lastCreated'] ?? null;

        // Validate essential fields
        if (!$customerId || !$email || !$token || !$search) {
            return response()->json(['error' => 'Missing required fields'], 400);
        }

        // Authenticate user
        $user = internalUserDetails($email);
        if (!$user) {
            return response()->json(['error' => 'User not found'], 404);
        }

        if ($user->customer_id != $customerId || $user->token != $token) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            // Prepare the base query
            $query = DB::table('oc_product as p')
        ->leftJoin('oc_product_description as pd', 'p.product_id', '=', 'pd.product_id')
        ->leftJoin('oc_product_to_category as pc', 'p.product_id', '=', 'pc.product_id')
        ->leftJoin('oc_category_description as cd', 'pc.category_id', '=', 'cd.category_id')
        ->leftJoin('oc_manufacturer as m', 'p.manufacturer_id', '=', 'm.manufacturer_id')
        ->leftJoin(DB::raw("(
            SELECT product_id, MIN(price) as discount
            FROM oc_product_discount
            WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
            GROUP BY product_id
        ) as dis"), 'p.product_id', '=', 'dis.product_id')
        ->leftJoin(DB::raw("(
            SELECT product_id, MIN(price) as specialprice
            FROM oc_product_special
            WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
            GROUP BY product_id
        ) as special"), 'p.product_id', '=', 'special.product_id')
        ->where('p.status', 1)
        ->where('p.quantity', '>', 0)
        ->where(function ($q) use ($search) {
            $q->where('pd.name', 'like', '%' . $search . '%')
            ->orWhere('p.model', 'like', '%' . $search . '%');
        });


            // Pagination logic based on product_id
            if (!empty($lastCreated)) {
                $query->where('p.product_id', '>', $lastCreated);
            }

            $products = $query->select(
                    'p.product_id',
                    'p.model',
                    'pd.name',
                    'pd.description',
                    'p.quantity',
                    'p.image',
                    'p.price',
                    'special.specialprice',
                    'dis.discount',
                    'cd.name as category',
                    'm.name as brand'
                )
                ->orderBy('p.product_id')
                ->limit(5)
                ->get();

            if ($products->isEmpty()) {
                return response()->json(['message' => 'No products found for this search']);
            }

            $cartTotal = $this->cartTotal($customerId);

            return response()->json([
                'searchitems' => $products,
                'total' => $cartTotal
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => 'Server error: ' . $e->getMessage()], 500);
        }
    }



    // Helper methods
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

    public function cartTotal($customerId)
    {
        try {
            // Query to count total items in the customer's cart
            $total = DB::table('oc_cart')
                ->where('customer_id', $customerId)
                ->count();

            return response()->json([
                'total' => $total
            ]);
        } catch (\Exception $e) {
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
