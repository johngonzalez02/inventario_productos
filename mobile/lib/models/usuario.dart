/// Datos publicos del usuario autenticado (nunca incluyen la contrasena).
class Usuario {
  const Usuario({required this.id, required this.nombre, required this.email});

  final int id;
  final String nombre;
  final String email;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'email': email};
}
