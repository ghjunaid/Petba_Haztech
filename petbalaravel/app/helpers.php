<?php 

if (!function_exists('internalUserDetails')) {
    /**
     * Get user details by email.
     *
     * @param string $email
     * @return \App\Models\User|null
     */
    function internalUserDetails($email)
    {
        return \App\Models\Customer::where('email', $email)->first();
    }
}

if (!function_exists('cartTotal')) {
    /**
     * Dummy cart total helper (replace with your real logic)
     *
     * @param int $customerId
     * @return float
     */
    function cartTotal($customerId)
    {
        // Implement your logic here, e.g. sum of items in cart
        return 100.0; // Example fixed value
    }
}

if (!function_exists('sendFCM')) {
    function sendFCM($type, $target_id, $from_id, $message)
    {
        // 🔑 Replace with your Firebase server key
        $SERVER_API_KEY = 'YOUR_FIREBASE_SERVER_KEY';

        // 🔔 Notification payload
        $data = [
            "to" => "/topics/{$type}_{$target_id}", // or a device token if you want
            "notification" => [
                "title" => ucfirst($type) . " Notification",
                "body"  => $message,
                "sound" => "default",
            ],
            "data" => [
                "type"      => $type,
                "target_id" => $target_id,
                "from_id"   => $from_id,
                "message"   => $message,
            ]
        ];

        $dataString = json_encode($data);

        $headers = [
            'Authorization: key=' . $SERVER_API_KEY,
            'Content-Type: application/json',
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $dataString);

        $response = curl_exec($ch);
        curl_close($ch);

        \Log::info("FCM Response: " . $response);

        return $response;
    }
}

?>