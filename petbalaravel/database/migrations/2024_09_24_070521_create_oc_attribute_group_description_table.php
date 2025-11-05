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
        Schema::create('oc_attribute_group_description', function (Blueprint $table) {
            $table->id('attribute_group_id');
            $table->integer('language_id')->nullable(false);
            $table->string('name', 64)->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_attribute_group_description');
    }
};
