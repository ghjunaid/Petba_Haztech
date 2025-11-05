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
        Schema::create('oc_event', function (Blueprint $table) {
            $table->id('event_id');
            $table->string('code', 64);
            $table->text('trigger');
            $table->text('action');
            $table->tinyInteger('status');
            $table->integer('sort_order');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_event');
    }
};
