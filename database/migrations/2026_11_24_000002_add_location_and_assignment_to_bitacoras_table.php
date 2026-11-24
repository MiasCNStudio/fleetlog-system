<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bitacoras', function (Blueprint $table) {
            $table->foreignId('assignment_id')->nullable()->after('driver_id')->constrained('assignments')->nullOnDelete();
            $table->text('destination_address')->nullable()->after('destination');
            $table->decimal('latitude', 10, 7)->nullable()->after('destination_address');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
            $table->string('place_id', 255)->nullable()->after('longitude');
            $table->text('official_instruction')->nullable()->after('companions');
        });
    }

    public function down(): void
    {
        Schema::table('bitacoras', function (Blueprint $table) {
            $table->dropConstrainedForeignId('assignment_id');
            $table->dropColumn([
                'destination_address',
                'latitude',
                'longitude',
                'place_id',
                'official_instruction',
            ]);
        });
    }
};
