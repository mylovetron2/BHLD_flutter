import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/employee_provider.dart';
import '../employee/employee_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController? controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final employeeProvider = context.read<EmployeeProvider>();
      await employeeProvider.selectEmployeeByCode(code);

      if (mounted) {
        if (employeeProvider.selectedEmployee != null) {
          // Navigate to employee detail for allocation
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeDetailScreen()),
          );
        } else {
          _showError('Không tìm thấy nhân viên với mã: $code');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã nhân viên'),
        actions: [
          IconButton(
            icon: Icon(
              controller?.torchEnabled ?? false
                  ? Icons.flash_on
                  : Icons.flash_off,
            ),
            onPressed: () {
              controller?.toggleTorch();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () {
              controller?.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner View
          MobileScanner(controller: controller, onDetect: _handleBarcode),

          // Overlay with instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hướng camera vào mã QR/Barcode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã nhân viên sẽ được tự động nhận diện',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
