class MonthlyReportModel {
  final String month; // Format: "MM/yyyy"
  final List<DepartmentReportModel> departments;
  final EquipmentSummaryModel? summary;

  MonthlyReportModel({
    required this.month,
    required this.departments,
    this.summary,
  });

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    return MonthlyReportModel(
      month: json['month'] ?? '',
      departments:
          (json['departments'] as List<dynamic>?)
              ?.map((dept) => DepartmentReportModel.fromJson(dept))
              .toList() ??
          [],
      summary: json['summary'] != null
          ? EquipmentSummaryModel.fromJson(json['summary'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'departments': departments.map((dept) => dept.toJson()).toList(),
      'summary': summary?.toJson(),
    };
  }
}

class DepartmentReportModel {
  final String departmentCode; // mapb
  final String departmentName; // tenphongban
  final List<EmployeeEquipmentModel> employees;

  DepartmentReportModel({
    required this.departmentCode,
    required this.departmentName,
    required this.employees,
  });

  factory DepartmentReportModel.fromJson(Map<String, dynamic> json) {
    return DepartmentReportModel(
      departmentCode: json['mapb'] ?? '',
      departmentName: json['tenphongban'] ?? '',
      employees:
          (json['employees'] as List<dynamic>?)
              ?.map((emp) => EmployeeEquipmentModel.fromJson(emp))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mapb': departmentCode,
      'tenphongban': departmentName,
      'employees': employees.map((emp) => emp.toJson()).toList(),
    };
  }
}

class EmployeeEquipmentModel {
  final String employeeCode; // manv
  final String employeeName; // tennhanvien
  final Map<String, EquipmentStatus> equipmentStatus;
  // Key: tên thiết bị, Value: trạng thái đã nhận

  EmployeeEquipmentModel({
    required this.employeeCode,
    required this.employeeName,
    required this.equipmentStatus,
  });

  factory EmployeeEquipmentModel.fromJson(Map<String, dynamic> json) {
    final Map<String, EquipmentStatus> status = {};

    if (json['equipment'] != null) {
      (json['equipment'] as Map<String, dynamic>).forEach((key, value) {
        status[key] = EquipmentStatus.fromJson(value);
      });
    }

    return EmployeeEquipmentModel(
      employeeCode: json['manv'] ?? '',
      employeeName: json['tennhanvien'] ?? '',
      equipmentStatus: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'manv': employeeCode,
      'tennhanvien': employeeName,
      'equipment': equipmentStatus.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  // Helper để lấy số lượng từng loại thiết bị
  int getEquipmentCount(String equipmentName) {
    return equipmentStatus[equipmentName]?.received ?? 0;
  }

  int getRequiredCount(String equipmentName) {
    return equipmentStatus[equipmentName]?.required ?? 0;
  }

  bool hasEquipment(String equipmentName) {
    return equipmentStatus.containsKey(equipmentName) &&
        (equipmentStatus[equipmentName]?.received ?? 0) > 0;
  }
}

class EquipmentStatus {
  final int received; // Số lượng đã nhận
  final int required; // Số lượng cần nhận (định mức)
  final String? notes; // Ghi chú

  EquipmentStatus({required this.received, required this.required, this.notes});

  factory EquipmentStatus.fromJson(Map<String, dynamic> json) {
    return EquipmentStatus(
      received: json['received'] ?? 0,
      required: json['required'] ?? 0,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'received': received, 'required': required, 'notes': notes};
  }
}

// Model cho thống kê tổng hợp vật tư
class EquipmentSummaryModel {
  final List<EquipmentSummaryItem> items;
  final int totalQuantity;

  EquipmentSummaryModel({required this.items, required this.totalQuantity});

  factory EquipmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return EquipmentSummaryModel(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => EquipmentSummaryItem.fromJson(item))
              .toList() ??
          [],
      totalQuantity: json['totalQuantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'totalQuantity': totalQuantity,
    };
  }
}

class EquipmentSummaryItem {
  final String code; // mavt
  final String name; // tenvt
  final String unit; // dvt
  final int quantity; // soluong

  EquipmentSummaryItem({
    required this.code,
    required this.name,
    required this.unit,
    required this.quantity,
  });

  factory EquipmentSummaryItem.fromJson(Map<String, dynamic> json) {
    return EquipmentSummaryItem(
      code: json['mavt'] ?? '',
      name: json['tenvt'] ?? '',
      unit: json['dvt'] ?? '',
      quantity: json['soluong'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'mavt': code, 'tenvt': name, 'dvt': unit, 'soluong': quantity};
  }
}
