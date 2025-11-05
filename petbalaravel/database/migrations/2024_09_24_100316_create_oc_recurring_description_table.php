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
        Schema::create('oc_recurring_description', function (Blueprint $table) {
            $table->unsignedInteger('recurring_id');
            $table->unsignedInteger('language_id');
            $table->string('name', 255);

            $table->primary(['recurring_id', 'language_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_recurring_description');
    }
};
