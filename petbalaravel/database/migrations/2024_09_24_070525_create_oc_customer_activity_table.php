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
        Schema::create('oc_customer_activity', function (Blueprint $table) {
            $table->id('customer_activity_id');
            $table->integer('customer_id')->nullable(false);
            $table->string('key', 64)->nullable(false);
            $table->text('data')->nullable(false);
            $table->string('ip', 40)->nullable(false);
            $table->dateTime('date_added')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_customer_activity');
    }
};
