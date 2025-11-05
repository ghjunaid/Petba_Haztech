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
        Schema::create('oc_translation', function (Blueprint $table) {
            $table->id('translation_id');
            $table->integer('store_id');
            $table->integer('language_id');
            $table->string('route', 64);
            $table->string('key', 64);
            $table->text('value');
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_translation');
    }
};
