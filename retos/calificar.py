"""Califica las entregas de un reto y produce la tabla de posiciones (espejo exacto de calificar.m).

    python calificar.py retos/reto_2 --verdad retos/privado/reto_2_verdad.json \
                        --entregas retos/reto_2/entregas [--salida CARPETA]
    python calificar.py --sitio data/retos.js       # tabla de posiciones del sitio

Las reglas están en la ayuda de calificar.m y en retos/README.md. En resumen, por cada caso y
parámetro (verdad x, intervalo [l, u], ancho del rango W, alfa = 1 - nivel):

    IS/W = [(u - l) + (2/alfa)(l - x)[x < l] + (2/alfa)(x - u)[x > u]] / W   (Gneiting-Raftery)
    veredicto: 0 acierto · 1 falsa modestia o sin respuesta · 2 "sí" sin serlo ·
               5 "sí" sin serlo y con un intervalo que no contiene la verdad
    penalización = suma de IS/W + veredicto.  GANA LA MENOR.
    desempate: error relativo medio |estimación - x|/W en los parámetros identificables.

Antes de calificar se verifica el SHA-256 de la verdad contra el sello publicado.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import escribir_json, json_canonico, sha256_archivo  # noqa: E402

RETOS = Path(__file__).resolve().parent


def _numero(q: dict, campo: str):
    v = q.get(campo)
    if isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v):
        return None
    return float(v)


def _leer(entrega: dict, caso: str, pid: str, rango):
    q = entrega.get("casos", {}).get(caso, {}).get("parametros", {}).get(pid, {})
    est, lo, hi = _numero(q, "estimacion"), _numero(q, "ic_inferior"), _numero(q, "ic_superior")
    d = q.get("identificable")
    decl = bool(d) if isinstance(d, bool) or (isinstance(d, (int, float)) and d in (0, 1)) else None
    if lo is None or hi is None or lo > hi:
        lo, hi = float(rango[0]), float(rango[1])
    if est is None:
        est = (lo + hi) / 2
    return est, lo, hi, decl


def calificar(carpeta_reto, archivo_verdad, carpeta_entregas, salida=None) -> list[dict]:
    carpeta_reto = Path(carpeta_reto)
    salida = Path(salida) if salida else carpeta_reto
    infos = sorted(carpeta_reto.glob("reto_*.json"))
    if len(infos) != 1:
        sys.exit(f"Se esperaba un único reto_K.json en {carpeta_reto}")
    info = json.loads(infos[0].read_text(encoding="utf-8"))

    # ---------------- 0. Sello ----------------
    sello = sha256_archivo(archivo_verdad)
    if sello != info["sha256_verdad"]:
        sys.exit("¡La verdad NO coincide con el sello publicado!\n"
                 f"  publicado: {info['sha256_verdad']}\n  archivo:   {sello}")
    print(f"Sello verificado: SHA-256 de la verdad = {sello}")
    verdad = json.loads(Path(archivo_verdad).read_text(encoding="utf-8"))

    alfa = 1 - info["nivel"]
    filas = []
    for ruta in sorted(Path(carpeta_entregas).glob("*.json"), key=lambda r: r.name):
        entrega = json.loads(ruta.read_text(encoding="utf-8"))
        equipo = entrega.get("equipo") if isinstance(entrega.get("equipo"), str) and entrega.get("equipo") else ruta.name
        if entrega.get("reto") != info["reto"]:
            print(f"Aviso: {ruta.name} no es una entrega del reto {info['reto']}: se omite.")
            continue
        detalle = []
        pen = sum_is = sum_v = 0.0
        aciertos = dentro = n = n_err = 0
        sum_err = 0.0
        for caso in info["casos"]:
            cid = caso["id"]
            for par in info["parametros"]:
                pid, rango = par["id"], par["rango"]
                w = rango[1] - rango[0]
                x = verdad["casos"][cid]["parametros"][pid]["valor"]
                es_real = verdad["casos"][cid]["parametros"][pid]["identificable"]
                est, lo, hi, decl = _leer(entrega, cid, pid, rango)

                is_ = (hi - lo) + (2 / alfa) * max(lo - x, 0) + (2 / alfa) * max(x - hi, 0)
                isn = is_ / w
                contiene = lo <= x <= hi
                if decl is None:
                    v = 1
                elif decl == es_real:
                    v = 0
                elif decl:
                    v = 2 + 3 * (not contiene)
                else:
                    v = 1
                err = abs(est - x) / w
                if es_real:
                    sum_err += err
                    n_err += 1
                pen = pen + isn + v
                sum_is += isn
                sum_v += v
                aciertos += v == 0
                dentro += contiene
                n += 1
                detalle.append({"caso": cid, "parametro": pid, "puntaje_intervalo": isn,
                                "contiene": contiene, "identificable_declarado": decl,
                                "veredicto": v, "error_relativo": err})
        filas.append({"posicion": 0, "equipo": equipo, "archivo": ruta.name, "penalizacion": pen,
                      "intervalo": sum_is, "veredicto": sum_v, "aciertos": aciertos, "total": n,
                      "cobertura": dentro / n, "error_relativo": sum_err / n_err if n_err else 0.0,
                      "detalle": detalle})

    # ---------------- Orden: menor penalización; desempate por error ----------------
    filas.sort(key=lambda f: (round(f["penalizacion"], 6), round(f["error_relativo"], 6), f["archivo"]))
    for i, f in enumerate(filas, 1):
        f["posicion"] = i

    # ---------------- Salidas ----------------
    salida.mkdir(parents=True, exist_ok=True)
    lineas = ["posicion,equipo,archivo,penalizacion,intervalo,veredicto,aciertos,total,cobertura,error_relativo"]
    for f in filas:
        lineas.append(f"{f['posicion']},{_csv(f['equipo'])},{_csv(f['archivo'])},{f['penalizacion']:.6f},"
                      f"{f['intervalo']:.6f},{f['veredicto']:.6f},{f['aciertos']},{f['total']},"
                      f"{f['cobertura']:.6f},{f['error_relativo']:.6f}")
    (salida / "posiciones.csv").write_text("\n".join(lineas) + "\n", encoding="utf-8", newline="\n")
    escribir_json(salida / "posiciones.json", {
        "reto": info["reto"], "titulo": info["titulo"], "sha256_verdad": sello,
        "verdad_verificada": True, "nivel": info["nivel"], "posiciones": filas})

    print(f"{'pos':>3}  {'penalización':>12}  {'aciertos':>8}  {'cobertura':>9}  {'error':>7}  equipo")
    for f in filas:
        print(f"{f['posicion']:>3}  {f['penalizacion']:>12.3f}  {f['aciertos']:>4}/{f['total']:<3}"
              f"  {f['cobertura']:>9.2f}  {f['error_relativo']:>7.4f}  {f['equipo']}")
    return filas


def _csv(s: str) -> str:
    return '"' + s.replace('"', '""') + '"' if ("," in s or '"' in s) else s


def escribir_sitio(archivo_js, carpeta=RETOS) -> None:
    """Resume los retos (sello y, si ya hay, posiciones) en data/retos.js para el sitio.

    Del reto se publica solo lo que ven los equipos: título, modelo y sello SHA-256. De las
    posiciones, los totales por equipo (nunca la verdad ni el detalle por parámetro).
    """
    retos = []
    for dir_reto in sorted(Path(carpeta).glob("reto_*"), key=lambda d: int(d.name.split("_")[1])):
        info = json.loads((dir_reto / f"{dir_reto.name}.json").read_text(encoding="utf-8"))
        r = {"reto": info["reto"], "titulo": info["titulo"], "modelo": info["modelo"],
             "casos": len(info["casos"]), "parametros": [p["nombre"] for p in info["parametros"]],
             "sha256_verdad": info["sha256_verdad"], "posiciones": []}
        pos = dir_reto / "posiciones.json"
        if pos.exists():
            res = json.loads(pos.read_text(encoding="utf-8"))
            r["posiciones"] = [{k: f[k] for k in ("posicion", "equipo", "penalizacion", "aciertos",
                                                  "total", "cobertura", "error_relativo")}
                               for f in res["posiciones"]]
        kit = dir_reto / f"kit_{dir_reto.name}.zip"
        if kit.exists():  # lo arma retos/empaquetar_kit.py
            r["kit"] = f"retos/{dir_reto.name}/{kit.name}"
            r["instrucciones"] = ("https://github.com/drojasd/semillero-matematicas-eafit/blob/main/"
                                  f"retos/{dir_reto.name}/README.md")
        retos.append(r)
    texto = ("// Generado por retos/calificar.py --sitio. No editar a mano.\n"
             "// Retos de identificabilidad: sello SHA-256 de cada verdad y tabla de posiciones.\n"
             "window.SEMILLERO_RETOS = " + json_canonico(retos).rstrip("\n") + ";\n")
    Path(archivo_js).write_text(texto, encoding="utf-8", newline="\n")
    print(f"Escrito {archivo_js} con {len(retos)} reto(s).")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("reto", nargs="?", help="carpeta del reto (retos/reto_K)")
    ap.add_argument("--verdad", help="retos/privado/reto_K_verdad.json (al revelar)")
    ap.add_argument("--entregas", help="carpeta con los entrega*.json de los equipos")
    ap.add_argument("--salida", help="dónde escribir posiciones.csv/.json (por defecto, la del reto)")
    ap.add_argument("--sitio", help="escribe la tabla de posiciones del sitio (data/retos.js)")
    a = ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")
    if a.reto:
        if not (a.verdad and a.entregas):
            ap.error("para calificar hacen falta --verdad y --entregas")
        calificar(a.reto, a.verdad, a.entregas, a.salida)
    if a.sitio:
        escribir_sitio(a.sitio)
    if not (a.reto or a.sitio):
        ap.print_help()


if __name__ == "__main__":
    main()
