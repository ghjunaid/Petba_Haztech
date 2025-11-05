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
        Schema::create('rescue_cities', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->text('city_name')->nullable();
            $table->text('city_code')->nullable();
            $table->text('state_code')->nullable();
        });
    }


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rescue_cities');
    }
};
