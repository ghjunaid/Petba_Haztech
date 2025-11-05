<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DonationController
{
    public function loadDonationHistory(Request $request)
    {
        $cId = $request->input('c_id');

        try {
            $donations = DB::table('donation as d')
                ->leftjoin('shelter as s', 'd.shelter_id', '=', 's.id')
                ->where('d.customer_id', $cId)
                ->orderBy('d.date_time', 'desc')
                ->select(
                    'd.donation_id',
                    'd.amount',
                    'd.transaction_id',
                    'd.date_time',
                    's.name',
                    's.img1'
                )
                ->get();

            return response()->json(['donations' => $donations], 200);

        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to load donation history',
                'message' => $e->getMessage()
            ], 500);
        }
    }


    public function makeDonation(Request $request)
    {
        $customer_id = $request->input('customer_id');
        $shelter_id = $request->input('shelter_id');
        $date_time = $request->input('date_time');
        $donation = $request->input('donation');
        $transaction_id = $request->input('transaction_id');

        try {
            $donationId = DB::table('donation')->insertGetId([
                'customer_id' => $customer_id,
                'shelter_id' => $shelter_id,
                'amount' => $donation,
                'transaction_id' => $transaction_id,
                'date_time' => $date_time,
                'status'         => $request->status
            ]);

            return response()->json(['donation' => 'success', 'id' => $donationId]);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


}
