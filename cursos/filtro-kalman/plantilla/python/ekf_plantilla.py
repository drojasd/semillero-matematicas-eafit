"""Funciones de la plantilla del filtro de Kalman extendido (versión Python).

Son las mismas de la carpeta matlab/ y dan los mismos números:
    ekf_correr          el filtro sobre toda la serie (ekfCorrer.m)
    jacobiano_num       jacobiano por diferencias centrales (jacobianoNum.m)
    paso_rk4            un periodo de muestreo de un modelo continuo (pasoRK4.m)
    cond_observabilidad rango y número de condición de la observabilidad local
    autocorr_innov      prueba de blancura de las innovaciones
Solo usa NumPy.
"""
import numpy as np


def jacobiano_num(fun, x):
    """J[i, j] = d fun_i / d x_j por diferencias centrales, paso 1e-6*max(|x_j|, 1e-3)."""
    x = np.asarray(x, dtype=float).ravel()
    f0 = np.atleast_1d(fun(x))
    J = np.zeros((f0.size, x.size))
    for j in range(x.size):
        h = 1e-6 * max(abs(x[j]), 1e-3)
        xp = x.copy(); xp[j] += h
        xm = x.copy(); xm[j] -= h
        J[:, j] = (np.atleast_1d(fun(xp)) - np.atleast_1d(fun(xm))) / (2 * h)
    return J


def paso_rk4(g, x, p, Ts, nsub=10):
    """Avanza dx/dt = g(x, p) un periodo Ts con nsub subpasos de Runge-Kutta 4."""
    h = Ts / nsub
    x = np.asarray(x, dtype=float).ravel()
    for _ in range(nsub):
        k1 = g(x, p)
        k2 = g(x + h / 2 * k1, p)
        k3 = g(x + h / 2 * k2, p)
        k4 = g(x + h * k3, p)
        x = x + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
    return x


def ekf_correr(y, fa, ha, xa0, P0, Q, R, lb=None):
    """Filtro de Kalman extendido sobre la serie y (m x N, o un vector si m = 1).

    y[:, 0] es el instante del estado inicial y no se usa; NaN = sin medición.
    fa(xa) -> xa(k+1) y ha(xa) -> y son el modelo aumentado y la medición.
    R es una matriz o una función R(xa). lb es una cota inferior opcional.
    Devuelve un dict con x, sd (n x N), yhat, e, z (m x N), trP, normK (N).
    """
    y = np.atleast_2d(np.asarray(y, dtype=float))
    m, N = y.shape
    x = np.asarray(xa0, dtype=float).ravel()
    n = x.size
    P = np.array(P0, dtype=float)
    lb = np.full(n, -np.inf) if lb is None else np.asarray(lb, dtype=float)
    Rf = R if callable(R) else (lambda xa: R)
    est = {k: np.full((n, N), np.nan) for k in ("x", "sd")}
    est.update({k: np.full((m, N), np.nan) for k in ("yhat", "e", "z")})
    est["trP"] = np.full(N, np.nan)
    est["normK"] = np.zeros(N)
    est["x"][:, 0] = x
    est["sd"][:, 0] = np.sqrt(np.diag(P))
    est["trP"][0] = np.trace(P)
    I = np.eye(n)
    for k in range(1, N):
        # predicción
        F = jacobiano_num(fa, x)
        x = np.asarray(fa(x), dtype=float).ravel()
        P = F @ P @ F.T + Q
        # corrección
        yp = np.atleast_1d(ha(x))
        est["yhat"][:, k] = yp
        yk = y[:, k]
        if np.all(np.isfinite(yk)):
            H = jacobiano_num(ha, x)
            Rk = np.atleast_2d(Rf(x))
            S = H @ P @ H.T + Rk
            K = P @ H.T @ np.linalg.inv(S)
            e = yk - yp
            x = x + K @ e
            P = (I - K @ H) @ P @ (I - K @ H).T + K @ Rk @ K.T   # forma de Joseph
            est["e"][:, k] = e
            est["z"][:, k] = e / np.sqrt(np.diag(S))
            est["normK"][k] = np.linalg.norm(K, 2)
        x = np.maximum(x, lb)
        est["x"][:, k] = x
        est["sd"][:, k] = np.sqrt(np.maximum(np.diag(P), 0))
        est["trP"][k] = np.trace(P)
    return est


def cond_observabilidad(X, fa, ha, ventana=None, escala=None):
    """Rango y número de condición de O(k) = [H; H F; H F F; ...] a lo largo de X (n x N).

    Las columnas se multiplican por 'escala' (magnitud típica de cada estado).
    """
    X = np.asarray(X, dtype=float)
    n, N = X.shape
    ventana = n if ventana is None else ventana
    escala = np.maximum(np.abs(X[:, 0]), 1e-12) if escala is None else np.asarray(escala, dtype=float)
    D = np.diag(escala)
    out = {"cond": np.full(N, np.nan), "rango": np.full(N, np.nan), "sv": np.full((n, N), np.nan)}
    for k in range(N - ventana + 1):
        filas, Phi = [], np.eye(n)
        for j in range(ventana):
            xk = X[:, k + j]
            filas.append(jacobiano_num(ha, xk) @ Phi)
            Phi = jacobiano_num(fa, xk) @ Phi
        O = np.vstack(filas)
        s = np.linalg.svd(O @ D, compute_uv=False)
        out["sv"][: s.size, k] = s
        out["rango"][k] = np.sum(s > max(O.shape) * np.spacing(s[0]))
        out["cond"][k] = s[0] / s[-1]
    return out


def autocorr_innov(z, max_lag=20):
    """Autocorrelación de las innovaciones normalizadas y su límite 1.96/sqrt(N)."""
    z = np.asarray(z, dtype=float)
    z = z[np.isfinite(z)]
    z = z - z.mean()
    N = z.size
    lags = np.arange(min(max_lag, N - 1) + 1)
    r = np.array([np.sum(z[: N - l] * z[l:]) for l in lags]) / np.sum(z ** 2)
    return r, lags, 1.96 / np.sqrt(N)
