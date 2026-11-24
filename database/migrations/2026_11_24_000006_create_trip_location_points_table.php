<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trip_location_points', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tracking_session_id')->constrained('trip_tracking_sessions')->cascadeOnDelete();
            $table->timestamp('recorded_at');
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->decimal('accuracy_m', 8, 2)->nullable();
            $table->decimal('speed_kmh', 7, 2)->nullable();
            $table->decimal('heading', 6, 2)->nullable();
            $table->decimal('altitude_m', 8, 2)->nullable();
            $table->unsignedTinyInteger('battery_level')->nullable();
            $table->boolean('is_moving')->default(true);
            $table->string('source', 32)->default('background');
            $table->string('address_hint', 255)->nullable();
            $table->timestamps();

            $table->index(['tracking_session_id', 'recorded_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trip_location_points');
    }
};
