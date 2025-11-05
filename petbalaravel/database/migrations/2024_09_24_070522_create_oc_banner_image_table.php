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
        Schema::create('oc_banner_image', function (Blueprint $table) {
            $table->id('banner_image_id');
            $table->integer('banner_id')->nullable(false);
            $table->integer('language_id')->nullable(false);
            $table->string('title', 64)->nullable(false);
            $table->string('link', 255)->nullable(false);
            $table->string('image', 255)->nullable(false);
            $table->integer('sort_order')->nullable(false)->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_banner_image');
    }
};
