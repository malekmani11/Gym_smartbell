import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/providers/auth_provider.dart';

class CheckinScannerScreen extends StatefulWidget {
  const CheckinScannerScreen({super.key});

  @override
  State<CheckinScannerScreen> createState() => _CheckinScannerScreenState();
}

class _CheckinScannerScreenState extends State<CheckinScannerScreen> {
  late final MobileScannerController _controller;
  bool _processing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      torchEnabled: false,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    setState(() => _processing = true);
    _controller.stop();

    if (raw != 'smartbell-checkin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code non reconnu')),
      );
      _restartScanner();
      return;
    }

    _handleCheckin();
  }

  Future<void> _handleCheckin() async {
    final token = context.read<AuthProvider>().user?.token ?? '';
    try {
      final res = await DioClient.instance.dio.post(
        '/checkins',
        data: {'qrCode': 'smartbell-checkin'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) _showResult(success: true, data: res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Erreur lors du check-in';
      if (mounted) _showResult(success: false, message: msg);
    }
  }

  void _restartScanner() {
    setState(() => _processing = false);
    _controller.start();
  }

  void _showResult({required bool success, Map<String, dynamic>? data, String? message}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ResultSheet(
        success: success,
        data: data,
        message: message,
        onClose: () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context); // close scanner
        },
        onScanAgain: () {
          Navigator.pop(context); // close sheet
          _restartScanner();
        },
        onHistory: () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context); // close scanner
          context.go('/member/checkin-history');
        },
      ),
    ).whenComplete(() {
      if (_processing) _restartScanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark overlay with cutout
          CustomPaint(
            size: Size.infinite,
            painter: _ScanOverlayPainter(),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Check-in SmartBell',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _controller.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _torchOn ? const Color(0xFFE5A01A) : Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.flashlight_on,
                        color: _torchOn ? Colors.black : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom hint
          Positioned(
            bottom: 80,
            left: 0, right: 0,
            child: _processing
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE5A01A)),
                  )
                : const Text(
                    "Pointez vers le QR code de l'entrée",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay painter ────────────────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutSize = 240.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: cutSize, height: cutSize);
    const radius = Radius.circular(8);

    final dark = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      dark,
    );

    // Golden corners
    final corner = Paint()
      ..color = const Color(0xFFE5A01A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 30.0;
    final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;

    // Top-left
    canvas.drawLine(Offset(l, t + len), Offset(l, t + 8), corner);
    canvas.drawLine(Offset(l + 8, t), Offset(l + len, t), corner);
    // Top-right
    canvas.drawLine(Offset(r, t + len), Offset(r, t + 8), corner);
    canvas.drawLine(Offset(r - 8, t), Offset(r - len, t), corner);
    // Bottom-left
    canvas.drawLine(Offset(l, b - len), Offset(l, b - 8), corner);
    canvas.drawLine(Offset(l + 8, b), Offset(l + len, b), corner);
    // Bottom-right
    canvas.drawLine(Offset(r, b - len), Offset(r, b - 8), corner);
    canvas.drawLine(Offset(r - 8, b), Offset(r - len, b), corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Result bottom sheet ────────────────────────────────────────────────────────

class _ResultSheet extends StatelessWidget {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;
  final VoidCallback onClose;
  final VoidCallback onScanAgain;
  final VoidCallback onHistory;

  const _ResultSheet({
    required this.success,
    this.data,
    this.message,
    required this.onClose,
    required this.onScanAgain,
    required this.onHistory,
  });

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberName = data?['memberName'] as String?;
    final subStatus = (data?['subscriptionStatus'] as String? ?? '').toUpperCase();
    final expiryDate = data?['expiryDate'] as String?;
    final isSubActive = subStatus == 'ACTIVE';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),

          // Icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: success ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              color: success ? const Color(0xFF3B6D11) : const Color(0xFFA32D2D),
              size: 38,
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            success ? 'Check-in réussi !' : 'Check-in échoué',
            style: TextStyle(
              color: success ? const Color(0xFF1A1A1A) : const Color(0xFFA32D2D),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          if (success && memberName != null) ...[
            Text(memberName, style: const TextStyle(color: Color(0xFF555555), fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSubActive ? const Color(0xFFEAF3DE) : const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isSubActive ? 'Abonnement actif' : 'Abonnement expiré',
                style: TextStyle(
                  color: isSubActive ? const Color(0xFF3B6D11) : const Color(0xFF854F0B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (expiryDate != null) ...[
              const SizedBox(height: 6),
              Text(
                'Expire le ${_formatDate(expiryDate)}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
            ],
          ],

          if (!success && message != null) ...[
            const SizedBox(height: 4),
            Text(message!, style: const TextStyle(color: Color(0xFF888888), fontSize: 13), textAlign: TextAlign.center),
          ],

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F0),
                      border: Border.all(color: const Color(0xFFE8E8E8)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Fermer', textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onScanAgain,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Scanner encore', textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onHistory,
            child: const Text(
              'Voir l\'historique de mes visites',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
