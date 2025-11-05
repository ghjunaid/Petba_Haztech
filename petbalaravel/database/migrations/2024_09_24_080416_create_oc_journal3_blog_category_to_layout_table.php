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
        Schema::create('oc_journal3_blog_category_to_layout', function (Blueprint $table) {
            $table->integer('category_id')->unsigned();
            $table->integer('store_id')->unsigned()->default(0);
            $table->integer('layout_id')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_journal3_blog_category_to_layout');
    }
};
