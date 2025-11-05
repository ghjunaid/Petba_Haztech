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
    Schema::create('otherPet', function (Blueprint $table) {
        $table->integer('id')->primary();
        $table->integer('otherID')->default(99);
        $table->text('petType');
        $table->text('breed');
    });
}


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('other_pet');
    }
};
