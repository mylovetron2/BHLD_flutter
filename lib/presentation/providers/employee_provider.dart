import 'package:flutter/material.dart';

import '../../data/models/employee_model.dart';
import '../../data/repositories/bhld_repository.dart';

class EmployeeProvider with ChangeNotifier {
  final BhldRepository _repository = BhldRepository();

  List<EmployeeModel> _employees = [];
  EmployeeModel? _selectedEmployee;
  bool _isLoading = false;
  String? _error;

  List<EmployeeModel> get employees => _employees;
  EmployeeModel? get selectedEmployee => _selectedEmployee;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEmployees({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _employees = await _repository.getEmployees(search: search);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectEmployeeByCode(String manv) async {
    try {
      _selectedEmployee = await _repository.getEmployeeByCode(manv);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setSelectedEmployee(EmployeeModel employee) {
    _selectedEmployee = employee;
    notifyListeners();
  }

  void clearSelectedEmployee() {
    _selectedEmployee = null;
    notifyListeners();
  }

  Future<bool> updateEmployeeName(String manv, String tennhanvien) async {
    try {
      final success = await _repository.updateEmployeeName(manv, tennhanvien);
      if (success) {
        // Update local list if successful
        final index = _employees.indexWhere((e) => e.manv == manv);
        if (index != -1) {
          _employees[index] = EmployeeModel(
            manv: _employees[index].manv,
            tennhanvien: tennhanvien,
            mapb: _employees[index].mapb,
            tenphongban: _employees[index].tenphongban,
            dinhmuc: _employees[index].dinhmuc,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
