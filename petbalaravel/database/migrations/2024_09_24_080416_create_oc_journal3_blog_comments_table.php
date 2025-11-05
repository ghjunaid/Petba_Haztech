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
        Schema::create('oc_journal3_blog_comments', function (Blueprint $table) {
            $table->id('comment_id');
            $table->integer('parent_id')->nullable();
            $table->integer('post_id')->nullable();
            $table->integer('customer_id')->nullable();
            $table->integer('author_id')->nullable();
            $table->string('name', 256)->nullable();
            $table->string('email', 256)->nullable();
            $table->string('website', 256)->nullable();
            $table->text('comment')->nullable();
            $table->tinyInteger('status')->nullable();
            $table->dateTime('date')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_journal3_blog_comments');
    }
};
