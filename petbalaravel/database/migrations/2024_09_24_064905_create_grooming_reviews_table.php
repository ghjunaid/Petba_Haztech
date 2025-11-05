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
        Schema::create('grooming_reviews', function (Blueprint $table) {
            $table->id('id');
            $table->string('name', 40)->nullable(false);
            $table->integer('rating')->nullable(false);
            $table->text('review')->nullable(false);
            $table->integer('grooming_id')->nullable(false);
            $table->string('time', 50)->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('grooming_reviews');
    }
};
