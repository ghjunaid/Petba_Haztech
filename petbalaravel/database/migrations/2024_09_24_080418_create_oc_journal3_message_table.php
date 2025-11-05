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
        Schema::create('oc_journal3_message', function (Blueprint $table) {
            $table->id('message_id');
            $table->string('name', 256)->nullable();
            $table->string('email', 256)->nullable();
            $table->text('fields');
            $table->integer('store_id')->nullable();
            $table->string('url', 256)->nullable();
            $table->dateTime('date')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_journal3_message');
    }
};
