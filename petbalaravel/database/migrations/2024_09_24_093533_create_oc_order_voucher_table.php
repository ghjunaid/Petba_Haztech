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
        Schema::create('oc_order_voucher', function (Blueprint $table) {
            $table->id('order_voucher_id');
            $table->integer('order_id');
            $table->integer('voucher_id');
            $table->string('description', 255);
            $table->string('code', 10);
            $table->string('from_name', 64);
            $table->string('from_email', 96);
            $table->string('to_name', 64);
            $table->string('to_email', 96);
            $table->integer('voucher_theme_id');
            $table->text('message');
            $table->decimal('amount', 15, 4);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_order_voucher');
    }
};
