<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    protected $table = 'oc_category'; // Specify the table name
    protected $primaryKey = 'category_id'; // Specify the primary key
    public $timestamps = false; // Disable timestamps if not used

    // Define the relationship to category description
    public function description()
    {
        return $this->hasOne(CategoryDescription::class, 'category_id', 'category_id');
    }
}
