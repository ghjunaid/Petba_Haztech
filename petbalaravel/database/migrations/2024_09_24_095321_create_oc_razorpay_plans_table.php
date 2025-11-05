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
        Schema::create('oc_razorpay_plans', function (Blueprint $table) {
            $table->id('entity_id');
            $table->string('plan_id', 40);
            $table->integer('recurring_id');
            $table->integer('opencart_product_id');
            $table->string('plan_name', 255);
            $table->string('plan_desc', 255);
            $table->string('plan_type', 30);
            $table->integer('plan_frequency')->default(1);
            $table->string('plan_bill_cycle', 255);
            $table->decimal('plan_trial', 10, 0)->default(0);
            $table->decimal('plan_bill_amount', 10, 0)->default(0);
            $table->decimal('plan_addons', 10, 0)->default(0);
            $table->integer('plan_status')->default(1);
            $table->timestamp('created_at')->useCurrent();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_razorpay_plans');
    }
};
