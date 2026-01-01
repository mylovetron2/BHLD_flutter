import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/allocation_provider.dart';

class AllocationScreen extends StatefulWidget {
  const AllocationScreen({super.key});

  @override
  State<AllocationScreen> createState() => _AllocationScreenState();
}

class _AllocationScreenState extends State<AllocationScreen> {
  final _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    final provider = context.read<AllocationProvider>();
    provider.loadHistory(
      manv: _searchController.text.isNotEmpty ? _searchController.text : null,
      fromDate: _fromDate != null
          ? DateFormat('yyyy-MM-dd').format(_fromDate!)
          : null,
      toDate: _toDate != null
          ? DateFormat('yyyy-MM-dd').format(_toDate!)
          : null,
      status: _statusFilter == 'all' ? null : _statusFilter,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (_fromDate ?? DateTime.now())
          : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử cấp phát'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
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
                              _loadHistory();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _loadHistory(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _fromDate != null
                              ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                              : 'Từ ngày',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _toDate != null
                              ? DateFormat('dd/MM/yyyy').format(_toDate!)
                              : 'Đến ngày',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'all',
                      label: Text('Tất cả'),
                      icon: Icon(Icons.list),
                    ),
                    ButtonSegment(
                      value: 'allocated',
                      label: Text('Đang dùng'),
                      icon: Icon(Icons.check_circle),
                    ),
                    ButtonSegment(
                      value: 'returned',
                      label: Text('Đã trả'),
                      icon: Icon(Icons.archive),
                    ),
                  ],
                  selected: {_statusFilter},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _statusFilter = newSelection.first;
                    });
                    _loadHistory();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<AllocationProvider>(
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
                          onPressed: _loadHistory,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                if (provider.history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có lịch sử',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _loadHistory(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.history.length,
                    itemBuilder: (context, index) {
                      final item = provider.history[index];
                      final statusColor = item.getStatusColor();
                      final statusText = item.getStatusText();
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
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      item.isAllocated
                                          ? Icons.check_circle
                                          : Icons.archive,
                                      color: statusColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.tenvt ?? 'Thiết bị ${item.mavt}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Mã: ${item.mavt}',
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
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    backgroundColor: statusColor.withOpacity(
                                      0.1,
                                    ),
                                    side: BorderSide.none,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${item.manv} - ${item.tennhanvien}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.tenphongban != null &&
                                  item.tenphongban!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.business,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.tenphongban!,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
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
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(
                                              DateTime.parse(item.ngnhan),
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.isAllocated) ...[
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hạn trả',
                                              style: TextStyle(
                                                color: item.isOverdue
                                                    ? Colors.red
                                                    : Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('dd/MM/yyyy').format(
                                                DateTime.parse(item.ngnhantt),
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: item.isOverdue
                                                    ? Colors.red
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.grey.shade300,
                                      ),
                                    ],
                                    const SizedBox(width: 12),
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
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.dmtg} tháng',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.receipt_long,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CT: ${item.mact}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
