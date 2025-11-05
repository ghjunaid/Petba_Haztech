<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductOptionValue extends Model
{
    protected $table = 'oc_product_option_value';
    protected $fillable = ['product_id', 'option_id', 'option_value_id'];
}