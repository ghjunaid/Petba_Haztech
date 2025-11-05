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
        Schema::create('oc_return_reason', function (Blueprint $table) {
            $table->id('return_reason_id');
            $table->unsignedInteger('language_id')->default(0);
            $table->string('name', 128);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_return_reason');
    }
};
