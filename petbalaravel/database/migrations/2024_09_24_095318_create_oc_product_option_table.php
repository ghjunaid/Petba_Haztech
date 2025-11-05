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
        Schema::create('oc_product_option', function (Blueprint $table) {
            $table->id('product_option_id');
            $table->integer('product_id');
            $table->integer('option_id');
            $table->text('value');
            $table->tinyInteger('required');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_product_option');
    }
};
