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
        Schema::create('oc_order_shipment', function (Blueprint $table) {
            $table->id('order_shipment_id');
            $table->integer('order_id');
            $table->dateTime('date_added');
            $table->string('shipping_courier_id', 255);
            $table->string('tracking_number', 255);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_order_shipment');
    }
};
