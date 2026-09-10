import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/presence_provider.dart';

/// Écran de scan du QR Code de séance pour valider sa présence.
/// Ticket MOB-B2. [RG-PRES-04]
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final provider = context.read<PresenceProvider>();
    if (provider.statutScan == ScanStatus.enCours) return;

    final barcodes = capture.barcodes;
    final contenu = barcodes.isNotEmpty ? barcodes.first.rawValue : null;
    if (contenu == null || contenu.isEmpty) return;

    provider.validerQrCode(contenu);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner ma présence'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Consumer<PresenceProvider>(
        builder: (context, provider, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(controller: _controller, onDetect: _onDetect),
              _CadreVise(),
              if (provider.statutScan != ScanStatus.idle)
                _BandeauResultat(
                  provider: provider,
                  onFermer: () {
                    provider.reinitialiserScan();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CadreVise extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _BandeauResultat extends StatelessWidget {
  final PresenceProvider provider;
  final VoidCallback onFermer;

  const _BandeauResultat({required this.provider, required this.onFermer});

  @override
  Widget build(BuildContext context) {
    final succes = provider.statutScan == ScanStatus.succes;
    final enCours = provider.statutScan == ScanStatus.enCours;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (enCours) const CircularProgressIndicator()
            else
              Icon(
                succes ? Icons.check_circle : Icons.error,
                color: succes ? Colors.green : Colors.redAccent,
                size: 40,
              ),
            const SizedBox(height: 12),
            Text(
              enCours ? 'Vérification en cours...' : (provider.messageScan ?? ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (!enCours) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onFermer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5AAC),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(succes ? 'Scanner une autre séance' : 'Réessayer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
