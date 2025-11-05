<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Authorisation extends Model 
{
    use HasFactory;

    protected $table = 'oc_customer';  // Defines the table name

    protected $primaryKey = 'customer_id'; // Defines the primary key

    // Define which fields can be mass-assigned
    protected $fillable = [
        'firstname',
        'lastname',
        'email',
        'password',
        'salt',
        'telephone',
        'token',
    ];

    // Hide the password and salt fields when serializing the model
    protected $hidden = [
        'password',
        'salt'
    ];
    
    public $timestamps = false;
}
