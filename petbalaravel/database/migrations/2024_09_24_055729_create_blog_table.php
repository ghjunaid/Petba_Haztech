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
        Schema::create('blog', function (Blueprint $table) {
            $table->id('id');
            $table->integer('author')->nullable(false);
            $table->string('title', 25)->nullable(false);
            $table->integer('like_count')->nullable(false)->default(0);
            $table->string('subtitle', 30)->nullable(false);
            $table->text('description')->nullable(false);
            $table->text('img')->nullable(false);
            $table->timestamp('date_time')->useCurrent()->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('blog');
    }
};
