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
        Schema::create('oc_customer_group_description', function (Blueprint $table) {
            $table->id('customer_group_id');
            $table->integer('language_id')->nullable(false);
            $table->string('name', 32)->nullable(false);
            $table->text('description')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_customer_group_description');
    }
};
