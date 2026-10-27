"""API REST de inventario de productos (FastAPI + SQLite).

Ejecutar:  python -m uvicorn main:app --reload
Swagger :  http://127.0.0.1:8000/docs
"""
import sqlite3
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from database import get_db, init_db
from schemas import ProductoIn, ProductoOut


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()  # crea la tabla y los productos de prueba al iniciar
    yield


app = FastAPI(title="API de Inventario", version="1.0.0", lifespan=lifespan)

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
    return JSONResponse(status_code=exc.status_code, content={"message": exc.detail})


# ----------------------------------------------------------------------------
# Endpoints
# ----------------------------------------------------------------------------
def _buscar(db: sqlite3.Connection, producto_id: int) -> dict:
    fila = db.execute("SELECT * FROM productos WHERE id = ?", (producto_id,)).fetchone()
    if fila is None:
        raise HTTPException(status_code=404, detail="Producto no encontrado.")
    return dict(fila)


@app.get("/api/productos", response_model=list[ProductoOut])
def listar_productos(db: sqlite3.Connection = Depends(get_db)):
    filas = db.execute("SELECT * FROM productos ORDER BY id").fetchall()
    return [dict(f) for f in filas]


@app.get("/api/productos/{producto_id}", response_model=ProductoOut)
def obtener_producto(producto_id: int, db: sqlite3.Connection = Depends(get_db)):
    return _buscar(db, producto_id)


@app.post("/api/productos", response_model=ProductoOut, status_code=201)
def crear_producto(datos: ProductoIn, db: sqlite3.Connection = Depends(get_db)):
    try:
        cur = db.execute(
            "INSERT INTO productos (nombre, codigo, descripcion, precio, cantidad, categoria) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (datos.nombre, datos.codigo, datos.descripcion, datos.precio,
             datos.cantidad, datos.categoria),
        )
        db.commit()
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=422, detail="Ya existe un producto con ese código.")
    return _buscar(db, cur.lastrowid)


@app.put("/api/productos/{producto_id}", response_model=ProductoOut)
def actualizar_producto(
    producto_id: int, datos: ProductoIn, db: sqlite3.Connection = Depends(get_db)
):
    _buscar(db, producto_id)  # lanza 404 si no existe
    try:
        db.execute(
            "UPDATE productos SET nombre = ?, codigo = ?, descripcion = ?, precio = ?, "
            "cantidad = ?, categoria = ? WHERE id = ?",
            (datos.nombre, datos.codigo, datos.descripcion, datos.precio,
             datos.cantidad, datos.categoria, producto_id),
        )
        db.commit()
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=422, detail="Ya existe un producto con ese código.")
    return _buscar(db, producto_id)


@app.delete("/api/productos/{producto_id}")
def eliminar_producto(producto_id: int, db: sqlite3.Connection = Depends(get_db)):
    _buscar(db, producto_id)  # lanza 404 si no existe
    db.execute("DELETE FROM productos WHERE id = ?", (producto_id,))
    db.commit()
    return {"message": "Producto eliminado correctamente."}
