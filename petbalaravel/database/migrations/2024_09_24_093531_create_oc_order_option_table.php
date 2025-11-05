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
        Schema::create('oc_order_option', function (Blueprint $table) {
            $table->integer('order_option_id')->primary();
            $table->integer('order_id');
            $table->integer('order_product_id');
            $table->integer('product_option_id');
            $table->integer('product_option_value_id')->default(0);
            $table->string('name', 255);
            $table->text('value');
            $table->string('type', 32);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_order_option');
    }
};
