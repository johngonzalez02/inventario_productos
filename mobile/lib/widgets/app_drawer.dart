import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: scheme.primaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.inventory_2,
                    size: 44, color: scheme.onPrimaryContainer),
                const SizedBox(height: 12),
                Text(
                  'Control de Inventario',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
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
        ],
      ),
    );
  }
}
