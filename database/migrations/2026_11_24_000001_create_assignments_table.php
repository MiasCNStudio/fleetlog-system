<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('vehicle_id')->constrained()->cascadeOnDelete();
            $table->foreignId('driver_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->date('scheduled_date');
            $table->string('scheduled_time', 10)->nullable();
            $table->string('schedule_group_id', 36)->nullable();
            $table->string('destination', 255);
            $table->text('destination_address')->nullable();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->string('place_id', 255)->nullable();
            $table->text('companions')->nullable();
            $table->text('description')->nullable();
            $table->text('official_instruction')->nullable();
            $table->string('status', 32)->default('pendiente');
            $table->boolean('is_emergency_reassigned')->default(false);
            $table->foreignId('original_driver_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('reassigned_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('reassignment_reason')->nullable();
            $table->timestamp('reassigned_at')->nullable();
            $table->timestamps();

            $table->index(['scheduled_date', 'status']);
            $table->index(['driver_id', 'scheduled_date']);
            $table->index(['vehicle_id', 'scheduled_date']);
            $table->index('schedule_group_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('assignments');
    }
};
