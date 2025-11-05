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
        Schema::create('oc_tax_rate', function (Blueprint $table) {
            $table->id('tax_rate_id');
            $table->integer('geo_zone_id')->default(0);
            $table->string('name', 32);
            $table->decimal('rate', 15, 4)->default(0.0000);
            $table->char('type', 1);
            $table->dateTime('date_added');
            $table->dateTime('date_modified');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_tax_rate');
    }
};
