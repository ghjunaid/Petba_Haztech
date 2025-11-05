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
        Schema::create('oc_recurring', function (Blueprint $table) {
            $table->id('recurring_id');
            $table->decimal('price', 10, 4);
            $table->enum('frequency', ['day', 'week', 'semi_month', 'month', 'year']);
            $table->unsignedInteger('duration');
            $table->unsignedInteger('cycle');
            $table->tinyInteger('trial_status');
            $table->decimal('trial_price', 10, 4);
            $table->enum('trial_frequency', ['day', 'week', 'semi_month', 'month', 'year']);
            $table->unsignedInteger('trial_duration');
            $table->unsignedInteger('trial_cycle');
            $table->tinyInteger('status');
            $table->integer('sort_order');
        });
    }
    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_recurring');
    }
};
