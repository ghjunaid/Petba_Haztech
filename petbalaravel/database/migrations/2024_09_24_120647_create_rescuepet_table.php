<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;


return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up()
    {
        Schema::create('rescuepet', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->integer('customer_id');
            $table->integer('condition_id');
            $table->integer('conditionLevel_id');
            $table->integer('animal_id');
            $table->integer('gender')->comment('1:male,2:female');
            $table->text('img1');
            $table->text('img2');
            $table->text('img3');
            $table->text('img4');
            $table->text('img5');
            $table->text('img6');
            $table->string('city', 70);
            $table->integer('city_id');
            $table->text('address');
            $table->double('latitude');
            $table->double('longitude');
            $table->text('description');
            $table->integer('status')->default(0);
            $table->timestamp('date_time')->default(DB::raw('CURRENT_TIMESTAMP'));
        });
    }


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rescuepet');
    }
};
