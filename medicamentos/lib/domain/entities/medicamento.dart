
class MedicamentoEntity {
  final int? id;
  final String nombre;
  final String laboratorio;
  final String origenLaboratorio;
  final String tipoMedicamento;
  final double precio;
  final int cantidad;
  

  MedicamentoEntity({
    this.id,
    required this.nombre,
    required this.laboratorio,
    required this.origenLaboratorio,
    required this.tipoMedicamento,
    required this.precio,
    required this.cantidad,
  });


  MedicamentoEntity copyWith({
    int? id,
    String? nombre,
    String? laboratorio,
    String? origenLaboratorio,
    String? tipoMedicamento,
    double? precio,
    int? cantidad,
  }) {
    return MedicamentoEntity(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      laboratorio: laboratorio ?? this.laboratorio,
      origenLaboratorio: origenLaboratorio ?? this.origenLaboratorio,
      tipoMedicamento: tipoMedicamento ?? this.tipoMedicamento,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}
