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
        Schema::create('oc_product_reward', function (Blueprint $table) {
            $table->id('product_reward_id');
            $table->integer('product_id')->default(0);
            $table->integer('customer_group_id')->default(0);
            $table->integer('points')->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_product_reward');
    }
};
