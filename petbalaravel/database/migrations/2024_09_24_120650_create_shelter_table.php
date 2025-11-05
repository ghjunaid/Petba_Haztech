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
        Schema::create('shelter', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->integer('c_id');
            $table->string('name', 50);
            $table->string('owner', 50);
            $table->text('img1');
            $table->text('address');
            $table->boolean('verified');
            $table->boolean('paid');
            $table->string('phoneNumber', 10);
            $table->double('latitude');
            $table->double('longitude');
            $table->string('acceptlimit', 3);
            $table->text('description');
            $table->text('d_description');
            $table->integer('city_id');
            $table->integer('fee');
            $table->double('rating');
            $table->string('open_time', 30);
            $table->string('close_time', 30);
        });
    }


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('shelter');
    }
};
