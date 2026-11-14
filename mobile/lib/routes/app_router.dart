import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_controller.dart';
import '../views/dashboard_view.dart';
import '../views/login_view.dart';
import '../views/producto_detail_view.dart';
import '../views/producto_form_view.dart';
import '../views/producto_list_view.dart';
import '../views/session_view.dart';
import '../views/splash_view.dart';
import '../widgets/state_views.dart';

Widget _notFound(String message) {
  return Scaffold(
    appBar: AppBar(title: const Text('No encontrado')),
    body: EmptyView(message: message),
  );
}

/// Navegacion con go_router y proteccion de rutas segun la sesion.
///
///   /splash                    Verificando la sesion guardada
///   /login                     Inicio de sesion            (publica)
///   /                          Dashboard                   (protegida)
///   /sesion                    Informacion de la sesion    (protegida)
///   /productos                 Listado                     (protegida)
///   /productos/nuevo           Registro (POST)             (protegida)
///   /productos/:id             Detalle                     (protegida)
///   /productos/:id/editar      Edicion (PUT)               (protegida)
///
/// `redirect` se ejecuta cada vez que cambia la sesion (refreshListenable):
/// sin sesion cualquier ruta lleva a /login; con sesion /login lleva al dashboard.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthController.instance,
  redirect: (context, state) {
    final auth = AuthController.instance;
    final ubicacion = state.matchedLocation;

    if (auth.status == AuthStatus.unknown) {
      return ubicacion == '/splash' ? null : '/splash';
    }
    if (!auth.isAuthenticated) {
      return ubicacion == '/login' ? null : '/login';
    }
    if (ubicacion == '/login' || ubicacion == '/splash') return '/';
    return null;
  },
  errorBuilder: (context, state) =>
      _notFound('La página "${state.uri}" no existe.'),
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardView(),
    ),
    GoRoute(
      path: '/sesion',
      name: 'sesion',
      builder: (context, state) => const SessionView(),
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
