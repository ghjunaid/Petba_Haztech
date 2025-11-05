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
        Schema::create('oc_filter_group_description', function (Blueprint $table) {
            $table->integer('filter_group_id')->unsigned();
            $table->integer('language_id')->unsigned();
            $table->string('name', 64);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_filter_group_description');
    }
};
