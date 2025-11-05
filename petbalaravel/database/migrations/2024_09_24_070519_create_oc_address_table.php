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
        Schema::create('oc_address', function (Blueprint $table) {
            $table->id('address_id');
            $table->integer('customer_id')->nullable(false);
            $table->string('firstname', 32)->nullable(false);
            $table->string('lastname', 32)->nullable(false);
            $table->string('company', 40)->nullable(false);
            $table->string('address_1', 128)->nullable(false);
            $table->string('address_2', 128)->nullable(false);
            $table->string('city', 128)->nullable(false);
            $table->string('postcode', 10)->nullable(false);
            $table->integer('country_id')->nullable(false)->default(0);
            $table->integer('zone_id')->nullable(false)->default(0);
            $table->text('custom_field')->nullable(false);
            $table->string('shipping_phone', 20)->nullable(true);
            $table->string('alt_number', 50)->nullable(false);
            $table->string('landmark', 50)->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_address');
    }
};
