<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OptionValueDescription extends Model
{
    protected $table = 'oc_option_value_description';
    protected $primaryKey = 'option_value_id';
    public $incrementing = false;
    protected $fillable = ['option_value_id', 'name'];
}
