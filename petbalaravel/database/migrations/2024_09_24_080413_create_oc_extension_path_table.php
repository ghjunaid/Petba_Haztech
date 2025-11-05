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
        Schema::create('oc_extension_path', function (Blueprint $table) {
            $table->id('extension_path_id');
            $table->integer('extension_install_id')->unsigned();
            $table->string('path', 255);
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_extension_path');
    }
};
