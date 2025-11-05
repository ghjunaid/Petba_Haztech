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
        Schema::create('oc_cart', function (Blueprint $table) {
            $table->id('cart_id');
            $table->integer('api_id')->nullable(false);
            $table->integer('customer_id')->nullable(false);
            $table->string('session_id', 32)->nullable(false);
            $table->integer('product_id')-> nullable(false);
            $table->integer('recurring_id')->nullable(false);
            $table->text('option')->nullable(false);
            $table->integer('quantity')->nullable(false);
            $table->dateTime('date_added')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_cart');
    }
};
