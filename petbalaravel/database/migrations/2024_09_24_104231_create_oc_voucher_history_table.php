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
        Schema::create('oc_voucher_history', function (Blueprint $table) {
            $table->id('voucher_history_id');
            $table->integer('voucher_id');
            $table->integer('order_id');
            $table->decimal('amount', 15, 4);
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_voucher_history');
    }
};
