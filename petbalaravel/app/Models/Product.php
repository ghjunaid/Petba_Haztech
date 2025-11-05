<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $table = 'oc_product'; // Specify the table name
    protected $primaryKey = 'product_id'; // Specify the primary key
    public $timestamps = false; // Disable timestamps if not used

    // Define relationships as needed (e.g., to categories, manufacturer)
}
