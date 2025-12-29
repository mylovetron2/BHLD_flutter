import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/certificate_model.dart';
import '../../providers/certificate_provider.dart';

class CertificateDetailScreen extends StatefulWidget {
  final CertificateModel certificate;

  const CertificateDetailScreen({super.key, required this.certificate});

  @override
  State<CertificateDetailScreen> createState() =>
      _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
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
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

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
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
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
      final provider = context.read<CertificateProvider>();
      final success = await provider.allocateEquipment(
        mact: widget.certificate.mact,
        mavt: mavt,
        ngnhan: dateController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Cấp phát thành công' : 'Cấp phát thất bại',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
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
      final provider = context.read<CertificateProvider>();
      final success = await provider.deallocateEquipment(
        mact: widget.certificate.mact,
        mavt: mavt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Thu hồi thành công' : 'Thu hồi thất bại'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chứng từ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetails,
            tooltip: 'Làm mới',
          ),
        ],
      ),
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
                          '',
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isAllocated
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isAllocated
                                        ? Icons.check_circle
                                        : Icons.inventory_2,
                                    color: isAllocated
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detail.tenvt ??
                                            'Thiết bị ${detail.mavt}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Mã: ${detail.mavt}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    isAllocated ? 'Đã cấp' : 'Chưa cấp',
                                    style: TextStyle(
                                      color: isAllocated
                                          ? Colors.green
                                          : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: isAllocated
                                      ? Colors.green.shade50
                                      : Colors.grey.shade100,
                                  side: BorderSide.none,
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
