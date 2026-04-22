<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('person_type')->default('funcionario')->after('password');
            $table->string('driver_code')->nullable()->unique()->after('person_type');
            $table->string('photo_path')->nullable()->after('driver_code');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['person_type', 'driver_code', 'photo_path']);
        });
    }
};
