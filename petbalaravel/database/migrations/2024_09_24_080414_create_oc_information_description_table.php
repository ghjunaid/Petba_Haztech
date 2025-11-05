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
        Schema::create('oc_information_description', function (Blueprint $table) {
            $table->integer('information_id')->unsigned();
            $table->integer('language_id')->unsigned();
            $table->string('title', 64);
            $table->text('description');
            $table->string('meta_title', 255);
            $table->string('meta_description', 255);
            $table->string('meta_keyword', 255);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_information_description');
    }
};
