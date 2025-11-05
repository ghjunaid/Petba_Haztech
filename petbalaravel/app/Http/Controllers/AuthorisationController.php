<?php

namespace App\Http\Controllers;

use App\Models\Authorisation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AuthorisationController 
{
    public function login(Request $request)
    {
        $data = $request->json()->all();
        $email = $data['email'];
        $password = $data['password'];
        $deviceId = $data['d_id'] ?? null;

        // Find the user by email
        $user = Authorisation::where('email', $email)->first();
        if (!$user) {
            return response()->json(['error' => 'Invalid username or password'], 401);
        }

        // Verify the password
        $hashedPassword = sha1($user->salt . sha1($user->salt . sha1($password)));
        if ($hashedPassword !== $user->password) {
            return response()->json(['error' => 'Invalid username or password'], 401);
        }

        $apiToken = $this->generateApiToken();

        // Save token to DB (overwriting deviceId if present)
        $user->token = $apiToken;
        $user->save();

        // Return user data
        return response()->json([
            'userData' => [
                'customer_id' => $user->customer_id,
                'firstname' => $user->firstname,
                'lastname' => $user->lastname,
                'email' => $user->email,
                'token' => $apiToken
            ]
        ]);
    }
    
    private function generateApiToken()
    {
        return base64_encode(Str::random(40));
    }

    public function signup(Request $request)
    {
        // Validate the input
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|min:6',
            'fname' => 'required',
            'lname' => 'required',
            'phone' => 'required',
        ]);
    
        try {
            // Check if the user already exists
            $existingUser = Authorisation::where('email', $validated['email'])
                ->orWhere('telephone', $validated['phone'])
                ->first();
    
            if ($existingUser) {
                return response()->json(['error' => 'Email or phone number is already registered'], 409);
            }
    
            // Generate a salt and hash the password
            $salt = Str::random(9);
            $hashedPassword = sha1($salt . sha1($salt . sha1($validated['password'])));
    
            // Insert the new user into the database
            $newUser = Authorisation::create([
                'firstname' => $validated['fname'],
                'lastname' => $validated['lname'],
                'email' => $validated['email'],
                'password' => $hashedPassword,
                'salt' => $salt,
                'telephone' => $validated['phone']
            ]);
    
            // Return user data
            return response()->json(['userData' => $newUser], 201);
        } catch (Exception $e) {
            // Log the error for debugging
           // Log::error('Signup error: ' . $e->getMessage());
            return response()->json(['error' => 'Internal Server Error'], 500);
        }
    }
    
    public function passwordCheck(Request $request)
    {
        $data = $request->json()->all();
        $password = $data['password'];
        $customerId = $data['customer_id'];

        try {
            // Fetch the salt from the database
            $user = Authorisation::where('customer_id', $customerId)->first();

            if (!$user) {
                return response()->json(['passwordCheck' => 'failed'], 401);
            }

            $salt = $user->salt;

            // Hash the password with the salt
            $hashedPassword = sha1($salt . sha1($salt . sha1($password)));

            // Verify the password
            $verifiedUser = Authorisation::where('customer_id', $customerId)->where('password', $hashedPassword)->first();

            if ($verifiedUser) {
                return response()->json(['passwordCheck' => 'passed']);
            } else {
                return response()->json(['passwordCheck' => 'failed'], 401);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
    public function changePassword(Request $request)
    {
        $data = $request->json()->all();
        $password = $data['password'];
        $customerId = $data['c_id'];

        try {
            // Validate password
            if (strlen(trim($password)) > 0) {
                // Generate salt and hash password
                $salt = Str::random(9);
                $hashedPassword = sha1($salt . sha1($salt . sha1($password)));

                // Update password and salt in database
                Authorisation::where('customer_id', $customerId)
                    ->update(['password' => $hashedPassword, 'salt' => $salt]);

                return response()->json(['changePassword' => 'success']);
            } else {
                return response()->json(['changePassword' => 'failed'], 400);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
    public function checkAccount(Request $request)
    {
        $data = $request->json()->all();
        $phone = $data['phone'];

        try {
            if (!empty($phone) && is_numeric($phone)) {
                // Check if the phone number exists in the database
                $user = Authorisation::where('telephone', $phone)->select('customer_id as cid')->first();

                if ($user) {
                    return response()->json(['resp' => $user]);
                } else {
                    return response()->json(['resp' => null], 404);
                }
            } else {
                return response()->json(['error' => 'phone number not provided'], 400);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function firstname(Request $request)
    {
        $validated = $request->validate([
            'userid' => 'required|integer',
            'email' => 'required|email',
            'token' => 'required|string',
        ]);

        $id = $validated['userid'];
        $email = $validated['email'];
        $token = $validated['token'];

        try {
            // Get customer details using internal function
            $out = internalUserDetails($email);

            if (!$out) {
                return response()->json(['error' => 'User not found'], 404);
            }

            $ck_id = $out->customer_id ?? null;
            $ck_token = $out->token ?? null;

            // Validate ID and token
            if ($id != $ck_id || $token != $ck_token) {
                return response()->json(['error' => 'Invalid credentials'], 401);
            }

            // Fetch the user's full name
            $name = DB::table('oc_customer as C')
                ->select(DB::raw("CONCAT(C.firstname, ' ', C.lastname) as name"))
                ->where('customer_id', $id)
                ->first();

            if ($name) {
                return response()->json(['firstname' => $name]);
            } else {
                return response()->json(['firstname' => 'No record found'], 404);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }


    public function updateProfilePic(Request $request) {
        $id = $request->input('c_id');
        $image = $request->input('img');
    
        try {
            if ($image) {
                // Create the target path for storing the profile picture
                $targetPath = 'profilepic/MyProfilePic_' . $id . '_' . time() . '.jpg';
    
                // Remove base64 tags from the image data
                $imagedata = str_replace(['data:image/jpeg;base64,', 'data:image/jpg;base64,'], '', $image);
                $imagedata = str_replace(' ', '+', $imagedata);
                $imagedata = base64_decode($imagedata);
    
                // Store the image in the designated path
                file_put_contents($targetPath, $imagedata);
                $imageUrl = 'api/' . $targetPath;
    
                // Update the image URL in the database
                if ($id) {
                    DB::table('oc_customer')
                        ->where('customer_id', $id)
                        ->update(['img' => $imageUrl]);
    
                    return response()->json(['Image' => $imageUrl]);
                }
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }
    
    public function customerData(Request $request)
    {
        $data = $request->validate([
            'c_id' => 'required|integer',
        ]);

        $c_id = $data['c_id'];

        try {
            $customer = DB::table('oc_customer')
                ->select('telephone', 'email', 'firstname', 'lastname', 'img')
                ->where('customer_id', $c_id)
                ->first();

            if ($customer) {
                return response()->json(['customerData' => $customer]);
            } else {
                return response()->json(['error' => 'Customer not found'], 404);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => ['text' => $e->getMessage()]], 500);
        }
    }
    
    public function getCustomerById(Request $request, $customerId)
    {
        try {
            $customer = DB::table('oc_customer')
                ->select('customer_id', 'firstname', 'lastname', 'email', 'telephone')
                ->where('customer_id', $customerId)
                ->first();

            if ($customer) {
                return response()->json([
                    'success' => true,
                    'data' => $customer
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Customer not found'
                ], 404);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

}
