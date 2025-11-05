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
        Schema::create('vet_timming', function (Blueprint $table) {
            $table->integer('timing_id')->primary();
            $table->integer('vet_id');
            $table->text('mon');
            $table->text('tue');
            $table->text('wed');
            $table->text('thu');
            $table->text('fri');
            $table->text('sat');
            $table->text('sun');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vet_timming');
    }
};
