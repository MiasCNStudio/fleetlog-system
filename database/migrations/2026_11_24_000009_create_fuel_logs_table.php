<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fuel_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('vehicle_id')->constrained('vehicles')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('driver_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('filled_at')->index();
            $table->unsignedInteger('odometer_km');
            $table->decimal('gallons', 8, 2);
            $table->decimal('cost_usd', 10, 2)->nullable();
            $table->string('fuel_type', 24)->default('regular');
            $table->string('station', 150)->nullable();
            $table->boolean('full_tank')->default(true);
            $table->unsignedInteger('km_since_last')->nullable();
            $table->decimal('km_per_gallon', 8, 2)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fuel_logs');
    }
};
