<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChatController
{
    public function newChats(Request $request)
    {
        $validated = $request->validate([
            'user1' => 'required|integer',
            'user2' => 'required|integer',
            'p_id'   => 'required|integer',
        ]);

        $user1 = $validated['user1'];
        $user2 = $validated['user2'];
        $p_id = $validated['p_id'];

        try {
            // Check if chat already exists
            $chat = DB::table('friends')
                ->select('id', 'user1', 'user2', 'p_id', 'petName', 'status', 'message', 'img', 'date_time', 'sendDelete', 'receiveDelete')
                ->where('user1', $user1)
                ->where('user2', $user2)
                ->where('p_id', $p_id)
                ->where('chatDeleted', 0)
                ->first();

            if (!$chat) {
                // Insert new chat
                DB::table('friends')->insert([
                    'user1' => $user1,
                    'user2' => $user2,
                    'p_id' => $p_id,
                    'sendDelete' => $user1,
                    'receiveDelete' => $user2,
                    'date_time' => now()
                ]);

                $chat = DB::table('friends')
                    ->select('id', 'user1', 'user2', 'p_id', 'petName', 'status', 'message', 'img', 'date_time', 'sendDelete', 'receiveDelete')
                    ->where('user1', $user1)
                    ->where('user2', $user2)
                    ->where('p_id', $p_id)
                    ->first();
            }

            return response()->json(['status' => true, 'chat' => $chat]);
        } catch (\Exception $e) {
            return response()->json(['status' => false, 'error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function friends(Request $request)
    {
        $data = $request->json()->all();

        $id = $data['c_id'] ?? null;
        $token = $data['token'] ?? null;
        $email = $data['email'] ?? null;  // You need to receive email here for internalUserDetails

        try {
            if (!$id || !$token || !$email) {
                return response()->json(['error' => 'User ID, token and email are required'], 400);
            }

            // Use your internal function to fetch user details by email
            $out = internalUserDetails($email);

            if (!$out) {
                return response()->json(['error' => 'User not found'], 404);
            }

            $ck_id = $out->customer_id ?? null;
            $ck_token = $out->token ?? null;

            // Validate id and token
            if ($id != $ck_id || $token != $ck_token) {
                return response()->json(['error' => 'Invalid credentials'], 401);
            }

            // Token validated — proceed with your original friends logic

            $friends = DB::table('friends')
                ->select('id', 'p_id')
                ->where('user1', $id)
                ->orWhere('user2', $id)
                ->get();

            foreach ($friends as $friend) {
                $mainCount = DB::table('chats')
                    ->where('status', '<>', 2)
                    ->where('conversation_id', $friend->id)
                    ->where('from_id', '<>', $id)
                    ->count();

                DB::table('friends')
                    ->where('id', $friend->id)
                    ->update(['status' => $mainCount]);

                $latestChat = DB::table('chats')
                    ->where('conversation_id', $friend->id)
                    ->orderBy('chat_id', 'DESC')
                    ->first();

                if ($latestChat) {
                    DB::table('friends')
                        ->where('id', $friend->id)
                        ->update([
                            'message' => $latestChat->message,
                            'date_time' => $latestChat->date_time,
                        ]);
                }

                $petData = DB::table('adopt')
                    ->select('img1', 'name')
                    ->where('adopt_id', $friend->p_id)
                    ->first();

                if ($petData) {
                    DB::table('friends')
                        ->where('id', $friend->id)
                        ->update([
                            'img' => $petData->img1,
                            'petName' => $petData->name,
                        ]);
                }
            }

            $updatedFriends = DB::table('friends')
                ->select('id', 'user1', 'user2', 'p_id', 'petName', 'status', 'message', 'img', 'date_time', 'sendDelete', 'receiveDelete')
                ->where(function ($query) use ($id) {
                    $query->where('user1', $id)
                        ->orWhere('user2', $id);
                })
                ->where(function ($query) use ($id) {
                    $query->where('sendDelete', $id)
                        ->orWhere('receiveDelete', $id);
                })
                ->orderBy('date_time', 'DESC')
                ->get();

            return response()->json(['friends' => $updatedFriends]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function chat_data(Request $request)
    {
        $validated = $request->validate([
            'id' => 'required|integer',
        ]);

        $id = $validated['id'];

        try {
            $chatData = DB::table('chats')
                ->select('conversation_id', 'message', 'sender_id', 'receiver_id', 'adoption_id', 'from_id', 'status', 'date_time')
                ->where('conversation_id', $id)
                ->get();

            return response()->json(['chatData' => $chatData]);
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function seenStatus(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
            'c_id' => 'required|integer',
            'from_id' => 'required|integer',
        ]);

        $email = $validated['email'];
        $token = $validated['token'];
        $c_id = $validated['c_id'];
        $from_id = $validated['from_id'];

        try {
            $authUser = internalUserDetails($email);
            if (!$authUser || $authUser->customer_id != $from_id || $authUser->token != $token) {
                return response()->json(['status' => false, 'message' => 'Invalid credentials'], 401);
            }

            DB::table('chats')
                ->where('from_id', $from_id)
                ->where('conversation_id', $c_id)
                ->update(['status' => 2]);

            return response()->json([
                'success' => 'The person has seen it',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'error' => ['text' => $e->getMessage()]
            ], 500);
        }
    }



   public function saveMessage(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
            'conversation_id' => 'required|integer',
            'from_id' => 'required|integer',
            'message' => 'required|string',
            'adoption_id' => 'required|integer',
            'receiver_id' => 'required|integer',
            'sender_id' => 'required|integer',
            'status' => 'required|integer',
        ]);

        $email = $validated['email'];
        $token = $validated['token'];
        $fromId = $validated['from_id'];

        try {
            $authUser = internalUserDetails($email);
            if (!$authUser || $authUser->customer_id != $fromId || $authUser->token != $token) {
                return response()->json(['status' => false, 'message' => 'Invalid sender credentials'], 401);
            }

            // Insert chat message
            DB::table('chats')->insert([
                'conversation_id' => $validated['conversation_id'],
                'message' => $validated['message'],
                'sender_id' => $validated['sender_id'],
                'receiver_id' => $validated['receiver_id'],
                'from_id' => $validated['from_id'],
                'adoption_id' => $validated['adoption_id'],
                'date_time' => now(),
                'status' => $validated['status'],
            ]);

            // Get receiver token
            $receiver = DB::table('oc_customer')->where('customer_id', $validated['receiver_id'])->first();
            if (!$receiver || !$receiver->token) {
                return response()->json(['error' => 'Receiver token not found'], 404);
            }

            $sender = DB::table('oc_customer')->where('customer_id', $validated['from_id'])->first();
            $senderName = $sender ? "{$sender->firstname} {$sender->lastname}" : 'Someone';

            // FCM Notification
            $notification = [
                'title' => "Message from {$senderName}",
                'body' => $validated['message'],
                'sound' => 'default',
                'click_action' => 'FCM_PLUGIN_ACTIVITY',
            ];
            $data = [
                'user_id' => $validated['from_id'],
                'user_name' => $senderName,
                'type' => 'message',
            ];

            $payload = [
                'to' => $receiver->token,
                'notification' => $notification,
                'data' => $data,
            ];

            $headers = [
                'Authorization: key=YOUR_SERVER_KEY_HERE',
                'Content-Type: application/json',
            ];

            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
            $result = curl_exec($ch);
            curl_close($ch);

            return response()->json(['message' => 'Message sent', 'sender' => $senderName]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'error' => ['text' => $e->getMessage()]
            ], 500);
        }
    }



    public function deleteEmpty(Request $request)
    {
        $c_id = $request->input('c_id');

        try {
            if (!$c_id) {
                return response()->json(['error' => 'Missing conversation ID'], 400);
            }

            // Check if any chats exist for this conversation
            $mainCount = DB::table('chats')
                ->where('conversation_id', $c_id)
                ->count();

            if ($mainCount === 0) {
                // Delete the corresponding record from the friends table
                DB::table('friends')
                    ->where('id', $c_id)
                    ->delete();

                return response()->json(['Empty' => 'Delete successful for ' . $c_id]);
            } else {
                return response()->json(['Error' => 'Chat not empty'], 400);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function deleteChat(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
            'customer_id' => 'required|integer',
            'id' => 'required|integer',
        ]);

        $email = $validated['email'];
        $token = $validated['token'];
        $customer_id = $validated['customer_id'];
        $id = $validated['id'];

        try {
            // Validate token
            $user = internalUserDetails($email);
            if (!$user || $user->customer_id != $customer_id || $user->token != $token) {
                return response()->json(['error' => 'Invalid credentials'], 401);
            }

            // Fetch delete status for the conversation
            $chat = DB::table('friends')
                ->select('sendDelete', 'receiveDelete')
                ->where('id', $id)
                ->first();

            if ($chat) {
                if ($chat->sendDelete == $customer_id) {
                    if ($chat->sendDelete == 0) {
                        return response()->json(['message' => 'Chat already deleted by sender']);
                    }

                    DB::table('friends')
                        ->where('id', $id)
                        ->update(['sendDelete' => 0]);

                    return response()->json(['message' => 'Chat deleted successfully by sender']);
                }

                if ($chat->receiveDelete == $customer_id) {
                    if ($chat->receiveDelete == 0) {
                        return response()->json(['message' => 'Chat already deleted by receiver']);
                    }

                    DB::table('friends')
                        ->where('id', $id)
                        ->update(['receiveDelete' => 0]);

                    return response()->json(['message' => 'Chat deleted successfully by receiver']);
                }

                return response()->json(['error' => 'User not authorized to delete this chat'], 403);
            } else {
                return response()->json(['error' => 'Chat not found'], 404);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    
    public function chatlist(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|integer'
        ]);
    
        $id = $data['c_id'];
    
        try {
            $chatlist = DB::table('chats as c')
                ->leftjoin(DB::raw('(
                    SELECT adoption_id, MAX(date_time) AS latest_time
                    FROM chats
                    WHERE sender_id = ' . $id . ' OR receiver_id = ' . $id . '
                    GROUP BY adoption_id
                ) as latest'), function($join) {
                    $join->on('c.adoption_id', '=', 'latest.adoption_id')
                         ->on('c.date_time', '=', 'latest.latest_time');
                })
                ->leftjoin('adopt', 'c.adoption_id', '=', 'adopt.adopt_id')
                ->leftJoin('adopt_images', function($join) {
                    $join->on('adopt.adopt_id', '=', 'adopt_images.adopt_id')
                         ->where('adopt_images.image_order', '=', 1);
                })
                ->leftJoin('oc_customer as sender', 'c.sender_id', '=', 'sender.customer_id')
                ->leftJoin('oc_customer as receiver', 'c.receiver_id', '=', 'receiver.customer_id')
                ->where(function($query) use ($id) {
                    $query->where('c.sender_id', $id)
                          ->orWhere('c.receiver_id', $id);
                })
                ->select(
                    'adopt.name as petname',
                    'c.adoption_id',
                    'c.chat_id',
                    'c.message as latest_message',
                    'c.imageUrl',
                    'c.sender_id',
                    'c.receiver_id',
                    'c.date_time as latest_message_time',
                    'c.status',
                    'adopt_images.image_path as adoption_image',
                    'sender.firstname as sender_name',
                    'receiver.firstname as receiver_name'
                )
                ->orderBy('c.date_time', 'desc')
                ->get();
    
            if ($chatlist->isNotEmpty()) {
                return response()->json(['chatlist' => $chatlist]);
            } else {
                return response()->json(['fri' => 'No Friends found']);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }

    public function loadChat(Request $request)
    {
        $validated = $request->validate([
            'sender_id' => 'required|integer',
            'receiver_id' => 'required|integer',
            'adoption_id' => 'required|integer',
            'email' => 'required|email',
            'token' => 'required|string',
        ]);

        $senderId = $validated['sender_id'];
        $receiverId = $validated['receiver_id'];
        $adoptionId = $validated['adoption_id'];
        $email = $validated['email'];
        $token = $validated['token'];

        try {
            $user = internalUserDetails($email);
            if (!$user || $user->customer_id != $senderId || $user->token != $token) {
                return response()->json(['error' => 'Invalid credentials'], 401);
            }

            $chatData = DB::table('chats')
                ->where('adoption_id', $adoptionId)
                ->where(function ($query) use ($senderId, $receiverId) {
                    $query->where(function ($q) use ($senderId, $receiverId) {
                        $q->where('sender_id', $senderId)
                        ->where('receiver_id', $receiverId);
                    })->orWhere(function ($q) use ($senderId, $receiverId) {
                        $q->where('sender_id', $receiverId)
                        ->where('receiver_id', $senderId);
                    });
                })
                ->select('message', 'sender_id', 'receiver_id', 'from_id', 'status', 'date_time')
                ->get();

            return response()->json(['chatData' => $chatData], 200);

        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error fetching chat',
                'message' => $e->getMessage()
            ], 500);
        }
    }


}

