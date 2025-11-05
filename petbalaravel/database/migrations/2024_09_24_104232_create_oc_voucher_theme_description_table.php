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
        Schema::create('oc_voucher_theme_description', function (Blueprint $table) {
            $table->integer('voucher_theme_id');
            $table->integer('language_id');
            $table->string('name', 32);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_voucher_theme_description');
    }
};
