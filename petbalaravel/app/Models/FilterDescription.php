<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FilterDescription extends Model
{
    protected $table = 'oc_filter_description';
    protected $primaryKey = 'filter_id';
    public $incrementing = false;
    protected $fillable = ['filter_id', 'filter_group_id', 'name'];
}
