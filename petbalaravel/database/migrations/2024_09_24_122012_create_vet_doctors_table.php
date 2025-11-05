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
        Schema::create('vet_doctors', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->string('name', 50);
            $table->integer('gender');
            $table->string('discipline', 50);
            $table->text('qualification');
            $table->string('experience', 50);
            $table->text('about');
            $table->text('img');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vet_doctors');
    }
};
