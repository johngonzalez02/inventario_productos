# # Inventario de Productos

Solución para la gestión de inventario de un establecimiento comercial, compuesta por una API REST desarrollada en Python con FastAPI y SQLite, y una aplicación móvil en Flutter que consume la API mediante Dio.

**Autor:** John Stiven Gonzalez Rivera · **Código:** 230232038 · **Asignatura:** Electiva Profesional I

---

## Tecnologías

**Backend**
- Python 3
- FastAPI 
- Uvicorn (servidor ASGI)
- SQLite (persistencia en el archivo `backend/inventario.db`)
- Pydantic (validación de datos)

**Frontend**
- Flutter (Dart)
- Dio 5.11.1 (peticiones HTTP)
- go_router 18.1.1 (navegación)
- flutter_dotenv 6.0.1 (configuración de la URL base)

---

## Estructura del repositorio

```
inventario_productos/
├── backend/            # API REST (FastAPI)
│   ├── main.py         # Endpoints y manejo de errores
│   ├── schemas.py      # Esquemas de validación (Pydantic)
│   ├── database.py     # Conexión a SQLite, creación de tabla y datos de prueba
│   └── requirements.txt
└── mobile/             # Aplicación Flutter
    ├── .env            # URL base de la API (no se sube al repositorio)
    └── lib/
        ├── config/     # Carga de variables de entorno
        ├── models/     # Modelo Producto con fromJson / toJson
        ├── routes/     # Rutas de go_router
        ├── services/   # Dio: cliente HTTP y servicio de productos
        ├── themes/     # Tema visual
        ├── views/      # Dashboard, listado, detalle y formulario
        ├── widgets/    # Menú lateral, tarjetas de estadísticas y estados
        └── main.dart
```

---

## Base de datos

Se utiliza SQLite. La tabla `productos` se crea automáticamente al iniciar la API si no existe.

| Campo | Tipo | Restricción |
|---|---|---|
| `id` | INTEGER | Clave primaria, autoincremental |
| `nombre` | TEXT | Obligatorio |
| `codigo` | TEXT | Obligatorio y único |
| `descripcion` | TEXT | Opcional |
| `precio` | REAL | Obligatorio |
| `cantidad` | INTEGER | Obligatorio |
| `categoria` | TEXT | Obligatorio |

Si la tabla está vacía al iniciar, la API inserta 10 productos de prueba.

---

## Endpoints

Base URL local: `http://127.0.0.1:8000/api`

| Método | Endpoint | Descripción | Respuesta exitosa |
|---|---|---|---|
| GET | `/api/productos` | Lista todos los productos | 200 |
| GET | `/api/productos/{id}` | Consulta un producto | 200 |
| POST | `/api/productos` | Registra un producto | 201 |
| PUT | `/api/productos/{id}` | Actualiza un producto | 200 |
| DELETE | `/api/productos/{id}` | Elimina un producto | 200 |

### Validaciones

- `nombre`, `codigo` y `categoria` son obligatorios (no vacíos).
- `codigo` no puede repetirse.
- `precio` debe ser mayor que 0.
- `cantidad` debe ser mayor o igual a 0.
- `descripcion` es opcional.

### Códigos de error

| Código | Cuándo ocurre |
|---|---|
| 404 | El producto indicado no existe. |
| 422 | Datos inválidos o código de producto repetido. |

---

## Ejemplos de peticiones y respuestas

**Listar productos** — `GET /api/productos`

```json
[
  {
    "id": 1,
    "nombre": "Arroz Diana 500g",
    "codigo": "ARZ-001",
    "descripcion": "Arroz blanco de grano largo",
    "precio": 3200.0,
    "cantidad": 80,
    "categoria": "Granos"
  }
]
```

**Registrar producto** — `POST /api/productos`

Cuerpo de la petición:

```json
{
  "nombre": "Azúcar Manuelita 1kg",
  "codigo": "AZU-011",
  "descripcion": "Azúcar blanca refinada",
  "precio": 4100,
  "cantidad": 50,
  "categoria": "Granos"
}
```

Respuesta (201):

```json
{
  "id": 11,
  "nombre": "Azúcar Manuelita 1kg",
  "codigo": "AZU-011",
  "descripcion": "Azúcar blanca refinada",
  "precio": 4100.0,
  "cantidad": 50,
  "categoria": "Granos"
}
```

**Error de validación** — `POST /api/productos` con `precio: -5`

```json
{
  "message": "Datos inválidos.",
  "errors": {
    "precio": "Debe ser mayor que 0."
  }
}
```

**Producto no encontrado** — `GET /api/productos/999`

```json
{
  "message": "Producto no encontrado."
}
```

**Eliminar producto** — `DELETE /api/productos/11`

```json
{
  "message": "Producto eliminado correctamente."
}
```

---

## Instalación y ejecución

### 1. Backend

```bash
cd backend
pip install -r requirements.txt
python -m uvicorn main:app --reload
```

La API queda disponible en `http://127.0.0.1:8000`. La documentación interactiva está en `http://127.0.0.1:8000/docs`.

### 2. Frontend

Crea el archivo `mobile/.env` con la URL base de la API:

```
API_BASE_URL=http://10.0.2.2:8000/api
```

La dirección `10.0.2.2` permite que el emulador Android acceda al servidor que corre en tu PC. Si ejecutas la app en un teléfono físico, usa la IP local de tu computadora.

Luego ejecuta:

```bash
cd mobile
flutter pub get
flutter run
```

---

## Despliegue

El proyecto se ejecuta en entorno local. La API no está publicada en un servidor externo.

---

## Video explicativo

https://drive.google.com/drive/folders/1m5NFkExeUv8Ftrt1v10UZ8AlmR09C2GP?usp=drive_link