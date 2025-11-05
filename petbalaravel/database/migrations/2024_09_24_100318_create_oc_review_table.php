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
        Schema::create('oc_review', function (Blueprint $table) {
            $table->id('review_id');
            $table->integer('product_id');
            $table->integer('customer_id');
            $table->string('author', 64);
            $table->text('text');
            $table->integer('rating');
            $table->tinyInteger('status')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_review');
    }
};
