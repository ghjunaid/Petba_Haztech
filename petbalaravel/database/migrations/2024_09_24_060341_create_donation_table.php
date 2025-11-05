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
        Schema::create('donation', function (Blueprint $table) {
            $table->id('donation_id');
            $table->integer('customer_id')->nullable(false);
            $table->integer('shelter_id')->nullable(false);
            $table->integer('amount')->nullable(false);
            $table->string('transaction_id', 30)->nullable(false);
            $table->string('date_time', 50)->nullable(false);
            $table->integer('status')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('donation');
    }
};
