"""Configuracion leida desde backend/.env (el .env NO se sube a Git)."""
import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

JWT_SECRET = os.getenv("JWT_SECRET")
if not JWT_SECRET:
    raise RuntimeError(
        "Falta JWT_SECRET. Copia backend/.env.example a backend/.env "
        "y define un valor secreto."
    )

JWT_ALGORITHM = "HS256"
JWT_EXPIRE_MINUTES = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))

DEMO_USER_NAME = os.getenv("DEMO_USER_NAME", "Administrador")
DEMO_USER_EMAIL = os.getenv("DEMO_USER_EMAIL", "admin@inventario.com")
DEMO_USER_PASSWORD = os.getenv("DEMO_USER_PASSWORD", "Admin123*")
