<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Product;
use App\Models\Wishlist;
use App\Models\Cart;
use App\Models\Customer;
use Tymon\JWTAuth\Facades\JWTAuth;

class ProductController 
{
    public function productDetails(Request $request)
    {
        $data = json_decode($request->getContent());
        $e = $data->userData;
        $id = $e->customer_id;
        $email = $e->email;
        $token = $e->token;
        $product_id = $e->product_id;

        try {
            $out = internalUserDetails($email);
            $ck_id = $out->customer_id;
            $ck_tkn = $out->token;

            if ($id == $ck_id && $token == $ck_tkn) {
                // Basic product fetch
                $product = DB::table('oc_product as p')
                    ->select('p.product_id', 'p.model', 'p.quantity', 'p.image', 'p.price', 'pd.name', 'pd.description')
                    ->join('oc_product_description as pd', function ($join) {
                        $join->on('p.product_id', '=', 'pd.product_id')
                            ->where('pd.language_id', 1);
                    })
                    ->where('p.product_id', $product_id)
                    ->where('p.status', 1)
                    ->first();

                if (!$product) {
                    return response()->json(['error' => 'Product not found']);
                }

                $product->description = html_entity_decode($product->description);

                return response()->json([
                    'proDetails' => $product
                ]);
            } else {
                return response()->json(['error' => 'Unauthorized'], 401);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }


    private function internalUserDetails($email) {
    try {
        $customer = Customer::where('email', $email)->first();

            if ($customer) {
                $customer->token = $this->apiToken($customer->customer_id);
                return $customer;
            } else {
                return null;
            }
        } catch (\Exception $e) {
            // Log the error and return null to avoid JsonResponse issues
            \Log::error('internalUserDetails error: ' . $e->getMessage());
            return null;
        }
    }


    private function productImg($productId) {
        return DB::table('oc_product_image')->where('product_id', $productId)->get();
    }

    private function productfeatures($productId) {
        return DB::table('oc_product_attribute as pa')
            ->join('oc_attribute_description as ad', 'pa.attribute_id', '=', 'ad.attribute_id')
            ->where('pa.product_id', $productId)
            ->get();
    }

    private function relatedproduct($productId) {
        return Product::select('p.product_id', 'p.model', 'pd.name', 'pd.description', 'p.quantity', 'p.image', 'p.price', 'cate.name as cate', 'oc_manufacturer.name as brand')
            ->from('oc_product as p')
            ->join('oc_product_description as pd', 'p.product_id', '=', 'pd.product_id')
            ->join(
                DB::raw('(SELECT c.product_id, b.name FROM oc_category_description as b INNER JOIN oc_product_to_category as c on c.category_id=b.category_id) as cate'),
                'p.product_id', '=', 'cate.product_id'
            )
            ->join('oc_manufacturer', 'p.manufacturer_id', '=', 'oc_manufacturer.manufacturer_id')
            ->whereIn('p.product_id', function($query) use ($productId) {
                $query->select('related_id')
                      ->from('oc_product_related')
                      ->where('product_id', $productId);
            })
            ->where('p.status', 1)
            ->where('p.quantity', '>', 0)
            ->groupBy('p.product_id')
            ->get();
    }

    public function cartTotal($input)
    {
        try {
            $sql = "SELECT count(*) as total FROM `oc_cart` WHERE customer_id = :id";
            $result = DB::select($sql, ['id' => $input]);

            return $result[0] ?? null;  // Fetch the first result as an object
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

    public function latestProduct()
    {
        try {
            $latestProducts = DB::table('oc_product as p')
                ->select(
                    'p.product_id',
                    'p.model',
                    'pd.name',
                    'pd.description',
                    'p.quantity',
                    'p.image',
                    'p.price',
                    'sp.price as specialprice',
                    'd.price as discount',
                    DB::raw('GROUP_CONCAT(DISTINCT cd.name SEPARATOR ", ") as categories'),
                    'm.name as brand'
                )
                ->leftjoin('oc_product_description as pd', 'p.product_id', '=', 'pd.product_id')
                ->leftjoin('oc_product_to_category as pc', 'p.product_id', '=', 'pc.product_id')
                ->leftjoin('oc_category as c', function ($join) {
                    $join->on('pc.category_id', '=', 'c.category_id')
                        ->where('c.status', '=', 1);
                })
                ->leftjoin('oc_category_description as cd', 'c.category_id', '=', 'cd.category_id')
                ->leftjoin('oc_manufacturer as m', 'p.manufacturer_id', '=', 'm.manufacturer_id')
                ->leftJoin(DB::raw('(
                    SELECT product_id, price
                    FROM oc_product_special
                    WHERE CURDATE() BETWEEN date_start AND date_end
                    ORDER BY priority ASC, price ASC
                ) as sp'), 'p.product_id', '=', 'sp.product_id')
                ->leftJoin(DB::raw('(
                    SELECT product_id, price
                    FROM oc_product_discount
                    WHERE CURDATE() BETWEEN date_start AND date_end
                    ORDER BY priority ASC, price ASC
                ) as d'), 'p.product_id', '=', 'd.product_id')
                ->where('p.status', 1)
                ->where('p.quantity', '>', 0)
                ->groupBy([
                    'p.product_id', 'p.model', 'pd.name', 'pd.description', 'p.quantity',
                    'p.image', 'p.price', 'sp.price', 'd.price', 'm.name'
                ])
                ->orderByDesc('p.product_id')
                // ->limit(10)
                ->get();

            return response()->json(['latestproduct' => $latestProducts]);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]]);
        }
    }



    // Featured ID
    public function featuredpro()
    {
        try {
            // Using query builder to get the 'setting' column where module_id = 32
            $result = DB::table('oc_module')
                ->select('setting')
                ->where('module_id', 32)
                ->first();

            if (!$result) {
                return response()->json(['error' => 'Module not found'], 404);
            }

            // Decode the JSON string from the 'setting' column
            $settings = json_decode($result->setting, true);

            // Return the decoded settings
            return response()->json(['featuredProductsSettings' => $settings]);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]]);
        }
    }


    // Featured Products
    public function featuredproducts(Request $request)
    {
        // Expecting an array of product IDs from the request input
        $productIds = $request->input('product'); // e.g. [71, 52, 61]

        // Validate input to make sure it's an array and not empty
        if (!is_array($productIds) || empty($productIds)) {
            return response()->json(['error' => 'Invalid product IDs provided'], 400);
        }

        try {
            $featuredProducts = DB::table('oc_product as p')
                ->select(
                    'p.product_id',
                    'p.model',
                    'pd.name',
                    'pd.description',
                    'p.quantity',
                    'p.image',
                    'p.price',
                    'sp.price as specialprice',
                    'd.price as discount',
                    'cd.name as category',
                    'm.name as brand'
                )
                ->leftjoin('oc_product_description as pd', 'p.product_id', '=', 'pd.product_id')
                ->leftjoin('oc_product_to_category as pc', 'p.product_id', '=', 'pc.product_id')
                ->leftjoin('oc_category as c', function ($join) {
                    $join->on('pc.category_id', '=', 'c.category_id')
                        ->where('c.status', '=', 1);
                })
                ->leftjoin('oc_category_description as cd', 'c.category_id', '=', 'cd.category_id')
                ->leftjoin('oc_manufacturer as m', 'p.manufacturer_id', '=', 'm.manufacturer_id')
                ->leftJoin(DB::raw('(
                    SELECT product_id, price 
                    FROM oc_product_special 
                    WHERE CURDATE() BETWEEN date_start AND date_end 
                    ORDER BY priority ASC, price ASC
                ) as sp'), 'p.product_id', '=', 'sp.product_id')
                ->leftJoin(DB::raw('(
                    SELECT product_id, price 
                    FROM oc_product_discount 
                    WHERE CURDATE() BETWEEN date_start AND date_end 
                    ORDER BY priority ASC, price ASC
                ) as d'), 'p.product_id', '=', 'd.product_id')
                ->whereIn('p.product_id', $productIds)
                ->where('p.status', 1)
                ->where('p.quantity', '>', 0)
                ->orderBy('p.product_id')
                ->limit(5)
                ->get();

            return response()->json(['featuredproducts' => $featuredProducts]);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]]);
        }
    }

    public function featuredproductsList(Request $request)
    {
        $productIds = $request->input('product'); // expects: [71, 52, 61]
        $lastCreated = $request->input('lastCreated'); // optional: e.g. 100

        if (!is_array($productIds) || empty($productIds)) {
            return response()->json(['error' => 'Invalid product IDs provided'], 400);
        }

        try {
            DB::enableQueryLog();

            $query = DB::table('oc_product as p')
                ->select(
                    'p.product_id',
                    'p.model',
                    'p.quantity',
                    'p.image',
                    'p.price',
                    'pd.name',
                    'pd.description',
                    'm.name as brand'
                )
                ->leftjoin('oc_product_description as pd', function ($join) {
                    $join->on('p.product_id', '=', 'pd.product_id');
                })
                ->leftjoin('oc_manufacturer as m', 'p.manufacturer_id', '=', 'm.manufacturer_id')
                ->whereIn('p.product_id', $productIds)
                ->where('p.status', 1)
                ->where('p.quantity', '>', 0);

            if (!is_null($lastCreated)) {
                $query->where('p.product_id', '>', $lastCreated)
                    ->orderBy('p.product_id', 'asc');
            } else {
                $query->orderBy('p.product_id', 'asc');
            }

            $featuredProducts = $query->limit(6)->get();

            \Log::info(DB::getQueryLog());

            return response()->json(['featuredproducts' => $featuredProducts]);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function specialProductList()
    {
        try {
            $specialProducts = DB::table('oc_product as p')
                ->select(
                    'p.product_id',
                    'p.model',
                    'pd.name',
                    'pd.description',
                    'p.quantity',
                    'p.image',
                    'p.price',
                    'sp.price as specialprice',
                    'd.price as discount',
                    'cd.name as category',
                    'm.name as brand'
                )
                ->join('oc_product_description as pd', 'p.product_id', '=', 'pd.product_id')
                ->join('oc_product_to_category as pc', 'p.product_id', '=', 'pc.product_id')
                ->join('oc_category as c', 'pc.category_id', '=', 'c.category_id')
                ->join('oc_category_description as cd', 'c.category_id', '=', 'cd.category_id')
                ->join('oc_manufacturer as m', 'p.manufacturer_id', '=', 'm.manufacturer_id')
                ->leftJoin(DB::raw('(
                    SELECT product_id, price 
                    FROM oc_product_special 
                    ORDER BY priority ASC, price ASC
                ) as sp'), 'p.product_id', '=', 'sp.product_id')
                ->leftJoin(DB::raw('(
                    SELECT product_id, price 
                    FROM oc_product_discount 
                    ORDER BY priority ASC, price ASC
                ) as d'), 'p.product_id', '=', 'd.product_id')
                ->where(function ($query) {
                    $query->whereNotNull('sp.price')
                        ->orWhereNotNull('d.price');
                })
                ->where('p.status', 1)
                ->where('p.quantity', '>', 0)
                ->orderBy('p.product_id')
                ->limit(10)
                ->get();

            return response()->json(['special' => $specialProducts->isNotEmpty() ? $specialProducts : '']);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }



    public function getLowerHigher(Request $request)
{
    $ids = $request->input('id'); // expects an array of product IDs like [1, 2, 3]

    if (!is_array($ids) || empty($ids)) {
        return response()->json(['error' => 'No valid product IDs provided'], 400);
    }

    try {
        $priceRange = DB::table('oc_product')
            ->whereIn('product_id', $ids)
            ->selectRaw('MAX(price) as highest, MIN(price) as lowest')
            ->first();

        return response()->json(['data' => $priceRange]);

    } catch (\Exception $e) {
        return response()->json(['error' => ['text' => $e->getMessage()]]);
    }
}

    /**
     * Get products filtered by filter IDs
     */
    public function filteredProducts(Request $request)
    {
        try {
            $data = $request->json()->all();
            $filterIds = $data['filter_ids'] ?? [];

            if (empty($filterIds) || !is_array($filterIds)) {
                return response()->json(['error' => 'filter_ids array is required'], 400);
            }

            // Get product IDs that have any of the selected filters
            $productIds = DB::table('oc_product_filter')
                ->whereIn('filter_id', $filterIds)
                ->distinct()
                ->pluck('product_id');

            if ($productIds->isEmpty()) {
                return response()->json(['products' => []]);
            }

            // Get products with same structure as latestProduct
            $filteredProducts = DB::table('oc_product as p')
                ->select(
                    'p.product_id',
                    'p.model',
                    'pd.name',
                    'pd.description',
                    'p.quantity',
                    'p.image',
                    'p.price',
                    'sp.price as specialprice',
                    'd.price as discount',
                    DB::raw('GROUP_CONCAT(DISTINCT cd.name SEPARATOR ", ") as categories'),
                    'm.name as brand'
                )
                ->leftjoin('oc_product_description as pd', function ($join) {
                    $join->on('p.product_id', '=', 'pd.product_id')
                        ->where('pd.language_id', 1);
                })
                ->leftjoin('oc_product_to_category as pc', 'p.product_id', '=', 'pc.product_id')
                ->leftjoin('oc_category as c', function ($join) {
                    $join->on('pc.category_id', '=', 'c.category_id')
                        ->where('c.status', '=', 1);
                })
                ->leftjoin('oc_category_description as cd', function ($join) {
                    $join->on('c.category_id', '=', 'cd.category_id')
                        ->where('cd.language_id', 1);
                })
                ->leftjoin('oc_manufacturer as m', 'p.manufacturer_id', '=', 'm.manufacturer_id')
                ->leftJoin(DB::raw('(
                    SELECT product_id, price
                    FROM oc_product_special
                    WHERE CURDATE() BETWEEN date_start AND date_end
                    ORDER BY priority ASC, price ASC
                ) as sp'), 'p.product_id', '=', 'sp.product_id')
                ->leftJoin(DB::raw('(
                    SELECT product_id, price
                    FROM oc_product_discount
                    WHERE CURDATE() BETWEEN date_start AND date_end
                    ORDER BY priority ASC, price ASC
                ) as d'), 'p.product_id', '=', 'd.product_id')
                ->whereIn('p.product_id', $productIds)
                ->where('p.status', 1)
                ->groupBy([
                    'p.product_id', 'p.model', 'pd.name', 'pd.description', 'p.quantity',
                    'p.image', 'p.price', 'sp.price', 'd.price', 'm.name'
                ])
                ->orderByDesc('p.product_id')
                ->get();

            return response()->json(['products' => $filteredProducts]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch filtered products',
                'message' => $e->getMessage()
            ], 500);
        }
    }

}
