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
        Schema::create('oc_customer_online', function (Blueprint $table) {
            $table->string('ip', 40)->nullable(false);
            $table->integer('customer_id')->nullable(false);
            $table->text('url')->nullable(false);
            $table->text('referer')->nullable(false);
            $table->dateTime('date_added')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_customer_online');
    }
};
