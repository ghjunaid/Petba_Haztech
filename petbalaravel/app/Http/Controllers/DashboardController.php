<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\BannerController;
use Exception;
use Illuminate\Http\Client\Request as ClientRequest;
use Illuminate\Support\Facades\Request as FacadesRequest;
use App\Models\Adopt;
use App\Models\AdoptImage;

class DashboardController
{
    public function dashboard(Request $request)
    {
        $data = $request->json()->all();
        $city_id = $data['city_id'];
        $userData = $data['userData'];
        $customer_id = $userData['customer_id'];
        $email = $userData['email'];
        $token = $userData['token'];

        try {
            $banner = $this->imageBanner();
            $latest = $this->latestProduct();
            $cart = $this->cartTotal($customer_id);
            $featured = $this->featuredProducts();
            $discount = $this->discountPrice();
            $rescueHome = $this->rescueListHome($city_id);
            $adoption = $this->adoptionListHome($city_id);
            $bannerImg = $this->imageBanner();

            return response()->json([
                'banner' => $banner,
                'featured' => $featured,
                'latest' => $latest,
                'total' => $cart,
                'special' => $discount,
                'rescueListhome' => $rescueHome,
                'adoption' => $adoption,
                'imageBanner' => $bannerImg
            ]);
        } catch (Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]]);
        }
    }

    public function imageBanner()
    {
        try {
            return DB::table('banner_product')->get();
        } catch (\Exception $e) {
            return ['error' => ['text' => $e->getMessage()]];
        }
    }

    private function latestProduct()
    {
        DB::statement("SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''))");
        try {
            $latestProducts = DB::table('oc_product as p')
                ->join('oc_product_description as pd', 'p.product_id', '=', 'pd.product_id')
                ->join('oc_product_to_category as ptc', 'p.product_id', '=', 'ptc.product_id')
                ->join('oc_category as c', 'ptc.category_id', '=', 'c.category_id')
                ->join('oc_category_description as cd', 'cd.category_id', '=', 'c.category_id')
                ->join('oc_manufacturer as m', 'p.manufacturer_id', '=', 'm.manufacturer_id')
                
                // Subquery for discount
                ->leftJoin(DB::raw('(
                    SELECT product_id, MIN(price) AS discount
                    FROM oc_product_discount
                    WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
                    GROUP BY product_id
                ) as dis'), 'p.product_id', '=', 'dis.product_id')

                // Subquery for special price
                ->leftJoin(DB::raw('(
                    SELECT product_id, MIN(price) AS specialprice
                    FROM oc_product_special
                    WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
                    GROUP BY product_id
                ) as special'), 'p.product_id', '=', 'special.product_id')

                ->where('p.status', 1)
                ->where('p.quantity', '>', 0)
                ->where('c.status', 1)

                ->groupBy('p.product_id')
                ->orderBy('p.product_id', 'DESC')
                ->limit(10)

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
                    'm.name as brand'
                )
                ->get();

            return response()->json(['latestproduct' => $latestProducts]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function cartTotal($customerId)
    {
        try {
            // Query to count the total number of items in the cart for the given customer ID
            $total = DB::table('oc_cart')
                ->where('customer_id', $customerId)
                ->count();
    
            // Return the result as a JSON response
            return response()->json(['total' => $total]);
        } catch (\Exception $e) {
            // Error handling: return the error message as a JSON response
            return response()->json(['error' => ['text' => $e->getMessage()]]);
        }
    }

    public function featuredProducts()
    {
        // Query oc_module table for featured module settings
        $module = DB::table('oc_module')
            ->where('code', 'featured')
            ->first();

        // Check if module exists
        if (!$module) {
            return response()->json(['error' => 'Featured module not found'], 404);
        }

        // Decode JSON settings
        $settings = json_decode($module->setting, true);

        // Check if settings contain product array
        if (!isset($settings['product']) || !is_array($settings['product'])) {
            return response()->json(['error' => 'No featured products configured'], 400);
        }

        // Get product IDs and convert to integers
        $ids = array_map('intval', $settings['product']);

        // Return error if no products specified
        if (empty($ids)) {
            return response()->json(['error' => 'No featured products specified'], 400);
        }

        try {
            $products = DB::table('oc_product as p')
                ->join('oc_product_description as pd', 'p.product_id', '=', 'pd.product_id')
                ->join('oc_product_to_category as ptc', 'p.product_id', '=', 'ptc.product_id')
                ->join('oc_category_description as cate', 'ptc.category_id', '=', 'cate.category_id')
                ->join('oc_manufacturer', 'p.manufacturer_id', '=', 'oc_manufacturer.manufacturer_id')

                // Subquery for discount prices
                ->leftJoin(DB::raw('(
                    SELECT product_id, MIN(price) AS discount
                    FROM oc_product_discount
                    WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
                    GROUP BY product_id
                ) as dis'), 'p.product_id', '=', 'dis.product_id')

                // Subquery for special prices
                ->leftJoin(DB::raw('(
                    SELECT product_id, MIN(price) AS specialprice
                    FROM oc_product_special
                    WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
                    GROUP BY product_id
                ) as special'), 'p.product_id', '=', 'special.product_id')

                ->whereIn('p.product_id', $ids)
                ->where('p.status', 1)
                ->where('p.quantity', '>', 0)
                ->groupBy('p.product_id')
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
                    'cate.name as category',
                    'oc_manufacturer.name as brand'
                )
                ->orderBy('p.product_id')
                ->limit(5)
                ->get();

            return response()->json(['featuredproducts' => $products]);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }






    public function discountPrice()
    {
        try {
            $products = DB::table('oc_product as p')
                ->join('oc_product_description as pd', 'p.product_id', '=', 'pd.product_id')
                ->join('oc_product_to_category as ptc', 'p.product_id', '=', 'ptc.product_id')
                ->join('oc_category_description as cate', 'ptc.category_id', '=', 'cate.category_id')
                ->join('oc_manufacturer', 'p.manufacturer_id', '=', 'oc_manufacturer.manufacturer_id')

                // Subquery for discounts
                ->leftJoin(DB::raw('(
                    SELECT product_id, MIN(price) AS discount
                    FROM oc_product_discount
                    WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
                    GROUP BY product_id
                ) as dis'), 'p.product_id', '=', 'dis.product_id')

                // Subquery for special prices
                ->leftJoin(DB::raw('(
                    SELECT product_id, MIN(price) AS specialprice
                    FROM oc_product_special
                    WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
                    GROUP BY product_id
                ) as special'), 'p.product_id', '=', 'special.product_id')

                // Where condition for products with special prices
                ->whereIn('p.product_id', function ($query) {
                    $query->select(DB::raw('product_id'))
                        ->from(DB::raw('(
                            SELECT product_id
                            FROM oc_product_special
                            WHERE DATE(date_start) <= CURDATE() AND DATE(date_end) >= CURDATE()
                            GROUP BY product_id
                        ) as spel'));
                })

                ->where('p.status', 1)
                ->where('p.quantity', '>', 0)

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
                    'cate.name as category',
                    'oc_manufacturer.name as brand'
                )

                ->orderBy('p.product_id')
                ->limit(10)
                ->get();

            return response()->json(['discountedproducts' => $products]);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function rescueListHome($city_id)
    {
        try {
            $query = DB::table('rescuepet as r')
                ->select(
    'r.id',
    'r.img1',
    'r.img2',
    'r.img3',
    'r.img4',
    'r.img5',
    'r.img6',
    'r.address',
    'c.name as conditionType',
    'r.conditionLevel_id as conditionStatus',
    'r.gender',
    DB::raw("(((radians(acos(sin(radians(15.2993)) * sin(radians(r.latitude)) + cos(radians(15.2993)) * cos(radians(r.latitude)) * cos(radians(74.1240 - r.longitude))))) * 60 * 1.1515) * 1.609344) AS Distance")
)
                ->join('petcondition as c', 'c.id', '=', 'r.condition_id');

            if ($city_id) {
                $query->whereIn('r.city_id', explode(',', $city_id)); // support for multiple IDs
            }

            $rescueList = $query
                ->orderBy('Distance', 'ASC')
                ->limit(6)
                ->get();

            return response()->json($rescueList);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


   public function adoptionListHome($city_id )
    {
        try {
            $latitude = 15.2993;
            $longitude = 74.1240;

            $distanceCalc = "(((radians(acos(sin(radians($latitude)) * sin(radians(a.latitude)) + cos(radians($latitude)) * cos(radians(a.latitude)) * cos(radians($longitude - a.longitude))))) * 60 * 1.1515) * 1.609344)";

            if ($city_id) {
                $sql = "
                    (
                        SELECT
                            a.adopt_id, a.c_id, a.dob, a.gender, ai.image_path as img1, a.name,
                            $distanceCalc AS Distance
                        FROM adopt AS a
                        LEFT JOIN adopt_images ai ON a.adopt_id = ai.adopt_id AND ai.image_order = 1
                        WHERE a.city_id IN(?) AND a.petFlag = 2
                    )
                    UNION
                    (
                        SELECT
                            a.adopt_id, a.c_id, a.dob, a.gender, ai.image_path as img1, a.name,
                            $distanceCalc AS Distance
                        FROM adopt AS a
                        LEFT JOIN adopt_images ai ON a.adopt_id = ai.adopt_id AND ai.image_order = 1
                        INNER JOIN animal AS b ON a.animal_typ = b.animal_id
                        INNER JOIN breed AS c ON c.animal_id = b.animal_id
                        WHERE a.petFlag = 2
                        GROUP BY a.adopt_id
                        ORDER BY Distance ASC
                        LIMIT 6
                    )
                ";
                $adoptionList = DB::select($sql, [$city_id]);
            } else {
                $sql = "
                    SELECT 
                        a.adopt_id, a.c_id, a.dob, a.gender, ai.image_path as img1, a.name, 
                        $distanceCalc AS Distance
                    FROM adopt AS a 
                    LEFT JOIN adopt_images ai ON a.adopt_id = ai.adopt_id AND ai.image_order = 1
                    INNER JOIN animal AS b ON a.animal_typ = b.animal_id 
                    INNER JOIN breed AS c ON c.animal_id = b.animal_id 
                    WHERE a.petFlag = 2 
                    GROUP BY a.adopt_id 
                    ORDER BY Distance ASC 
                    LIMIT 6
                ";
                $adoptionList = DB::select($sql);
            }

            return response()->json($adoptionList);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }
}
