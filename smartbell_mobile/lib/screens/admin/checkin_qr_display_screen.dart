import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CheckinQrDisplayScreen extends StatelessWidget {
  const CheckinQrDisplayScreen({super.key});

  static const _qrValue = 'smartbell-checkin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("QR code d'entrée SmartBell",
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 16)),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QR container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrValue,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SmartBell Check-in',
                style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "Imprimez ce QR code et collez-le\nà l'entrée de la salle",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Partage — bientôt disponible')),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_outlined, color: Color(0xFFE5A01A), size: 18),
                      SizedBox(width: 8),
                      Text('Télécharger / Partager',
                          style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
