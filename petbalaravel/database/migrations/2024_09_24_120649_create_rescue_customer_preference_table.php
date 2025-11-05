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
        Schema::create('rescue_customer_preference', function (Blueprint $table) {
            $table->integer('rcp_id')->primary();
            $table->integer('customer_id');
            $table->string('city_id', 35);
            $table->string('name', 20);
            $table->double('latitude');
            $table->double('longitude');
        });
    }


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rescue_customer_preference');
    }
};
