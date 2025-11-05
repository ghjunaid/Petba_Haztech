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
        Schema::create('oc_upload', function (Blueprint $table) {
            $table->id('upload_id');
            $table->string('name', 255);
            $table->string('filename', 255);
            $table->string('code', 255);
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_upload');
    }
};
