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
        Schema::create('oc_custom_field_value_description', function (Blueprint $table) {
            $table->integer('custom_field_value_id')->unsigned();
            $table->integer('language_id')->unsigned();
            $table->string('name', 128);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_custom_field_value_description');
    }
};
