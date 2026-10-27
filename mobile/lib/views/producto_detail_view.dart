import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/formatters.dart';
import '../models/producto.dart';
import '../services/api_client.dart';
import '../services/producto_service.dart';
import '../widgets/state_views.dart';

/// Detalle de un producto (GET /productos/{id}) con acciones editar y eliminar.
class ProductoDetailView extends StatefulWidget {
  const ProductoDetailView({super.key, required this.productoId});

  final int productoId;

  @override
  State<ProductoDetailView> createState() => _ProductoDetailViewState();
}

class _ProductoDetailViewState extends State<ProductoDetailView> {
  final ProductoService _service = ProductoService();
  late Future<Producto> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.obtener(widget.productoId);
  }

  void _reload() {
    setState(() {
      _future = _service.obtener(widget.productoId);
    });
  }

  Future<void> _editar() async {
    await context.push('/productos/${widget.productoId}/editar');
    if (mounted) _reload();
  }

  Future<void> _eliminar(Producto producto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Seguro que deseas eliminar "${producto.nombre}"? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await _service.eliminar(widget.productoId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Producto eliminado correctamente.')),
      );
      router.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: FutureBuilder<Producto>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Cargando detalle...');
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
          return _buildDetalle(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildDetalle(BuildContext context, Producto p) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final descripcion = (p.descripcion == null || p.descripcion!.isEmpty)
        ? 'Sin descripción'
        : p.descripcion!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          p.nombre,
          style:
              textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _Fila(etiqueta: 'Código', valor: p.codigo),
              const Divider(height: 1),
              _Fila(etiqueta: 'Categoría', valor: p.categoria),
              const Divider(height: 1),
              _Fila(etiqueta: 'Precio unitario', valor: formatMoney(p.precio)),
              const Divider(height: 1),
              _Fila(
                  etiqueta: 'Unidades disponibles',
                  valor: formatNumber(p.cantidad)),
              const Divider(height: 1),
              _Fila(
                  etiqueta: 'Valor en inventario',
                  valor: formatMoney(p.valorTotal)),
              const Divider(height: 1),
              _Fila(etiqueta: 'Descripción', valor: descripcion),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _editar,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _eliminar(p),
                icon: Icon(Icons.delete_outline, color: scheme.error),
                label: Text('Eliminar', style: TextStyle(color: scheme.error)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
