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
        Schema::create('oc_weight_class_description', function (Blueprint $table) {
            $table->integer('weight_class_id');
            $table->integer('language_id');
            $table->string('title', 32);
            $table->string('unit', 4);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_weight_class_description');
    }
};
