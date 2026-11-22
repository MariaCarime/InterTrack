import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:intertrack_app/models/auth_service.dart';

/// Encabezado azul de las pantallas.
class BlueHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const BlueHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.azul,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onBack != null || Navigator.canPop(context))
                GestureDetector(
                  onTap: onBack ?? () => Navigator.maybePop(context),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back,
                            color: AppColors.blanco, size: 18),
                        SizedBox(width: 6),
                        Text('Volver',
                            style: TextStyle(
                                color: AppColors.blanco,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              if (subtitle != null || trailing != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(subtitle ?? '',
                          style: const TextStyle(
                              color: AppColors.azulClaro, fontSize: 14)),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              const SizedBox(height: 2),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.blanco,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta gris sobre un campo.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            color: AppColors.gris,
            fontSize: 13,
            fontWeight: FontWeight.w500)),
  );
}

OutlineInputBorder _border(Color c) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: c),
);

/// Campo de texto con etiqueta.
class AppTextField extends StatelessWidget {
  final String? label;
  final String hint;
  final TextEditingController? controller;
  final bool enabled;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const AppTextField({
    super.key,
    this.label,
    required this.hint,
    this.controller,
    this.enabled = true,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) FieldLabel(label!),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, color: AppColors.texto),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.gris, fontSize: 15),
            filled: true,
            fillColor: enabled ? AppColors.blanco : AppColors.grisClaro,
            suffixIcon: suffix,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: _border(AppColors.borde),
            enabledBorder: _border(AppColors.borde),
            disabledBorder: _border(AppColors.borde),
            focusedBorder: _border(AppColors.azul),
          ),
        ),
      ],
    );
  }
}

/// Campo de selección: abre una hoja inferior con las opciones.
/// Si la lista está vacía (primer día), muestra [emptyMessage].
class AppSelectField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onSelected;
  final String emptyMessage;

  const AppSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.value,
    required this.onSelected,
    this.emptyMessage = 'Aún no hay opciones registradas.',
  });

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.blanco,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: options.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gris)),
          )
              : ListView(
            shrinkWrap: true,
            children: [
              for (final o in options)
                ListTile(
                  title: Text(o),
                  onTap: () {
                    onSelected(o);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.blanco,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(value ?? hint,
                      style: TextStyle(
                          fontSize: 15,
                          color: value == null
                              ? AppColors.gris
                              : AppColors.texto)),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.gris),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón principal azul.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azul,
          foregroundColor: AppColors.blanco,
          disabledBackgroundColor: AppColors.deshabilitado,
          disabledForegroundColor: AppColors.blanco,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Text(text),
      ),
    );
  }
}

/// Barra inferior de las pantallas principales.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  static const _rutas = ['/dashboard', '/stock', '/camiones', '/reportes', '/catalogos'];

  void _ir(BuildContext context, int i) {
    if (i == currentIndex) return;
    final ruta = i == 0
        ? (AuthService.rolActual?.rutaInicial ?? '/dashboard')
        : _rutas[i];
    Navigator.pushReplacementNamed(context, ruta);
  }

  static const _items = [
    (Icons.home_rounded, 'Inicio'),
    (Icons.inventory_2_rounded, 'Stock'),
    (Icons.local_shipping_rounded, 'Camiones'),
    (Icons.bar_chart_rounded, 'Reportes'),
    (Icons.folder_rounded, 'Catálogos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.blanco,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => _ir(context, i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_items[i].$1,
                            size: 24,
                            color: i == currentIndex
                                ? AppColors.azul
                                : AppColors.borde),
                        const SizedBox(height: 2),
                        Text(_items[i].$2,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: i == currentIndex
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: i == currentIndex
                                    ? AppColors.azul
                                    : AppColors.gris)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Tarjeta blanca de estado vacío (círculo + título + mensaje).
class EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;

  const EmptyStateCard({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: AppColors.azulPalido, shape: BoxShape.circle),
          ),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texto)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gris, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Filtro en forma de píldora (Todas / Activas / Asesor / Fecha...).
class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.azul : AppColors.blanco,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: selected ? AppColors.azul : AppColors.borde),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.blanco : AppColors.texto)),
      ),
    );
  }
}


/// Enlace blanco "Cerrar sesión" para el encabezado azul.
class CerrarSesionLink extends StatelessWidget {
  const CerrarSesionLink({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => cerrarSesionYSalir(context),
      child: const Text(
        'Cerrar sesión',
        style: TextStyle(
          color: AppColors.blanco,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}