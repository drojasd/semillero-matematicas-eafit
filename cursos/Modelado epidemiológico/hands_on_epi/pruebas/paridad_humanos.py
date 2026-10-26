"""Paridad MATLAB vs Python de los modelos humano-humano.

Para cada entrada de modelos/catalogo_humanos.json corre en Python los 20 vectores de
pruebas/pars_paridad_<id>.csv (domain = [0, 100], opt = opt_defecto) y compara con
pruebas/salidas_matlab_<id>.csv (generado por generar_paridad_humanos.m).

Error relativo: |py - matlab| / max|fila de matlab| (escala por fila de salida y por vector).
Tolerancias del contrato: 1e-8 en los discretos, 1e-4 en los continuos.

Uso:  python pruebas/paridad_humanos.py     (también se puede correr con pytest)
"""
import importlib
import json
import pathlib
import sys

import numpy as np

RAIZ = pathlib.Path(__file__).resolve().parents[1]
PRUEBAS = RAIZ / "pruebas"
sys.path.insert(0, str(RAIZ / "python"))
CATALOGO = json.loads((RAIZ / "modelos" / "catalogo_humanos.json").read_text(encoding="utf-8"))
DOMAIN = [0, 100]
TOL = {"discreto": 1e-8, "continuo": 1e-4}


def comparar(e):
    mod = importlib.import_module(f"modelos.{e['modelo']}")
    f = getattr(mod, e["modelo"])
    P = np.loadtxt(PRUEBAS / f"pars_paridad_{e['id']}.csv", delimiter=",", ndmin=2)
    M = np.loadtxt(PRUEBAS / f"salidas_matlab_{e['id']}.csv", delimiter=",", ndmin=2)
    err = 0.0
    for p, m in zip(P, M):
        y = f(p, DOMAIN, **e["opt_defecto"])
        ym = m.reshape(y.shape)
        escala = np.maximum(np.abs(ym).max(axis=1, keepdims=True), 1e-12)
        err = max(err, float(np.max(np.abs(y - ym) / escala)))
    return err, len(P)


def test_paridad():
    fallos = []
    for e in CATALOGO:
        err, n = comparar(e)
        tol = TOL[e["tipo"]]
        estado = "OK   " if err < tol else "FALLA"
        print(f"  {estado} {e['id']:<24s} {n} vectores, error relativo máximo {err:.2e} (tol {tol:g})")
        if err >= tol:
            fallos.append(e["id"])
    assert not fallos, f"paridad fallida en: {fallos}"


if __name__ == "__main__":
    test_paridad()
    print("PARIDAD OK")
