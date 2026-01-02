import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/equipment_categories.dart';
import '../../../data/models/certificate_model.dart';
import '../../providers/certificate_provider.dart';

class CertificateDetailScreen extends StatefulWidget {
  final CertificateModel certificate;
  final DateTime? filterToDate;

  const CertificateDetailScreen({
    super.key,
    required this.certificate,
    this.filterToDate,
  });

  @override
  State<CertificateDetailScreen> createState() =>
      _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
  final Set<int> _selectedEquipment = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  void _loadDetails() {
    context.read<CertificateProvider>().loadCertificateDetails(
      widget.certificate.mact,
    );
  }

  Future<void> _showAllocateDialog(int mavt, String tenvt) async {
    final defaultDate = widget.filterToDate != null
        ? DateFormat('yyyy-MM-dd').format(widget.filterToDate!)
        : widget.certificate.ngct;
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
              ),
              readOnly: true,
              onTap: () async {
                final initialDate =
                    widget.filterToDate ??
                    DateTime.parse(widget.certificate.ngct);
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
            child: const Text('Cấp phát'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Show loading dialog
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
        mact: widget.certificate.mact,
        mavt: mavt,
        ngnhan: dateController.text,
      );

      // Close loading dialog
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

        // Show error if any
        if (!success && provider.error != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Lỗi'),
              content: Text(provider.error ?? 'Có lỗi xảy ra'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      }
    }

    dateController.dispose();
  }

  Future<void> _showDeallocateDialog(int mavt, String tenvt) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Thu hồi thiết bị: $tenvt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Show loading dialog
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
        mact: widget.certificate.mact,
        mavt: mavt,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Thu hồi thành công' : 'Thu hồi thất bại'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        // Show error if any
        if (!success && provider.error != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Lỗi'),
              content: Text(provider.error ?? 'Có lỗi xảy ra'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _showBulkAllocateDialog() async {
    final provider = context.read<CertificateProvider>();
    final selectedDetails = provider.certificateDetails
        .where((detail) => _selectedEquipment.contains(detail.mavt))
        .toList();

    final defaultDate = widget.filterToDate != null
        ? DateFormat('yyyy-MM-dd').format(widget.filterToDate!)
        : widget.certificate.ngct;
    final dateController = TextEditingController(text: defaultDate);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cấp phát ${selectedDetails.length} thiết bị'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách thiết bị:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedDetails.map((detail) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              detail.tenvt ?? 'Thiết bị ${detail.mavt}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 24),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Ngày nhận (chung)',
                hintText: 'yyyy-MM-dd',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final initialDate =
                    widget.filterToDate ??
                    DateTime.parse(widget.certificate.ngct);
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
                Text('0 / ${selectedDetails.length}'),
              ],
            ),
          ),
        ),
      );

      int successCount = 0;
      int failCount = 0;
      final failedItems = <String>[];

      for (int i = 0; i < selectedDetails.length; i++) {
        final detail = selectedDetails[i];
        final success = await provider.allocateEquipment(
          mact: widget.certificate.mact,
          mavt: detail.mavt,
          ngnhan: dateController.text,
        );

        if (success) {
          successCount++;
        } else {
          failCount++;
          failedItems.add(detail.tenvt ?? 'Thiết bị ${detail.mavt}');
        }

        // Update progress
        if (mounted && i < selectedDetails.length - 1) {
          Navigator.pop(context); // Close old dialog
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
                    Text('${i + 1} / ${selectedDetails.length}'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (i + 1) / selectedDetails.length,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }

      // Close progress dialog
      if (mounted) Navigator.pop(context);

      // Show result dialog
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Thành công: $successCount thiết bị'),
                if (failCount > 0) ...[
                  const SizedBox(height: 8),
                  Text('❌ Thất bại: $failCount thiết bị'),
                  if (failedItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Chi tiết lỗi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...failedItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text('• $item'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );

        // Clear selection
        setState(() {
          _selectedEquipment.clear();
        });

        // Reload details
        _loadDetails();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CertificateProvider>();
    final unallocatedCount = provider.certificateDetails
        .where((detail) => detail.sl == 0)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: _selectedEquipment.isNotEmpty
            ? Text('${_selectedEquipment.length} thiết bị đã chọn')
            : const Text('Chi tiết chứng từ'),
        actions: [
          if (_selectedEquipment.isNotEmpty && unallocatedCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  // Select all unallocated equipment
                  _selectedEquipment.clear();
                  for (var detail in provider.certificateDetails) {
                    if (detail.sl == 0) {
                      _selectedEquipment.add(detail.mavt);
                    }
                  }
                });
              },
              child: const Text('Chọn tất cả'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetails,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: _selectedEquipment.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkAllocateDialog,
              icon: const Icon(Icons.add_circle),
              label: Text('Cấp phát ${_selectedEquipment.length} thiết bị'),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Certificate Info
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.certificate.mact,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Nhân viên',
                      value:
                          '${widget.certificate.manv} - ${widget.certificate.tennhanvien ?? ''}',
                    ),
                    _InfoRow(
                      icon: Icons.business,
                      label: 'Phòng ban',
                      value:
                          widget.certificate.tenphongban ??
                          widget.certificate.mapb ??
                          'Chưa có thông tin',
                    ),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Ngày chứng từ',
                      value: DateFormat(
                        'dd/MM/yyyy',
                      ).format(DateTime.parse(widget.certificate.ngct)),
                    ),
                    if (widget.certificate.ghichu != null &&
                        widget.certificate.ghichu!.isNotEmpty)
                      _InfoRow(
                        icon: Icons.note,
                        label: 'Ghi chú',
                        value: widget.certificate.ghichu!,
                      ),
                  ],
                ),
              ),
            ),

            // Equipment List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Danh sách thiết bị',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            Consumer<CertificateProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text('Lỗi: ${provider.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadDetails,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.certificateDetails.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có thiết bị nào',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.certificateDetails.length,
                  itemBuilder: (context, index) {
                    final detail = provider.certificateDetails[index];
                    final isAllocated = detail.sl == 1;
                    final isSelected = _selectedEquipment.contains(detail.mavt);
                    final category = EquipmentCategories.getCategory(
                      detail.mavt,
                      detail.tenvt,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 4 : 1,
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: InkWell(
                        onTap: !isAllocated
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedEquipment.remove(detail.mavt);
                                  } else {
                                    _selectedEquipment.add(detail.mavt);
                                  }
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (!isAllocated)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedEquipment.add(detail.mavt);
                                            } else {
                                              _selectedEquipment.remove(
                                                detail.mavt,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                // Icon vật tư theo danh mục
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: category.backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: category.color.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    category.icon,
                                    color: category.color,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Tên thiết bị nổi bật hơn
                                      Text(
                                        detail.tenvt ??
                                            'Thiết bị ${detail.mavt}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: category.color,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Mã vật tư và danh mục
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Mã: ${detail.mavt}',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: category.backgroundColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  category.icon,
                                                  size: 14,
                                                  color: category.color,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  category.name,
                                                  style: TextStyle(
                                                    color: category.color,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Status chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAllocated
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isAllocated
                                          ? Colors.green
                                          : Colors.orange,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAllocated
                                            ? Icons.check_circle
                                            : Icons.schedule,
                                        size: 16,
                                        color: isAllocated
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isAllocated ? 'Đã cấp' : 'Chưa cấp',
                                        style: TextStyle(
                                          color: isAllocated
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (isAllocated) ...[
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ngày nhận',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(
                                            DateTime.parse(detail.ngnhan),
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hạn trả',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(
                                            DateTime.parse(detail.ngnhantt),
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Định mức',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${detail.dmtg} tháng',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: isAllocated
                                  ? OutlinedButton.icon(
                                      onPressed: () => _showDeallocateDialog(
                                        detail.mavt,
                                        detail.tenvt ??
                                            'Thiết bị ${detail.mavt}',
                                      ),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      label: const Text('Thu hồi'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: () => _showAllocateDialog(
                                        detail.mavt,
                                        detail.tenvt ??
                                            'Thiết bị ${detail.mavt}',
                                      ),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      label: const Text('Cấp phát'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
