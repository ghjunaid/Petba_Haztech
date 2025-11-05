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
        Schema::create('oc_location', function (Blueprint $table) {
            $table->id('location_id');
            $table->string('name', 32);
            $table->text('address');
            $table->string('telephone', 32);
            $table->string('fax', 32);
            $table->string('geocode', 32);
            $table->string('image', 255)->nullable();
            $table->text('open');
            $table->text('comment');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_location');
    }
};
