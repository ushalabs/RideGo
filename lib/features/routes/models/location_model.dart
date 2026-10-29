class LocationModel {
  final String id;
  final String name;
  final String province;
  final String? terminalName;

  const LocationModel({
    required this.id,
    required this.name,
    required this.province,
    this.terminalName,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      province: json['province'] as String? ?? 'Samar',
      terminalName: json['terminal_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province': province,
      'terminal_name': terminalName,
    };
  }
}
