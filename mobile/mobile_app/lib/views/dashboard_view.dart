import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/formatters.dart';
import '../models/producto.dart';
import '../services/api_client.dart';
import '../services/producto_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/stat_card.dart';
import '../widgets/state_views.dart';

/// Pantalla de inicio: indicadores calculados con los datos reales de la API.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ProductoService _service = ProductoService();
  late Future<List<Producto>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listar();
  }

  void _reload() {
    setState(() {
      _future = _service.listar();
    });
  }

  Future<void> _registrar() async {
    await context.push('/productos/nuevo');
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _reload,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/'),
      body: FutureBuilder<List<Producto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Cargando indicadores...');
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorView(
              message: error is ApiException
                  ? error.message
                  : 'Ocurrió un error inesperado.',
              onRetry: _reload,
            );
          }
          return _buildResumen(context, snapshot.data ?? const <Producto>[]);
        },
      ),
    );
  }

  Widget _buildResumen(BuildContext context, List<Producto> productos) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final totalProductos = productos.length;
    final totalUnidades = productos.fold<int>(0, (sum, p) => sum + p.cantidad);
    final valorInventario =
        productos.fold<double>(0, (sum, p) => sum + p.valorTotal);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, size: 44, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control de Inventario',
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Resumen en tiempo real desde la API',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        StatCard(
          icon: Icons.category_outlined,
          label: 'Total de productos',
          value: formatNumber(totalProductos),
          color: const Color(0xFF1565C0),
        ),
        StatCard(
          icon: Icons.layers_outlined,
          label: 'Unidades disponibles',
          value: formatNumber(totalUnidades),
          color: const Color(0xFF2E7D32),
        ),
        StatCard(
          icon: Icons.attach_money,
          label: 'Valor total del inventario',
          value: formatMoney(valorInventario),
          color: const Color(0xFFEF6C00),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => context.go('/productos'),
          icon: const Icon(Icons.list_alt_outlined),
          label: const Text('Gestionar productos'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _registrar,
          icon: const Icon(Icons.add),
          label: const Text('Registrar producto'),
        ),
      ],
    );
  }
}
