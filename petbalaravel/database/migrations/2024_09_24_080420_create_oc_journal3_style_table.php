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
        Schema::create('oc_journal3_style', function (Blueprint $table) {
            $table->string('style_name', 64);
            $table->string('style_label', 64);
            $table->string('style_type', 64);
            $table->mediumText('style_value');
            $table->integer('serialized');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_journal3_style');
    }
};
