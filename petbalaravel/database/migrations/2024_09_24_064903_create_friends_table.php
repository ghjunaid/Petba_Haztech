<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('friends', function (Blueprint $table) {
            $table->id('id');
            $table->integer('user1')->nullable(false);
            $table->integer('user2')->nullable(false);
            $table->integer('p_id')->nullable(false)->default(0);
            $table->string('petName', 50)->nullable(false);
            $table->integer('status')->nullable(false);
            $table->text('message')->nullable(false);
            $table->longText('img')->nullable(false);
            $table->dateTime('date_time')->nullable(false);
            $table->integer('sendDelete')->nullable(false);
            $table->integer('receiveDelete')->nullable(false);
            $table->tinyInteger('chatDeleted')->nullable(false)->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('friends');
    }
};
