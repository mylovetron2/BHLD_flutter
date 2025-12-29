class CertificateDetailModel {
  final String mact;
  final int mavt;
  final int dmtg;
  final int sl;
  final String ngnhan;
  final String ngnhantt;
  String? tenvt;
  String? dvt;

  CertificateDetailModel({
    required this.mact,
    required this.mavt,
    required this.dmtg,
    required this.sl,
    required this.ngnhan,
    required this.ngnhantt,
    this.tenvt,
    this.dvt,
  });

  factory CertificateDetailModel.fromJson(Map<String, dynamic> json) {
    return CertificateDetailModel(
      mact: json['mact']?.toString() ?? '',
      mavt: int.tryParse(json['mavt']?.toString() ?? '0') ?? 0,
      dmtg: int.tryParse(json['dmtg']?.toString() ?? '0') ?? 0,
      sl: int.tryParse(json['sl']?.toString() ?? '0') ?? 0,
      ngnhan: json['ngnhan']?.toString() ?? '1911-11-11',
      ngnhantt: json['ngnhantt']?.toString() ?? '1911-11-11',
      tenvt: json['tenvt']?.toString(),
      dvt: json['dvt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mact': mact,
      'mavt': mavt,
      'dmtg': dmtg,
      'sl': sl,
      'ngnhan': ngnhan,
      'ngnhantt': ngnhantt,
    };
  }

  bool get isAllocated => sl > 0;
  bool get isPending => ngnhan == '1911-11-11';

  String get statusText {
    if (isPending) return 'Chưa nhận';
    if (isAllocated) return 'Đã cấp';
    return 'Đã trả';
  }
}
