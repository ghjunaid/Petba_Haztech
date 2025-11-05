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
        Schema::create('oc_journal3_blog_category', function (Blueprint $table) {
            $table->id('category_id');
            $table->integer('parent_id')->nullable();
            $table->string('image', 256)->nullable();
            $table->tinyInteger('status')->nullable();
            $table->integer('sort_order')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_journal3_blog_category');
    }
};
