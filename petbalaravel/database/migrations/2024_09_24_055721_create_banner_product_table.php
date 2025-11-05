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
        Schema::create('banner_product', function (Blueprint $table) {
            $table->id('id');
            $table->tinyInteger('flag')->nullable(false);
            $table->integer('product_id')->nullable(false);
            $table->text('imgLink')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('banner_product');
    }
};
