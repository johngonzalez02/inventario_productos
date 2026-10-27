import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/producto.dart';
import '../services/api_client.dart';
import '../services/producto_service.dart';
import '../widgets/state_views.dart';

/// Formulario para registrar (POST) o editar (PUT) un producto.
/// Si recibe [productoId], precarga los datos del producto a editar.
class ProductoFormView extends StatefulWidget {
  const ProductoFormView({super.key, this.productoId});

  final int? productoId;

  @override
  State<ProductoFormView> createState() => _ProductoFormViewState();
}

class _ProductoFormViewState extends State<ProductoFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProductoService _service = ProductoService();

  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _codigo = TextEditingController();
  final TextEditingController _descripcion = TextEditingController();
  final TextEditingController _precio = TextEditingController();
  final TextEditingController _cantidad = TextEditingController();
  final TextEditingController _categoria = TextEditingController();

  bool _cargando = false;
  bool _guardando = false;
  String? _errorCarga;

  bool get _esEdicion => widget.productoId != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) _cargar();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    _descripcion.dispose();
    _precio.dispose();
    _cantidad.dispose();
    _categoria.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final p = await _service.obtener(widget.productoId!);
      if (!mounted) return;
      _nombre.text = p.nombre;
      _codigo.text = p.codigo;
      _descripcion.text = p.descripcion ?? '';
      _precio.text = p.precio == p.precio.roundToDouble()
          ? p.precio.round().toString()
          : p.precio.toString();
      _cantidad.text = p.cantidad.toString();
      _categoria.text = p.categoria;
      setState(() {
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorCarga = e.message;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final descripcion = _descripcion.text.trim();
    final producto = Producto(
      nombre: _nombre.text.trim(),
      codigo: _codigo.text.trim(),
      descripcion: descripcion.isEmpty ? null : descripcion,
      precio: double.parse(_precio.text.trim().replaceAll(',', '.')),
      cantidad: int.parse(_cantidad.text.trim()),
      categoria: _categoria.text.trim(),
    );

    setState(() {
      _guardando = true;
    });

    try {
      if (_esEdicion) {
        await _service.actualizar(widget.productoId!, producto);
      } else {
        await _service.crear(producto);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(_esEdicion
              ? 'Producto actualizado correctamente.'
              : 'Producto registrado correctamente.'),
        ),
      );
      router.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
      });
      final detalle =
          e.fieldErrors.entries.map((x) => '${x.key}: ${x.value}').join('\n');
      messenger.showSnackBar(
        SnackBar(
          content: Text(detalle.isEmpty ? e.message : '${e.message}\n$detalle'),
        ),
      );
    }
  }

  String? _requerido(String? value) {
    if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio';
    return null;
  }

  String? _validarPrecio(String? value) {
    final n = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Ingresa un precio válido';
    if (n <= 0) return 'El precio debe ser mayor que 0';
    return null;
  }

  String? _validarCantidad(String? value) {
    final n = int.tryParse((value ?? '').trim());
    if (n == null) return 'Ingresa una cantidad válida';
    if (n < 0) return 'La cantidad no puede ser negativa';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) return const LoadingView(message: 'Cargando producto...');
    if (_errorCarga != null) {
      return ErrorView(message: _errorCarga!, onRetry: _cargar);
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nombre,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: _requerido,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _codigo,
            decoration: const InputDecoration(
              labelText: 'Código (único)',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: _requerido,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _categoria,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: _requerido,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _precio,
            decoration: const InputDecoration(
              labelText: 'Precio unitario',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: _validarPrecio,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cantidad,
            decoration: const InputDecoration(
              labelText: 'Cantidad disponible',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            validator: _validarCantidad,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descripcion,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_guardando ? 'Guardando...' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
