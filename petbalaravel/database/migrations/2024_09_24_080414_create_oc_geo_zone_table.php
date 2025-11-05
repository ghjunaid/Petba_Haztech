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
        Schema::create('oc_geo_zone', function (Blueprint $table) {
            $table->id('geo_zone_id');
            $table->string('name', 32);
            $table->string('description', 255);
            $table->dateTime('date_added');
            $table->dateTime('date_modified');
        });
    }


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_geo_zone');
    }
};
