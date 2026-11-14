"""Esquemas de validacion (Pydantic)."""
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ProductoIn(BaseModel):
    """Datos que envia el cliente para crear o actualizar un producto."""

    model_config = ConfigDict(str_strip_whitespace=True)

    nombre: str = Field(..., min_length=1, max_length=120)
    codigo: str = Field(..., min_length=1, max_length=40)
    descripcion: Optional[str] = Field(default=None, max_length=500)
    precio: float = Field(..., gt=0)
    cantidad: int = Field(..., ge=0)
    categoria: str = Field(..., min_length=1, max_length=60)


class ProductoOut(ProductoIn):
    """Producto tal como lo devuelve la API (incluye el id autogenerado)."""

    id: int


class LoginIn(BaseModel):
    email: str = Field(..., min_length=1, max_length=120)
    password: str = Field(..., min_length=1, max_length=128)


class UsuarioOut(BaseModel):
    """Datos publicos del usuario (nunca incluye el hash de la contrasena)."""

    id: int
    nombre: str
    email: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int  # segundos de vigencia del token
    usuario: UsuarioOut
