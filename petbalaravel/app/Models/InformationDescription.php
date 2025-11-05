<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InformationDescription extends Model
{
    protected $table = 'oc_information_description'; // Specify the table name
    protected $primaryKey = 'information_id'; // Specify the primary key
    public $timestamps = false; // Disable timestamps if not used

    // Define the fillable fields if needed
    protected $fillable = ['title', 'information_id'];
}
