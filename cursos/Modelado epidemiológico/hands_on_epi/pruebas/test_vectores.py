"""Pruebas de los modelos de transmisión vectorial (dengue) en Python.

Uso:  python -m pytest pruebas/test_vectores.py      o      python pruebas/test_vectores.py

1. Nominal (punto medio de los rangos del catálogo): sin NaN ni negativos, forma correcta.
2. ``domain`` como [t0, tf] y como vector de tiempos dan lo mismo en los puntos comunes.
3. dengue_lizarralde conserva la población humana (natalidad = mortalidad).
4. Humo GSUA: UserFunctionModel + parameter_estimation (n=2) con datos sintéticos del nominal.
La paridad con MATLAB está en paridad_vectores.py.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent
sys.path.insert(0, str(RAIZ / "python"))
TOOLBOX_PY = Path(r"D:\MATLAB Drive.source-of-truth-20260718T095207\Toolbox\python\src")
try:
    import gsua_csb  # noqa: F401
except ImportError:  # la toolbox no está instalada: se usa la copia local
    sys.path.insert(0, str(TOOLBOX_PY))

from modelos.dengue_cl_discreto import dengue_cl_discreto  # noqa: E402
from modelos.dengue_lizarralde import dengue_lizarralde  # noqa: E402

FUNCIONES = {"dengue_lizarralde": dengue_lizarralde, "dengue_cl_discreto": dengue_cl_discreto}
CATALOGO = {e["id"]: e for e in json.loads((RAIZ / "modelos" / "catalogo_vectores.json").read_text(encoding="utf-8"))}


def rangos(entrada):
    return np.array([p["rango"] for p in entrada["parametros"] + entrada["condiciones_iniciales"]], float)


def nombres(entrada):
    return [p["id"] for p in entrada["parametros"] + entrada["condiciones_iniciales"]]


def nombres_salida(entrada):
    filas = list(entrada["estados"])
    for s in sorted(entrada["salidas"], key=lambda s: s["fila"]):
        assert s["fila"] == len(filas) + 1, "las salidas deben ir justo después de los estados"
        filas.append(s["id"])
    return filas


def test_nominal_sin_nan_ni_negativos():
    for mid, f in FUNCIONES.items():
        e = CATALOGO[mid]
        y = f(rangos(e).mean(axis=1), [0, 104], **e["opt_defecto"])
        assert y.shape == (len(nombres_salida(e)), 105), mid
        assert np.all(np.isfinite(y)), mid
        assert y.min() >= -1e-6 * np.abs(y).max(), f"{mid}: mínimo {y.min()}"


def test_dominio_vector_igual_a_rejilla():
    for mid, f in FUNCIONES.items():
        e = CATALOGO[mid]
        nom = rangos(e).mean(axis=1)
        y = f(nom, [0, 60], **e["opt_defecto"])
        for puntos in (np.arange(0, 61), np.arange(0, 61, 4), np.array([0, 3, 7, 8, 50, 60])):
            yp = f(nom, puntos, **e["opt_defecto"])
            assert yp.shape == (y.shape[0], puntos.size)
            np.testing.assert_allclose(yp, y[:, puntos], rtol=1e-4, atol=1e-6 * np.abs(y).max())


def test_lizarralde_conserva_humanos():
    e = CATALOGO["dengue_lizarralde"]
    y = dengue_lizarralde(rangos(e).mean(axis=1), [0, 104], **e["opt_defecto"])
    H = y[3:7].sum(axis=0)
    assert np.max(np.abs(H - H[0])) / H[0] < 1e-5
    # Casos acumulados = Hi0 + suma de semanales posteriores
    np.testing.assert_allclose(np.cumsum(y[7]), y[8], rtol=1e-10)


def test_cl_discreto_conserva_humanos_y_acumulados():
    e = CATALOGO["dengue_cl_discreto"]
    nom = rangos(e).mean(axis=1)
    for mu_h in (0.0, 0.0004):
        y = dengue_cl_discreto(nom, [0, 104], mu_h=mu_h)
        H = y[2:5].sum(axis=0)
        assert np.max(np.abs(H - H[0])) / H[0] < 1e-12
        np.testing.assert_allclose(np.cumsum(y[5]), y[6], rtol=1e-12)


def test_gsua_estimacion_humo():
    from gsua_csb import UserFunctionModel, parameter_estimation

    T = 30
    xdata = np.arange(0, T + 1, dtype=float)
    for mid, f in FUNCIONES.items():
        e = CATALOGO[mid]
        salida = next(s for s in e["salidas"] if s["id"] == "casos_semanales")
        modelo = UserFunctionModel(
            func=f,
            names=nombres(e),
            range=rangos(e),
            domain=xdata,
            output_names=nombres_salida(e),
            opt=dict(e["opt_defecto"]),
            output=salida["fila"] - 1,
        )
        ydata = modelo.evaluate(modelo.nominal, xdata)
        assert ydata.size == T + 1  # (1, T+1): una salida seleccionada
        pe = parameter_estimation(modelo, xdata, ydata, n=2, seed=0, solver_kwargs={"max_nfev": 20})
        assert pe.x.shape == (2, len(modelo.names))
        assert np.all(np.isfinite(pe.cost))
        print(f"  GSUA {mid}: costos {pe.cost}")


if __name__ == "__main__":
    fallas = 0
    for nombre, prueba in list(globals().items()):
        if nombre.startswith("test_") and callable(prueba):
            try:
                prueba()
                print(f"OK    {nombre}")
            except Exception as exc:  # noqa: BLE001
                fallas += 1
                print(f"FALLA {nombre}: {exc!r}")
    sys.exit(1 if fallas else 0)
