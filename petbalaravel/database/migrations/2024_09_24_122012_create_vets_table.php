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
        Schema::create('vets', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->string('name', 50);
            $table->text('img1');
            $table->text('img2');
            $table->text('img3');
            $table->text('img4');
            $table->string('phoneNumber', 10);
            $table->string('city', 30);
            $table->integer('city_id');
            $table->text('address');
            $table->text('details');
            $table->double('latitude');
            $table->double('longitude');
            $table->integer('fee');
            $table->double('rating');
            $table->string('open_time', 30);
            $table->string('close_time', 30);
            $table->integer('doc_id');
            $table->text('description');
            $table->text('d_description');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vets');
    }
};
