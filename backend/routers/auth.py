"""Endpoints de autenticacion: login y consulta de la sesion actual."""
import sqlite3

from fastapi import APIRouter, Depends, HTTPException

from config import JWT_EXPIRE_MINUTES
from database import get_db, get_user_by_email
from dependencies import get_current_user
from schemas import LoginIn, TokenOut, UsuarioOut
from security import HASH_RELLENO, create_access_token, verify_password

router = APIRouter(prefix="/api/auth", tags=["Autenticación"])


@router.post("/login", response_model=TokenOut)
def login(datos: LoginIn, db: sqlite3.Connection = Depends(get_db)):
    """Valida las credenciales y, si son correctas, devuelve un token JWT."""
    usuario = get_user_by_email(db, datos.email)

    # Siempre se verifica un hash (real o de relleno) para no revelar si el correo existe.
    hash_guardado = usuario["password_hash"] if usuario else HASH_RELLENO
    credenciales_ok = verify_password(datos.password, hash_guardado)

    if usuario is None or not credenciales_ok:
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return {
        "access_token": create_access_token(usuario["id"], usuario["email"]),
        "token_type": "bearer",
        "expires_in": JWT_EXPIRE_MINUTES * 60,
        "usuario": {
            "id": usuario["id"],
            "nombre": usuario["nombre"],
            "email": usuario["email"],
        },
    }


@router.get("/me", response_model=UsuarioOut)
def sesion_actual(usuario: dict = Depends(get_current_user)):
    """Devuelve el usuario del token. La app lo usa para comprobar que la sesion sigue vigente."""
    return usuario
