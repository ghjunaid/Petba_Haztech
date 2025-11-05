<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Support\Facades\DB;

class CategoryController
{
    public function category(Request $request)
    {
        $userData = $request->input('userData');
        $id = $userData['customer_id'];
        $email = $userData['email'];
        $token = $userData['token'];

        try {
            $out = internalUserDetails($email); // Assuming you will provide this helper function
            $ck_id = $out->customer_id;
            $ck_tkn = $out->token;

            if ($id == $ck_id && $token == $ck_tkn) {
                $categories = DB::table('oc_category as c')
                    ->join('oc_category_description as cd', 'c.category_id', '=', 'cd.category_id')
                    ->select('c.category_id as c_id', 'cd.name as c_name', 'c.parent_id', 'c.sort_order as sort')
                    ->where('c.status', 1)
                    ->orderBy('c.sort_order', 'DESC')
                    ->get();

                $f = cartTotal($id); // Assuming you will provide this helper function
                return response()->json(['category' => $categories, 'total' => $f]);
            } else {
                return response()->json(['error' => 'Invalid user credentials'], 401);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function categoryProducts(Request $request)
    {
        $userData = $request->input('userData');
        $id = $userData['customer_id'];
        $email = $userData['email'];
        $token = $userData['token'];
        $cate_id = $userData['cate_id'];
        $lastCreated = (int)$userData['lastCreated'];
        $filters = $userData['filters'] ?? [];
        $price = $userData['price'] ?? ['lower' => null, 'upper' => null];
        $sort = $userData['sort'] ?? [];
        $sortColumn = $sort['column'] ?? 'product_id';
        $sortDirection = $sort['direction'] ?? 'asc';

        try {
            $out = internalUserDetails($email);
            $ck_id = $out->customer_id;
            $ck_tkn = $out->token;

            if ($id == $ck_id && $token == $ck_tkn) {
                $query = Product::select(
                    'oc_product.product_id',
                    'oc_product.model',
                    'oc_product_description.name',
                    'oc_product_description.description',
                    'oc_product.quantity',
                    'oc_product.image',
                    'oc_product.price'
                )
                ->join('oc_product_description', function ($join) {
                    $join->on('oc_product.product_id', '=', 'oc_product_description.product_id')
                        ->where('oc_product_description.language_id', 1);
                })
                ->join('oc_product_to_category', 'oc_product.product_id', '=', 'oc_product_to_category.product_id')
                ->where('oc_product_to_category.category_id', $cate_id)
                ->where('oc_product.status', 1)
                ->where('oc_product.quantity', '>', 0);

                if (!is_null($price['lower']) && !is_null($price['upper'])) {
                    $query->whereBetween('oc_product.price', [$price['lower'], $price['upper']]);
                }

                // Filter by Color option, use leftJoin + where to avoid excluding products
                if (!empty($filters['color'])) {
                    $query->leftJoin('oc_product_option_value as pov_color', 'oc_product.product_id', '=', 'pov_color.product_id')
                        ->leftJoin('oc_option_value as ov_color', 'pov_color.option_value_id', '=', 'ov_color.option_value_id')
                        ->leftJoin('oc_option_value_description as ovd_color', function($join) {
                            $join->on('ov_color.option_value_id', '=', 'ovd_color.option_value_id')
                                ->where('ovd_color.language_id', 1);
                        })
                        ->leftJoin('oc_option_description as od_color', function($join) {
                            $join->on('ov_color.option_id', '=', 'od_color.option_id')
                                ->where('od_color.language_id', 1);
                        })
                        ->where('od_color.name', 'Color')
                        ->where('ovd_color.name', $filters['color']);
                }

                // Filter by Size option, similarly
                if (!empty($filters['size'])) {
                    $query->leftJoin('oc_product_option_value as pov_size', 'oc_product.product_id', '=', 'pov_size.product_id')
                        ->leftJoin('oc_option_value as ov_size', 'pov_size.option_value_id', '=', 'ov_size.option_value_id')
                        ->leftJoin('oc_option_value_description as ovd_size', function($join) {
                            $join->on('ov_size.option_value_id', '=', 'ovd_size.option_value_id')
                                ->where('ovd_size.language_id', 1);
                        })
                        ->leftJoin('oc_option_description as od_size', function($join) {
                            $join->on('ov_size.option_id', '=', 'od_size.option_id')
                                ->where('od_size.language_id', 1);
                        })
                        ->where('od_size.name', 'Size')
                        ->where('ovd_size.name', $filters['size']);
                }

                $products = $query
                    ->orderBy("oc_product.$sortColumn", $sortDirection)
                    ->offset($lastCreated)
                    ->limit(8)
                    ->get();

                $f = cartTotal($id);
                return response()->json(['categoryProducts' => $products, 'total' => $f]);
            } else {
                return response()->json(['error' => 'Invalid user credentials'], 401);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

}
