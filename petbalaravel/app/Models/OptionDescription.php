<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OptionDescription extends Model
{
    protected $table = 'oc_option_description';
    protected $primaryKey = 'option_id';
    public $incrementing = false;
    protected $fillable = ['option_id', 'name'];
}
