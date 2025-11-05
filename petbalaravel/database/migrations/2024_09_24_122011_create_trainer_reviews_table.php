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
        Schema::create('trainer_reviews', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->string('name', 40);
            $table->integer('rating');
            $table->text('review');
            $table->integer('trainer_id');
            $table->string('time', 50);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trainer_reviews');
    }
};
