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
        Schema::create('oc_razorpay_subscriptions', function (Blueprint $table) {
            $table->id('entity_id');
            $table->integer('plan_entity_id');
            $table->string('subscription_id', 30);
            $table->integer('product_id');
            $table->integer('order_id');
            $table->string('razorpay_customer_id', 30);
            $table->integer('opencart_user_id');
            $table->string('status', 30);
            $table->string('updated_by', 30);
            $table->integer('qty')->default(0);
            $table->integer('total_count')->default(0);
            $table->integer('paid_count')->default(0);
            $table->integer('remaining_count')->default(0);
            $table->integer('auth_attempts')->default(0);
            $table->timestamp('start_at')->nullable();
            $table->timestamp('end_at')->nullable();
            $table->timestamp('subscription_created_at')->nullable();
            $table->timestamp('next_charge_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_razorpay_subscriptions');
    }
};
