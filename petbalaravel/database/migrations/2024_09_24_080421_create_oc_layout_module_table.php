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
        Schema::create('oc_layout_module', function (Blueprint $table) {
            $table->id('layout_module_id');
            $table->integer('layout_id')->unsigned();
            $table->string('code', 64);
            $table->string('position', 14);
            $table->integer('sort_order');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_layout_module');
    }
};
