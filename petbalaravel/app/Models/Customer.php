<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    protected $table = 'oc_customer'; // Define your table name here if it's not the plural of model name
    
    protected $primaryKey = 'customer_id'; // Define the primary key if it's different from 'id'
    
    public $incrementing = false;
    protected $fillable = ['customer_id', 'firstname', 'lastname', 'email', 'token'];

    public $timestamps = false; // If your table does not have 'created_at' and 'updated_at' fields
}
