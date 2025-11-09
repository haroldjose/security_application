import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionmedicamentos/presentation/pages/qr_scan_page.dart';
import 'package:gestionmedicamentos/presentation/pages/retiro_medicamentos_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../application/providers/medicamento_provider.dart';
import '../../application/providers/user_provider.dart';
import '../pages/login_page.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/medicamento.dart';

/// Panel principal del Encargado de Farmacia
/// Permite registrar, editar y eliminar medicamentos.
/// También puede ver los retiros realizados por doctores.
/// No gestiona usuarios ni MFA.
class EncargadoDashboard extends ConsumerStatefulWidget {
  final UserEntity user;
  const EncargadoDashboard({super.key, required this.user});

  @override
  ConsumerState<EncargadoDashboard> createState() => _EncargadoDashboardState();
}

class _EncargadoDashboardState extends ConsumerState<EncargadoDashboard> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController laboratorioController = TextEditingController();
  final TextEditingController origenController = TextEditingController();
  final TextEditingController tipoController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  MedicamentoEntity? medicamentoEditando;

  @override
  void initState() {
    super.initState();
    ref.read(medicamentoProvider.notifier).loadMedicamentos();
    loadProfileImage();
  }

  /// Cargar imagen de perfil almacenada localmente
  Future<void> loadProfileImage() async {
    final user = ref.read(currentUserProvider);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${user?.name}_profile.png';
    if (File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  /// Seleccionar imagen (cámara o galería)
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

  /// Limpiar los campos del formulario
  void limpiarFormulario() {
    nombreController.clear();
    laboratorioController.clear();
    origenController.clear();
    tipoController.clear();
    precioController.clear();
    cantidadController.clear();
    setState(() => medicamentoEditando = null);
  }

  /// Escanear código QR con datos de medicamento
  void escanearQR() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScanPage(
          onScan: (code) {
            final parts = code.split(',');
            if (parts.length >= 6) {
              nombreController.text = parts[0];
              laboratorioController.text = parts[1];
              origenController.text = parts[2];
              tipoController.text = parts[3];
              precioController.text = parts[4];
              cantidadController.text = parts[5];
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Formato de QR incorrecto')),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicamentosState = ref.watch(medicamentoProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Panel del Encargado de Farmacia')),
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
                      // Imagen de perfil
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
                              'Bienvenido, ${user?.name}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            Text(user?.role ?? '', style: const TextStyle(color: Colors.white70)),
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
                title: const Text('Ver Retiros de Medicamentos'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar Medicamentos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _buildForm(context),
            const SizedBox(height: 16),
            Text('Lista de Medicamentos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _buildMedicamentosList(medicamentosState),
          ],
        ),
      ),
    );
  }

  /// Construye el formulario de registro/edición de medicamentos
  Widget _buildForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: laboratorioController, decoration: const InputDecoration(labelText: 'Laboratorio'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: origenController, decoration: const InputDecoration(labelText: 'Origen'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: tipoController, decoration: const InputDecoration(labelText: 'Tipo'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: precioController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _guardarMedicamento,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(medicamentoEditando != null ? 'Actualizar' : 'Guardar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: escanearQR,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Por QR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Guarda o actualiza el medicamento
  void _guardarMedicamento() {
    final nuevo = MedicamentoEntity(
      nombre: nombreController.text,
      laboratorio: laboratorioController.text,
      origenLaboratorio: origenController.text,
      tipoMedicamento: tipoController.text,
      precio: double.tryParse(precioController.text) ?? 0,
      cantidad: int.tryParse(cantidadController.text) ?? 0,
    );

    if (medicamentoEditando != null) {
      final actualizado = medicamentoEditando!.copyWith(
        nombre: nuevo.nombre,
        laboratorio: nuevo.laboratorio,
        origenLaboratorio: nuevo.origenLaboratorio,
        tipoMedicamento: nuevo.tipoMedicamento,
        precio: nuevo.precio,
        cantidad: nuevo.cantidad,
      );
      ref.read(medicamentoProvider.notifier).updateMedicamento(actualizado);
    } else {
      ref.read(medicamentoProvider.notifier).addMedicamento(nuevo);
    }
    limpiarFormulario();
  }

  /// Muestra la lista de medicamentos existentes
  Widget _buildMedicamentosList(AsyncValue<List<MedicamentoEntity>> medicamentosState) {
    return medicamentosState.when(
      data: (medicamentos) => Column(
        children: medicamentos.map((m) {
          return Card(
            child: ListTile(
              title: Text(m.nombre),
              subtitle: Text(
                'Lab: ${m.laboratorio} • Origen: ${m.origenLaboratorio}\n'
                'Tipo: ${m.tipoMedicamento} • Precio: \$${m.precio} • Stock: ${m.cantidad}',
              ),
              isThreeLine: true,
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        medicamentoEditando = m;
                        nombreController.text = m.nombre;
                        laboratorioController.text = m.laboratorio;
                        origenController.text = m.origenLaboratorio;
                        tipoController.text = m.tipoMedicamento;
                        precioController.text = m.precio.toString();
                        cantidadController.text = m.cantidad.toString();
                      });
                    },
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('¿Eliminar medicamento?'),
                          content: Text('¿Deseas eliminar "${m.nombre}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () {
                                ref.read(medicamentoProvider.notifier).deleteMedicamento(m);
                                Navigator.pop(context);
                              },
                              child: const Text('Eliminar', style: TextStyle(color: Color(0xFFE74C3C))),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (error, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $error')),
    );
  }
}



















// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:gestionmedicamentos/presentation/pages/qr_scan_page.dart';
// import 'package:gestionmedicamentos/presentation/pages/retiro_medicamentos_page.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';

// import '../../application/providers/medicamento_provider.dart';
// import '../../application/providers/user_provider.dart';
// import '../pages/login_page.dart';
// import '../../domain/entities/user.dart';
// import '../../domain/entities/medicamento.dart';

// class AdminDashboard extends ConsumerStatefulWidget {
//   final UserEntity user;
//   const AdminDashboard({super.key, required this.user});

//   @override
//   ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
// }

// class _AdminDashboardState extends ConsumerState<AdminDashboard> {
//   File? _profileImage;
//   final ImagePicker _picker = ImagePicker();
//   final TextEditingController nombreController = TextEditingController();
//   final TextEditingController laboratorioController = TextEditingController();
//   final TextEditingController origenController = TextEditingController();
//   final TextEditingController tipoController = TextEditingController();
//   final TextEditingController precioController = TextEditingController();
//   final TextEditingController cantidadController = TextEditingController();

//   MedicamentoEntity? medicamentoEditando;

//   @override
//   void initState() {
//     super.initState();
//     ref.read(medicamentoProvider.notifier).loadMedicamentos();
//     loadProfileImage();
//   }

//   Future<void> pickImage(ImageSource source) async {
//     final pickedFile = await _picker.pickImage(source: source);
//     if (pickedFile != null) {
//       final user = ref.read(currentUserProvider);
//       final directory = await getApplicationDocumentsDirectory();
//       final path = '${directory.path}/${user?.name}_profile.png';
//       final newImage = await File(pickedFile.path).copy(path);
//       setState(() => _profileImage = newImage);
//     }
//   }

//   Future<void> loadProfileImage() async {
//     final user = ref.read(currentUserProvider);
//     final directory = await getApplicationDocumentsDirectory();
//     final path = '${directory.path}/${user?.name}_profile.png';
//     if (File(path).existsSync()) {
//       setState(() => _profileImage = File(path));
//     }
//   }

//   void escanearQR() async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => QrScanPage(
//           onScan: (code) {
//             final parts = code.split(',');
//             if (parts.length >= 6) {
//               nombreController.text = parts[0];
//               laboratorioController.text = parts[1];
//               origenController.text = parts[2];
//               tipoController.text = parts[3];
//               precioController.text = parts[4];
//               cantidadController.text = parts[5];
//             } else {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Formato de QR incorrecto')),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }

//   void limpiarFormulario() {
//     nombreController.clear();
//     laboratorioController.clear();
//     origenController.clear();
//     tipoController.clear();
//     precioController.clear();
//     cantidadController.clear();
//     setState(() => medicamentoEditando = null);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final medicamentosState = ref.watch(medicamentoProvider);
//     final user = ref.watch(currentUserProvider);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Panel de Administrador')),
//       drawer: Drawer(
//         child: SafeArea(
//           child: ListView(
//             padding: const EdgeInsets.all(12),
//             children: [
//               Card(
//                 elevation: 0,
//                 color: Theme.of(context).colorScheme.primary,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () {
//                           showModalBottomSheet(
//                             context: context,
//                             showDragHandle: true,
//                             shape: const RoundedRectangleBorder(
//                               borderRadius:
//                                   BorderRadius.vertical(top: Radius.circular(16)),
//                             ),
//                             builder: (_) => SafeArea(
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   ListTile(
//                                     leading: const Icon(Icons.camera_alt_outlined),
//                                     title: const Text('Tomar foto'),
//                                     onTap: () {
//                                       Navigator.pop(context);
//                                       pickImage(ImageSource.camera);
//                                     },
//                                   ),
//                                   ListTile(
//                                     leading: const Icon(Icons.photo_library_outlined),
//                                     title: const Text('Seleccionar de galería'),
//                                     onTap: () {
//                                       Navigator.pop(context);
//                                       pickImage(ImageSource.gallery);
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                         child: CircleAvatar(
//                           radius: 28,
//                           backgroundImage:
//                               _profileImage != null ? FileImage(_profileImage!) : null,
//                           child: _profileImage == null
//                               ? const Icon(Icons.person, size: 32, color: Colors.white)
//                               : null,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Bienvenido, ${user?.name}',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             Text(
//                               user?.role ?? '',
//                               style: const TextStyle(color: Colors.white70),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               ListTile(
//                 leading: const Icon(Icons.receipt_long),
//                 title: const Text('Retiros de Medicamentos'),
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const RetiroMedicamentosPage()),
//                 ),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.logout),
//                 title: const Text('Cerrar sesión'),
//                 onTap: () {
//                   Navigator.pushAndRemoveUntil(
//                     context,
//                     MaterialPageRoute(builder: (_) => const LoginPage()),
//                     (route) => false,
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Registrar Medicamentos',
//               style: Theme.of(context)
//                   .textTheme
//                   .titleLarge
//                   ?.copyWith(fontWeight: FontWeight.w700),
//             ),
//             const SizedBox(height: 8),
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: nombreController,
//                             decoration:
//                                 const InputDecoration(labelText: 'Nombre'),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: TextField(
//                             controller: laboratorioController,
//                             decoration:
//                                 const InputDecoration(labelText: 'Laboratorio'),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: origenController,
//                             decoration:
//                                 const InputDecoration(labelText: 'Origen'),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: TextField(
//                             controller: tipoController,
//                             decoration:
//                                 const InputDecoration(labelText: 'Tipo'),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: precioController,
//                             keyboardType: TextInputType.number,
//                             decoration:
//                                 const InputDecoration(labelText: 'Precio'),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: TextField(
//                             controller: cantidadController,
//                             keyboardType: TextInputType.number,
//                             decoration:
//                                 const InputDecoration(labelText: 'Cantidad'),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: FilledButton.icon(
//                             onPressed: () {
//                               final nuevo = MedicamentoEntity(
//                                 nombre: nombreController.text,
//                                 laboratorio: laboratorioController.text,
//                                 origenLaboratorio: origenController.text,
//                                 tipoMedicamento: tipoController.text,
//                                 precio:
//                                     double.tryParse(precioController.text) ?? 0,
//                                 cantidad:
//                                     int.tryParse(cantidadController.text) ?? 0,
//                               );

//                               if (medicamentoEditando != null) {
//                                 final actualizado =
//                                     medicamentoEditando!.copyWith(
//                                   nombre: nuevo.nombre,
//                                   laboratorio: nuevo.laboratorio,
//                                   origenLaboratorio: nuevo.origenLaboratorio,
//                                   tipoMedicamento: nuevo.tipoMedicamento,
//                                   precio: nuevo.precio,
//                                   cantidad: nuevo.cantidad,
//                                 );
//                                 ref
//                                     .read(medicamentoProvider.notifier)
//                                     .updateMedicamento(actualizado);
//                               } else {
//                                 ref
//                                     .read(medicamentoProvider.notifier)
//                                     .addMedicamento(nuevo);
//                               }
//                               limpiarFormulario();
//                             },
//                             icon: const Icon(Icons.save_outlined),
//                             label: Text(medicamentoEditando != null
//                                 ? 'Actualizar'
//                                 : 'Guardar'),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             onPressed: escanearQR,
//                             icon: const Icon(Icons.qr_code_scanner),
//                             label: const Text('Por QR'),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Lista de Medicamentos',
//               style: Theme.of(context)
//                   .textTheme
//                   .titleLarge
//                   ?.copyWith(fontWeight: FontWeight.w700),
//             ),
//             const SizedBox(height: 8),
//             medicamentosState.when(
//               data: (medicamentos) => Column(
//                 children: medicamentos
//                     .map(
//                       (m) => Card(
//                         child: ListTile(
//                           title: Text(m.nombre),
//                           subtitle: Text(
//                             'Lab: ${m.laboratorio} • Origen: ${m.origenLaboratorio} • Tipo: ${m.tipoMedicamento}\\nPrecio: \$${m.precio} • Stock: ${m.cantidad}',
//                           ),
//                           isThreeLine: true,
//                           trailing: Wrap(
//                             spacing: 4,
//                             children: [
//                               IconButton(
//                                 tooltip: 'Editar',
//                                 icon: const Icon(Icons.edit_outlined,
//                                     color: Colors.blue),
//                                 onPressed: () {
//                                   setState(() {
//                                     medicamentoEditando = m;
//                                     nombreController.text = m.nombre;
//                                     laboratorioController.text = m.laboratorio;
//                                     origenController.text = m.origenLaboratorio;
//                                     tipoController.text = m.tipoMedicamento;
//                                     precioController.text =
//                                         m.precio.toString();
//                                     cantidadController.text =
//                                         m.cantidad.toString();
//                                   });
//                                 },
//                               ),
//                               IconButton(
//                                 tooltip: 'Eliminar',
//                                 icon: const Icon(Icons.delete_outline,
//                                     color: Colors.red),
//                                 onPressed: () {
//                                   showDialog(
//                                     context: context,
//                                     builder: (_) => AlertDialog(
//                                       title: const Text('¿Eliminar medicamento?'),
//                                       content: Text(
//                                           '¿Deseas eliminar \"${m.nombre}\"?'),
//                                       actions: [
//                                         TextButton(
//                                           onPressed: () =>
//                                               Navigator.pop(context),
//                                           child: const Text('Cancelar'),
//                                         ),
//                                         TextButton(
//                                           onPressed: () {
//                                             ref
//                                                 .read(medicamentoProvider.notifier)
//                                                 .deleteMedicamento(m);
//                                             Navigator.pop(context);
//                                           },
//                                           child: const Text(
//                                             'Eliminar',
//                                             style: TextStyle(
//                                                 color: Color(0xFFE74C3C)),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     )
//                     .toList(),
//               ),
//               loading: () => const Center(
//                   child: Padding(
//                 padding: EdgeInsets.all(24.0),
//                 child: CircularProgressIndicator(),
//               )),
//               error: (error, stack) =>
//                   Padding(padding: const EdgeInsets.all(16), child: Text('Error: $error')),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


