import 'package:flutter/material.dart';

import '../../data/models/certificate_detail_model.dart';
import '../../data/models/certificate_model.dart';
import '../../data/repositories/bhld_repository.dart';

class CertificateProvider with ChangeNotifier {
  final BhldRepository _repository = BhldRepository();

  List<CertificateModel> _certificates = [];
  CertificateModel? _selectedCertificate;
  final Map<String, List<CertificateDetailModel>> _certificateDetailsMap = {};
  bool _isLoading = false;
  String? _error;

  List<CertificateModel> get certificates => _certificates;
  CertificateModel? get selectedCertificate => _selectedCertificate;
  List<CertificateDetailModel> get certificateDetails {
    // Return all details from all certificates for backward compatibility
    final allDetails = <CertificateDetailModel>[];
    for (var details in _certificateDetailsMap.values) {
      allDetails.addAll(details);
    }
    return allDetails;
  }

  List<CertificateDetailModel> getDetailsForCertificate(String mact) {
    return _certificateDetailsMap[mact] ?? [];
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCertificates({
    String? manv,
    String? fromDate,
    String? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _certificates = await _repository.getCertificates(
        manv: manv,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCertificateDetails(String mact) async {
    try {
      final details = await _repository.getCertificateDetails(mact);
      _certificateDetailsMap[mact] = details;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> allocateEquipment({
    required String mact,
    required int mavt,
    required String ngnhan,
  }) async {
    try {
      final result = await _repository.allocateEquipment(
        mact: mact,
        mavt: mavt,
        ngnhan: ngnhan,
      );

      // Don't auto-reload to avoid concurrent modification
      // Screen will handle reload

      return result['success'];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deallocateEquipment({
    required String mact,
    required int mavt,
  }) async {
    try {
      final result = await _repository.deallocateEquipment(
        mact: mact,
        mavt: mavt,
      );

      // Don't auto-reload to avoid concurrent modification
      // Screen will handle reload

      return result['success'];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setSelectedCertificate(CertificateModel certificate) {
    _selectedCertificate = certificate;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
