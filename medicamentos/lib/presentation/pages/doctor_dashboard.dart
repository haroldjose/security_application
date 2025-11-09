import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionmedicamentos/domain/entities/user.dart';
import 'package:gestionmedicamentos/presentation/pages/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:gestionmedicamentos/application/providers/user_provider.dart';
import '../../application/providers/medicamento_provider.dart';
import 'retiro_medicamentos_page.dart';

class DoctorDashboard extends ConsumerStatefulWidget {
  final UserEntity user;
  const DoctorDashboard({super.key, required this.user});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final user = ref.read(currentUserProvider);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${user?.name}_profile.png';
      final newImage = await File(pickedFile.path).copy(path);
      setState(() => _profileImage = newImage);
    }
  }

  Future<void> loadProfileImage() async {
    final user = ref.read(currentUserProvider);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${user?.name}_profile.png';
    if (File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  @override
  void initState() {
    super.initState();
    ref.read(medicamentoProvider.notifier).loadMedicamentos();
    loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final medicamentosState = ref.watch(medicamentoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Panel Médico')),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (_) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt_outlined),
                                    title: const Text('Tomar foto'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library_outlined),
                                    title: const Text('Seleccionar de galería'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                          child: _profileImage == null
                              ? const Icon(Icons.person, size: 32, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${user?.name} (${user?.specialty ?? '-'})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user?.role ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Retiros de Medicamentos'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RetiroMedicamentosPage()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lista de Medicamentos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: medicamentosState.when(
                data: (medicamentos) => ListView.builder(
                  itemCount: medicamentos.length,
                  itemBuilder: (_, i) {
                    final m = medicamentos[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.medication_outlined),
                        title: Text(m.nombre),
                        subtitle: Text(
                          'Lab: ${m.laboratorio} • Precio: \$${m.precio} • Stock: ${m.cantidad}',
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
