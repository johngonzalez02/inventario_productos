# Control de Inventario: API REST + app Flutter con autenticación JWT

Sistema de gestión de inventario de productos para un establecimiento comercial. Está compuesto por una **API REST propia** con base de datos y una **aplicación móvil en Flutter** que la consume con Dio. Los servicios están protegidos con **JSON Web Tokens (JWT)**: sin iniciar sesión no se puede usar ninguna funcionalidad del inventario.

- **Estudiante:** John Stiven Gonzalez Rivera (código 230232038)
- **Asignatura:** Electiva Profesional I, Desarrollo de Aplicaciones Móviles
- **Entregas que cubre este repositorio:** Parcial 2 (CRUD de inventario) y Taller de autenticación JWT

## Tecnologías

| Capa | Tecnologías |
|---|---|
| Backend | Python 3.9+, FastAPI, Uvicorn, SQLite, PyJWT, python-dotenv, Pydantic |
| Frontend | Flutter, Dio, go_router, flutter_dotenv, flutter_secure_storage, shared_preferences |

## Estructura del repositorio

```
inventario_productos/
├── backend/                     API REST (FastAPI + SQLite)
│   ├── main.py                  aplicación, manejo de errores y registro de rutas
│   ├── config.py                lee JWT_SECRET y demás variables desde .env
│   ├── database.py              conexión SQLite, tablas, datos de prueba
│   ├── schemas.py               validación de datos (Pydantic)
│   ├── security.py              hash de contraseñas (PBKDF2) y creación/validación del JWT
│   ├── dependencies.py          get_current_user: protege los endpoints
│   ├── routers/
│   │   ├── auth.py              POST /api/auth/login, GET /api/auth/me
│   │   └── productos.py         CRUD de productos (protegido)
│   ├── requirements.txt
│   └── .env.example             plantilla de configuración (sin secretos)
└── mobile/                      app Flutter
    └── lib/
        ├── config/              env.dart (URL base), formatters.dart
        ├── models/              producto.dart, usuario.dart (fromJson / toJson)
        ├── services/            api_client.dart, auth_interceptor.dart, auth_service.dart,
        │                        auth_controller.dart, session_storage.dart, producto_service.dart
        ├── routes/              app_router.dart (go_router + protección de rutas)
        ├── themes/              app_theme.dart
        ├── views/               login, splash, dashboard, productos, detalle, formulario, sesión
        └── widgets/             menú lateral, tarjetas y estados (cargando / error / vacío)
```

## Base de datos (SQLite)

El archivo `backend/inventario.db` se crea automáticamente al iniciar el servidor, junto con 10 productos de prueba y el usuario de prueba.

**Tabla `productos`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | INTEGER | Identificador único autogenerado |
| nombre | TEXT | Nombre del producto |
| codigo | TEXT (único) | Código del producto |
| descripcion | TEXT | Descripción (opcional) |
| precio | REAL | Precio unitario (mayor que 0) |
| cantidad | INTEGER | Unidades disponibles (0 o más) |
| categoria | TEXT | Categoría |

**Tabla `usuarios`**

| Campo | Tipo | Descripción |
|---|---|---|
| id | INTEGER | Identificador único autogenerado |
| nombre | TEXT | Nombre del usuario |
| email | TEXT (único) | Correo, usado para iniciar sesión |
| password_hash | TEXT | Hash PBKDF2 de la contraseña. **Nunca se guarda en texto plano** |

## Endpoints

| Método | Endpoint | Acceso | Funcionalidad |
|---|---|---|---|
| POST | `/api/auth/login` | Público | Valida credenciales y devuelve el token JWT |
| GET | `/api/auth/me` | **Token** | Devuelve el usuario del token (valida la sesión) |
| GET | `/api/productos` | **Token** | Listar todos los productos |
| GET | `/api/productos/{id}` | **Token** | Consultar el detalle de un producto |
| POST | `/api/productos` | **Token** | Registrar un producto (201) |
| PUT | `/api/productos/{id}` | **Token** | Actualizar un producto |
| DELETE | `/api/productos/{id}` | **Token** | Eliminar un producto |

Códigos de respuesta: `200`, `201`, `401` (sin token, token inválido o expirado), `404` (no encontrado) y `422` (datos inválidos o código duplicado).
Con el servidor encendido, la documentación interactiva está en **http://127.0.0.1:8000/docs** (botón *Authorize* para probar con token).

## Cómo funciona la autenticación JWT

```
Flutter                                       API (FastAPI)
  |  POST /api/auth/login (correo, clave) ---> busca el usuario y verifica el hash PBKDF2
  |  <--- 200 { access_token, usuario }        genera un JWT firmado (HS256, 60 min)
  |  guarda el token (flutter_secure_storage)
  |  GET /api/productos                        get_current_user valida firma, expiración
  |      Authorization: Bearer <token> ------> y existencia del usuario
  |  <--- 200 con datos  /  401 si el token falta, es inválido o expiró
  |  si recibe 401 -> borra la sesión y vuelve al login
```

**Backend**
- `security.py`: contraseñas con **PBKDF2-HMAC-SHA256** (600.000 iteraciones y sal aleatoria). El token lleva `sub` (id del usuario), `email`, `iat` y `exp`, y se firma con HS256.
- `dependencies.py`: `get_current_user` lee el encabezado `Authorization: Bearer <token>` y responde **401** si falta, si está manipulado, si expiró o si el usuario ya no existe.
- `routers/productos.py`: el router completo se declara con `dependencies=[Depends(get_current_user)]`, por lo que **los cinco endpoints del CRUD exigen token**. La protección existe en el servidor, no solo en la app.
- El login responde siempre el mismo mensaje cuando el correo no existe o la contraseña es incorrecta, para no revelar qué usuarios están registrados.

**Flutter**
- `api_client.dart`: un único cliente Dio con la URL base del `.env` y el interceptor de autenticación.
- `auth_interceptor.dart`: agrega `Authorization: Bearer <token>` a cada petición y, si la API responde 401, cierra la sesión.
- `session_storage.dart`: el **access_token** va a `flutter_secure_storage` (cifrado); el **id, nombre y correo** van a `shared_preferences`. La contraseña nunca se almacena.
- `auth_controller.dart`: estado global de la sesión. Al abrir la app restaura el token guardado y lo valida contra `/api/auth/me`.
- `app_router.dart`: `redirect` + `refreshListenable`. Sin sesión, cualquier ruta lleva a `/login`; con sesión, `/login` lleva al dashboard.

### Rutas de la app (go_router)

| Ruta | Pantalla | Acceso |
|---|---|---|
| `/splash` | Verificando la sesión guardada | Transitoria |
| `/login` | Inicio de sesión | Pública |
| `/` | Dashboard (indicadores del inventario) | Protegida |
| `/sesion` | Información de la sesión y cierre de sesión | Protegida |
| `/productos` | Listado de productos | Protegida |
| `/productos/nuevo` | Registro de producto (POST) | Protegida |
| `/productos/:id` | Detalle de un producto | Protegida |
| `/productos/:id/editar` | Edición de un producto (PUT) | Protegida |

## Instalación y ejecución

### Requisitos
Python 3.9 o superior, Flutter instalado (`flutter doctor` sin errores críticos) y un emulador Android (o un dispositivo conectado).

### 1. Backend

```bash
cd backend
pip install -r requirements.txt
```

Crea el archivo `backend/.env` a partir de la plantilla y define una clave secreta propia. **El `.env` no se sube a Git.**

```powershell
# Windows (PowerShell), desde la carpeta backend
python -c "import secrets; print('JWT_SECRET=' + secrets.token_hex(32))" | Out-File -Encoding ascii .env
Add-Content .env "JWT_EXPIRE_MINUTES=60"
```

También puedes copiar `.env.example` a `.env` y cambiar el valor de `JWT_SECRET` a mano. Luego inicia el servidor:

```bash
python -m uvicorn main:app --reload
```

Debe mostrar `Uvicorn running on http://127.0.0.1:8000`. En el primer arranque se crean la base de datos, los 10 productos de prueba y el usuario de prueba.

### 2. Aplicación Flutter

```bash
cd mobile
flutter pub get
```

Verifica que exista `mobile/.env` con la URL de la API. En el **emulador Android**, `10.0.2.2` apunta al computador donde corre el backend:

```
API_BASE_URL=http://10.0.2.2:8000/api
```

(Para un celular físico usa la IP de tu computador en la red, por ejemplo `http://192.168.1.10:8000/api`, y arranca el backend con `--host 0.0.0.0`.)

Con el backend encendido y el emulador abierto:

```bash
flutter run
```

> Nota: la app usa HTTP local en desarrollo, por eso `android/app/src/main/AndroidManifest.xml` incluye `android:usesCleartextTraffic="true"`.

## Usuario de prueba

| Correo | Contraseña |
|---|---|
| `admin@inventario.com` | `Admin123*` |

Se crea automáticamente al iniciar el backend (configurable con `DEMO_USER_NAME`, `DEMO_USER_EMAIL` y `DEMO_USER_PASSWORD` en el `.env`). Son credenciales de demostración, no reales.

## Cómo probar la autenticación

Con el backend y la app funcionando de forma integrada:

1. **Acceso sin autenticación:** abre la app sin sesión. Lleva al login y no permite entrar al dashboard ni a los productos.
2. **Credenciales incorrectas:** inicia sesión con una contraseña errada. Aparece "Correo o contraseña incorrectos."
3. **Inicio de sesión correcto:** con el usuario de prueba se accede al dashboard.
4. **Servicios protegidos:** lista, registra, edita y elimina productos. Cada petición lleva el token.
5. **Persistencia de sesión:** cierra la app por completo (deslizándola desde recientes) y ábrela de nuevo. Entra directo al dashboard.
6. **Validación desde el backend:** en `http://127.0.0.1:8000/docs`, ejecuta `GET /api/productos` sin autorizar. La API responde `401`.
7. **Cierre de sesión:** menú lateral, *Mi sesión*, *Cerrar sesión*. Se borran el token y los datos locales, y se vuelve al login.

**Sesión expirada (opcional):** inicia el servidor con `JWT_EXPIRE_MINUTES=1` (por ejemplo `$env:JWT_EXPIRE_MINUTES="1"` en PowerShell antes de `uvicorn`), inicia sesión en la app y espera más de un minuto. Al hacer una operación, la API responde 401 y la app regresa al login con el aviso de sesión expirada.

## Ejemplos de peticiones y respuestas

**Login correcto** (`POST /api/auth/login`)

```bash
curl -X POST http://127.0.0.1:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@inventario.com","password":"Admin123*"}'
```

En PowerShell:

```powershell
Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8000/api/auth/login `
  -ContentType "application/json" `
  -Body '{"email":"admin@inventario.com","password":"Admin123*"}'
```

Respuesta `200`:

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "usuario": { "id": 1, "nombre": "Administrador", "email": "admin@inventario.com" }
}
```

**Credenciales incorrectas** (`401`)

```json
{ "message": "Correo o contraseña incorrectos." }
```

**Endpoint protegido sin token** (`GET /api/productos`, `401`)

```json
{ "message": "No autenticado: falta el token de acceso." }
```

Otros mensajes `401`: `"La sesión ha expirado. Inicia sesión de nuevo."`, `"Token inválido."` y `"El usuario del token ya no existe."`.

**Endpoint protegido con token** (`GET /api/productos`)

```bash
curl http://127.0.0.1:8000/api/productos -H "Authorization: Bearer <access_token>"
```

Respuesta `200`:

```json
[
  {
    "nombre": "Arroz Diana 500g",
    "codigo": "ARZ-001",
    "descripcion": "Arroz blanco de grano largo",
    "precio": 3200.0,
    "cantidad": 80,
    "categoria": "Granos",
    "id": 1
  }
]
```

**Registrar un producto** (`POST /api/productos`, con token)

```json
{
  "nombre": "Producto X",
  "codigo": "TST-100",
  "descripcion": null,
  "precio": 1500.5,
  "cantidad": 7,
  "categoria": "Prueba"
}
```

Respuesta `201`: el mismo objeto con su `id` generado. Si el código ya existe responde `422`:

```json
{ "message": "Ya existe un producto con ese código." }
```

**Datos inválidos** (`422`)

```json
{ "message": "Datos inválidos.", "errors": { "precio": "Debe ser mayor que 0." } }
```

## Seguridad

- Las contraseñas se guardan solo como hash PBKDF2 con sal. No existe ninguna contraseña en texto plano en la base de datos.
- La clave de firma del JWT (`JWT_SECRET`) se lee del archivo `backend/.env`, que está en `.gitignore`. El repositorio solo incluye `.env.example`.
- El token se almacena cifrado con `flutter_secure_storage`; en `shared_preferences` solo hay datos no sensibles (id, nombre y correo).
- La validación del token ocurre en el backend. Ocultar pantallas en Flutter no sustituye la protección del servidor.
- Al cerrar sesión, o ante cualquier respuesta 401, se elimina el token y los datos locales.

## Flujo de trabajo (GitFlow)

- `main`: rama estable.
- `dev`: rama de integración.
- `feature/taller_jwt`: desarrollo de la autenticación JWT, creada a partir de `dev`, con commits descriptivos (`feat:`, `fix:`, `chore:`, `docs:`).
- Se integró con un Pull Request `feature/taller_jwt` hacia `dev` y luego `dev` hacia `main`.

## Despliegue

No se realizó despliegue. Tanto el backend como la aplicación se ejecutan de forma local.
