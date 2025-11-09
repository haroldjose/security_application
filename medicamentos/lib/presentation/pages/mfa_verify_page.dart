import 'package:flutter/material.dart';
import 'package:gestionmedicamentos/presentation/pages/admin_panel_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import '../../../domain/entities/user.dart';
import 'admin_dashboard.dart';
import 'doctor_dashboard.dart';

class MfaVerifyPage extends StatefulWidget {
  final String name;

  const MfaVerifyPage({super.key, required this.name});

  @override
  State<MfaVerifyPage> createState() => _MfaVerifyPageState();
}

class _MfaVerifyPageState extends State<MfaVerifyPage> {
  final codeController = TextEditingController();
  bool verifying = false;

  Future<void> _verify() async {
    setState(() => verifying = true);

    try {
      final supabase = SupabaseConfig.client;
      final user = supabase.auth.currentUser;

      if (user?.factors == null || user!.factors!.isEmpty) {
        throw Exception('No se encontró factor MFA activo');
      }

      // Verificamos el código TOTP
      await supabase.auth.mfa.challengeAndVerify(
        factorId: user.factors!.first.id,
        code: codeController.text.trim(),
      );

      // Buscamos datos del usuario en la tabla pública
      final userData = await SupabaseConfig.client
          .from('users')
          .select('name, role, specialty, area')
          .eq('name', widget.name)
          .maybeSingle();

      if (userData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró información del usuario')),
        );
        return;
      }

      // Construimos entidad local segura
      final userEntity = UserEntity(
        name: userData['name'] ?? widget.name,
        password: '',
        role: userData['role'] ?? 'doctor',
        specialty: userData['specialty'],
        area: userData['area'],
      );

      if (!mounted) return;

      // Navegación segura según rol
      if (userEntity.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminPanelPage( )),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DoctorDashboard(user: userEntity)),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error verificando MFA: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código inválido o expirado')),
      );
    } finally {
      if (mounted) setState(() => verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar MFA')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Introduce tu código de 6 dígitos',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_clock_outlined),
                  labelText: 'Código TOTP',
                ),
              ),
              const SizedBox(height: 20),
              verifying
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      onPressed: _verify,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Verificar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
