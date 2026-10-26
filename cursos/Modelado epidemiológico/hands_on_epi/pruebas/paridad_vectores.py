"""Paridad MATLAB vs Python de los modelos de vectores (dengue).

Lee pruebas/pars_paridad_<id>.csv y pruebas/salidas_matlab_<id>.csv (generados por
generar_paridad_vectores.m), corre los mismos vectores en Python y compara.
Tolerancia relativa: 1e-8 en los discretos y 1e-4 en los continuos (CONTRATO.md). El error de
cada valor se mide como |py − mat| / max(|mat|, 1).

Uso:  python pruebas/paridad_vectores.py      o      python -m pytest pruebas/paridad_vectores.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent
sys.path.insert(0, str(RAIZ / "python"))

from modelos.dengue_cl_discreto import dengue_cl_discreto  # noqa: E402
from modelos.dengue_lizarralde import dengue_lizarralde  # noqa: E402

FUNCIONES = {"dengue_lizarralde": dengue_lizarralde, "dengue_cl_discreto": dengue_cl_discreto}
CATALOGO = {e["id"]: e for e in json.loads((RAIZ / "modelos" / "catalogo_vectores.json").read_text(encoding="utf-8"))}
DOMINIO = [0, 52]


def comparar(mid: str) -> float:
    """Devuelve el error relativo máximo entre Python y MATLAB para el modelo ``mid``."""
    e = CATALOGO[mid]
    P = np.loadtxt(AQUI / f"pars_paridad_{mid}.csv", delimiter=",", skiprows=1, ndmin=2)
    S = np.loadtxt(AQUI / f"salidas_matlab_{mid}.csv", delimiter=",", skiprows=1, ndmin=2)
    peor = 0.0
    for k, p in enumerate(P, start=1):
        y = FUNCIONES[mid](p, DOMINIO, **e["opt_defecto"])
        m = S[S[:, 0] == k][:, 2:]
        assert m.shape == y.shape, f"{mid} vector {k}: forma {y.shape} vs MATLAB {m.shape}"
        peor = max(peor, float(np.max(np.abs(y - m) / np.maximum(np.abs(m), 1.0))))
    return peor


def tolerancia(mid: str) -> float:
    return 1e-8 if CATALOGO[mid]["tipo"] == "discreto" else 1e-4


def test_paridad_dengue_lizarralde():
    assert comparar("dengue_lizarralde") < tolerancia("dengue_lizarralde")


def test_paridad_dengue_cl_discreto():
    assert comparar("dengue_cl_discreto") < tolerancia("dengue_cl_discreto")


if __name__ == "__main__":
    fallas = 0
    for mid in FUNCIONES:
        err = comparar(mid)
        ok = err < tolerancia(mid)
        fallas += not ok
        print(f"{'OK   ' if ok else 'FALLA'} {mid}: error relativo máximo {err:.3g} (tolerancia {tolerancia(mid):g})")
    sys.exit(1 if fallas else 0)
