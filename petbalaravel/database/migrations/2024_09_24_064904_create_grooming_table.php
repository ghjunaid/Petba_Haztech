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
        Schema::create('grooming', function (Blueprint $table) {
            $table->id('id');
            $table->string('name', 55)->nullable(false);
            $table->text('img1')->nullable(false);
            $table->text('img2')->nullable(false);
            $table->text('img3')->nullable(false);
            $table->text('img4')->nullable(false);
            $table->string('phoneNumber', 10)->nullable(false);
            $table->text('address')->nullable(false);
            $table->text('description')->nullable(false);
            $table->text('d_description')->nullable(false);
            $table->double('latitude')->nullable(false);
            $table->double('longitude')->nullable(false);
            $table->integer('city_id')->nullable(false);
            $table->integer('fee')->nullable(false);
            $table->double('rating')->nullable(false);
            $table->string('open_time', 30)->nullable(false);
            $table->string('close_time', 30)->nullable(false);
            $table->integer('groomer_id')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('grooming');
    }
};
