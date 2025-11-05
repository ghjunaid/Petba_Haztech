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
        Schema::create('oc_customer_login', function (Blueprint $table) {
            $table->id('customer_login_id');
            $table->string('email', 96)->nullable(false);
            $table->string('ip', 40)->nullable(false);
            $table->integer('total')->nullable(false);
            $table->dateTime('date_added')->nullable(false);
            $table->dateTime('date_modified')->nullable(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oc_customer_login');
    }
};
