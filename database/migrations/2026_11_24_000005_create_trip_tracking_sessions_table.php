<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trip_tracking_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('salida_bitacora_id')->unique()->constrained('bitacoras')->cascadeOnDelete();
            $table->foreignId('regreso_bitacora_id')->nullable()->constrained('bitacoras')->nullOnDelete();
            $table->foreignId('assignment_id')->nullable()->constrained('assignments')->nullOnDelete();
            $table->foreignId('vehicle_id')->constrained('vehicles')->cascadeOnDelete();
            $table->foreignId('driver_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('started_by_user_id')->constrained('users')->cascadeOnDelete();

            // Vinculación estricta al celular / dispositivo exacto que inició la misión
            $table->string('device_uuid', 128)->index();
            $table->string('device_name', 120);
            $table->string('device_platform', 40)->nullable();
            $table->unsignedBigInteger('started_by_token_id')->nullable();

            $table->string('status', 24)->default('activa')->index();
            $table->timestamp('started_at')->index();
            $table->timestamp('ended_at')->nullable();
            $table->timestamp('last_ping_at')->nullable();

            $table->decimal('last_latitude', 10, 7)->nullable();
            $table->decimal('last_longitude', 10, 7)->nullable();
            $table->decimal('last_speed_kmh', 7, 2)->nullable();
            $table->unsignedTinyInteger('last_battery_level')->nullable();

            $table->unsignedInteger('points_count')->default(0);
            $table->decimal('gps_distance_km', 10, 2)->default(0);
            $table->unsignedInteger('declared_distance_km')->nullable();
            $table->decimal('max_speed_kmh', 7, 2)->default(0);
            $table->unsignedInteger('stops_count')->default(0);
            $table->boolean('has_sos_alert')->default(false);
            $table->json('summary_json')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trip_tracking_sessions');
    }
};
