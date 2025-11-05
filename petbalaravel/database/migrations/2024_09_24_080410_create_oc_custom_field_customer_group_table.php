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
        Schema::create('oc_custom_field_customer_group', function (Blueprint $table) {
            $table->integer('custom_field_id')->unsigned();
            $table->integer('customer_group_id')->unsigned();
            $table->tinyInteger('required');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_custom_field_customer_group');
    }
};
