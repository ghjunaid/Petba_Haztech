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
        Schema::create('rescue_comments', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->integer('from_id');
            $table->integer('rescue_id');
            $table->string('c_time', 50);
            $table->string('AmPm', 20)->nullable();
            $table->text('comment')->charset('utf8mb4')->collation('utf8mb4_general_ci');
        });
    }
    

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rescue_comments');
    }
};
