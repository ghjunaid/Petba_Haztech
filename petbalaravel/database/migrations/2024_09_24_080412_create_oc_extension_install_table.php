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
        Schema::create('oc_extension_install', function (Blueprint $table) {
            $table->id('extension_install_id');
            $table->integer('extension_download_id')->unsigned();
            $table->string('filename', 255);
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_extension_install');
    }
};
