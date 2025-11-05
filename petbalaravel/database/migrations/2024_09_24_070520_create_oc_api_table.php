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
        Schema::create('oc_api', function (Blueprint $table) {
            $table->id('api_id');
            $table->string('username', 64)->nullable(false);
            $table->text('key')->nullable(false);
            $table->tinyInteger('status')->nullable(false);
            $table->dateTime('date_added')->nullable(false);
            $table->dateTime('date_modified')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_api');
    }
};
