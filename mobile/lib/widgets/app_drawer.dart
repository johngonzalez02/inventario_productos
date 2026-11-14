import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_controller.dart';

/// Menu lateral de navegacion entre las funcionalidades principales.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  void _navigate(BuildContext context, String route) {
    // Se captura el router antes de cerrar el drawer (el context queda inactivo).
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(route);
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    Navigator.of(context).pop();
    // go_router detecta el cambio de sesion y redirige al login.
    await AuthController.instance.logout();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final usuario = AuthController.instance.usuario;
    final nombre = usuario?.nombre ?? 'Sin sesión';
    final inicial = nombre.isEmpty ? '?' : nombre[0].toUpperCase();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: scheme.primary),
            accountName: Text(
              nombre,
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              usuario?.email ?? '',
              style: TextStyle(color: scheme.onPrimary),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: scheme.onPrimary,
              child: Text(
                inicial,
                style: TextStyle(fontSize: 26, color: scheme.primary),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: currentRoute == '/',
            onTap: () => _navigate(context, '/'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: const Text('Productos'),
            selected: currentRoute == '/productos',
            onTap: () => _navigate(context, '/productos'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi sesión'),
            selected: currentRoute == '/sesion',
            onTap: () => _navigate(context, '/sesion'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: scheme.error),
            title: Text('Cerrar sesión', style: TextStyle(color: scheme.error)),
            onTap: () => _cerrarSesion(context),
          ),
        ],
      ),
    );
  }
}
