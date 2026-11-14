"""API REST de inventario con autenticacion JWT (FastAPI + SQLite).

Ejecutar:  python -m uvicorn main:app --reload
Swagger :  http://127.0.0.1:8000/docs   (boton "Authorize" para probar con token)
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

import config
from database import create_user, get_connection, get_user_by_email, init_db
from routers import auth, productos
from security import hash_password


def seed_usuario_demo() -> None:
    """Crea el usuario de prueba la primera vez (la contrasena se guarda con hash)."""
    conn = get_connection()
    try:
        if get_user_by_email(conn, config.DEMO_USER_EMAIL) is None:
            create_user(
                conn,
                config.DEMO_USER_NAME,
                config.DEMO_USER_EMAIL,
                hash_password(config.DEMO_USER_PASSWORD),
            )
    finally:
        conn.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()  # crea las tablas y los productos de prueba
    seed_usuario_demo()  # crea el usuario de prueba
    yield


app = FastAPI(title="API de Inventario", version="2.0.0", lifespan=lifespan)

# ----------------------------------------------------------------------------
# Manejo uniforme de errores: siempre {"message": ..., "errors": {campo: msg}}
# ----------------------------------------------------------------------------
MENSAJES = {
    "missing": "Este campo es obligatorio.",
    "string_too_short": "Este campo es obligatorio.",
    "string_type": "Debe ser un texto.",
    "greater_than": "Debe ser mayor que 0.",
    "greater_than_equal": "Debe ser mayor o igual a 0.",
    "float_parsing": "Debe ser un número.",
    "int_parsing": "Debe ser un número entero.",
    "string_too_long": "El texto es demasiado largo.",
}


@app.exception_handler(RequestValidationError)
async def validation_handler(request: Request, exc: RequestValidationError):
    errores = {}
    for err in exc.errors():
        campo = str(err["loc"][-1])
        errores[campo] = MENSAJES.get(err["type"], err["msg"])
    return JSONResponse(
        status_code=422, content={"message": "Datos inválidos.", "errors": errores}
    )


@app.exception_handler(StarletteHTTPException)
async def http_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"message": exc.detail},
        headers=getattr(exc, "headers", None),
    )


app.include_router(auth.router)
app.include_router(productos.router)
