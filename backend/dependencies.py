"""Dependencia que protege los endpoints: valida el token JWT del encabezado Authorization."""
import sqlite3
from typing import Optional

import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from database import get_db, get_user_by_id
from security import decode_access_token

# auto_error=False: el mensaje de error lo definimos nosotros (siempre 401).
bearer_scheme = HTTPBearer(
    auto_error=False,
    description="Pega aqui el access_token obtenido en POST /api/auth/login",
)


def _no_autorizado(mensaje: str) -> HTTPException:
    return HTTPException(
        status_code=401, detail=mensaje, headers={"WWW-Authenticate": "Bearer"}
    )


def get_current_user(
    credenciales: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    """Devuelve el usuario dueño del token o responde 401 si no es valido."""
    if credenciales is None or not credenciales.credentials:
        raise _no_autorizado("No autenticado: falta el token de acceso.")

    try:
        payload = decode_access_token(credenciales.credentials)
    except jwt.ExpiredSignatureError:
        raise _no_autorizado("La sesión ha expirado. Inicia sesión de nuevo.")
    except jwt.InvalidTokenError:
        raise _no_autorizado("Token inválido.")

    try:
        user_id = int(payload.get("sub", ""))
    except (TypeError, ValueError):
        raise _no_autorizado("Token inválido.")

    usuario = get_user_by_id(db, user_id)
    if usuario is None:
        raise _no_autorizado("El usuario del token ya no existe.")
    return usuario
