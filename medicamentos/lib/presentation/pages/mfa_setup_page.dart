import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';

class MfaSetupPage extends StatefulWidget {
  const MfaSetupPage({super.key});

  @override
  State<MfaSetupPage> createState() => _MfaSetupPageState();
}

class _MfaSetupPageState extends State<MfaSetupPage> {
  String? qrCodeUrl;

  @override
  void initState() {
    super.initState();
    _enableMfa();
  }

  Future<void> _enableMfa() async {
    final supabase = SupabaseConfig.client;
    try {
      final factor = await supabase.auth.mfa.enroll(factorType: FactorType.totp);
      setState(() => qrCodeUrl = factor.totp!.qrCode);
    } catch (e) {
      debugPrint('❌ Error activando MFA: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar MFA (TOTP)')),
      body: Center(
        child: qrCodeUrl == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Escanea este QR en Google Authenticator:'),
                  const SizedBox(height: 20),
                  Image.network(qrCodeUrl!, width: 240),
                  const SizedBox(height: 20),
                  const Text('Luego ingresa el código para verificar.'),
                ],
              ),
      ),
    );
  }
}
