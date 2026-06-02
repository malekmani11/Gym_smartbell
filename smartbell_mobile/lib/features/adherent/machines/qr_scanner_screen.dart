import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/scanner_overlay.dart';
import 'machine_detail_screen.dart';
import 'machine_model.dart';

const _checkinQr = 'smartbell-checkin';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _processing = false;
  bool _torchOn    = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final rawValue = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _processing = true);
    await _ctrl.stop();
    await _handleCode(rawValue);
    if (mounted) {
      setState(() => _processing = false);
      await _ctrl.start();
    }
  }

  Future<void> _handleCode(String code) async {
    if (code == _checkinQr) {
      await _doCheckIn();
    } else {
      await _doMachineLookup(code);
    }
  }

  Future<void> _doCheckIn() async {
    try {
      final res = await DioClient.instance.dio.post('/checkins', data: {
        'qrCode': _checkinQr,
      });

      if (!mounted) return;
      final data          = res.data as Map<String, dynamic>;
      final status        = data['status'] as String? ?? 'SUCCESS';
      final pointsAwarded = (data['pointsAwarded'] as num?)?.toInt() ?? 0;
      final note          = data['note'] as String? ?? '';

      await _showCheckinResult(
        success: status == 'SUCCESS',
        points: pointsAwarded,
        note: note,
      );
    } catch (e) {
      if (!mounted) return;
      await _showCheckinResult(success: false, points: 0, note: 'Erreur de connexion');
    }
  }

  Future<void> _doMachineLookup(String code) async {
    try {
      final res = await DioClient.instance.dio.get('/training/machines/qr/$code');
      if (!mounted) return;
      final machine = Machine.fromJson(res.data as Map<String, dynamic>);
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MachineDetailScreen(machine: machine)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR code non reconnu'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCheckinResult({
    required bool success,
    required int points,
    required String note,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CheckinResultDialog(
        success: success,
        points: points,
        note: note,
      ),
    );
  }

  Future<void> _toggleTorch() async {
    await _ctrl.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  // Web fallback handler
  Future<void> _handleWebCode(String code) async {
    if (_processing) return;
    setState(() => _processing = true);
    await _handleCode(code);
    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _WebFallback(onCode: _handleWebCode);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera feed ──
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),

          // ── Animated overlay ──
          const ScannerOverlay(),

          // ── Processing blocker ──
          if (_processing)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Traitement en cours...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top controls ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ScanBtn(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _ScanBtn(
                    icon: _torchOn ? Icons.flash_off : Icons.flash_on,
                    onTap: _toggleTorch,
                    active: _torchOn,
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom guide ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Pointez vers le QR code',
                        style: TextStyle(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Entrée salle ou machine',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5), fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Check-in result dialog ────────────────────────────────────────────────────

class _CheckinResultDialog extends StatelessWidget {
  final bool success;
  final int  points;
  final String note;
  const _CheckinResultDialog({required this.success, required this.points, required this.note});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: (success ? const Color(0xFF4CAF50) : const Color(0xFFE53935))
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: success ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Entrée validée !' : 'Accès refusé',
              style: TextStyle(
                color: success ? const Color(0xFF1A1A1A) : const Color(0xFFE53935),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              note,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (success && points > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A01A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5A01A).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFE5A01A), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '+$points points de fidélité',
                      style: const TextStyle(
                        color: Color(0xFFE5A01A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: const Color(0xFFE5A01A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _ScanBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(
            color: active
                ? AppTheme.primary.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icon,
          color: active ? AppTheme.primary : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

// ── Web fallback ───────────────────────────────────────────────────────────────

class _WebFallback extends StatefulWidget {
  final Future<void> Function(String code) onCode;
  const _WebFallback({required this.onCode});

  @override
  State<_WebFallback> createState() => _WebFallbackState();
}

class _WebFallbackState extends State<_WebFallback> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty || _loading) return;
    setState(() => _loading = true);
    await widget.onCode(code);
    if (mounted) {
      setState(() => _loading = false);
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: const Text('Scanner QR code',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 15)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.qr_code_scanner, color: AppTheme.primary, size: 34),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan caméra non disponible sur web',
              style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Saisissez le code QR manuellement\nou utilisez l\'application mobile.',
              style: TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _ctrl,
              onSubmitted: (_) => _submit(),
              autofocus: true,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ex: smartbell-checkin',
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF888888), size: 20),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                      )
                    : const Text('Valider',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
