import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrDisplayScreen extends StatelessWidget {
  const QrDisplayScreen({super.key});

  static const _qrValue = 'smartbell-checkin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("QR code d'entrée",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icône + titre ───────────────────────────────────────────────
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code, color: Color(0xFFE5A01A), size: 32),
            ),
            const SizedBox(height: 16),
            const Text('QR code SmartBell',
                style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              "Imprimez et plastifiez ce QR code.\nCollez-le à l'entrée de la salle.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.5),
            ),

            // ── Carte QR ────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                QrImageView(
                  data: _qrValue,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(_qrValue,
                    style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
              ]),
            ),

            // ── Étapes ──────────────────────────────────────────────────────
            _Step(number: '1', text: "Faites une capture d'écran de ce QR code"),
            const SizedBox(height: 12),
            _Step(number: '2', text: 'Imprimez-le en format A4 et plastifiez-le'),
            const SizedBox(height: 12),
            _Step(number: '3', text: "Collez-le bien visible à l'entrée de la salle"),

            // ── Bouton partager ─────────────────────────────────────────────
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                try {
                  await Share.share(
                    'SmartBell Check-in QR: $_qrValue',
                    subject: 'QR code entrée SmartBell',
                  );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copiez le texte : $_qrValue')),
                    );
                  }
                }
              },
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share, color: Color(0xFFE5A01A), size: 20),
                    SizedBox(width: 10),
                    Text('Partager le QR code',
                        style: TextStyle(color: Color(0xFFE5A01A), fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28, height: 28,
        decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(number,
            style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(text, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13)),
        ),
      ),
    ]);
  }
}
