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
        Schema::create('oc_tax_class', function (Blueprint $table) {
            $table->id('tax_class_id');
            $table->string('title', 32);
            $table->string('description', 255);
            $table->dateTime('date_added');
            $table->dateTime('date_modified');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_tax_class');
    }
};
