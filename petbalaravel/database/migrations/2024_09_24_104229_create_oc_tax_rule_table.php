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
        Schema::create('oc_tax_rule', function (Blueprint $table) {
            $table->id('tax_rule_id');
            $table->integer('tax_class_id');
            $table->integer('tax_rate_id');
            $table->string('based', 10);
            $table->integer('priority')->default(1);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_tax_rule');
    }
};
