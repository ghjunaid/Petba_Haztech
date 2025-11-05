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
        Schema::create('shelter_reviews', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->string('name', 40);
            $table->integer('rating');
            $table->text('review');
            $table->integer('shelter_id');
            $table->string('time', 50);
        });
    }


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('shelter_reviews');
    }
};
