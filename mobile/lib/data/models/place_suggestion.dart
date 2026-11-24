class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.provider,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? provider;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      placeId: json['place_id']?.toString(),
      provider: json['provider']?.toString(),
    );
  }
}
