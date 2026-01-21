import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Ekran skanera kodów kreskowych EAN
/// 
/// WYMAGANIE KLIENTA:
/// - Skanowanie EAN włączone
/// - Dodawanie produktów do koszyka przez skan kodu
/// - Używana kamera tabletu lub zewnętrzny skaner
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanning = true;
  String? _lastScannedCode;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isProcessing) return;
    
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    
    final code = barcode.rawValue!;
    
    // Ignoruj powtórzenia tego samego kodu
    if (code == _lastScannedCode) return;
    
    setState(() {
      _lastScannedCode = code;
      _isProcessing = true;
    });
    
    // Zwróć zeskanowany kod do poprzedniego ekranu
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skanuj kod EAN'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Przycisk latarki
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on 
                      ? Icons.flash_on 
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Latarka',
          ),
          // Przycisk zmiany kamery
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Zmień kamerę',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Podgląd kamery
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          
          // Ramka skanowania
          Center(
            child: Container(
              width: 280,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.green : Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isProcessing ? Icons.check_circle : Icons.qr_code_scanner,
                    color: _isProcessing ? Colors.green : Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isProcessing 
                        ? 'Znaleziono!' 
                        : 'Skieruj na kod kreskowy',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Instrukcja na dole
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Skanuj kody EAN produktów',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Produkt zostanie wyszukany w katalogu\ni dodany do koszyka',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_lastScannedCode != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        'Ostatni skan: $_lastScannedCode',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Przycisk ręcznego wprowadzenia kodu
          Positioned(
            bottom: 180,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () => _showManualEntryDialog(context),
              icon: const Icon(Icons.keyboard),
              label: const Text('Wpisz kod ręcznie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wpisz kod EAN'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '1234567890123',
            labelText: 'Kod kreskowy',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.qr_code),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(code);
              }
            },
            child: const Text('Szukaj'),
          ),
        ],
      ),
    );
  }
}
