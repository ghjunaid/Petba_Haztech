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
        Schema::create('oc_product_attribute', function (Blueprint $table) {
            $table->integer('product_id');
            $table->integer('attribute_id');
            $table->integer('language_id');
            $table->text('text');
            $table->primary(['product_id', 'attribute_id', 'language_id']);
        });
    }
    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_product_attribute');
    }
};
