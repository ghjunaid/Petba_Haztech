<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CategoryDescription extends Model
{
    protected $table = 'oc_category_description'; // Specify the table name
    protected $primaryKey = 'category_id'; // Specify the primary key
    public $incrementing = false;
    protected $fillable = ['category_id', 'name'];
    public $timestamps = false; // Disable timestamps if not used
}
