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
        Schema::create('oc_layout_route', function (Blueprint $table) {
            $table->id('layout_route_id');
            $table->integer('layout_id')->unsigned();
            $table->integer('store_id')->unsigned();
            $table->string('route', 64);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_layout_route');
    }
};
