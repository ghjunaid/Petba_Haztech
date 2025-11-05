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
        Schema::create('my_pets', function (Blueprint $table) {
            $table->id('pet_id');
            $table->integer('c_id')->nullable(false);
            $table->string('name', 100)->nullable(false);
            $table->date('DoB')->nullable(false);
            $table->longText('image')->nullable(false);
            $table->integer('gender')->nullable(false)->comment('1:male,2:female');
            $table->string('color', 100)->nullable(false);
            $table->string('breed', 200)->nullable(false);
            $table->date('anti_rbs')->nullable(true);
            $table->date('viral')->nullable(true);
            $table->text('note')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('my_pets');
    }
};
