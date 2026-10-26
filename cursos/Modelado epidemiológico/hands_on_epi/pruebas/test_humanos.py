"""Pruebas de los modelos humano-humano en Python (pytest o ejecución directa).

1. Corrida nominal (punto medio de los rangos) de cada entrada de catalogo_humanos.json:
   forma, sin NaN, sin negativos, conservación de la población, filas de salida.
2. ``domain`` como [t0, tf] y como vector de tiempos de observación (lo que pasa gsua_csb).
3. Prueba corta con gsua_csb: UserFunctionModel + parameter_estimation (n = 2) con datos
   sintéticos generados desde el nominal.

Uso:  python pruebas/test_humanos.py      o      python -m pytest pruebas/test_humanos.py
"""
import importlib
import json
import pathlib
import sys

import numpy as np

RAIZ = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ / "python"))
try:
    import gsua_csb  # noqa: F401
except ImportError:  # toolbox sin instalar: se usa la copia fuente
    sys.path.insert(0, r"D:\MATLAB Drive.source-of-truth-20260718T095207\Toolbox\python\src")
import gsua_csb  # noqa: E402

CATALOGO = json.loads((RAIZ / "modelos" / "catalogo_humanos.json").read_text(encoding="utf-8"))


def funcion(entrada):
    mod = importlib.import_module(f"modelos.{entrada['modelo']}")
    return getattr(mod, entrada["modelo"])


def rangos(entrada):
    lista = entrada["parametros"] + entrada["condiciones_iniciales"]
    return [p["id"] for p in lista], np.array([p["rango"] for p in lista], dtype=float)


def nominal(entrada):
    return rangos(entrada)[1].mean(axis=1)


def test_nominal():
    for e in CATALOGO:
        f = funcion(e)
        opt = e["opt_defecto"]
        N = opt["N"]
        nest = len(e["estados"])
        Y = f(nominal(e), [0, 150], **opt)
        assert Y.shape == (nest + len(e["salidas"]), 151), e["id"]
        assert np.all(np.isfinite(Y)), e["id"]
        assert Y.min() >= -1e-9 * N, (e["id"], Y.min())
        consv = np.max(np.abs(Y[:nest].sum(axis=0) - N)) / N
        assert consv < 1e-8, (e["id"], consv)
        fila_estado = 5 if e["modelo"] == "sir_cuarentena_cl" else 2
        assert np.array_equal(Y[e["salidas"][0]["fila"] - 1], Y[fila_estado - 1]), e["id"]
        # incidencia con convención hacia atrás: en t0 vale la condición inicial (I0 o Ij0)
        nombres, _ = rangos(e)
        ci = "Ij0" if e["modelo"] == "sir_cuarentena_cl" else "I0"
        inc = Y[e["salidas"][1]["fila"] - 1]
        assert inc[0] == nominal(e)[nombres.index(ci)], e["id"]
        if e["modelo"] != "sir_cuarentena_cl":  # en los SIR: casos(t) = S(t-1) - S(t)
            assert np.max(np.abs(inc[1:] - (Y[0, :-1] - Y[0, 1:]))) < 1e-8 * N, e["id"]
        print(f"  OK  {e['id']:<24s} pico de activos {Y[e['salidas'][0]['fila'] - 1].max():.4g}, "
              f"conservación {consv:.1e}")


def test_dominio_vector():
    """domain = [t0, tf] -> rejilla entera; domain = vector -> exactamente esos tiempos."""
    for e in CATALOGO:
        f = funcion(e)
        opt = e["opt_defecto"]
        Y = f(nominal(e), [5, 40], **opt)
        assert Y.shape[1] == 36, e["id"]
        pts = np.array([5.0, 9.0, 17.0, 40.0])
        Z = f(nominal(e), pts, **opt)
        assert Z.shape == (Y.shape[0], 4), e["id"]
        tol = 1e-4 if e["tipo"] == "continuo" else 1e-12
        escala = np.maximum(np.abs(Y).max(axis=1, keepdims=True), 1e-12)
        err = np.max(np.abs(Z - Y[:, (pts - 5).astype(int)]) / escala)
        assert err < tol, (e["id"], err)


def test_gsua():
    """UserFunctionModel + parameter_estimation (n = 2) sobre datos sintéticos."""
    ids = {"sir_continuo", "sir_discreto", "sir_discreto_G1", "sir_cuarentena_cl"}
    Tf = 60
    xdata = np.arange(0, Tf + 1, dtype=float)
    for e in CATALOGO:
        if e["id"] not in ids:
            continue
        nombres, rng = rangos(e)
        salidas = e["estados"] + [s["id"] for s in e["salidas"]]
        modelo = gsua_csb.UserFunctionModel(
            func=funcion(e), names=nombres, range=rng, domain=xdata,
            output_names=salidas, opt=e["opt_defecto"],
        )
        modelo.set_output(e["salidas"][0]["fila"] - 1)
        ydata = modelo.evaluate(modelo.nominal, xdata)
        assert ydata.size == Tf + 1, (e["id"], ydata.shape)
        pe = gsua_csb.parameter_estimation(modelo, xdata, ydata, n=2, seed=0,
                                           solver_kwargs={"max_nfev": 200})
        assert np.all(np.isfinite(pe.cost)), e["id"]
        libres = int((rng[:, 0] != rng[:, 1]).sum())
        print(f"  OK  {e['id']:<24s} {libres} parámetros libres, costos {np.array2string(np.asarray(pe.cost), precision=3)}")


if __name__ == "__main__":
    for prueba in (test_nominal, test_dominio_vector, test_gsua):
        print(f"--- {prueba.__name__} ---")
        prueba()
    print("TODAS LAS PRUEBAS PASARON")
