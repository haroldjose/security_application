// lib/core/sanitize.dart
/// Quita caracteres potencialmente peligrosos y trimea.
/// Nota: usamos un string normal (NO raw) para poder incluir comillas sin romper el parser.
String sanitize(String v) {
  return v.replaceAll(RegExp('[<>;\'"/]'), '').trim();
}

