<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('oc_download_description', function (Blueprint $table) {
            $table->increments('download_id'); // 'true' sets it as auto-increment
            $table->primary('download_id');
            $table->integer('language_id')->unsigned();
            $table->string('name', 64);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_download_description');
    }
};
