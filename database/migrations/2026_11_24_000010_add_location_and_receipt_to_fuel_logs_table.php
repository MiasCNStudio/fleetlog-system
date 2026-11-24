<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('fuel_logs', function (Blueprint $table) {
            $table->foreignId('bitacora_id')->nullable()->after('driver_id')->constrained('bitacoras')->nullOnDelete();
            $table->decimal('latitude', 10, 7)->nullable()->after('station');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
            $table->string('location_address', 255)->nullable()->after('longitude');
            $table->string('receipt_path', 255)->nullable()->after('notes');
            $table->string('receipt_name', 180)->nullable()->after('receipt_path');
        });
    }

    public function down(): void
    {
        Schema::table('fuel_logs', function (Blueprint $table) {
            $table->dropConstrainedForeignId('bitacora_id');
            $table->dropColumn([
                'latitude',
                'longitude',
                'location_address',
                'receipt_path',
                'receipt_name',
            ]);
        });
    }
};
