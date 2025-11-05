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
        Schema::create('notification', function (Blueprint $table) {
            $table->id('id');
            $table->integer('customer_id')->nullable(false);
            $table->tinyInteger('flag')->nullable(false)->default(1);
            $table->string('type', 20)->nullable(false);
            $table->text('title')->nullable(false);
            $table->text('body')->nullable(false);
            $table->text('data')->nullable(false);
            $table->string('time', 50)->nullable(false);
            $table->string('notification_time', 20)->nullable(true);
            $table->text('img')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notification');
    }
};
