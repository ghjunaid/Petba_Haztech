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
        Schema::create('blogLikeRelation', function (Blueprint $table) {
            $table->id('id');
            $table->integer('customer_id')->nullable(false);
            $table->integer('blog_id')->nullable(false);
            $table->enum('liked', ['1', '0'])->nullable(false)->comment('1:liked, 0:not Liked');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('blog_like_relation');
    }
};
