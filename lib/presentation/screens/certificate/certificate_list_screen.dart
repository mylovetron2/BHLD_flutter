import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/certificate_provider.dart';
import 'certificate_detail_screen.dart';

class CertificateListScreen extends StatefulWidget {
  const CertificateListScreen({super.key});

  @override
  State<CertificateListScreen> createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen> {
  final _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCertificates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCertificates() {
    final provider = context.read<CertificateProvider>();
    provider.loadCertificates(
      manv: _searchController.text.isNotEmpty ? _searchController.text : null,
      fromDate: _fromDate != null
          ? DateFormat('yyyy-MM-dd').format(_fromDate!)
          : null,
      toDate: _toDate != null
          ? DateFormat('yyyy-MM-dd').format(_toDate!)
          : null,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách chứng từ'),
        actions: [
          if (_searchController.text.isNotEmpty ||
              _fromDate != null ||
              _toDate != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Xóa bộ lọc',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Search by employee code
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã nhân viên...',
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
                  ),
                  onSubmitted: (_) => _loadCertificates(),
                ),
                const SizedBox(height: 12),
                // Date filter
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _fromDate != null
                              ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                              : 'Từ ngày',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _toDate != null
                              ? DateFormat('dd/MM/yyyy').format(_toDate!)
                              : 'Đến ngày',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 32),
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(
                              Icons.description,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            certificate.mact,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${certificate.manv} - ${certificate.tennhanvien ?? ''}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.business,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      certificate.tenphongban ??
                                          certificate.mapb ??
                                          '',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(DateTime.parse(certificate.ngct)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CertificateDetailScreen(
                                  certificate: certificate,
                                  filterToDate: _toDate,
                                ),
                              ),
                            );
                          },
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
    );
  }
}
