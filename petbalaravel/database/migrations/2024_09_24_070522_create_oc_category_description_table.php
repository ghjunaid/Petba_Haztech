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
        Schema::create('oc_category_description', function (Blueprint $table) {
            $table->id('category_id');
            $table->integer('language_id')->nullable(false);
            $table->string('name', 255)->nullable(false);
            $table->text('description')->nullable(false);
            $table->string('meta_title', 255)->nullable(false);
            $table->string('meta_description', 255)->nullable(false);
            $table->string('meta_keyword', 255)->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_category_description');
    }
};
