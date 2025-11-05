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
        Schema::create('oc_journal3_blog_post_description', function (Blueprint $table) {
            $table->integer('post_id')->unsigned();
            $table->integer('language_id')->unsigned();
            $table->string('name', 256)->nullable();
            $table->mediumText('description')->nullable();
            $table->string('meta_title', 256)->nullable();
            $table->string('meta_keywords', 256)->nullable();
            $table->text('meta_description')->nullable();
            $table->string('keyword', 256)->nullable();
            $table->string('tags', 256)->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_journal3_blog_post_description');
    }
};
