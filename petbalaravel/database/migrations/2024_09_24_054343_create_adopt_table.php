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
        Schema::create('adopt', function (Blueprint $table) {
            $table->id('adopt_id');
            $table->increments('c_id')->nullable(false);
            $table->tinyInteger('petFlag')->nullable(false)->comment('1:Pet,2:adoption,3:removed');
            $table->longText('img1')->nullable(true);
            $table->longText('img2')->nullable(true);
            $table->longText('img3')->nullable(true);
            $table->longText('img4')->nullable(true);
            $table->longText('img5')->nullable(true);
            $table->longText('img6')->nullable(true);
            $table->string('name', 100)->nullable(false);
            $table->string('animal_typ', 40)->nullable(false);
            $table->string('animalTypeName', 60)->nullable(true);
            $table->integer('gender')->nullable(false);
            $table->date('dob')->nullable(false);
            $table->string('breed', 40)->nullable(false);
            $table->string('breedName', 50)->nullable(true);
            $table->string('color', 100)->nullable(false);
            $table->string('anti_rbs', 30)->nullable(true);
            $table->string('viral', 30)->nullable(true);
            $table->text('note')->nullable(true);
            $table->string('city', 255)->nullable(true);
            $table->integer('city_id')->nullable(true);
            $table->double('longitude')->nullable(true);
            $table->double('latitude')->nullable(true);
            $table->timestamp('date_added')->useCurrent()->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('adopt');
    }
};
