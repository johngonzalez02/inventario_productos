import 'package:flutter/material.dart';

/// Pantalla breve mientras se restaura y valida la sesion guardada.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 64, color: scheme.primary),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Verificando sesión...'),
          ],
        ),
      ),
    );
  }
}
