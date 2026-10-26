"""Paridad MATLAB vs Python de los escenarios: datos, rangos, opt y simulación nominal.

Lee pruebas/paridad_escenarios_matlab.json (generado por generar_paridad_escenarios.m, que corre
las secciones 1 y 2 de matlab/handson.m) y arma lo mismo con python/handson.py
(cargar_datos + armar_modelo). Para cada escenario y modelo sugerido comprueba:
  - la misma ventana de datos (y) y la misma rejilla (x), valor por valor;
  - los mismos rangos de los factores (catálogo + ajustes de la localidad) y el mismo opt;
  - la misma salida comparada;
  - la misma simulación nominal: tolerancia relativa 1e-8 en los discretos y 1e-4 en los
    continuos (CONTRATO.md), con el error medido como |py − mat| / max(|mat|, 1).
También comprueba que el archivo de MATLAB cubra todos los escenarios de escenarios.json.

Uso:  python pruebas/paridad_escenarios.py      o      python -m pytest pruebas/paridad_escenarios.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
import pytest

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent
sys.path.insert(0, str(RAIZ / "python"))

import handson  # noqa: E402

ARCHIVO = AQUI / "paridad_escenarios_matlab.json"
MATLAB = json.loads(ARCHIVO.read_text(encoding="utf-8")) if ARCHIVO.exists() else []
ESCENARIOS = handson.leer_escenarios()
CATALOGO = handson.leer_catalogo()
COMBINACIONES = [(e["id"], m) for e in ESCENARIOS.values() for m in e["modelos_sugeridos"]]

pytestmark = pytest.mark.skipif(not ARCHIVO.exists(), reason="corre antes pruebas/generar_paridad_escenarios.m en MATLAB")


def registro(eid: str, mid: str) -> dict:
    return next(r for r in MATLAB if r["escenario"] == eid and r["modelo"] == mid)


def comparar(eid: str, mid: str) -> dict:
    """Arma el escenario en Python y devuelve las diferencias con MATLAB."""
    esc, entrada, mat = ESCENARIOS[eid], CATALOGO[mid], registro(eid, mid)
    x, y, _ = handson.cargar_datos(esc)
    modelo, nombres, salida = handson.armar_modelo(entrada, esc, x)
    y_nom = handson.simular(modelo, modelo.nominal, x)
    m_nom = np.ravel(mat["y_nominal"])
    opt = {**entrada.get("opt_defecto", {}), **esc.get("opt", {})}
    return {
        "x": np.array_equal(x, np.ravel(mat["x"])),
        "y": np.array_equal(y, np.ravel(mat["y"])),
        "nombres": nombres == list(mat["nombres"]),
        "rangos": np.array_equal(np.asarray(modelo.range, dtype=float), np.asarray(mat["rangos"], dtype=float).reshape(-1, 2)),
        "opt": opt == mat["opt"],
        "salida": salida == mat["salida"],
        "error_nominal": float(np.max(np.abs(y_nom - m_nom) / np.maximum(np.abs(m_nom), 1.0))),
    }


def tolerancia(mid: str) -> float:
    return 1e-8 if CATALOGO[mid]["tipo"] == "discreto" else 1e-4


def test_matlab_cubre_todos_los_escenarios():
    hechos = {(r["escenario"], r["modelo"]) for r in MATLAB}
    faltan = [c for c in COMBINACIONES if c not in hechos]
    assert not faltan, f"Regenera paridad_escenarios_matlab.json en MATLAB; faltan: {faltan}"


@pytest.mark.parametrize("eid,mid", COMBINACIONES)
def test_paridad_escenario(eid, mid):
    d = comparar(eid, mid)
    for k in ("x", "y", "nombres", "rangos", "opt", "salida"):
        assert d[k], f"{eid}/{mid}: {k} distinto entre MATLAB y Python"
    assert d["error_nominal"] < tolerancia(mid)


if __name__ == "__main__":
    if not ARCHIVO.exists():
        sys.exit("Corre antes pruebas/generar_paridad_escenarios.m en MATLAB")
    fallas = 0
    for eid, mid in COMBINACIONES:
        try:
            d = comparar(eid, mid)
        except StopIteration:
            print(f"FALTA {eid:26s} {mid:22s} (regenera el archivo en MATLAB)")
            fallas += 1
            continue
        malos = [k for k in ("x", "y", "nombres", "rangos", "opt", "salida") if not d[k]]
        ok = not malos and d["error_nominal"] < tolerancia(mid)
        fallas += not ok
        print(f"{'OK   ' if ok else 'FALLA'} {eid:26s} {mid:22s} nominal {d['error_nominal']:.2g}"
              + (f"  distinto: {', '.join(malos)}" if malos else ""))
    sys.exit(1 if fallas else 0)
