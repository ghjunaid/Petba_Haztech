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
        Schema::create('trainerFilters', function (Blueprint $table) {
            $table->integer('filter_id');
            $table->string('name', 40);
            $table->integer('filter_group_id');
            $table->primary('filter_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trainer_filters');
    }
};
