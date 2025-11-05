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
        Schema::create('oc_return', function (Blueprint $table) {
            $table->id('return_id');
            $table->integer('order_id');
            $table->integer('product_id');
            $table->integer('customer_id');
            $table->string('firstname', 32);
            $table->string('lastname', 32);
            $table->string('email', 96);
            $table->string('telephone', 32);
            $table->string('product', 255);
            $table->string('model', 64);
            $table->integer('quantity');
            $table->tinyInteger('opened');
            $table->integer('return_reason_id');
            $table->integer('return_action_id');
            $table->integer('return_status_id');
            $table->text('comment')->nullable();
            $table->date('date_ordered')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_return');
    }
};
