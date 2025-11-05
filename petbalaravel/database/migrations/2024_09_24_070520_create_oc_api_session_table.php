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
        Schema::create('oc_api_session', function (Blueprint $table) {
            $table->id('api_session_id');
            $table->integer('api_id')->nullable(false);
            $table->string('session_id', 32)->nullable(false);
            $table->string('ip', 40)->nullable(false);
            $table->dateTime('date_added')->nullable(false);
            $table->dateTime('date_modified')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_api_session');
    }
};
