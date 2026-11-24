<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicle_maintenances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('vehicle_id')->constrained('vehicles')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('title', 150);
            $table->text('description')->nullable();
            $table->string('status', 24)->default('programado')->index();
            $table->unsignedInteger('scheduled_odometer_km')->nullable();
            $table->unsignedInteger('completed_odometer_km')->nullable();
            $table->date('scheduled_date')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->string('workshop', 150)->nullable();
            $table->decimal('cost_usd', 10, 2)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicle_maintenances');
    }
};
