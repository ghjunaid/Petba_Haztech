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
        Schema::create('oc_order_history', function (Blueprint $table) {
            $table->integer('order_history_id')->primary();
            $table->integer('order_id');
            $table->integer('order_status_id');
            $table->tinyInteger('notify')->default(0);
            $table->text('comment');
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_order_history');
    }
};
