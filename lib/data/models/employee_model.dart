class EmployeeModel {
  final String manv;
  final String tennhanvien;
  final String mapb;
  final String? tenphongban;
  final String? dinhmuc;

  EmployeeModel({
    required this.manv,
    required this.tennhanvien,
    required this.mapb,
    this.tenphongban,
    this.dinhmuc,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      manv: json['manv']?.toString() ?? '',
      tennhanvien: json['tennhanvien']?.toString() ?? '',
      mapb: json['mapb']?.toString() ?? '',
      tenphongban: json['tenphongban']?.toString(),
      dinhmuc: json['dinhmuc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'manv': manv,
      'tennhanvien': tennhanvien,
      'mapb': mapb,
      'tenphongban': tenphongban,
      'dinhmuc': dinhmuc,
    };
  }

  String get displayName => '$manv - $tennhanvien';
}
