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
        Schema::create('oc_coupon', function (Blueprint $table) {
            $table->bigIncrements('coupon_id');
            $table->string('name', 128);
            $table->string('code', 20);
            $table->char('type', 1);
            $table->decimal('discount', 15, 4);
            $table->tinyInteger('logged');
            $table->tinyInteger('shipping');
            $table->decimal('total', 15, 4);
            $table->date('date_start');
            $table->date('date_end');
            $table->integer('uses_total');
            $table->string('uses_customer', 11);
            $table->tinyInteger('status');
            $table->dateTime('date_added');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_coupon');
    }
};
