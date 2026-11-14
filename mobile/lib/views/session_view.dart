import 'package:flutter/material.dart';

import '../services/auth_controller.dart';
import '../widgets/app_drawer.dart';

/// Informacion de la sesion: usuario, estado, indicador del token y cierre de sesion.
class SessionView extends StatelessWidget {
  const SessionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi sesión')),
      drawer: const AppDrawer(currentRoute: '/sesion'),
      body: ListenableBuilder(
        listenable: AuthController.instance,
        builder: (context, _) {
          final auth = AuthController.instance;
          final usuario = auth.usuario;
          final scheme = Theme.of(context).colorScheme;
          final activa = auth.isAuthenticated;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Fila(etiqueta: 'Nombre', valor: usuario?.nombre ?? '-'),
                    const Divider(height: 1),
                    _Fila(etiqueta: 'Correo', valor: usuario?.email ?? '-'),
                    const Divider(height: 1),
                    _Fila(
                      etiqueta: 'Estado',
                      valor: activa ? 'Sesión activa' : 'Sin sesión',
                      color: activa ? Colors.green.shade700 : scheme.error,
                    ),
                    const Divider(height: 1),
                    _Fila(
                      etiqueta: 'Token almacenado',
                      valor: auth.tieneToken
                          ? 'Sí  (${auth.tokenPreview})'
                          : 'No hay token',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'El token se guarda cifrado con flutter_secure_storage. '
                'El nombre y el correo se guardan con shared_preferences. '
                'La contraseña nunca se almacena.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () => AuthController.instance.logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor, this.color});

  final String etiqueta;
  final String valor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              etiqueta,
              style: textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              valor,
              style: textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
