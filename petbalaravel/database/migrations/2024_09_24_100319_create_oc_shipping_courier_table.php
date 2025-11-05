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
        Schema::create('oc_shipping_courier', function (Blueprint $table) {
            $table->id('shipping_courier_id');
            $table->string('shipping_courier_code', 255);
            $table->string('shipping_courier_name', 255);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_shipping_courier');
    }
};
