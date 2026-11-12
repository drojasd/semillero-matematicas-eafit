%[text] # Plantilla: filtro de Kalman extendido con estado aumentado
%[text] Plantilla mínima para la entrega 3 de Modelación Experimental. Corre de principio a fin con un ejemplo (un SIR continuo con datos sintéticos) y está escrita para que solo haya que cambiar las secciones marcadas con **CAMBIAR**: el modelo, los parámetros de la entrega 2 y los datos.
%[text] Funciones de la carpeta: |ekfCorrer| (el filtro), |jacobianoNum| (jacobianos por diferencias finitas), |pasoRK4| (un paso de un modelo continuo), |condObservabilidad| (rango y número de condición) y |autocorrInnov| (prueba de blancura). La versión de Python hace lo mismo y da los mismos números.
thisDir = "";
try, thisDir = string(fileparts(mfilename("fullpath"))); catch, end
if thisDir == "", try, thisDir = string(fileparts(matlab.desktop.editor.getActiveFilename)); catch, end, end
if thisDir == "", thisDir = string(pwd); end
addpath(thisDir)
%%
%[text] ## 1. Modelo (CAMBIAR)
%[text] Escriba el modelo de la entrega 2. Si es continuo, $g$ es el lado derecho $dx/dt = g(x,p)$ y |pasoRK4| lo integra entre muestras; si es discreto, escriba directamente el paso $x(k+1) = f(x(k),p)$ en |paso|. La medición $h(x,p)$ es la variable que se comparó con los datos en la entrega 2.
%[text] Ejemplo: SIR normalizado, $\\dot{s} = -\\beta s i$, $\\dot{i} = \\beta s i - \\gamma i$, y se mide $i$.
nombresX = ["s", "i"];
nombresP = ["beta", "gamma"];
g = @(x,p) [-p(1)*x(1)*x(2); p(1)*x(1)*x(2) - p(2)*x(2)];
h = @(x,p) x(2);
Ts = 1;                                   % periodo de muestreo de los datos (días)
paso = @(x,p) pasoRK4(g, x, p, Ts, 10);   % modelo discreto: x(k+1) = paso(x(k), p)
%%
%[text] ## 2. Parámetros de la entrega 2 (CAMBIAR)
%[text] |pEst| son los parámetros estimados en la entrega 2 e |icP| sus intervalos de confianza del 95 % del bootstrap. |idx| dice qué parámetros estima el filtro (al menos uno); los demás quedan fijos en |pEst|.
pEst = [0.45; 0.2];
icP  = [0.38 0.55; 0.17 0.23];
idx  = 1;                                 % el filtro estima beta
x0   = [0.999; 0.001];                    % estado inicial del modelo
%%
%[text] ## 3. Datos (CAMBIAR)
%[text] Un CSV con el tiempo |t| y la medición |y|. Si se conocen los estados verdaderos (datos sintéticos), van en columnas con los nombres de |nombresX| y se dibujan como referencia; con datos reales no existen.
datos = readtable(fullfile(thisDir, "..", "ejemplo_datos.csv"));
t = datos.t';
y = datos.y';
hayVerdad = all(ismember(nombresX, string(datos.Properties.VariableNames)));
plot(t, y, ".")
xlabel("t"), ylabel("y"), title("Datos"), grid on
%%
%[text] ## 4. Modelo aumentado
%[text] El estado aumentado es $x_a = [x;\\ \\theta]$, con $\\theta = p(\\mathrm{idx})$ y $\\theta(k+1) = \\theta(k)$. No hay que cambiar nada aquí.
nx = numel(x0);  nt = numel(idx);
fa = @(xa) [paso(xa(1:nx), reemplazar(pEst, idx, xa(nx+1:end))); xa(nx+1:end)];
ha = @(xa) h(xa(1:nx), reemplazar(pEst, idx, xa(nx+1:end)));
nombresXa = [nombresX, nombresP(idx)];
%%
%[text] ## 5. Observabilidad: número de condición
%[text] Se linealiza a lo largo de una simulación con los parámetros de la entrega 2 y en cada instante se arma $\\mathcal{O}(k) = [H;\\ HF;\\ HF^2;\\ \\dots]$ con tantas mediciones como estados aumentados. Las columnas se escalan por la magnitud típica de cada estado (|escala|). Un número de condición alto significa que alguna combinación de estados casi no se ve en las mediciones: su banda tarda en cerrarse.
N = numel(t);
Xnom = zeros(nx+nt, N);  Xnom(:,1) = [x0; pEst(idx)];
for k = 1:N-1, Xnom(:,k+1) = fa(Xnom(:,k)); end
escala = max(abs(Xnom), [], 2);                 % CAMBIAR si conviene otra escala
obs = condObservabilidad(Xnom, fa, ha, nx+nt, escala);
tiledlayout(2,1)
nexttile
semilogy(t, obs.cond, "LineWidth", 1.5), grid on
ylabel("cond(O)"), title("Número de condición de la observabilidad local")
nexttile
stairs(t, obs.rango, "LineWidth", 1.5), grid on
ylim([0 nx+nt+0.5]), ylabel("rango"), xlabel("t")
%%
%[text] ## 6. Configuración del filtro (CAMBIAR)
%[text] - $R$: varianza del ruido de medición. Use la de los residuales del mejor ajuste de la entrega 2 (aquí, un ruido relativo del 5 %).
%[text] - $P(0)$: para $\\theta$, una desviación de un cuarto del ancho del intervalo del bootstrap; para los estados, según qué tan bien se conoce la condición inicial.
%[text] - $Q$: ruido de proceso. El de $\\theta$ dice qué tan rápido puede cambiar el parámetro; en la sección 8 se comparan dos valores. \
R   = @(xa) (0.05*max(ha(xa),0) + 5e-4)^2;
xa0 = [x0; pEst(idx)];
P0  = diag([[1e-3; 1e-3]; (icP(idx,2) - icP(idx,1))/4].^2);
qX  = [1e-4; 1e-4];                       % desviación diaria del ruido de los estados
qT  = 1e-3*ones(nt,1);                    % desviación diaria del ruido de los parámetros
Q   = diag([qX; qT].^2);
lb  = [zeros(nx,1); zeros(nt,1)];         % fracciones y tasas no negativas
%%
%[text] ## 7. Correr el filtro
est = ekfCorrer(y, fa, ha, xa0, P0, Q, R, lb);
tiledlayout(nx+nt, 1)
for c = 1:nx+nt
    nexttile
    banda = [est.x(c,:) + 2*est.sd(c,:), fliplr(est.x(c,:) - 2*est.sd(c,:))];
    fill([t, fliplr(t)], banda, [0.3 0.75 0.9], "FaceAlpha", 0.3, "EdgeColor", "none")
    hold on
    plot(t, est.x(c,:), "LineWidth", 1.3)
    if c <= nx && hayVerdad, plot(t, datos.(nombresX(c)), "k--"), end
    if c > nx, yline(icP(idx(c-nx),:), ":", "IC 95 % entrega 2"), end
    hold off, grid on, ylabel(nombresXa(c))
end
xlabel("t")
%%
%[text] La medición predicha contra los datos:
plot(t, y, ".", t, est.yhat, "-")
legend("medición", "predicción del filtro"), xlabel("t"), grid on
%%
%[text] ## Traza de $P$ y norma de la ganancia
tiledlayout(2,1)
nexttile, semilogy(t, est.trP, "LineWidth", 1.3), grid on, ylabel("traza(P)")
nexttile, plot(t, est.normK, "LineWidth", 1.3), grid on, ylabel("||K||"), xlabel("t")
%%
%[text] ## Prueba de blancura de las innovaciones
[r, lags, lim] = autocorrInnov(est.z(1,:), 20);
stem(lags, r, "filled"), hold on, yline([-lim lim], "--"), hold off
xlabel("retardo"), ylabel("autocorrelación"), grid on
title(sprintf("Innovaciones normalizadas: media %.2f, desviación %.2f", mean(est.z(1,2:end),"omitnan"), std(est.z(1,2:end),"omitnan")))
%%
%[text] ## 8. Efecto de $Q$ sobre el parámetro
qs = [1e-4 1e-3 1e-2];
for j = 1:numel(qs)
    e = ekfCorrer(y, fa, ha, xa0, P0, diag([qX; qs(j)*ones(nt,1)].^2), R, lb);
    plot(t, e.x(nx+1,:), "LineWidth", 1.2)
    hold on
end
yline(icP(idx(1),:), ":")
hold off, grid on
legend("q_\theta = " + string(qs)), xlabel("t"), ylabel(nombresXa(nx+1))
%%
%[text] Valores finales (para comparar con la versión de Python):
final = table(nombresXa', est.x(:,end), 2*est.sd(:,end), 'VariableNames', ["estado","estimación final","2 sigma"])
%%
function p = reemplazar(p, idx, theta)
% Copia de p con p(idx) = theta.
p(idx) = theta;
end
%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
