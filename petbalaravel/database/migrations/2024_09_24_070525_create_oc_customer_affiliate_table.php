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
        Schema::create('oc_customer_affiliate', function (Blueprint $table) {
            $table->id('customer_id');
            $table->string('company', 40)->nullable(false);
            $table->string('website', 255)->nullable(false);
            $table->string('tracking', 64)->nullable(false);
            $table->decimal('commission', 4, 2)->nullable(false)->default(0.00);
            $table->string('tax', 64)->nullable(false);
            $table->string('payment', 6)->nullable(false);
            $table->string('cheque', 100)->nullable(false);
            $table->string('paypal', 64)->nullable(false);
            $table->string('bank_name', 64)->nullable(false);
            $table->string('bank_branch_number', 64)->nullable(false);
            $table->string('bank_swift_code', 64)->nullable(false);
            $table->string('bank_account_name', 64)->nullable(false);
            $table->string('bank_account_number', 64)->nullable(false);
            $table->text('custom_field')->nullable(false);
            $table->tinyInteger('status')->nullable(false);
            $table->dateTime('date_added')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_customer_affiliate');
    }
};
