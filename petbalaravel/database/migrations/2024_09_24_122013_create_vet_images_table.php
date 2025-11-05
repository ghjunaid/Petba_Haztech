<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up()
    {
        Schema::create('vet_images', function (Blueprint $table) {
            $table->integer('vet_image_id')->primary();
            $table->integer('vet_id');
            $table->text('image');
            $table->timestamp('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vet_images');
    }
};
