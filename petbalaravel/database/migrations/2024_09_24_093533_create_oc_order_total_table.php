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
        Schema::create('oc_order_total', function (Blueprint $table) {
            $table->id('order_total_id');
            $table->integer('order_id');
            $table->string('code', 32);
            $table->string('title', 255);
            $table->decimal('value', 15, 4)->default(0.0000);
            $table->integer('sort_order');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_order_total');
    }
};
