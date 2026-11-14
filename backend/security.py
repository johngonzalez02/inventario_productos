"""Hash de contrasenas (PBKDF2 + sal) y creacion / validacion de tokens JWT."""
import base64
import hashlib
import hmac
import os
from datetime import datetime, timedelta, timezone

import jwt

from config import JWT_ALGORITHM, JWT_EXPIRE_MINUTES, JWT_SECRET

_ITERACIONES = 600_000


def hash_password(password: str) -> str:
    """Devuelve 'pbkdf2_sha256$iteraciones$sal$hash'. La contrasena nunca se guarda en claro."""
    sal = os.urandom(16)
    derivada = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), sal, _ITERACIONES)
    return "$".join(
        [
            "pbkdf2_sha256",
            str(_ITERACIONES),
            base64.b64encode(sal).decode(),
            base64.b64encode(derivada).decode(),
        ]
    )


def verify_password(password: str, guardado: str) -> bool:
    try:
        algoritmo, iteraciones, sal_b64, hash_b64 = guardado.split("$")
        if algoritmo != "pbkdf2_sha256":
            return False
        derivada = hashlib.pbkdf2_hmac(
            "sha256",
            password.encode("utf-8"),
            base64.b64decode(sal_b64),
            int(iteraciones),
        )
        return hmac.compare_digest(derivada, base64.b64decode(hash_b64))
    except (ValueError, TypeError):
        return False


# Hash de relleno: se verifica contra el cuando el correo no existe, para que
# el tiempo de respuesta no revele si el usuario esta registrado.
HASH_RELLENO = hash_password("relleno-no-es-una-contrasena-real")


def create_access_token(user_id: int, email: str) -> str:
    ahora = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "email": email,
        "iat": ahora,
        "exp": ahora + timedelta(minutes=JWT_EXPIRE_MINUTES),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> dict:
    """Valida firma y expiracion. Lanza jwt.ExpiredSignatureError o jwt.InvalidTokenError."""
    return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
