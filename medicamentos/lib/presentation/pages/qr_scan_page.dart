import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatefulWidget {
  final Function(String) onScan;

  const QrScanPage({Key? key, required this.onScan}) : super(key: key);

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Escanear código QR'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  onDetect: (capture) {
                    if (_isScanned) return;
                    final barcode = capture.barcodes.first;
                    final code = barcode.rawValue;

                    if (code != null) {
                      _isScanned = true;
                      widget.onScan(code);

                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) Navigator.pop(context);
                      });
                    }
                  },
                ),
                Container(
                  color: Colors.black.withOpacity(0.2),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            color: Colors.white, size: 80),
                        SizedBox(height: 12),
                        Text(
                          'Apunta al código QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}













// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// class QrScanPage extends StatefulWidget {
//   final Function(String) onScan;

//   const QrScanPage({Key? key, required this.onScan}) : super(key: key);

//   @override
//   State<QrScanPage> createState() => _QrScanPageState();
// }

// class _QrScanPageState extends State<QrScanPage> {
//   bool _isScanned = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Escanear código QR')),
//       body: MobileScanner(
//         onDetect: (capture) {
//           if (_isScanned) return; 

//           final barcode = capture.barcodes.first;
//           final code = barcode.rawValue;

//           if (code != null) {
//             _isScanned = true; 
//             widget.onScan(code);

//             Future.delayed(const Duration(milliseconds: 300), () {
//               if (mounted) {
//                 Navigator.pop(context);
//               }
//             });
//           }
//         },
//       ),
//     );
//   }
// }

