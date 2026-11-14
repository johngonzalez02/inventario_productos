"""CRUD de productos. TODOS los endpoints exigen un token JWT valido."""
import sqlite3

from fastapi import APIRouter, Depends, HTTPException

from database import get_db
from dependencies import get_current_user
from schemas import ProductoIn, ProductoOut

# dependencies=[Depends(get_current_user)] protege cada ruta de este router:
# sin token valido la API responde 401 antes de ejecutar la operacion.
router = APIRouter(
    prefix="/api/productos",
    tags=["Productos (protegidos)"],
    dependencies=[Depends(get_current_user)],
)


def _buscar(db: sqlite3.Connection, producto_id: int) -> dict:
    fila = db.execute("SELECT * FROM productos WHERE id = ?", (producto_id,)).fetchone()
    if fila is None:
        raise HTTPException(status_code=404, detail="Producto no encontrado.")
    return dict(fila)


@router.get("", response_model=list[ProductoOut])
def listar_productos(db: sqlite3.Connection = Depends(get_db)):
    filas = db.execute("SELECT * FROM productos ORDER BY id").fetchall()
    return [dict(f) for f in filas]


@router.get("/{producto_id}", response_model=ProductoOut)
def obtener_producto(producto_id: int, db: sqlite3.Connection = Depends(get_db)):
    return _buscar(db, producto_id)


@router.post("", response_model=ProductoOut, status_code=201)
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


@router.put("/{producto_id}", response_model=ProductoOut)
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


@router.delete("/{producto_id}")
def eliminar_producto(producto_id: int, db: sqlite3.Connection = Depends(get_db)):
    _buscar(db, producto_id)  # lanza 404 si no existe
    db.execute("DELETE FROM productos WHERE id = ?", (producto_id,))
    db.commit()
    return {"message": "Producto eliminado correctamente."}
