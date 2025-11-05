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
        Schema::create('oc_information_to_layout', function (Blueprint $table) {
            $table->integer('information_id')->unsigned();
            $table->integer('store_id')->unsigned();
            $table->integer('layout_id')->unsigned();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_information_to_layout');
    }
};
