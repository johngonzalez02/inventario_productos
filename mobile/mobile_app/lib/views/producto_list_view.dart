import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/formatters.dart';
import '../models/producto.dart';
import '../services/api_client.dart';
import '../services/producto_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/state_views.dart';

/// Listado de productos obtenido desde la API (GET /productos).
class ProductoListView extends StatefulWidget {
  const ProductoListView({super.key});

  @override
  State<ProductoListView> createState() => _ProductoListViewState();
}

class _ProductoListViewState extends State<ProductoListView> {
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

  Future<void> _abrirDetalle(Producto producto) async {
    await context.push('/productos/${producto.id}');
    if (mounted) _reload(); // refleja ediciones o eliminaciones
  }

  Future<void> _registrar() async {
    await context.push('/productos/nuevo');
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _reload,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/productos'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registrar,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: FutureBuilder<List<Producto>>(
        future: _future,
        builder: (context, snapshot) {
          // Estado: cargando
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Cargando productos...');
          }
          // Estado: error
          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorView(
              message: error is ApiException
                  ? error.message
                  : 'Ocurrió un error inesperado.',
              onRetry: _reload,
            );
          }
          // Estado: sin registros
          final productos = snapshot.data ?? const <Producto>[];
          if (productos.isEmpty) {
            return const EmptyView(
              message: 'Aún no hay productos registrados.\n'
                  'Toca "Nuevo" para agregar el primero.',
            );
          }
          // Estado: exito
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final p = productos[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      p.nombre.isEmpty ? '?' : p.nombre[0].toUpperCase(),
                    ),
                  ),
                  title: Text(
                    p.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${formatMoney(p.precio)}   ·   Disponibles: ${p.cantidad}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrirDetalle(p),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
