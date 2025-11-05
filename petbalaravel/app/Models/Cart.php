<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Cart extends Model
{
    protected $table = 'oc_cart';
    protected $fillable = ['customer_id', 'product_id'];
}