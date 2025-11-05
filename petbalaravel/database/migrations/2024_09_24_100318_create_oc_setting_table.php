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
        Schema::create('oc_setting', function (Blueprint $table) {
            $table->id('setting_id');
            $table->integer('store_id')->default(0);
            $table->string('code', 128);
            $table->string('key', 128);
            $table->text('value');
            $table->tinyInteger('serialized');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_setting');
    }
};
