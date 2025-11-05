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
        Schema::create('oc_category', function (Blueprint $table) {
            $table->id('category_id');
            $table->string('image', 255)->nullable(true);
            $table->integer('parent_id')->nullable(false)->default(0);
            $table->tinyInteger('top')->nullable(false);
            $table->integer('column')->nullable(false);
            $table->integer('sort_order')->nullable(false)->default(0);
            $table->tinyInteger('status')->nullable(false);
            $table->dateTime('date_added')->nullable(false);
            $table->dateTime('date_modified')->nullable(false);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('oc_category');
    }
};
