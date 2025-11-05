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
        Schema::create('oc_seo_url', function (Blueprint $table) {
            $table->id('seo_url_id');
            $table->integer('store_id');
            $table->integer('language_id');
            $table->string('query', 255);
            $table->string('keyword', 255);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_seo_url');
    }
};
