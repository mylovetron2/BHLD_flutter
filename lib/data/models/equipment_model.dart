class EquipmentModel {
  final int mavt;
  final String tenvt;
  final String? dvt;
  final String? ghichu;

  EquipmentModel({
    required this.mavt,
    required this.tenvt,
    this.dvt,
    this.ghichu,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      mavt: int.tryParse(json['mavt']?.toString() ?? '0') ?? 0,
      tenvt: json['tenvt']?.toString() ?? '',
      dvt: json['dvt']?.toString(),
      ghichu: json['ghichu']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'mavt': mavt, 'tenvt': tenvt, 'dvt': dvt, 'ghichu': ghichu};
  }

  String get displayName => '$tenvt (${dvt ?? 'cái'})';
}
