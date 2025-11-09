import 'package:gestionmedicamentos/domain/entities/medicamento.dart';

class Medicamento {
  final int? id;
  final String nombre;
  final String laboratorio;
  final String? origenLaboratorio;
  final String? tipoMedicamento;
  final double precio;
  final int cantidad;

  Medicamento({
    this.id,
    required this.nombre,
    required this.laboratorio,
    this.origenLaboratorio,
    this.tipoMedicamento,
    required this.precio,
    required this.cantidad,
  });

  factory Medicamento.fromMap(Map<String, dynamic> map) {
    return Medicamento(
      id: map['id'],
      nombre: map['nombre'],
      laboratorio: map['laboratorio'],
      origenLaboratorio: map['origenLaboratorio'],
      tipoMedicamento: map['tipoMedicamento'],
      precio: map['precio'],
      cantidad: map['cantidad'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'laboratorio': laboratorio,
      'origenLaboratorio': origenLaboratorio,
      'tipoMedicamento': tipoMedicamento,
      'precio': precio,
      'cantidad': cantidad,
    };
  }
  
  MedicamentoEntity toEntity() {
    return MedicamentoEntity(
      id: id,
      nombre: nombre,
      laboratorio: laboratorio,
      origenLaboratorio: origenLaboratorio??'',
      tipoMedicamento: tipoMedicamento??'',
      precio: precio,
      cantidad: cantidad,
    );
  }

  /// Conversión desde entidad
  static Medicamento fromEntity(MedicamentoEntity entity) {
    return Medicamento(
      id: entity.id,
      nombre: entity.nombre,
      laboratorio: entity.laboratorio,
      origenLaboratorio: entity.origenLaboratorio,
      tipoMedicamento: entity.tipoMedicamento,
      precio: entity.precio,
      cantidad: entity.cantidad,
    );
  }



}
