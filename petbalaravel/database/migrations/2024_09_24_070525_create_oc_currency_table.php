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
        Schema::create('oc_currency', function (Blueprint $table) {
            $table->id('currency_id');
            $table->string('title',  32)->nullable(false);
            $table->string('code', 3)->nullable(false);
            $table->string('symbol_left', 12)->nullable(false);
            $table->string('symbol_right', 12)->nullable(false);
            $table->char('decimal_place', 1)->nullable(false);
            $table->double('value', 15, 8)->nullable(false);
            $table->tinyInteger('status')->nullable(false);
            $table->dateTime('date_modified')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_currency');
    }
};
