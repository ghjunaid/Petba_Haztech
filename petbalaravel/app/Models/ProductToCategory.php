<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductToCategory extends Model
{
    protected $table = 'oc_product_to_category';
    protected $fillable = ['product_id', 'category_id'];
}