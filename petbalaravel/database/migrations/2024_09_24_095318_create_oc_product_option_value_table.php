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
        Schema::create('oc_product_option_value', function (Blueprint $table) {
            $table->id('product_option_value_id');
            $table->integer('product_option_id');
            $table->integer('product_id');
            $table->integer('option_id');
            $table->integer('option_value_id');
            $table->integer('quantity');
            $table->tinyInteger('subtract');
            $table->decimal('price', 15, 4);
            $table->string('price_prefix', 1);
            $table->integer('points');
            $table->string('points_prefix', 1);
            $table->decimal('weight', 15, 8);
            $table->string('weight_prefix', 1);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_product_option_value');
    }
};
