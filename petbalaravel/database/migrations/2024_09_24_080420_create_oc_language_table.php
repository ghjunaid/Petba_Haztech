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
        Schema::create('oc_language', function (Blueprint $table) {
            $table->id('language_id');
            $table->string('name', 32);
            $table->string('code', 5);
            $table->string('locale', 255);
            $table->string('image', 64);
            $table->string('directory', 32);
            $table->integer('sort_order')->default(0);
            $table->tinyInteger('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_language');
    }
};
