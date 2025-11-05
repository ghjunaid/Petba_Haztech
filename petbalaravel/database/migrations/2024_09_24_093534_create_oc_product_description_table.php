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
        Schema::create('oc_product_description', function (Blueprint $table) {
            $table->integer('product_id');
            $table->integer('language_id');
            $table->string('name', 255);
            $table->text('description');
            $table->text('tag');
            $table->string('meta_title', 255);
            $table->string('meta_description', 255);
            $table->string('meta_keyword', 255);
            $table->primary(['product_id', 'language_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_product_description');
    }
};
