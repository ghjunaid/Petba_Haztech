<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\Address;

class PaymentController
{
   public function payment(Request $request)
{
    // Get request data (root-level now, since your JSON has no userData)
    $email       = $request->input('email');
    $totalAmt    = $request->input('total');
    $firstName   = $request->input('firstname');
    $addressId   = $request->input('arddressid');
    $shippingPhone = $request->input('shipping_phone');

    // Get cart products safely
    $cartProducts = $request->input('cartproducts', []);

    // Prepare purpose by concatenating product names
    $purpose = collect($cartProducts)->pluck('name')->implode(',');

    // Prepare the payment request
    $payload = [
        'purpose'                => $purpose ?: 'Buying Products',
        'amount'                 => $totalAmt,
        'phone'                  => $shippingPhone, // ✅ directly use string
        'buyer_name'             => $firstName,
        'redirect_url'           => '', // Set appropriate redirect URL here
        'send_email'             => false,
        'webhook'                => '', // Optional: Set webhook URL here
        'send_sms'               => true,
        'email'                  => $email,
        'allow_repeated_payments'=> false,
    ];

    try {
        // Perform the API call using Laravel's Http facade
        $response = Http::withHeaders([
            'X-Api-Key'    => 'test_a48a79961f9744c567ba3066147',
            'X-Auth-Token' => 'test_3453142bd2b731c33e18215e81d'
        ])->post('https://www.instamojo.com/api/1.1/payment-requests/', $payload);

        // Return the payment response
        return response()->json(['payment' => $response->json()]);
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
}

    public function findContactNo($addressId)
    {
        try {
            // Use Eloquent to find the shipping_phone based on the address ID
            $address = Address::select('shipping_phone')->where('address_id', $addressId)->first();

            if ($address) {
                return $address;
            }

            return response()->json(['error' => 'Address not found'], 404);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}
