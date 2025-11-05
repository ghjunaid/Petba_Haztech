<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController
{
    public function sendRescueFCM(Request $request)
    {
        $payload = $request->json()->all();

        $city_id = $payload['city_id'];
        $city = $payload['city'];
        $sender_id = $payload['c_id'];
        $rescue_id = $payload['rescue_id'];

        $title = "Urgent Pet Rescue: Help Needed Now!";
        $message = "A furry friend is in desperate need of rescue in {$city}! Click to lend a hand and make a real difference today.";

        try {
            // Get customer IDs from same city (excluding sender)
            $recipientIds = DB::table('rescue_customers')
                ->where('city_id', $city_id)
                ->where('c_id', '!=', $sender_id)
                ->pluck('c_id');

            if ($recipientIds->isEmpty()) {
                return response()->json(['Result' => 'EMPTY']);
            }

            // Get image
            $img = DB::table('rescuepet')->where('id', $rescue_id)->value('img1');
            $imageUrl = 'https://petba.in/Api/' . $img;

            $now = now('Asia/Kolkata')->toIso8601String();

            $notificationPayload = [
                'title' => $title,
                'body' => $message,
                'sound' => 'default',
                'icon' => 'ic_launcher',
                'priority' => 'high',
            ];

            $customData = [
                'type' => 'rescue',
                'id' => $rescue_id,
                'image' => $imageUrl
            ];

            $headers = [
                'Authorization: key=' . env('FCM_SERVER_KEY'),
                'Content-Type: application/json'
            ];

            foreach ($recipientIds as $user_id) {
                $token = DB::table('oc_customer')->where('customer_id', $user_id)->value('token');

                if ($token) {
                    // Save notification
                    DB::table('notification')->insert([
                        'customer_id' => $user_id,
                        'flag' => 1,
                        'type' => 'rescue',
                        'title' => $title,
                        'body' => $message,
                        'data' => $rescue_id,
                        'img' => $imageUrl,
                        'time' => $now
                    ]);

                    // Send FCM push
                    $fcmPayload = [
                        'to' => $token,
                        'notification' => $notificationPayload,
                        'data' => $customData
                    ];

                    $ch = curl_init();
                    curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
                    curl_setopt($ch, CURLOPT_POST, true);
                    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fcmPayload));
                    curl_exec($ch);
                    curl_close($ch);
                }
            }

            return response()->json(['Result' => 'success']);

        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function sendFCM($pageType, $pageId, $senderId, $message)
    {
        try {
            $db = DB::connection()->getPdo();

            if ($pageType == 'blog') {
                $user = DB::table('blog as b')
                    ->join('oc_customer as c', 'b.author', '=', 'c.customer_id')
                    ->select('b.id as blog_id', 'b.author as author_id', 'b.img as blog_img', 'c.token')
                    ->where('b.id', $pageId)
                    ->first();
                $image = '/blogImg/' . $user->blog_img;
            } elseif ($pageType == 'rescue_comment') {
                $user = DB::table('rescuepet as r')
                    ->join('oc_customer as c', 'r.customer_id', '=', 'c.customer_id')
                    ->select('r.id', 'r.customer_id as author_id', 'r.img1 as rescue_img', 'c.token')
                    ->where('r.id', $pageId)
                    ->first();
                $image = '/Api/' . $user->rescue_img;
            }

            if ($user->author_id != $senderId) {
                // Getting Sender Info
                $sender = DB::table('oc_customer')
                    ->select('customer_id', DB::raw("CONCAT(firstname, ' ', lastname) as name"), 'img')
                    ->where('customer_id', $senderId)
                    ->first();

                // Title for Notification
                $title = $pageType == 'blog' ? "{$sender->name} commented on your post" : "{$sender->name} commented on your rescue post";

                // Prepare Notification
                date_default_timezone_set("Asia/Kolkata");
                $date = date("c");

                $msg = [
                    'title' => $title,
                    'body' => $message,
                    'sound' => 'default',
                    'icon' => "ic_launcher",
                    "priority" => "high",
                ];

                $data = [
                    'type' => $pageType,
                    'id' => $pageId,
                    'image' => 'https://petba.in' . $image
                ];

                // Send Notification
                $fields = [
                    'to' => $user->token,
                    'notification' => $msg,
                    "data" => $data
                ];

                $headers = [
                    'Authorization:key=' . "YOUR_SERVER_KEY",
                    'Content-Type:application/json'
                ];

                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
                curl_setopt($ch, CURLOPT_POST, true);
                curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
                curl_exec($ch);
                curl_close($ch);

                // Save Notification
                DB::table('notification')->insert([
                    'customer_id' => $user->author_id,
                    'flag' => 1,
                    'type' => $data['type'],
                    'title' => $title,
                    'body' => $message,
                    'data' => $data['id'],
                    'img' => $image,
                    'time' => $date
                ]);
            }

            return response()->json(['Result' => 'success']);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function notificationList(Request $request)
    {
        // Validate incoming request
        $data = $request->validate([
            'c_id' => 'required|string',
        ]);

        $c_id = $data['c_id'];

        try {
            // Fetch notifications
            $notifications = DB::table('notification')
                ->where('customer_id', $c_id)
                ->where('type', '!=', 'message')
                ->orderBy('time', 'DESC')
                ->get();

            return response()->json(['notificationList' => $notifications]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function clearNotification(Request $request)
    {
        // Validate incoming request
        $data = $request->validate([
            'c_id' => 'required|string',
        ]);

        $c_id = $data['c_id'];

        try {
            // Delete all notifications for the customer
            DB::table('notification')->where('customer_id', $c_id)->delete();

            return response()->json(['notificationList' => 'success']);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function deleteNotification(Request $request)
    {
        // Validate incoming request
        $data = $request->validate([
            'c_id' => 'required|string',
            'notification_id' => 'required|string',
        ]);

        $c_id = $data['c_id'];
        $notification_id = $data['notification_id'];

        try {
            // Delete specific notification
            $deletedCount = DB::table('notification')
                ->where('customer_id', $c_id)
                ->where('id', $notification_id)
                ->delete();

            return response()->json(['notificationList' => 'success', 'Deleted' => $deletedCount]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function saveNotification(Request $request)
    {
        // Validate incoming request
        $data = $request->validate([
            'c_id' => 'required|string',
            'type' => 'required|string',
            'title' => 'required|string',
            'body' => 'required|string',
            'data' => 'required|string',
        ]);

        try {
            // Insert new notification
            DB::table('notification')->insert([
                'customer_id' => $data['c_id'],
                'flag' => 1,
                'type' => $data['type'],
                'title' => $data['title'],
                'body' => $data['body'],
                'data' => $data['data'],
            ]);

            return response()->json([
                'saveNotification' => 'CID=' . $data['c_id'] . ' + type=' . $data['type'] . ' + title=' . $data['title'] . ' + body=' . $data['body'] . ' + data=' . $data['data']
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function sendProductNotification(Request $request)
    {
        $request->validate([
            'id' => 'required|integer',
            'city_name' => 'required|string',
            'user_token' => 'required|string'
        ]);

        $id = $request->input('id');
        $city_name = $request->input('city_name');
        $token = $request->input('user_token');

        try {
            date_default_timezone_set("Asia/Kolkata");
            $title = "Animal Rescue Needed";
            $message = "Rescue needed in " . $city_name;

            $notification = [
                'title' => $title,
                'body' => $message,
                'sound' => 'default',
                'click_action' => 'FCM_PLUGIN_ACTIVITY'
            ];

            $data = [
                'type' => 'rescue',
                'id' => $id
            ];

            $fields = [
                'to' => $token,
                'notification' => $notification,
                'data' => $data
            ];

            $response = Http::withHeaders([
                'Authorization' => 'key=AAAAl8jlOjM:APA91bFI42WLnYVpTUifV48CLLIyOTBFe77pT9DvXatNjxi8Qj0ZBc2j6yjj9ekO_gw00vDZPZAR5Uk6DHV3TrFjqayXu5on_QnDiRM1dMgULKFy7kuQeZW0joHjA6P_bhtiZcsMOSoN',
                'Content-Type' => 'application/json'
            ])->post('https://fcm.googleapis.com/fcm/send', $fields);

            return response()->json([
                'status' => 'success',
                'fcm_response' => $response->body()
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }   

}
