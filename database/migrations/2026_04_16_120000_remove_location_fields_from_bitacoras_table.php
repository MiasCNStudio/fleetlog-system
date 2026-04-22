<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! Schema::hasTable('bitacoras')) {
            return;
        }

        $columns = ['latitude', 'longitude', 'location_label', 'destination_latitude', 'destination_longitude'];
        $toDrop = array_values(array_filter($columns, fn (string $c) => Schema::hasColumn('bitacoras', $c)));

        if ($toDrop === []) {
            return;
        }

        Schema::table('bitacoras', function (Blueprint $table) use ($toDrop) {
            $table->dropColumn($toDrop);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (! Schema::hasTable('bitacoras')) {
            return;
        }

        Schema::table('bitacoras', function (Blueprint $table) {
            if (! Schema::hasColumn('bitacoras', 'latitude')) {
                $table->decimal('latitude', 10, 7)->nullable();
            }
            if (! Schema::hasColumn('bitacoras', 'longitude')) {
                $table->decimal('longitude', 11, 7)->nullable();
            }
            if (! Schema::hasColumn('bitacoras', 'location_label')) {
                $table->string('location_label', 500)->nullable();
            }
            if (! Schema::hasColumn('bitacoras', 'destination_latitude')) {
                $table->decimal('destination_latitude', 10, 7)->nullable();
            }
            if (! Schema::hasColumn('bitacoras', 'destination_longitude')) {
                $table->decimal('destination_longitude', 11, 7)->nullable();
            }
        });
    }
};
