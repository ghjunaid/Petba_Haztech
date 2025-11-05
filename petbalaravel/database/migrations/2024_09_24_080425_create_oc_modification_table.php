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
        Schema::create('oc_modification', function (Blueprint $table) {
            $table->id('modification_id');
            $table->integer('extension_install_id')->unsigned();
            $table->string('name', 64);
            $table->string('code', 64);
            $table->string('author', 64);
            $table->string('version', 32);
            $table->string('link', 255);
            $table->mediumText('xml');
            $table->tinyInteger('status');
            $table->dateTime('date_added');
            $table->integer('extension_download_id')->unsigned();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_modification');
    }
};
