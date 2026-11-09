%[text] # Filtro de Kalman: de la observabilidad al filtro extendido
%[text] Introducción corta, siguiendo a Isermann y Münchhof (_Identification of Dynamic Systems_, 2011). Hasta ahora identificamos modelos con todos los datos a la vez (por lotes). El filtro de Kalman hace otra cosa: **estima el estado mientras llegan las mediciones**, una a la vez, y con un truco (el estado aumentado) también estima parámetros.
%[text] Ejemplo de toda la clase: un brote SIRS. Solo medimos (con ruido) la fracción de infectados $i$. Queremos reconstruir lo que no medimos: los susceptibles $s$ y las tasas $\\beta$ (transmisión) y $\\gamma$ (recuperación).
%[text] Archivos de la carpeta: |sirsAumentado| (modelo y jacobiano), |ekfPaso| (un paso del filtro), |simularSIRS| (datos sintéticos), |correrEKF| (filtro sobre toda la serie), |observabilidadLocal| y |kalman_tiempo_real| (animación).
% Bootstrap portable (escritorio y MATLAB Online, sin rutas absolutas):
thisDir = "";
try, thisDir = string(fileparts(mfilename("fullpath"))); catch, end
if thisDir == "", try, thisDir = string(fileparts(matlab.desktop.editor.getActiveFilename)); catch, end, end
if thisDir == "", thisDir = string(pwd); end
addpath(thisDir)
%%
%[text] ## 1. El modelo y los datos
%[text] SIRS discreto del semillero, con paso de un día y la población normalizada ($s+i+r=1$, así que $r = 1-s-i$ no es estado):
%[text] $ s(k+1) = s(k)\\,e^{-\\beta i(k)} + \\alpha\\,r(k), \\qquad i(k+1) = s(k)\\left(1-e^{-\\beta i(k)}\\right) + (1-\\gamma)\\,i(k) $
%[text] La medición es $y(k) = i(k) + v(k)$, con un ruido $v(k)$ de desviación $0.05\\,i(k) + 0.0005$. Valores verdaderos (que el filtro no conoce): $\\beta = 0.5$, $\\gamma = 0.2$, $\\alpha = 0.01$ por día.
datos = simularSIRS();
alpha = datos.opc.alpha;
plot(datos.t, datos.y, ".", datos.t, datos.x(2,:), "-", datos.t, datos.x(1,:), "--")
legend("medición y", "i verdadero (oculto)", "s verdadero (oculto)")
xlabel("día")
ylabel("fracción de la población")
title("Lo único que ve el filtro son los puntos")
grid on
%%
%[text] ## 2. Observabilidad: ¿las mediciones alcanzan?
%[text] Para un sistema lineal $x(k+1) = A\\,x(k)$, $y(k) = C\\,x(k)$, las primeras $n$ mediciones son $y = \\mathcal{O}\\,x(0)$ con $\\mathcal{O} = [C;\\ CA;\\ \\dots;\\ CA^{n-1}]$. El estado inicial se puede reconstruir si y solo si $\\mathrm{rango}(\\mathcal{O}) = n$. Si el rango es menor, hay estados iniciales distintos que producen **exactamente** las mismas mediciones, y ningún filtro puede distinguirlos.
%[text] Ejemplo: un carrito con posición $p$ y velocidad $v$, muestreado cada $T$ segundos. Si medimos la posición, la velocidad se deduce de dos posiciones seguidas. Si medimos la velocidad, la posición inicial queda indeterminada.
T = 0.5;
A = [1 T; 0 1];
Cpos = [1 0];
Cvel = [0 1];
rangos = table(["mide posición"; "mide velocidad"], [rank(obsv(A,Cpos)); rank(obsv(A,Cvel))], ...
    'VariableNames', ["medición","rango de O (n = 2)"])
%%
%[text] La dirección que no se ve es el núcleo de $\\mathcal{O}$. Dos carritos que difieren en esa dirección dan las mismas mediciones de velocidad:
kerO = abs(null(obsv(A,Cvel)))'           % núcleo de O: mover solo la posición
k = 0:10;
xa = [0; 1];  xb = xa + 3*kerO';         % misma velocidad, distinta posición
ya = zeros(size(k));  yb = ya;  pa = ya;  pb = ya;
for j = 1:numel(k)
    Ak = A^k(j);
    ya(j) = Cvel*Ak*xa;  yb(j) = Cvel*Ak*xb;
    pa(j) = Cpos*Ak*xa;  pb(j) = Cpos*Ak*xb;
end
tiledlayout(1,2)
nexttile
plot(k, ya, "o-", k, yb, "x--")
title("Velocidad medida: idéntica")
xlabel("k"), legend("carrito a","carrito b"), grid on
nexttile
plot(k, pa, "o-", k, pb, "x--")
title("Posición oculta: distinta")
xlabel("k"), grid on
%%
%[text] ## 3. Observabilidad del SIRS aumentado
%[text] Para estimar parámetros los volvemos estados que no cambian: $x = [s;\\ i;\\ \\beta;\\ \\gamma]$ con $\\beta(k+1) = \\beta(k)$, $\\gamma(k+1) = \\gamma(k)$. Así, **identificabilidad de parámetros = observabilidad del sistema aumentado**.
%[text] El modelo no es lineal, así que lo linealizamos a lo largo de la trayectoria con el jacobiano $F(k) = \\partial f/\\partial x$ y armamos la matriz de observabilidad con las mediciones de los días $0$ a $k$. Al principio del brote ($s \\approx 1$, $i$ pequeño) vale $i(k+1) \\approx (1 + \\beta - \\gamma)\\,i(k)$: las mediciones solo ven la **diferencia** $\\beta - \\gamma$. Se nota en el coseno entre las columnas de $\\beta$ y de $\\gamma$: vale $-1$ hasta que los susceptibles se agotan.
obs = observabilidadLocal(datos, alpha);
tiledlayout(2,1)
nexttile
plot(obs.t, obs.cosBG, "LineWidth", 1.5)
ylabel("cos(\beta, \gamma)")
title("Columnas de \beta y \gamma en la matriz de observabilidad")
xline(find(datos.x(2,:) == max(datos.x(2,:))) - 1, ":", "pico")
grid on
nexttile
semilogy(obs.t, obs.sv(end,:), "LineWidth", 1.5)
ylabel("\sigma_{min}(O)")
xlabel("día k (mediciones usadas: 0..k)")
title("Valor singular más pequeño: información sobre la dirección peor vista")
grid on
%%
%[text] ## 4. El filtro de Kalman
%[text] Un observador corrige la predicción del modelo con el error de predicción (la _innovación_): $\\hat{x}(k|k) = \\hat{x}(k|k-1) + K(k)\\,[\\,y(k) - C\\,\\hat{x}(k|k-1)\\,]$. Kalman escoge la ganancia $K(k)$ que minimiza la varianza del error de estimación, si el modelo es $x(k+1) = A\\,x(k) + w(k)$, $y(k) = C\\,x(k) + v(k)$, con ruidos blancos de covarianzas $Q$ y $R$:
%[text] - Predicción: $ \\hat{x}(k|k-1) = A\\,\\hat{x}(k-1|k-1), \\qquad P(k|k-1) = A\\,P(k-1|k-1)\\,A^T + Q $
%[text] - Ganancia: $ K(k) = P(k|k-1)\\,C^T\\left[C\\,P(k|k-1)\\,C^T + R\\right]^{-1} $
%[text] - Corrección: $ \\hat{x}(k|k) = \\hat{x}(k|k-1) + K(k)\\left[y(k) - C\\,\\hat{x}(k|k-1)\\right], \\qquad P(k|k) = \\left[I - K(k)\\,C\\right]P(k|k-1) $ \
%[text] $P$ es la covarianza del error: dice cuánto confía el filtro en su estimación. Si $R$ es grande (medición mala) la ganancia es pequeña y el filtro confía en el modelo; si $Q$ es grande (modelo malo) la ganancia crece y confía en la medición. Primero, el carrito: medimos la posición con ruido y el filtro estima también la velocidad, que nunca se mide (es observable).
rng(1)
nk = 60;
xv = zeros(2,nk);  xv(:,1) = [0; 1];
yv = zeros(1,nk);
for j = 1:nk
    if j > 1, xv(:,j) = A*xv(:,j-1) + [0; 0.05*randn]; end
    yv(j) = xv(1,j) + 0.3*randn;
end
fLin = @(x) deal(A*x, A);                 % modelo lineal: el jacobiano es A
xh = [0; 0];  P = diag([1 1]);
xhat = zeros(2,nk);  xhat(:,1) = xh;
for j = 2:nk
    [xh, P] = ekfPaso(xh, P, yv(j), fLin, Cpos, diag([1e-4 0.05^2]), 0.3^2);
    xhat(:,j) = xh;
end
tiledlayout(2,1)
nexttile
plot(1:nk, yv, ".", 1:nk, xv(1,:), 1:nk, xhat(1,:), "--")
legend("medición","verdadera","estimada","Location","northwest"), ylabel("posición"), grid on
nexttile
plot(1:nk, xv(2,:), 1:nk, xhat(2,:), "--")
legend("verdadera","estimada (nunca se midió)"), ylabel("velocidad"), xlabel("k"), grid on
%%
%[text] ## 5. El filtro de Kalman extendido (EKF)
%[text] Con un modelo no lineal $x(k+1) = f(x(k)) + w(k)$, $y(k) = h(x(k)) + v(k)$, el EKF hace dos cambios: **predice con el modelo no lineal** $\\hat{x}(k|k-1) = f(\\hat{x}(k-1|k-1))$ y **propaga la covarianza con el jacobiano** evaluado en la estimación actual, $F(k) = \\partial f/\\partial x$ en $\\hat{x}(k-1|k-1)$. Lo demás es igual, con $C$ reemplazada por $H = \\partial h/\\partial x$ (aquí $H = [0\\ 1\\ 0\\ 0]$). Ver |ekfPaso.m|: son diez líneas.
%[text] Suposición inicial deliberadamente mala: $\\hat{\\beta}(0) = 0.3$ y $\\hat{\\gamma}(0) = 0.1$. Las bandas son $\\pm 2$ desviaciones, sacadas de $P$.
est = correrEKF(datos);
nombres = ["s", "i", "\beta", "\gamma"];
tiledlayout(2,2)
for c = 1:4
    nexttile
    banda = [est.x(c,:) + 2*est.sd(c,:), fliplr(est.x(c,:) - 2*est.sd(c,:))];
    fill([datos.t, fliplr(datos.t)], banda, [0.3 0.75 0.9], "FaceAlpha", 0.25, "EdgeColor", "none")
    hold on
    plot(datos.t, datos.x(c,:), "k-", datos.t, est.x(c,:), "-", "LineWidth", 1.2)
    if c == 2, plot(datos.t, datos.y, ".", "MarkerSize", 5), end
    hold off
    title(nombres(c)), grid on
end
xlabel("día")
%%
%[text] Antes del pico el filtro acierta en $\\hat{\\beta} - \\hat{\\gamma} \\approx 0.3$ pero no puede separar las dos tasas: es la observabilidad de la sección 3 en acción. Cuando los susceptibles se agotan, las bandas se cierran.
resumen = table(["beta"; "gamma"; "beta - gamma"], [0.5; 0.2; 0.3], ...
    [est.x(3,21); est.x(4,21); est.x(3,21) - est.x(4,21)], [est.x(3,end); est.x(4,end); est.x(3,end) - est.x(4,end)], ...
    'VariableNames', ["parámetro","verdadero","EKF día 20","EKF día 240"])
%%
%[text] ## 6. ¿El filtro está bien sintonizado? Las innovaciones
%[text] Si el modelo y las covarianzas son correctos, las innovaciones normalizadas $e(k)/\\sqrt{S(k)}$ son ruido blanco de varianza 1 ($S = H P H^T + R$). Es la versión en línea del análisis de residuos de identificación.
z = est.e(2:end) ./ sqrt(est.S(2:end));
plot(datos.t(2:end), z, ".")
yline([-2 2], "--")
title(sprintf("Innovaciones normalizadas: media %.2f, desviación %.2f", mean(z), std(z)))
xlabel("día"), grid on
%%
%[text] ## 7. Parámetros que cambian: sintonizar $Q$
%[text] En el día 40 llega una intervención y $\\beta$ baja de 0.5 a 0.3. Con el estado aumentado, el ruido de proceso de $\\beta$ (su desviación diaria $q_\\beta$) es la velocidad a la que el filtro acepta que el parámetro cambie: pequeño es lento pero suave; grande es rápido pero ruidoso.
datosInt = simularSIRS(struct("diaCambio", 40, "betaDespues", 0.3));
qs = [1e-3 1e-2 3e-2];
plot(datosInt.t, datosInt.x(3,:), "k-", "LineWidth", 1.5)
hold on
for q = qs
    e = correrEKF(datosInt, struct("q", [1e-4; 1e-4; q; 1e-4]));
    plot(datosInt.t, e.x(3,:), "LineWidth", 1.1)
end
hold off
legend(["verdadero", "q_\beta = " + string(qs)])
xlabel("día"), ylabel("\beta"), ylim([0 0.8]), grid on
title("Seguimiento de un parámetro que cambia")
%%
%[text] ## 8. Lo mismo con |extendedKalmanFilter|
%[text] Control System Toolbox trae el objeto |extendedKalmanFilter|. Recibe las mismas piezas: la función de transición, la de medición, sus jacobianos y las covarianzas. Con la misma configuración debe dar lo mismo que |correrEKF|.
cfg = est.cfg;
ekf = extendedKalmanFilter(@(x) sirsAumentado(x, alpha), @(x) x(2), cfg.x0, ...
    "StateTransitionJacobianFcn", @(x) jacobianoSIRS(x, alpha), ...
    "MeasurementJacobianFcn", @(x) [0 1 0 0], ...
    "StateCovariance", diag(cfg.sd0.^2), "ProcessNoise", diag(cfg.q.^2));
xTb = zeros(4, numel(datos.t));  xTb(:,1) = cfg.x0;
for j = 2:numel(datos.t)
    ekf.MeasurementNoise = (cfg.ruidoRel*max(ekf.State(2),0) + cfg.ruidoAbs)^2;   % R(k) como en correrEKF
    predict(ekf);
    correct(ekf, datos.y(j));
    ekf.State = max(ekf.State, [0; 0; 1e-3; 1e-3]);
    xTb(:,j) = ekf.State;
end
diferenciaMaxima = max(abs(xTb - est.x), [], "all")
%%
%[text] ## 9. En tiempo real
%[text] El script |kalman_tiempo_real| corre el mismo filtro día a día y redibuja en cada paso: se ve cómo llega cada medición, cómo se corrige la estimación y cómo se cierran las bandas de $\\beta$ y $\\gamma$ después del pico. Arriba del script se escoge el escenario (constante o con intervención), $q_\\beta$ y la velocidad.
%[text] Ejercicios:
%[text] - Corra |kalman_tiempo_real| con |escenario = "intervencion"| y tres valores de |qBeta|. ¿Cuál escogería y por qué?
%[text] - Multiplique $R$ por 100 en |correrEKF| (el filtro cree que la medición es muy mala). ¿Qué pasa con las innovaciones normalizadas?
%[text] - Estime también $\\alpha$ (estado de 5 componentes; |sirsAumentado| ya lo admite). ¿Se cierra su banda en 240 días? Relaciónelo con la observabilidad.
%[text] - Mida los casos nuevos $s(k)\\,(1-e^{-\\beta i(k)})$ en vez de $i(k)$. ¿Qué cambia en $H$? \
disp("Para la animación: kalman_tiempo_real")
%%
function F = jacobianoSIRS(x, alpha)
% Solo el jacobiano, como lo pide extendedKalmanFilter.
[~, F] = sirsAumentado(x, alpha);
end
%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
