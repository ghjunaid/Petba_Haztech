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
        Schema::create('trainers', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->string('name', 40);
            $table->integer('gender');
            $table->string('details', 50);
            $table->text('experience');
            $table->text('about');
            $table->text('img');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trainers');
    }
};
