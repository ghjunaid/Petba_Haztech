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
        Schema::create('oc_option_value', function (Blueprint $table) {
            $table->id('option_value_id');
            $table->integer('option_id')->unsigned();
            $table->string('image', 255);
            $table->integer('sort_order');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_option_value');
    }
};
