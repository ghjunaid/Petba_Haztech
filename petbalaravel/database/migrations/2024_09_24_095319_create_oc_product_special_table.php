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
        Schema::create('oc_product_special', function (Blueprint $table) {
            $table->id('product_special_id');
            $table->integer('product_id');
            $table->integer('customer_group_id');
            $table->integer('priority')->default(1);
            $table->decimal('price', 15, 4)->default(0.0000);
            $table->date('date_start')->nullable();
            $table->date('date_end')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_product_special');
    }
};
