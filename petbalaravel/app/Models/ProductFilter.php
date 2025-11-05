<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductFilter extends Model
{
    protected $table = 'oc_product_filter';
    protected $fillable = ['product_id', 'filter_id'];
}
