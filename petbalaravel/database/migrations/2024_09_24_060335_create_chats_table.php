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
        Schema::create('chats', function (Blueprint $table) {
            $table->id('chat_id');
            $table->integer('conversation_id')->nullable(false);
            $table->text('message')->nullable(false);
            $table->text('imageUrl')->nullable(false);
            $table->integer('sender_id')->nullable(false);
            $table->integer('receiver_id')->nullable(false);
            $table->integer('from_id')->nullable(false);
            $table->integer('adoption_id')->nullable(false);
            $table->dateTime('date_time')->nullable(false);
            $table->tinyInteger('status')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('chats');
    }
};
