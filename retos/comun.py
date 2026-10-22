"""Utilidades compartidas por los retos (espejo de json_canonico.m y sha256_archivo.m)."""
from __future__ import annotations

import hashlib
import math
from pathlib import Path


def sha256_archivo(ruta) -> str:
    """Huella SHA-256 (hexadecimal, minúsculas) de los bytes de un archivo."""
    return hashlib.sha256(Path(ruta).read_bytes()).hexdigest()


def json_canonico(valor) -> str:
    """JSON con un formato fijo, idéntico byte a byte al de json_canonico.m.

    Sangría de 2 espacios; un campo por línea; listas de valores simples en una línea;
    números con %.15g; None y NaN -> null; texto UTF-8 sin escapar.
    """
    return _codificar(valor, "") + "\n"


def escribir_json(ruta, valor) -> None:
    Path(ruta).write_text(json_canonico(valor), encoding="utf-8", newline="\n")


def _codificar(v, sangria: str) -> str:
    sub = sangria + "  "
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        return '"' + _escapar(v) + '"'
    if isinstance(v, (int, float)) or hasattr(v, "dtype"):
        if hasattr(v, "tolist"):
            v = v.tolist()
            if isinstance(v, list):
                return _codificar(v, sangria)
            if isinstance(v, bool):
                return "true" if v else "false"
        x = float(v)
        return format(x, ".15g") if math.isfinite(x) else "null"
    if isinstance(v, dict):
        if not v:
            return "{}"
        partes = [f'{sub}"{k}": {_codificar(x, sub)}' for k, x in v.items()]
        return "{\n" + ",\n".join(partes) + "\n" + sangria + "}"
    if isinstance(v, (list, tuple)) or hasattr(v, "tolist"):
        v = list(v)
        if not v:
            return "[]"
        partes = [_codificar(x, sub) for x in v]
        if all(not isinstance(x, (dict, list, tuple)) for x in v):
            return "[" + ", ".join(partes) + "]"
        return "[\n" + sub + (",\n" + sub).join(partes) + "\n" + sangria + "]"
    raise TypeError(f"Tipo no soportado: {type(v).__name__}")


def _escapar(s: str) -> str:
    return (s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
            .replace("\r", "\\r").replace("\t", "\\t"))
