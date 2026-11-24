<?php

namespace App\Services;

use App\Models\SystemLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

class SystemLogger
{
    public static function record(
        ?User $user,
        string $module,
        string $action,
        string $summary,
        ?Model $subject = null,
        array $metadata = [],
        ?Request $request = null,
    ): SystemLog {
        $req = $request ?? request();

        return SystemLog::query()->create([
            'user_id' => $user?->id,
            'user_name' => $user?->name ?? 'Sistema',
            'user_role' => $user?->role,
            'module' => $module,
            'action' => $action,
            'subject_type' => $subject ? class_basename($subject) : null,
            'subject_id' => $subject?->getKey(),
            'summary' => mb_substr($summary, 0, 500),
            'metadata' => empty($metadata) ? null : $metadata,
            'ip_address' => $req?->ip(),
            'created_at' => now(),
        ]);
    }
}
