<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FilterGroup extends Model
{
    protected $table = 'oc_filter_group_description';
    protected $primaryKey = 'filter_group_id';
    public $incrementing = false;
    protected $fillable = ['filter_group_id', 'name'];
}
