/// Entidad Producto, tal como la entrega y recibe la API.
class Producto {
  const Producto({
    this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    required this.precio,
    required this.cantidad,
    required this.categoria,
  });

  final int? id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final double precio;
  final int cantidad;
  final String categoria;

  /// Valor economico de este producto en inventario: precio x cantidad.
  double get valorTotal => precio * cantidad;

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      categoria: json['categoria']?.toString() ?? '',
    );
  }

  /// Cuerpo JSON para POST / PUT (el id lo genera la base de datos).
  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'codigo': codigo,
        'descripcion': descripcion,
        'precio': precio,
        'cantidad': cantidad,
        'categoria': categoria,
      };
}
