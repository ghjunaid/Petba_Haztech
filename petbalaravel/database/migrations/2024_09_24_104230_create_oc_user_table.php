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
        Schema::create('oc_user', function (Blueprint $table) {
            $table->id('user_id');
            $table->integer('user_group_id');
            $table->string('username', 20);
            $table->string('password', 40);
            $table->string('salt', 9);
            $table->string('firstname', 32);
            $table->string('lastname', 32);
            $table->string('email', 96);
            $table->string('image', 255);
            $table->string('code', 40);
            $table->string('ip', 40);
            $table->boolean('status');
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_user');
    }
};
