import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/storage/hive_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final lastSync = HiveService.lastSyncDate;

    final syncText = lastSync != null
        ? 'Données du ${DateFormat('dd/MM à HH:mm').format(lastSync)}'
        : 'Aucune synchronisation récente';

    // AnimatedContainer slides from height 0 → 40 when offline
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isOnline ? 0 : 40,
      color: const Color(0xFFE24B4A),
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Colors.white, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode hors-ligne · $syncText',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
