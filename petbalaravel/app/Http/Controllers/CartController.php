<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Tymon\JWTAuth\Facades\JWTAuth;

class CartController
{
    public function cartProducts(Request $request)
{
    $data = json_decode($request->getContent());
    $userData = $data->userData;
    $id = $userData->customer_id;
    $email = $userData->email;
    $token = $userData->token;

    try {
        $userDetails = internalUserDetails($email);
        $customerId = $userDetails->customer_id;
        $userToken = $userDetails->token;

        if ($id == $customerId && $token == $userToken) {
            $sql = "
                SELECT 
                    p.product_id,
                    MIN(p.model) AS model,
                    MIN(pd.name) AS name,
                    MIN(pd.description) AS description,
                    MIN(p.quantity) AS quantity,
                    MIN(p.image) AS image,
                    MIN(p.price) AS price,
                    MIN(special.specialprice) AS specialprice,
                    MIN(dis.discount) AS discount,
                    MIN(cate.name) AS category,
                    MIN(oc_manufacturer.name) AS brand,
                    MIN(oc_cart.cart_id) AS cart_id,
                    MIN(oc_cart.quantity) AS cart_qty
                FROM oc_product AS p 
                INNER JOIN oc_product_description AS pd 
                    ON p.product_id = pd.product_id AND pd.language_id = 1
                LEFT JOIN (
                    SELECT c.product_id, MIN(b.name) AS name
                    FROM oc_category_description AS b 
                    INNER JOIN oc_product_to_category AS c ON c.category_id = b.category_id
                    WHERE b.language_id = 1
                    GROUP BY c.product_id
                ) AS cate ON p.product_id = cate.product_id 
                LEFT JOIN oc_manufacturer 
                    ON p.manufacturer_id = oc_manufacturer.manufacturer_id
                LEFT JOIN (
                    SELECT disc.product_id, MIN(disc.price) AS discount 
                    FROM oc_product_discount AS disc
                    WHERE DATE(disc.date_start) <= CURDATE() 
                      AND DATE(disc.date_end) >= CURDATE() 
                    GROUP BY disc.product_id
                ) AS dis ON p.product_id = dis.product_id 
                LEFT JOIN (
                    SELECT spel.product_id, MIN(spel.price) AS specialprice 
                    FROM oc_product_special AS spel
                    WHERE DATE(spel.date_start) <= CURDATE() 
                      AND DATE(spel.date_end) >= CURDATE() 
                    GROUP BY spel.product_id
                ) AS special ON p.product_id = special.product_id 
                INNER JOIN oc_cart 
                    ON p.product_id = oc_cart.product_id 
                WHERE oc_cart.customer_id = ?
                GROUP BY p.product_id 
                ORDER BY cart_id ASC
            ";

            $cartProducts = DB::select($sql, [$id]);

            if (!empty($cartProducts)) {
                return response()->json(['cartProducts' => $cartProducts]);
            } else {
                return response()->json(['cart' => 'No Data found']);
            }
        } else {
            return response()->json(['error' => 'Unauthorized access'], 403);
        }
    } catch (\Exception $e) {
        return response()->json(['error' => ['text' => $e->getMessage()]], 500);
    }
}

    // Mocked internalUserDetails method
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
    private function apiToken($userId) {
        // Get user by ID and generate token
        $user = \App\Models\Customer::find($userId);
        
        if ($user) {
            // Generate and return token
            return JWTAuth::fromUser($user);
        }
    
        return null;
    }

    public function addcart(Request $request)
    {
        $data = json_decode($request->getContent());
        $userData = $data->userData;
        $id = $userData->customer_id;
        $email = $userData->email;
        $token = $userData->token;
        $product_id = $userData->product_id;
        $qty = $userData->qty;

        try {
            // Fetch user details based on email
            $userDetails = internalUserDetails($email);
            $customerId = $userDetails->user_id;
            $userToken = $userDetails->token;

            if ($product_id !== null) {
                // Check if the product is already in the cart
                $existingProduct = DB::table('oc_cart')
                    ->where('product_id', $product_id)
                    ->where('customer_id', $id)
                    ->first();

                if (!$existingProduct) {
                    // Insert the product into the cart if not already added
                    DB::table('oc_cart')->insert([
                        'customer_id' => $id,
                        'product_id' => $product_id,
                        'quantity' => $qty
                    ]);

                    // Fetch cart total and return success message
                    $cartTotal = $this->cartTotal($id);
                    return response()->json([
                        'added' => 'added to cart',
                        'total' => $cartTotal
                    ]);
                } else {
                    // If the product is already in the cart
                    return response()->json([
                        'added' => 'product already added to cart'
                    ]);
                }
            } else {
                return response()->json(['error' => 'Invalid product ID'], 400);
            }
        } catch (\Exception $e) {
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
    
    public function deleteCartItem(Request $request)
    {
        $data = $request->input('userData');
        $customerId = $data['customer_id'];
        $email = $data['email'];
        $token = $data['token'];
        $cartId = $data['c_id'];

        try {
            // Fetch user details (validate user)
            $userDetails = internalUserDetails($email);
            $dbCustomerId = $userDetails->customer_id;
            $dbToken = $userDetails->token;

            if ($customerId == $dbCustomerId && $token == $dbToken) {
                // Check if the cart item belongs to the customer
                $cartItem = DB::table('oc_cart')
                    ->where('cart_id', $cartId)
                    ->first();

                if (!$cartItem) {
                    return response()->json(['error' => 'Cart item not found'], 404);
                }

                if ($cartItem->customer_id != $customerId) {
                    return response()->json(['error' => 'Unauthorized: Cart item does not belong to this customer'], 403);
                }

                // Delete the cart item
                DB::table('oc_cart')
                    ->where('cart_id', $cartId)
                    ->delete();

                return response()->json(['message' => 'Product removed from Cart']);
            } else {
                return response()->json(['error' => 'Unauthorized request'], 403);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

}