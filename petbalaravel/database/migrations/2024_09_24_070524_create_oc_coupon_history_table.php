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
        Schema::create('oc_coupon_history', function (Blueprint $table) {
            $table->id('coupon_history_id');
            $table->integer('coupon_id')->nullable(false);
            $table->integer('order_id')->nullable(false);
            $table->integer('customer_id')->nullable(false);
            $table->decimal('amount', 15, 4)->nullable(false);
            $table->dateTime('date_added')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_coupon_history');
    }
};
