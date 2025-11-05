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
        Schema::create('oc_customer_reward', function (Blueprint $table) {
            $table->id('customer_reward_id');
            $table->integer('customer_id')->nullable(false)->default(0);
            $table->integer('order_id')->nullable(false)->default(0);
            $table->text('description')->nullable(false);
            $table->integer('points')->nullable(false)->default(0);
            $table->dateTime('date_added')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_customer_reward');
    }
};
