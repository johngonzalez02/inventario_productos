import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../views/dashboard_view.dart';
import '../views/producto_detail_view.dart';
import '../views/producto_form_view.dart';
import '../views/producto_list_view.dart';
import '../widgets/state_views.dart';

Widget _notFound(String message) {
  return Scaffold(
    appBar: AppBar(title: const Text('No encontrado')),
    body: EmptyView(message: message),
  );
}

/// Navegacion con go_router.
///
///   /                          Dashboard
///   /productos                 Listado
///   /productos/nuevo           Formulario de registro (POST)
///   /productos/:id             Detalle (GET /productos/{id})
///   /productos/:id/editar      Formulario de edicion (PUT)
///
/// "nuevo" se declara antes que ":id" para que no sea interpretado como un id.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) =>
      _notFound('La página "${state.uri}" no existe.'),
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardView(),
    ),
    GoRoute(
      path: '/productos',
      name: 'productos',
      builder: (context, state) => const ProductoListView(),
    ),
    GoRoute(
      path: '/productos/nuevo',
      name: 'producto-nuevo',
      builder: (context, state) => const ProductoFormView(),
    ),
    GoRoute(
      path: '/productos/:id',
      name: 'producto-detalle',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return _notFound('El producto solicitado no existe.');
        return ProductoDetailView(productoId: id);
      },
    ),
    GoRoute(
      path: '/productos/:id/editar',
      name: 'producto-editar',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return _notFound('El producto solicitado no existe.');
        return ProductoFormView(productoId: id);
      },
    ),
  ],
);
