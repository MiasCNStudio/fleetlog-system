import 'dart:convert';

class SystemLogEntry {
  const SystemLogEntry({
    required this.id,
    required this.userName,
    required this.module,
    required this.action,
    required this.summary,
    required this.createdAt,
    this.userRole,
    this.ipAddress,
    this.metadata,
  });

  final int id;
  final String userName;
  final String? userRole;
  final String module;
  final String action;
  final String summary;
  final String createdAt;
  final String? ipAddress;
  final Map<String, dynamic>? metadata;

  String get prettyMetadata =>
      metadata == null ? '' : const JsonEncoder.withIndent('  ').convert(metadata);

  factory SystemLogEntry.fromJson(Map<String, dynamic> json) {
    return SystemLogEntry(
      id: (json['id'] as num).toInt(),
      userName: (json['user_name'] ?? 'Sistema').toString(),
      userRole: json['user_role']?.toString(),
      module: (json['module'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      ipAddress: json['ip_address']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }
}
