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
        Schema::create('oc_zone_to_geo_zone', function (Blueprint $table) {
            $table->integer('zone_to_geo_zone_id')->primary();
            $table->integer('country_id');
            $table->integer('zone_id')->default(0); // default value for integer columns
            $table->integer('geo_zone_id');
            $table->timestamp('date_added')->useCurrent(); // Automatically sets the current timestamp
            $table->timestamp('date_modified')->useCurrent()->useCurrentOnUpdate(); // Automatically updates the timestamp on each update
        });
    }


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_zone_to_geo_zone');
    }
};
