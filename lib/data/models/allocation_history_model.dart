import 'package:flutter/material.dart';

class AllocationHistoryModel {
  final String mact;
  final String manv;
  final String tennhanvien;
  final String? tenphongban;
  final int mavt;
  final String? tenvt;
  final String? dvt;
  final int sl;
  final String ngnhan;
  final String ngnhantt;
  final int dmtg;
  final String ngct;

  AllocationHistoryModel({
    required this.mact,
    required this.manv,
    required this.tennhanvien,
    this.tenphongban,
    required this.mavt,
    this.tenvt,
    this.dvt,
    required this.sl,
    required this.ngnhan,
    required this.ngnhantt,
    required this.dmtg,
    required this.ngct,
  });

  factory AllocationHistoryModel.fromJson(Map<String, dynamic> json) {
    return AllocationHistoryModel(
      mact: json['mact']?.toString() ?? '',
      manv: json['manv']?.toString() ?? '',
      tennhanvien: json['tennhanvien']?.toString() ?? '',
      tenphongban: json['tenphongban']?.toString(),
      mavt: int.tryParse(json['mavt']?.toString() ?? '0') ?? 0,
      tenvt: json['tenvt']?.toString(),
      dvt: json['dvt']?.toString(),
      sl: int.tryParse(json['sl']?.toString() ?? '0') ?? 0,
      ngnhan: json['ngnhan']?.toString() ?? '',
      ngnhantt: json['ngnhantt']?.toString() ?? '',
      dmtg: int.tryParse(json['dmtg']?.toString() ?? '0') ?? 0,
      ngct: json['ngct']?.toString() ?? '',
    );
  }

  bool get isAllocated => sl == 1;

  bool get isOverdue {
    if (!isAllocated) return false;
    try {
      final dueDate = DateTime.parse(ngnhantt);
      return DateTime.now().isAfter(dueDate);
    } catch (e) {
      return false;
    }
  }

  Color getStatusColor() {
    if (!isAllocated) return Colors.grey;
    if (isOverdue) return Colors.red;
    return Colors.green;
  }

  String getStatusText() {
    if (!isAllocated) return 'Đã trả';
    if (isOverdue) return 'Quá hạn';
    return 'Đang sử dụng';
  }
}
