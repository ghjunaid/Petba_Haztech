<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Address extends Model
{
    protected $table = 'oc_address'; // Assuming your table is 'oc_address'
    protected $primaryKey = 'address_id';
    public $timestamps = false; // If the table doesn't have timestamps
    
    protected $fillable = ['shipping_phone'];
}
