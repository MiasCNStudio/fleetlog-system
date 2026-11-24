<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bitacoras', function (Blueprint $table) {
            $table->string('trip_category', 32)->default('asignacion')->after('type');
            $table->text('notes')->nullable()->after('official_instruction');
            $table->index('trip_category');
        });
    }

    public function down(): void
    {
        Schema::table('bitacoras', function (Blueprint $table) {
            $table->dropIndex(['trip_category']);
            $table->dropColumn(['trip_category', 'notes']);
        });
    }
};
