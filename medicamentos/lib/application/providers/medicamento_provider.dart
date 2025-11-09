import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionmedicamentos/core/providers.dart';
import '../../domain/entities/medicamento.dart';
import '../../domain/repositories/app_repository.dart';




final medicamentoProvider = StateNotifierProvider<MedicamentoNotifier, AsyncValue<List<MedicamentoEntity>>>(
  (ref) => MedicamentoNotifier(ref.watch(appRepositoryProvider)),
);


class MedicamentoNotifier extends StateNotifier<AsyncValue<List<MedicamentoEntity>>>{
  final AppRepository repository;
  final List<Map<String, dynamic>> retiros = [];
  
  MedicamentoNotifier(this.repository) : super(const AsyncLoading());


  

  
   Future<void> loadMedicamentos() async {
    try {
      final medicamentos = await repository.getMedicamentos();
      state = AsyncData(medicamentos);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  void loadRetiros() {
     // fuerza una reconstrucción
  }


  Future<void> updateMedicamento(MedicamentoEntity updated) async {
    await repository.updateMedicamento(updated);
    await loadMedicamentos();
  }

  Future<bool> retirarMedicamento({
  required MedicamentoEntity medicamento,
  required int cantidad,
  required String? doctor,
}) async {
  if (medicamento.cantidad < cantidad) return false;

  final actualizado = medicamento.copyWith(cantidad: medicamento.cantidad - cantidad);
  await repository.updateMedicamento(actualizado);

   retiros.add({
    'medicamento': medicamento.nombre,
    'cantidad': cantidad,
    'doctor': doctor ?? 'Desconocido',
   });

  await loadMedicamentos();
  return true;
}

Future<void> addMedicamento(MedicamentoEntity nuevo) async {
  try {
    await repository.addMedicamento(nuevo);
    await loadMedicamentos(); // Recarga la lista
  } catch (e, st) {
    state = AsyncError(e, st);
  }
}

Future<void> deleteMedicamento(MedicamentoEntity medicamento) async {
  try {
    // 1. Eliminar de la base de datos
    if (medicamento.id != null) {
      await repository.deleteMedicamento(medicamento.id!);
    }

    // 2. Recargar la lista actualizada desde la base de datos
    await loadMedicamentos();
  } catch (e, st) {
    state = AsyncError(e, st);
  }
}



List<Map<String, dynamic>> get retiro => retiros; 

}
