<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('vehicles', function (Blueprint $table) {
            $table->string('plate_type', 10)->nullable()->after('license_plate');
            $table->string('plate_number', 24)->nullable()->after('plate_type');
            $table->unsignedInteger('next_maintenance_odometer')->nullable()->after('maintenance_interval_km');
            $table->unsignedInteger('maintenance_alert_before_km')->default(500)->after('next_maintenance_odometer');
            $table->unsignedInteger('last_maintenance_odometer')->nullable()->after('maintenance_alert_before_km');
            $table->timestamp('last_maintenance_at')->nullable()->after('last_maintenance_odometer');
        });
    }

    public function down(): void
    {
        Schema::table('vehicles', function (Blueprint $table) {
            $table->dropColumn([
                'plate_type',
                'plate_number',
                'next_maintenance_odometer',
                'maintenance_alert_before_km',
                'last_maintenance_odometer',
                'last_maintenance_at',
            ]);
        });
    }
};
