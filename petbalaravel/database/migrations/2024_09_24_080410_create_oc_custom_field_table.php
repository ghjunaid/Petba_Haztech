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
        Schema::create('oc_custom_field', function (Blueprint $table) {
            $table->id('custom_field_id');
            $table->string('type', 32);
            $table->text('value');
            $table->string('validation', 255);
            $table->string('location', 10);
            $table->tinyInteger('status');
            $table->integer('sort_order');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_custom_field');
    }
};
