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
        Schema::create('oc_marketing', function (Blueprint $table) {
            $table->id('marketing_id');
            $table->string('name', 32);
            $table->text('description');
            $table->string('code', 64);
            $table->integer('clicks')->default(0);
            $table->dateTime('date_added');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_marketing');
    }
};
