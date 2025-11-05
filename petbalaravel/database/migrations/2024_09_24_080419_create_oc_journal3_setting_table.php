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
        Schema::create('oc_journal3_setting', function (Blueprint $table) {
            $table->integer('store_id')->unsigned();
            $table->string('setting_group', 128);
            $table->string('setting_name', 128);
            $table->text('setting_value');
            $table->integer('serialized');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_journal3_setting');
    }
};
