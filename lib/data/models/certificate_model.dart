class CertificateModel {
  final String mact;
  final String ngct;
  final String mapb;
  final String manv;
  final String? ghichu;
  final String madm;
  String? tennhanvien;
  String? tenphongban;

  CertificateModel({
    required this.mact,
    required this.ngct,
    required this.mapb,
    required this.manv,
    this.ghichu,
    required this.madm,
    this.tennhanvien,
    this.tenphongban,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      mact: json['mact']?.toString() ?? '',
      ngct: json['ngct']?.toString() ?? '',
      mapb: json['mapb']?.toString() ?? '',
      manv: json['manv']?.toString() ?? '',
      ghichu: json['ghichu']?.toString(),
      madm: json['madm']?.toString() ?? '',
      tennhanvien: json['tennhanvien']?.toString(),
      tenphongban: json['tenphongban']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mact': mact,
      'ngct': ngct,
      'mapb': mapb,
      'manv': manv,
      'ghichu': ghichu,
      'madm': madm,
    };
  }

  String get displayDate => ngct.split(' ')[0]; // Format: yyyy-mm-dd
}
