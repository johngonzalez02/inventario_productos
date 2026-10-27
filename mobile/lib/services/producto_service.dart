import 'package:dio/dio.dart';

import '../models/producto.dart';
import 'api_client.dart';

/// Operaciones CRUD de productos contra la API REST.
/// Las vistas usan esta clase; ningun widget llama a Dio directamente.
class ProductoService {
  ProductoService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  /// GET /productos
  Future<List<Producto>> listar() async {
    try {
      final response = await _dio.get('/productos');
      final data = response.data;
      if (data is! List) {
        throw const ApiException('La respuesta de la API no tiene el formato esperado.');
      }
      return data
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /productos/{id}
  Future<Producto> obtener(int id) async {
    try {
      final response = await _dio.get('/productos/$id');
      return Producto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /productos
  Future<Producto> crear(Producto producto) async {
    try {
      final response = await _dio.post('/productos', data: producto.toJson());
      return Producto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PUT /productos/{id}
  Future<Producto> actualizar(int id, Producto producto) async {
    try {
      final response =
          await _dio.put('/productos/$id', data: producto.toJson());
      return Producto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE /productos/{id}
  Future<void> eliminar(int id) async {
    try {
      await _dio.delete('/productos/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
