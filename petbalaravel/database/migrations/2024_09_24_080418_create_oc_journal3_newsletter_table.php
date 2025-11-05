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
        Schema::create('oc_journal3_newsletter', function (Blueprint $table) {
            $table->id('newsletter_id');
            $table->string('name', 256)->nullable();
            $table->string('email', 256)->nullable();
            $table->string('ip', 40)->nullable();
            $table->integer('store_id')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_journal3_newsletter');
    }
};
