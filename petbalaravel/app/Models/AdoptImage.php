<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AdoptImage extends Model
{
    use HasFactory;

    protected $table = 'adopt_images';
    protected $primaryKey = 'image_id';
    public $timestamps = true;

    protected $fillable = [
        'adopt_id',
        'image_path',
        'image_order'
    ];

    /**
     * Get the adopt record that owns the image.
     */
    public function adopt(): BelongsTo
    {
        return $this->belongsTo(Adopt::class, 'adopt_id', 'adopt_id');
    }
}
