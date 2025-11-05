<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Adopt extends Model
{
    use HasFactory;

    protected $table = 'adopt';
    protected $primaryKey = 'adopt_id';
    public $timestamps = false;

    protected $fillable = [
        'c_id',
        'petFlag',
        'name',
        'animal_typ',
        'animalTypeName',
        'gender',
        'dob',
        'breed',
        'breedName',
        'color',
        'anti_rbs',
        'viral',
        'note',
        'city',
        'city_id',
        'longitude',
        'latitude',
        'date_added'
    ];

    /**
     * Get the images for the adopt record.
     */
    public function images(): HasMany
    {
        return $this->hasMany(AdoptImage::class, 'adopt_id', 'adopt_id')->orderBy('image_order');
    }

    /**
     * Get the first image (for backward compatibility).
     */
    public function getFirstImageAttribute()
    {
        return $this->images()->first()?->image_path;
    }

    /**
     * Get all image paths as array (for backward compatibility).
     */
    public function getAllImagesAttribute()
    {
        return $this->images()->pluck('image_path')->toArray();
    }
}
