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
        Schema::create('oc_order_recurring', function (Blueprint $table) {
            $table->integer('order_recurring_id')->primary();
            $table->integer('order_id');
            $table->string('reference', 255);
            $table->integer('product_id');
            $table->string('product_name', 255);
            $table->integer('product_quantity');
            $table->integer('recurring_id');
            $table->string('recurring_name', 255);
            $table->string('recurring_description', 255);
            $table->string('recurring_frequency', 25);
            $table->smallInteger('recurring_cycle');
            $table->smallInteger('recurring_duration');
            $table->decimal('recurring_price', 10, 4);
            $table->tinyInteger('trial');
            $table->string('trial_frequency', 25);
            $table->smallInteger('trial_cycle');
            $table->smallInteger('trial_duration');
            $table->decimal('trial_price', 10, 4);
            $table->tinyInteger('status');
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_order_recurring');
    }
};
