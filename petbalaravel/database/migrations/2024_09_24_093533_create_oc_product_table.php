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
        Schema::create('oc_product', function (Blueprint $table) {
            $table->id('product_id');
            $table->string('model', 64);
            $table->string('sku', 64);
            $table->string('upc', 12);
            $table->string('ean', 14);
            $table->string('jan', 13);
            $table->string('isbn', 17);
            $table->string('mpn', 64);
            $table->string('location', 128);
            $table->integer('quantity')->default(0);
            $table->integer('stock_status_id');
            $table->string('image', 255)->nullable();
            $table->integer('manufacturer_id');
            $table->tinyInteger('shipping')->default(1);
            $table->decimal('price', 15, 4)->default(0.0000);
            $table->integer('points')->default(0);
            $table->integer('tax_class_id');
            $table->date('date_available')->nullable();
            $table->decimal('weight', 15, 8)->default(0.00000000);
            $table->integer('weight_class_id')->default(0);
            $table->decimal('length', 15, 8)->default(0.00000000);
            $table->decimal('width', 15, 8)->default(0.00000000);
            $table->decimal('height', 15, 8)->default(0.00000000);
            $table->integer('length_class_id')->default(0);
            $table->tinyInteger('subtract')->default(1);
            $table->integer('minimum')->default(1);
            $table->integer('sort_order')->default(0);
            $table->tinyInteger('status')->default(0);
            $table->integer('viewed')->default(0);
            $table->dateTime('date_added');
            $table->dateTime('date_modified');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_product');
    }
};
