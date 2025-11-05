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
        Schema::create('cities', function (Blueprint $table) {
            $table->id('city_id');
            $table->string('circle', 50)->nullable(false);
            $table->string('region', 50)->nullable(false);
            $table->string('city', 50)->nullable(false);
            $table->integer('pincode')->nullable(false);
            $table->string('district', 50)->nullable(false);
            $table->string('state', 50)->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cities');
    }
};
