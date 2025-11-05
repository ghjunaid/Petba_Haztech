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
        Schema::create('oc_customer_transaction', function (Blueprint $table) {
            $table->id('customer_transaction_id');
            $table->integer('customer_id')->unsigned();
            $table->integer('order_id')->unsigned();
            $table->text('description');
            $table->decimal('amount', 15, 4);
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_customer_transaction');
    }
};
