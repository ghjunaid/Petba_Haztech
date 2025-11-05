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
        Schema::create('groomers', function (Blueprint $table) {
            $table->id('id');
            $table->string('name', 40)->nullable(false);
            $table->integer('gender')->nullable(false);
            $table->string('details', 50)->nullable(false);
            $table->text('experience')->nullable(false);
            $table->text('about')->nullable(false);
            $table->text('img')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('groomers');
    }
};
