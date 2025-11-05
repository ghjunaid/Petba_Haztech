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
        Schema::create('blog_comment', function (Blueprint $table) {
            $table->id('id');
            $table->integer('from_id')->nullable(false);
            $table->integer('blog_id')->nullable(false);
            $table->string('b_time', 50)->nullable(false);
            $table->text('comment')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('blog_comment');
    }
};
