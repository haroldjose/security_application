import 'package:flutter/material.dart';

/// 🔘 Botón principal reutilizable con estilo moderno
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.check_circle_outline),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 🧾 Campo de texto reutilizable y consistente con el tema
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? icon;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }
}

/// ⚠️ Diálogo genérico de confirmación, con botones estilizados
Future<bool> showConfirmDialog(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Confirmar acción',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 15),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Aceptar'),
        ),
      ],
    ),
  );
  return result ?? false;
}

















// import 'package:flutter/material.dart';

// /// Botón reutilizable con estilos comunes
// class PrimaryButton extends StatelessWidget {
//   final String label;
//   final VoidCallback onPressed;
//   final bool isLoading;

//   const PrimaryButton({
//     Key? key,
//     required this.label,
//     required this.onPressed,
//     this.isLoading = false,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: isLoading ? null : onPressed,
//       style: ElevatedButton.styleFrom(
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         minimumSize: const Size.fromHeight(48),
//       ),
//       child: isLoading
//           ? const CircularProgressIndicator(color: Colors.white)
//           : Text(label, style: const TextStyle(fontSize: 16)),
//     );
//   }
// }

// /// Campo de texto reutilizable
// class CustomTextField extends StatelessWidget {
//   final TextEditingController controller;
//   final String label;
//   final bool obscureText;
//   final TextInputType keyboardType;

//   const CustomTextField({
//     Key? key,
//     required this.controller,
//     required this.label,
//     this.obscureText = false,
//     this.keyboardType = TextInputType.text,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: controller,
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       ),
//     );
//   }
// }

// /// Diálogo de confirmación genérico
// Future<bool> showConfirmDialog(BuildContext context, String message) async {
//   final result = await showDialog<bool>(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: const Text('Confirmar'),
//       content: Text(message),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context, false),
//           child: const Text('Cancelar'),
//         ),
//         ElevatedButton(
//           onPressed: () => Navigator.pop(context, true),
//           child: const Text('Aceptar'),
//         ),
//       ],
//     ),
//   );
//   return result ?? false;
// }
