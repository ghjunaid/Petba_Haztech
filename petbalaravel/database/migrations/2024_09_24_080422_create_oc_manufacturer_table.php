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
        Schema::create('oc_manufacturer', function (Blueprint $table) {
            $table->id('manufacturer_id');
            $table->string('name', 64);
            $table->string('image', 255)->nullable();
            $table->integer('sort_order');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_manufacturer');
    }
};
