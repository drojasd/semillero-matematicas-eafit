"""Hands-on de epidemiología con GSUA-CSB (Python). Espejo de matlab/handson.m.

Elige un ESCENARIO (datos reales + ventana + salida observada) y un MODELO del catálogo, y
recorre el ciclo completo:

  1. datos  2. modelo  3. simulación nominal  4. incertidumbre  5. sensibilidad
  6. estimación multicomienzo  7. bootstrap  8. identificabilidad e intervalos

Uso:
    python handson.py                                   # escenario y modelo por omisión
    python handson.py --escenario dengue_bello_2009_2011 --modelo dengue_cl_discreto
    python handson.py --listar                          # escenarios y modelos disponibles
    python handson.py --rapido                          # tamaños pequeños, para probar

Los resultados (JSON y figuras) quedan en ../resultados/.
"""
from __future__ import annotations

import argparse
import importlib
import json
import sys
import time
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # figuras a archivo; quítalo si trabajas en un cuaderno
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from gsua_csb import (
    UserFunctionModel,
    design_matrix,
    identifiability_analysis,
    parameter_estimation,
    sensitivity_analysis,
    uncertainty_analysis,
)

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ / "python"))


# ---------------------------------------------------------------- 0. catálogo y escenarios
def leer_catalogo() -> dict[str, dict]:
    cat = {}
    for f in sorted((RAIZ / "modelos").glob("catalogo_*.json")):
        for m in json.loads(f.read_text(encoding="utf-8")):
            cat[m["id"]] = m
    return cat


def leer_escenarios() -> dict[str, dict]:
    return {e["id"]: e for e in json.loads((RAIZ / "escenarios.json").read_text(encoding="utf-8"))}


# ---------------------------------------------------------------- 1. datos
def cargar_datos(esc: dict) -> tuple[np.ndarray, np.ndarray, pd.DataFrame]:
    d = pd.read_csv(RAIZ / "datos" / esc["datos"])
    f = esc.get("filtro")
    if f:
        col = d[f["columna"]]
        d = d[(col >= f["desde"]) & (col <= f["hasta"])].reset_index(drop=True)
    y = d[esc["columna"]].to_numpy(dtype=float)
    if esc.get("acumular"):
        y = np.cumsum(y)
    x = np.arange(len(y), dtype=float)  # tiempo relativo: 0, 1, 2, ... en la unidad del modelo
    return x, y, d


# ---------------------------------------------------------------- 2. modelo
def armar_modelo(entrada: dict, esc: dict, x: np.ndarray) -> tuple[UserFunctionModel, list[str], int]:
    funcion_id = entrada.get("modelo", entrada["id"])
    func = getattr(importlib.import_module(f"modelos.{funcion_id}"), funcion_id)

    factores = entrada["parametros"] + entrada.get("condiciones_iniciales", [])
    nombres = [p["id"] for p in factores]
    rangos = np.array([p["rango"] for p in factores], dtype=float)
    ajustes = esc.get("rangos", {}).get(entrada["id"]) or esc.get("rangos", {}).get(funcion_id) or {}
    for k, r in ajustes.items():  # rangos propios de la localidad (escenarios.json)
        rangos[nombres.index(k)] = r

    opt = {**entrada.get("opt_defecto", {}), **esc.get("opt", {})}
    salidas = {s["id"]: s["fila"] for s in entrada["salidas"]}
    salida = next(s for s in esc["salidas"] if s in salidas)
    # Una etiqueta por fila de la función: primero los estados y luego las salidas observables.
    filas = list(entrada["estados"]) + [s["id"] for s in sorted(entrada["salidas"], key=lambda s: s["fila"])]
    modelo = UserFunctionModel(
        func, nombres, rangos, domain=x,
        output_names=filas,
        opt=opt, output=salidas[salida] - 1,
    )
    return modelo, nombres, salida


def simular(modelo: UserFunctionModel, p: np.ndarray, x: np.ndarray) -> np.ndarray:
    return np.ravel(modelo.evaluate(np.asarray(p, dtype=float), x))


# ---------------------------------------------------------------- programa
def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--escenario", default="covid_colombia_ola1")
    ap.add_argument("--modelo", default="sir_discreto")
    ap.add_argument("--n-ua", type=int, default=200, help="muestras para incertidumbre")
    ap.add_argument("--n-sa", type=int, default=200, help="muestras para sensibilidad")
    ap.add_argument("--n-multi", type=int, default=None,
                    help="arranques de la estimación (por omisión: 10 si hay ≤ 4 factores libres, 60 si hay más)")
    ap.add_argument("--n-boot", type=int, default=20, help="re-ajustes bootstrap")
    ap.add_argument("--semilla", type=int, default=2026)
    ap.add_argument("--sin-sa", action="store_true", help="omite la sensibilidad (lenta en EDO)")
    ap.add_argument("--rapido", action="store_true", help="tamaños mínimos para probar que todo corre")
    ap.add_argument("--listar", action="store_true")
    a = ap.parse_args()
    if a.rapido:
        a.n_ua, a.n_sa, a.n_multi, a.n_boot = 20, 20, 2, 3

    cat, escs = leer_catalogo(), leer_escenarios()
    if a.listar:
        print("Escenarios:")
        for e in escs.values():
            print(f"  {e['id']:26s} {e['nombre']}  (sugeridos: {', '.join(e['modelos_sugeridos'])})")
        print("Modelos:")
        for m in cat.values():
            print(f"  {m['id']:26s} {m['nombre']}")
        return

    esc, entrada = escs[a.escenario], cat[a.modelo]
    if entrada["transmision"] != esc["transmision"]:
        print(f"OJO: el modelo es de transmisión {entrada['transmision']} y los datos son {esc['transmision']}.")
    salida_dir = RAIZ / "resultados"
    salida_dir.mkdir(exist_ok=True)
    tag = f"{esc['id']}__{entrada['id']}__python"
    rng = np.random.default_rng(a.semilla)
    reloj = time.time()

    # 1. Datos
    x, y, tabla = cargar_datos(esc)
    print(f"[1] Datos: {esc['nombre']} -> {len(y)} puntos ({entrada['unidad_tiempo']})")

    # 2. Modelo
    modelo, nombres, salida = armar_modelo(entrada, esc, x)
    libres = [i for i, f in enumerate(modelo.fixed) if not f]
    print(f"[2] Modelo: {entrada['nombre']}; salida comparada: {salida}")
    print(f"    Factores libres ({len(libres)}): {', '.join(nombres[i] for i in libres)}")
    if a.n_multi is None:  # con muchos factores, el costo tiene muchos mínimos locales
        a.n_multi = 10 if len(libres) <= 4 else 60
    print(f"    Estimación con {a.n_multi} arranques; bootstrap de {a.n_boot} re-ajustes")

    # 3. Simulación nominal
    y_nom = simular(modelo, modelo.nominal, x)
    fig, ax = plt.subplots(figsize=(9, 4))
    ax.plot(x, y, ".", color="tab:red", label="Datos")
    ax.plot(x, y_nom, "-", label="Modelo (nominal: centro de los rangos)")
    ax.set_xlabel(f"t ({entrada['unidad_tiempo']}s)"); ax.set_ylabel(salida); ax.legend(); ax.grid(True)
    fig.tight_layout(); fig.savefig(salida_dir / f"{tag}_1_nominal.png", dpi=110); plt.close(fig)
    print("[3] Simulación nominal guardada")

    # 4. Incertidumbre: ¿los datos caen dentro de lo que el modelo puede producir?
    M = design_matrix(modelo, n=a.n_ua, method="latin_hypercube", seed=a.semilla)
    ua = uncertainty_analysis(modelo, M, y_exp=y)
    P5, P50, P95 = np.percentile(np.asarray(ua.Y), [5, 50, 95], axis=0)
    dentro = float(np.mean((y >= P5) & (y <= P95)))
    fig, ax = plt.subplots(figsize=(9, 4))
    ax.fill_between(x, P5, P95, alpha=0.3, label="Banda P5–P95")
    ax.plot(x, P50, label="Mediana"); ax.plot(x, y, ".", color="tab:red", label="Datos")
    ax.set_xlabel(f"t ({entrada['unidad_tiempo']}s)"); ax.set_ylabel(salida); ax.legend(); ax.grid(True)
    fig.tight_layout(); fig.savefig(salida_dir / f"{tag}_2_incertidumbre.png", dpi=110); plt.close(fig)
    print(f"[4] Incertidumbre: {dentro:.0%} de los datos dentro de la banda P5–P95")

    # 5. Sensibilidad (Xiao): ¿qué factores explican la varianza de la salida?
    sens = None
    if not a.sin_sa:
        Ms = design_matrix(modelo, n=a.n_sa, method="latin_hypercube", seed=a.semilla + 1)
        sa = sensitivity_analysis(modelo, Ms, method="xiao")
        STi = np.ravel(sa.STi)
        if len(STi) == len(nombres):  # índices de todos los factores: quedarse con los libres
            STi = STi[libres]
        sens = dict(zip([nombres[i] for i in libres], map(float, STi)))
        orden = sorted(sens.items(), key=lambda kv: -kv[1])
        print("[5] Sensibilidad total ST_i: " + ", ".join(f"{k}={v:.2f}" for k, v in orden))

    # 6. Estimación multicomienzo
    pe = parameter_estimation(modelo, x, y, n=a.n_multi, solver="least_squares", seed=a.semilla)
    mejor = np.asarray(pe.x[0], dtype=float)
    y_fit = simular(modelo, mejor, x)
    print(f"[6] Estimación: costo = {float(pe.cost[0]):.4g}")
    for i in libres:
        print(f"      {nombres[i]:10s} = {mejor[i]:.6g}")

    # 7. Bootstrap de residuos: re-ajustar datos sintéticos = ajuste + residuos re-muestreados
    resid = y - y_fit
    est = np.zeros((a.n_boot, len(nombres)))
    for b in range(a.n_boot):
        yb = np.maximum(y_fit + rng.choice(resid, size=resid.size, replace=True), 0.0)
        pb = parameter_estimation(modelo, x, yb, n=max(3, a.n_multi // 6), solver="least_squares", seed=a.semilla + 100 + b)
        est[b] = pb.x[0]
    print(f"[7] Bootstrap: {a.n_boot} re-ajustes")

    # 8. Identificabilidad e intervalos. El IC es el percentil 2.5–97.5 % del bootstrap (no el
    #    Range de gsua_ia, que es un IC de la MEDIANA del conjunto). Veredicto sugerido según el
    #    ancho del IC relativo al rango de búsqueda: < 25 % sí, > 50 % no, en medio "dudoso".
    ia = identifiability_analysis(modelo, est, correction=False)
    indice = np.asarray(ia.index, dtype=float)
    lo, hi = np.percentile(est, [2.5, 97.5], axis=0)
    rng_ancho = modelo.range[:, 1] - modelo.range[:, 0]
    filas = []
    print("[8] IC 95 % bootstrap, ancho relativo al rango e índice de gsua_ia (0 = bien, 1 = mal)")
    for i in libres:
        ind = float(indice[i]) if indice.size == len(nombres) else float(indice[libres.index(i)])
        rel = float((hi[i] - lo[i]) / rng_ancho[i])
        veredicto = "sí" if rel < 0.25 else ("no" if rel > 0.5 else "dudoso")
        filas.append({"parametro": nombres[i], "estimacion": float(mejor[i]), "ic_inferior": float(lo[i]),
                      "ic_superior": float(hi[i]), "ancho_relativo": rel, "indice_gsua": ind,
                      "identificable_sugerido": veredicto})
        print(f"      {nombres[i]:10s} {mejor[i]:12.5g}  [{lo[i]:.5g}, {hi[i]:.5g}]  ancho={rel:5.0%}"
              f"  índice={ind:.2f}  identificable: {veredicto}")
    C = np.corrcoef(est[:, libres], rowvar=False)
    if len(libres) > 1:
        Ca = np.abs(C - np.eye(len(libres)))
        a1, a2 = np.unravel_index(int(np.nanargmax(Ca)), Ca.shape)
        print(f"      Par más correlacionado: {nombres[libres[a1]]} <-> {nombres[libres[a2]]} (|r| = {Ca[a1, a2]:.2f})")

    fig, ax = plt.subplots(figsize=(9, 4))
    for b in range(a.n_boot):
        ax.plot(x, simular(modelo, est[b], x), color="tab:blue", alpha=0.15, lw=1)
    ax.plot(x, y_fit, color="tab:blue", lw=2, label="Mejor ajuste")
    ax.plot(x, y, ".", color="tab:red", label="Datos")
    ax.set_xlabel(f"t ({entrada['unidad_tiempo']}s)"); ax.set_ylabel(salida); ax.legend(); ax.grid(True)
    fig.tight_layout(); fig.savefig(salida_dir / f"{tag}_3_ajuste.png", dpi=110); plt.close(fig)

    res = {"escenario": esc["id"], "modelo": entrada["id"], "lenguaje": "python", "salida": salida,
           "costo": float(pe.cost[0]), "datos_dentro_banda_ua": dentro, "sensibilidad_STi": sens,
           "parametros": filas, "tamanos": {"n_ua": a.n_ua, "n_sa": a.n_sa, "n_multi": a.n_multi, "n_boot": a.n_boot},
           "semilla": a.semilla, "segundos": round(time.time() - reloj, 1)}
    (salida_dir / f"{tag}.json").write_text(json.dumps(res, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Listo en {res['segundos']} s. Resultados en resultados/{tag}.json y figuras *.png")


if __name__ == "__main__":
    main()
