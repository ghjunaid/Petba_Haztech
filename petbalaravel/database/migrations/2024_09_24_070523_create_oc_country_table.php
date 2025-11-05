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
        Schema::create('oc_country', function (Blueprint $table) {
            $table->id('country_id');
            $table->string('name', 128)->nullable(false);
            $table->string('iso_code_2', 2)->nullable(false);
            $table->string('iso_code_3', 3)->nullable(false);
            $table->text('address_format')->nullable(false);
            $table->tinyInteger('postcode_required')->nullable(false);
            $table->tinyInteger('status')->nullable(false)->default(1);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_country');
    }
};
