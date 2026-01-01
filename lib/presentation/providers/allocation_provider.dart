import 'package:flutter/material.dart';

import '../../data/models/allocation_history_model.dart';
import '../../data/repositories/bhld_repository.dart';

class AllocationProvider with ChangeNotifier {
  final BhldRepository _repository = BhldRepository();

  List<AllocationHistoryModel> _history = [];
  bool _isLoading = false;
  String? _error;

  List<AllocationHistoryModel> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHistory({
    String? manv,
    int? mavt,
    String? fromDate,
    String? toDate,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _repository.getAllocationHistory(
        manv: manv,
        mavt: mavt,
        fromDate: fromDate,
        toDate: toDate,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _history = [];
    _error = null;
    notifyListeners();
  }
}
