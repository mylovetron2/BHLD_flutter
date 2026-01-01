import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/certificate_model.dart';
import '../../providers/certificate_provider.dart';
import '../../providers/employee_provider.dart';

class CertificateUnifiedScreen extends StatefulWidget {
  const CertificateUnifiedScreen({super.key});

  @override
  State<CertificateUnifiedScreen> createState() =>
      _CertificateUnifiedScreenState();
}

class _CertificateUnifiedScreenState extends State<CertificateUnifiedScreen> {
  final _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  final Set<String> _expandedCertificates = {};
  final Map<String, String> _selectedEquipment = {}; // mavt -> mact
  String? _selectedDepartment;
  String? _selectedEmployee;
  String? _selectedEmployeeName;
  bool _showSidebar = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmployees();
      _loadCertificates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEmployees() {
    context.read<EmployeeProvider>().loadEmployees();
  }

  void _loadCertificates() async {
    final provider = context.read<CertificateProvider>();
    await provider.loadCertificates(
      manv:
          _selectedEmployee ??
          (_searchController.text.isNotEmpty ? _searchController.text : null),
      fromDate: _fromDate != null
          ? DateFormat('yyyy-MM-dd').format(_fromDate!)
          : null,
      toDate: _toDate != null
          ? DateFormat('yyyy-MM-dd').format(_toDate!)
          : null,
    );

    // Auto-expand and load details for all certificates
    if (mounted) {
      setState(() {
        _expandedCertificates.clear();
        for (var cert in provider.certificates) {
          _expandedCertificates.add(cert.mact);
        }
      });

      // Load details for all certificates
      for (var cert in provider.certificates) {
        await provider.loadCertificateDetails(cert.mact);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _loadCertificates();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _fromDate = null;
      _toDate = null;
    });
    _loadCertificates();
  }

  String _getSelectedKey(String mact, int mavt) {
    return '$mact-$mavt';
  }

  Future<void> _showBulkAllocateDialog() async {
    if (_selectedEquipment.isEmpty) return;

    final provider = context.read<CertificateProvider>();
    final defaultDate = _toDate != null
        ? DateFormat('yyyy-MM-dd').format(_toDate!)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dateController = TextEditingController(text: defaultDate);

    // Group by certificate
    final groupedEquipment = <String, List<int>>{};
    _selectedEquipment.forEach((key, mact) {
      final mavt = int.parse(key.split('-')[1]);
      groupedEquipment.putIfAbsent(mact, () => []).add(mavt);
    });

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cấp phát ${_selectedEquipment.length} thiết bị'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thiết bị đã chọn:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...groupedEquipment.entries.map((entry) {
                final cert = provider.certificates.firstWhere(
                  (c) => c.mact == entry.key,
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${cert.tennhanvien} - ${cert.tenphongban ?? ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Divider(height: 16),
                      Text(
                        '${entry.value.length} thiết bị',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Ngày nhận (chung)',
                  hintText: 'yyyy-MM-dd',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final initialDate = _toDate ?? DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    dateController.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle),
            label: const Text('Xác nhận cấp phát'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _performBulkAllocation(dateController.text);
    }
  }

  Future<void> _performBulkAllocation(String date) async {
    final provider = context.read<CertificateProvider>();
    final totalItems = _selectedEquipment.length;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Đang cấp phát...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('0 / $totalItems'),
            ],
          ),
        ),
      ),
    );

    int successCount = 0;
    int failCount = 0;
    final failedItems = <String>[];
    int current = 0;

    // Create copy to avoid concurrent modification
    final equipmentEntries = _selectedEquipment.entries.toList();

    for (var entry in equipmentEntries) {
      // Key format: "mact-mavt", Value: mact
      // Since mact can contain '-', we use the value directly
      final mact = entry.value; // mact from map value (correct)

      // Extract mavt by removing mact prefix and the separator '-'
      final mavtString = entry.key.substring(mact.length + 1); // Skip "mact-"
      final mavt = int.parse(mavtString);

      // Debug log
      print('DEBUG: Allocating - Key: ${entry.key}, Value: ${entry.value}');
      print('DEBUG: Parsed - mact: $mact, mavt: $mavt');

      final success = await provider.allocateEquipment(
        mact: mact,
        mavt: mavt,
        ngnhan: date,
      );

      current++;

      if (success) {
        successCount++;
      } else {
        failCount++;
        failedItems.add('$mact - Thiết bị $mavt');
      }

      // Update progress
      if (mounted && current < totalItems) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Đang cấp phát...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('$current / $totalItems'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: current / totalItems),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Close progress dialog
    if (mounted) Navigator.pop(context);

    // Show result
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                failCount == 0 ? Icons.check_circle : Icons.warning,
                color: failCount == 0 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text('Kết quả cấp phát'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thành công: $successCount thiết bị',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                if (failCount > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Thất bại: $failCount thiết bị',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  if (failedItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const Text(
                      'Chi tiết lỗi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...failedItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text('• $item'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );

      // Clear selection and reload
      setState(() {
        _selectedEquipment.clear();
      });

      // Reload all expanded certificates (create copy to avoid concurrent modification)
      final expandedList = _expandedCertificates.toList();
      for (var mact in expandedList) {
        await provider.loadCertificateDetails(mact);
      }
    }
  }

  Future<void> _showAllocateDialog(String mact, int mavt, String tenvt) async {
    final defaultDate = _toDate != null
        ? DateFormat('yyyy-MM-dd').format(_toDate!)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dateController = TextEditingController(text: defaultDate);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cấp phát: $tenvt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Ngày nhận',
                hintText: 'yyyy-MM-dd',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final initialDate = _toDate ?? DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  dateController.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang cấp phát...'),
                ],
              ),
            ),
          ),
        ),
      );

      final provider = context.read<CertificateProvider>();
      final success = await provider.allocateEquipment(
        mact: mact,
        mavt: mavt,
        ngnhan: dateController.text,
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Cấp phát thành công' : 'Cấp phát thất bại',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          await provider.loadCertificateDetails(mact);
        }
      }
    }
  }

  Future<void> _showDeallocateDialog(
    String mact,
    int mavt,
    String tenvt,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thu hồi'),
        content: Text('Bạn có chắc muốn thu hồi thiết bị "$tenvt"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang thu hồi...'),
                ],
              ),
            ),
          ),
        ),
      );

      final provider = context.read<CertificateProvider>();
      final success = await provider.deallocateEquipment(
        mact: mact,
        mavt: mavt,
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Thu hồi thành công' : 'Thu hồi thất bại'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          await provider.loadCertificateDetails(mact);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedEquipment.isNotEmpty
            ? Text('${_selectedEquipment.length} thiết bị đã chọn')
            : const Text('Quản lý chứng từ'),
        actions: [
          if (_selectedEquipment.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedEquipment.clear();
                });
              },
              icon: const Icon(Icons.clear_all, color: Colors.white),
              label: const Text(
                'Bỏ chọn',
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (_searchController.text.isNotEmpty ||
              _fromDate != null ||
              _toDate != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _clearFilters,
              tooltip: 'Xóa bộ lọc',
            ),
        ],
      ),
      floatingActionButton: _selectedEquipment.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkAllocateDialog,
              icon: const Icon(Icons.add_circle),
              label: Text('Cấp phát (${_selectedEquipment.length})'),
            )
          : null,
      body: Row(
        children: [
          // Sidebar - Employee List
          if (_showSidebar)
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: _buildEmployeeSidebar(),
            ),

          // Main content - Certificates
          Expanded(
            child: Column(
              children: [
                // Filter section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_showSidebar ? Icons.menu_open : Icons.menu),
                        onPressed: () {
                          setState(() {
                            _showSidebar = !_showSidebar;
                          });
                        },
                        tooltip: _showSidebar
                            ? 'Ẩn danh sách'
                            : 'Hiện danh sách',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            if (_selectedEmployee != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _selectedEmployeeName ??
                                                _selectedEmployee ??
                                                '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (_selectedEmployeeName !=
                                              _selectedEmployee)
                                            Text(
                                              'Mã: $_selectedEmployee',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          _selectedEmployee = null;
                                          _selectedEmployeeName = null;
                                        });
                                        _loadCertificates();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            if (_selectedEmployee == null)
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Tìm theo mã nhân viên',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            _loadCertificates();
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _loadCertificates(),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectDate(context, true),
                                    icon: const Icon(
                                      Icons.date_range,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _fromDate != null
                                          ? DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(_fromDate!)
                                          : 'Từ ngày',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _selectDate(context, false),
                                    icon: const Icon(
                                      Icons.date_range,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _toDate != null
                                          ? DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(_toDate!)
                                          : 'Đến ngày',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Certificate list
                Expanded(
                  child: Consumer<CertificateProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Lỗi tải dữ liệu',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  provider.error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadCertificates,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (provider.certificates.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Không có chứng từ nào',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Thử thay đổi bộ lọc tìm kiếm',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => _loadCertificates(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.certificates.length,
                          itemBuilder: (context, index) {
                            final certificate = provider.certificates[index];
                            final isExpanded = _expandedCertificates.contains(
                              certificate.mact,
                            );

                            return _CertificateCard(
                              certificate: certificate,
                              isExpanded: isExpanded,
                              selectedEquipment: _selectedEquipment,
                              toDate: _toDate,
                              onToggleExpand: () async {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedCertificates.remove(
                                      certificate.mact,
                                    );
                                  } else {
                                    _expandedCertificates.add(certificate.mact);
                                  }
                                });

                                if (!isExpanded) {
                                  await provider.loadCertificateDetails(
                                    certificate.mact,
                                  );
                                }
                              },
                              onToggleSelect: (mavt) {
                                setState(() {
                                  final key = _getSelectedKey(
                                    certificate.mact,
                                    mavt,
                                  );
                                  if (_selectedEquipment.containsKey(key)) {
                                    _selectedEquipment.remove(key);
                                  } else {
                                    _selectedEquipment[key] = certificate.mact;
                                  }
                                });
                              },
                              onAllocate: (mavt, tenvt) => _showAllocateDialog(
                                certificate.mact,
                                mavt,
                                tenvt,
                              ),
                              onDeallocate: (mavt, tenvt) =>
                                  _showDeallocateDialog(
                                    certificate.mact,
                                    mavt,
                                    tenvt,
                                  ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSidebar() {
    return Consumer<EmployeeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        print('DEBUG SIDEBAR: employees.length = ${provider.employees.length}');
        if (provider.employees.isNotEmpty) {
          print(
            'DEBUG: First employee manv=${provider.employees[0].manv}, tennhanvien="${provider.employees[0].tennhanvien}"',
          );
        }

        if (provider.employees.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nhân viên',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng kiểm tra kết nối',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadEmployees,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.employees.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nhân viên',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng kiểm tra kết nối',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadEmployees,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter employees with names only
        final employeesWithName = provider.employees
            .where(
              (emp) => emp.tennhanvien != null && emp.tennhanvien.isNotEmpty,
            )
            .toList();

        // Group employees by department
        final employeesByDept = <String, List<dynamic>>{};
        for (var emp in employeesWithName) {
          final dept = emp.tenphongban ?? emp.mapb ?? 'Chưa phân loại';
          employeesByDept.putIfAbsent(dept, () => []).add(emp);
        }

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Danh sách nhân viên',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Department filter
            if (employeesByDept.keys.length > 1)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Lọc theo đội',
                    prefixIcon: Icon(Icons.filter_list, size: 18),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả đội'),
                    ),
                    ...employeesByDept.keys.map((dept) {
                      return DropdownMenuItem(value: dept, child: Text(dept));
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                      _selectedEmployee = null;
                    });
                  },
                ),
              ),

            // Employee list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: employeesByDept.length,
                itemBuilder: (context, index) {
                  final dept = employeesByDept.keys.elementAt(index);

                  // Skip if filtered and not matching
                  if (_selectedDepartment != null &&
                      _selectedDepartment != dept) {
                    return const SizedBox.shrink();
                  }

                  final employees = employeesByDept[dept]!;

                  return ExpansionTile(
                    initiallyExpanded:
                        _selectedDepartment == dept ||
                        employeesByDept.length == 1,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 16,
                      child: Text(
                        '${employees.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      dept,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${employees.length} nhân viên',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    children: employees.map((emp) {
                      final isSelected = _selectedEmployee == emp.manv;
                      final displayName = emp.tennhanvien.isNotEmpty
                          ? emp.tennhanvien
                          : 'NV ${emp.manv}';

                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: Colors.blue.shade50,
                        leading: Icon(
                          Icons.person,
                          size: 20,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          emp.manv,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedEmployee = emp.manv;
                            _selectedEmployeeName = displayName;
                          });
                          _loadCertificates();
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final CertificateModel certificate;
  final bool isExpanded;
  final Map<String, String> selectedEquipment;
  final DateTime? toDate;
  final VoidCallback onToggleExpand;
  final Function(int mavt) onToggleSelect;
  final Function(int mavt, String tenvt) onAllocate;
  final Function(int mavt, String tenvt) onDeallocate;

  const _CertificateCard({
    required this.certificate,
    required this.isExpanded,
    required this.selectedEquipment,
    required this.toDate,
    required this.onToggleExpand,
    required this.onToggleSelect,
    required this.onAllocate,
    required this.onDeallocate,
  });

  String _getSelectedKey(String mact, int mavt) {
    return '$mact-$mavt';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isExpanded ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExpanded
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certificate.mact,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${certificate.manv} - ${certificate.tennhanvien ?? ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(DateTime.parse(certificate.ngct)),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildEquipmentList(context),
        ],
      ),
    );
  }

  Widget _buildEquipmentList(BuildContext context) {
    return Consumer<CertificateProvider>(
      builder: (context, provider, child) {
        final details = provider.getDetailsForCertificate(certificate.mact);

        if (details.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: details.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final detail = details[index];
                  final isAllocated = detail.sl == 1;
                  final key = _getSelectedKey(certificate.mact, detail.mavt);
                  final isSelected = selectedEquipment.containsKey(key);

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade300
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (!isAllocated)
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) => onToggleSelect(detail.mavt),
                            ),
                          if (isAllocated)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail.tenvt ?? 'Thiết bị ${detail.mavt}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Mã: ${detail.mavt}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (isAllocated) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Nhận: ${DateFormat('dd/MM/yy').format(DateTime.parse(detail.ngnhan))} - Trả: ${DateFormat('dd/MM/yy').format(DateTime.parse(detail.ngnhantt))}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isAllocated)
                            IconButton(
                              onPressed: () => onDeallocate(
                                detail.mavt,
                                detail.tenvt ?? 'Thiết bị ${detail.mavt}',
                              ),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              tooltip: 'Thu hồi',
                              iconSize: 20,
                            )
                          else
                            IconButton(
                              onPressed: () => onAllocate(
                                detail.mavt,
                                detail.tenvt ?? 'Thiết bị ${detail.mavt}',
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                              color: Theme.of(context).primaryColor,
                              tooltip: 'Cấp phát',
                              iconSize: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
