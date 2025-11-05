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
        Schema::create('oc_customer', function (Blueprint $table) {
            $table->id('customer_id');
            $table->integer('customer_group_id')->nullable();
            $table->integer('store_id')->nullable()->default(0);
            $table->integer('language_id')->nullable();
            $table->string('firstname', 32)->nullable(false);
            $table->string('lastname', 32)->nullable(false);
            $table->string('email', 96)->nullable(false);
            $table->string('telephone', 32)->nullable();
            $table->string('fax', 32)->nullable();
            $table->string('password', 40)->nullable(false);
            $table->string('salt', 9)->nullable(false);
            $table->text('cart')->nullable(true);
            $table->text('wishlist')->nullable(true);
            $table->tinyInteger('newsletter')->nullable()->default(0);
            $table->integer('address_id')->nullable()->default(0);
            $table->text('custom_field')->nullable();
            $table->string('ip', 40)->nullable();
            $table->tinyInteger('status')->nullable();
            $table->tinyInteger('safe')->nullable();
            $table->text('token')->nullable();
            $table->string('code', 40)->nullable();
            $table->dateTime('date_added')->nullable();
            $table->longText('img')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_customer');
    }
};
