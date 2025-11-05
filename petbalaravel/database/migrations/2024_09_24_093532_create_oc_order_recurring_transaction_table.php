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
        Schema::create('oc_order_recurring_transaction', function (Blueprint $table) {
            $table->id('order_recurring_transaction_id');
            $table->integer('order_recurring_id');
            $table->string('reference', 255);
            $table->string('type', 255);
            $table->decimal('amount', 10, 4);
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_order_recurring_transaction');
    }
};
