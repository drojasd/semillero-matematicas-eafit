"""Paridad MATLAB vs Python de la preparación de datos (datos/preparar_datos.m y .py).

Compara lo que escribe MATLAB en pruebas/paridad_datos_matlab/ (generado por
generar_paridad_datos.m) con lo versionado, que sale de preparar_datos.py:
  - cada CSV, valor por valor (los vacíos de pandas son los NaN de MATLAB);
  - resumen.json;
  - escenarios.json, objeto por objeto (mismo contenido, aunque el formato del texto difiera).
Si la carpeta no existe, las pruebas se omiten: hay que correr antes el generador en MATLAB.

Uso:  python pruebas/paridad_datos.py      o      python -m pytest pruebas/paridad_datos.py
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import pandas as pd
import pytest

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent
MATLAB = AQUI / "paridad_datos_matlab"
CSV = sorted(p.name for p in MATLAB.glob("*.csv")) if MATLAB.exists() else []

pytestmark = pytest.mark.skipif(not MATLAB.exists(), reason="corre antes pruebas/generar_paridad_datos.m en MATLAB")


def normal(v):
    """JSON de MATLAB: los vectores de un elemento y los enteros guardados como float se igualan."""
    if isinstance(v, dict):
        return {k: normal(x) for k, x in v.items()}
    if isinstance(v, list):
        return [normal(x) for x in v]
    if isinstance(v, float) and math.isfinite(v) and v.is_integer():
        return int(v)
    return v


def diferencias_escenarios() -> list[str]:
    py = json.loads((RAIZ / "escenarios.json").read_text(encoding="utf-8"))
    mat = json.loads((MATLAB / "escenarios.json").read_text(encoding="utf-8"))
    malos = [] if [e["id"] for e in py] == [e["id"] for e in mat] else ["orden o ids"]
    for a, b in zip(py, mat):
        if normal(a) != normal(b):
            malos += [f"{a['id']}.{k}" for k in a if normal(a.get(k)) != normal(b.get(k))]
    return malos


@pytest.mark.parametrize("nombre", CSV)
def test_paridad_csv(nombre):
    py = pd.read_csv(RAIZ / "datos" / nombre)
    mat = pd.read_csv(MATLAB / nombre)
    pd.testing.assert_frame_equal(py, mat, check_dtype=False)


def test_paridad_resumen():
    if not (MATLAB / "resumen.json").exists():
        pytest.skip("MATLAB no tenía los archivos de origen: solo hay escenarios")
    py = json.loads((RAIZ / "datos" / "resumen.json").read_text(encoding="utf-8"))
    mat = json.loads((MATLAB / "resumen.json").read_text(encoding="utf-8"))
    assert normal(py) == normal(mat)


def test_paridad_escenarios():
    assert not diferencias_escenarios()


if __name__ == "__main__":
    if not MATLAB.exists():
        sys.exit("Corre antes pruebas/generar_paridad_datos.m en MATLAB")
    fallas = 0
    for nombre in CSV:
        try:
            test_paridad_csv(nombre)
            print(f"OK    {nombre}")
        except AssertionError as e:
            fallas += 1
            print(f"FALLA {nombre}: {str(e).splitlines()[0]}")
    malos = diferencias_escenarios()
    fallas += bool(malos)
    print(f"{'OK   ' if not malos else 'FALLA'} escenarios.json" + (f": {', '.join(malos)}" if malos else ""))
    sys.exit(1 if fallas else 0)
