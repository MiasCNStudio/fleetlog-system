<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('vehicles', function (Blueprint $table) {
            $table->string('status', 32)->default('disponible')->after('model');
            $table->unsignedInteger('current_odometer')->default(0)->after('status');
            $table->unsignedInteger('maintenance_interval_km')->nullable()->after('current_odometer');
        });

        Schema::table('bitacoras', function (Blueprint $table) {
            $table->foreignId('driver_id')->nullable()->after('user_id')->constrained('users')->nullOnDelete();
            $table->unsignedInteger('odometer_km')->nullable()->after('recorded_at');
            $table->string('fuel_level', 32)->nullable()->after('odometer_km');
            $table->index(['type', 'recorded_at']);
        });

        // Sincronizar estado inicial de vehículos existentes según su última bitácora
        $vehicles = DB::table('vehicles')->select('id')->get();
        foreach ($vehicles as $vehicle) {
            $last = DB::table('bitacoras')
                ->where('vehicle_id', $vehicle->id)
                ->orderByDesc('recorded_at')
                ->orderByDesc('id')
                ->first();

            if ($last && $last->type === 'salida') {
                DB::table('vehicles')->where('id', $vehicle->id)->update(['status' => 'en_ruta']);
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bitacoras', function (Blueprint $table) {
            $table->dropIndex(['type', 'recorded_at']);
            $table->dropConstrainedForeignId('driver_id');
            $table->dropColumn(['odometer_km', 'fuel_level']);
        });

        Schema::table('vehicles', function (Blueprint $table) {
            $table->dropColumn(['status', 'current_odometer', 'maintenance_interval_km']);
        });
    }
};
