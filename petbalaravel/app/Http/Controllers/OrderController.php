<?php

namespace App\Http\Controllers;

use App\Models\Address;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController
{
    public function orderProduct(Request $request)
    {
        // Get user data and products
        $userData = $request->input('userData');
        $cartProducts = $request->input('cartproducts'); // ✅ fixed key name

        // Extract user details
        $customerId     = $userData['customer_id'] ?? null;
        $firstName      = $userData['firstname'] ?? '';
        $lastName       = $userData['lastname'] ?? '';
        $email          = $userData['email'] ?? '';
        $addressId      = $userData['arddressid'] ?? 0;
        $total          = $userData['total'] ?? 0;
        $payMethod      = $userData['paym'] ?? '';
        $payCode        = $userData['payc'] ?? '';
        $shippingPhone  = $userData['shipping_phone'] ?? 'N/A'; // ✅ fallback

        // Get address and phone (if available from DB)
        $address   = $this->getAddress($addressId);
        $phoneData = $this->findContactNo($addressId);

        if ($phoneData && !empty($phoneData->shipping_phone)) {
            $shippingPhone = $phoneData->shipping_phone;
        }

        try {
            DB::beginTransaction();

            // Insert order
            $orderId = DB::table('oc_order')->insertGetId([
                'invoice_prefix'       => 'INV-',
                'store_id'             => 0,
                'store_name'           => 'Default Store',
                'store_url'            => 'http://localhost/',

                'customer_id'          => $customerId,
                'customer_group_id'    => 1,
                'firstname'            => $firstName,
                'lastname'             => $lastName,
                'email'                => $email,
                'telephone'            => $shippingPhone,
                'fax'                  => '',
                'custom_field'         => '[]',

                // Payment
                'payment_firstname'    => $firstName,
                'payment_lastname'     => $lastName,
                'payment_company'      => '',
                'payment_address_1'    => $address->address_1 ?? '',
                'payment_address_2'    => '',
                'payment_city'         => $address->city ?? '',
                'payment_postcode'     => $address->postcode ?? '',
                'payment_country'      => $address->country ?? '',
                'payment_country_id'   => 0,
                'payment_zone'         => $address->zone ?? '',
                'payment_zone_id'      => 0,
                'payment_address_format' => '',
                'payment_custom_field' => '[]',
                'payment_method'       => $payMethod,
                'payment_code'         => $payCode,

                // Shipping
                'shipping_firstname'   => $firstName,
                'shipping_lastname'    => $lastName,
                'shipping_company'     => '',
                'shipping_address_1'   => $address->address_1 ?? '',
                'shipping_address_2'   => '',
                'shipping_city'        => $address->city ?? '',
                'shipping_postcode'    => $address->postcode ?? '',
                'shipping_country'     => $address->country ?? '',
                'shipping_country_id'  => 0,
                'shipping_zone'        => $address->zone ?? '',
                'shipping_zone_id'     => 0,
                'shipping_address_format' => '',
                'shipping_custom_field'=> '[]',
                'shipping_method'      => 'Flat Rate',
                'shipping_code'        => 'flat.flat',

                // Order info
                'comment'              => '',
                'total'                => $total,
                'order_status_id'      => 1,
                'affiliate_id'         => 0,
                'commission'           => 0.00,
                'marketing_id'         => 0,
                'tracking'             => '',
                'language_id'          => 1,
                'currency_id'          => 1,
                'currency_code'        => 'USD',
                'currency_value'       => 1.000000,
                'ip'                   => request()->ip(),
                'forwarded_ip'         => '',
                'user_agent'           => request()->header('User-Agent', ''),
                'accept_language'      => request()->header('Accept-Language', ''),
                'date_added'           => now(),
                'date_modified'        => now(),
            ]);

            // Insert products + update stock + clear from cart
            foreach ($cartProducts as $product) {
                DB::table('oc_order_product')->insert([
                    'order_id'   => $orderId,
                    'product_id' => $product['product_id'],
                    'name'       => $product['name'],
                    'model'      => $product['model'],
                    'quantity'   => $product['cart_qty'],
                    'price'      => $product['price'],
                    'total'      => $product['price'] * $product['cart_qty'],
                    'tax'        => 0.00,
                    'reward'     => 0,
                ]);

                // Decrement product stock
                DB::table('oc_product')
                    ->where('product_id', $product['product_id'])
                    ->decrement('quantity', $product['cart_qty']);

                // Remove from cart
                DB::table('oc_cart')
                    ->where('customer_id', $customerId)
                    ->where('product_id', $product['product_id'])
                    ->delete();
            }

            // Insert order totals
            DB::table('oc_order_total')->insert([
                ['order_id' => $orderId, 'code' => 'sub_total', 'title' => 'Sub-Total', 'value' => $total, 'sort_order' => 1],
                ['order_id' => $orderId, 'code' => 'shipping', 'title' => 'Flat Shipping Rate', 'value' => 0, 'sort_order' => 3],
                ['order_id' => $orderId, 'code' => 'total', 'title' => 'Total', 'value' => $total, 'sort_order' => 9],
            ]);

            DB::commit();

            return response()->json(['orderproduct' => 'Order placed successfully']);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function findContactNo($addressId)
    {
        return Address::select('shipping_phone')->where('address_id', $addressId)->first();
    }

    public function getAddress($addressId)
    {
        return Address::where('address_id', $addressId)->first();
    }

    public function loadOrderHistory(Request $request)
    {
        $c_id = $request->input('c_id');

        try {
            $orders = DB::table('oc_order as o')
                ->leftJoin('oc_order_product as p', 'p.order_id', '=', 'o.order_id')
                ->leftJoin('oc_order_status as s', 's.order_status_id', '=', 'o.order_status_id')
                ->leftJoin('oc_product as ocp', 'ocp.product_id', '=', 'p.product_id')
                ->where('o.customer_id', $c_id)
                ->select(
                    'o.order_id',
                    'o.firstname',
                    'o.lastname',
                    'o.telephone',
                    'o.payment_method',
                    'o.date_modified',
                    'o.payment_city as city',
                    'o.shipping_postcode as postcode',
                    'o.shipping_address_1 as address_1',
                    'o.shipping_address_2 as address_2',
                    'o.shipping_company as company',
                    'p.name',
                    'p.price',
                    'p.product_id',
                    's.name as order_status',
                    'ocp.image'
                )
                ->get();

            return response()->json(['loadOrderHistory' => $orders]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }
}
