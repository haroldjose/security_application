import '../entities/medicamento.dart';
import '../entities/user.dart';

abstract class AppRepository {
  // Usuarios
  Future<void> insertUser(UserEntity user);
  Future<UserEntity?> getUser(String name, String password);
  Future<List<UserEntity>> getAllUsers();
   Future<void> deleteUserLocal(String name);


  // Medicamentos
  Future<List<MedicamentoEntity>> getMedicamentos();
  Future<void> updateMedicamento(MedicamentoEntity medicamento);
  Future<void> addMedicamento(MedicamentoEntity medicamento);
  Future<void> deleteMedicamento(int id);


  // Retiros
  Future<void> registrarRetiro(String nombre, int cantidad, String doctor);
  Future<List<Map<String, dynamic>>> getRetiros();

  

}
