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
        Schema::create('oc_order_product', function (Blueprint $table) {
            $table->integer('order_product_id')->primary();
            $table->integer('order_id');
            $table->integer('product_id');
            $table->string('name', 255);
            $table->string('model', 64);
            $table->integer('quantity');
            $table->decimal('price', 15, 4)->default(0.0000);
            $table->decimal('total', 15, 4)->default(0.0000);
            $table->decimal('tax', 15, 4)->default(0.0000);
            $table->integer('reward');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_order_product');
    }
};
