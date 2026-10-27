"""Acceso a la base de datos SQLite (persistencia real en el archivo inventario.db)."""
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).parent / "inventario.db"

PRODUCTOS_INICIALES = [
    ("Arroz Diana 500g", "ARZ-001", "Arroz blanco de grano largo", 3200, 80, "Granos"),
    ("Aceite Gourmet 1L", "ACE-002", "Aceite vegetal de girasol", 14500, 35, "Despensa"),
    ("Leche Alquería 1L", "LCH-003", "Leche entera larga vida", 4300, 120, "Lácteos"),
    ("Huevos AA x30", "HUE-004", "Cubeta de 30 huevos tipo AA", 18900, 25, "Lácteos"),
    ("Café Sello Rojo 250g", "CAF-005", "Café molido tostado", 9800, 60, "Bebidas"),
    ("Gaseosa Postobón 1.5L", "GAS-006", "Gaseosa sabor manzana", 5200, 90, "Bebidas"),
    ("Pan Tajado Bimbo", "PAN-007", "Pan blanco tajado 450g", 6700, 40, "Panadería"),
    ("Jabón Rey 300g", "JAB-008", "Jabón de lavar en barra", 3100, 70, "Aseo"),
    ("Papel Higiénico x12", "PAP-009", "Paquete de 12 rollos doble hoja", 21500, 30, "Aseo"),
    ("Atún Van Camp's 160g", "ATU-010", "Atún en agua lata", 7400, 55, "Enlatados"),
]


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def get_db():
    """Dependencia de FastAPI: abre una conexion por peticion y la cierra al terminar."""
    conn = get_connection()
    try:
        yield conn
    finally:
        conn.close()


def init_db() -> None:
    """Crea la tabla si no existe y carga 10 productos de prueba si esta vacia."""
    conn = get_connection()
    try:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS productos (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre      TEXT    NOT NULL,
                codigo      TEXT    NOT NULL UNIQUE,
                descripcion TEXT,
                precio      REAL    NOT NULL,
                cantidad    INTEGER NOT NULL,
                categoria   TEXT    NOT NULL
            )
            """
        )
        total = conn.execute("SELECT COUNT(*) FROM productos").fetchone()[0]
        if total == 0:
            conn.executemany(
                "INSERT INTO productos (nombre, codigo, descripcion, precio, cantidad, categoria) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                PRODUCTOS_INICIALES,
            )
        conn.commit()
    finally:
        conn.close()
