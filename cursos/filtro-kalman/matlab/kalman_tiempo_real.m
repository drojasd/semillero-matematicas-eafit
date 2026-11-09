% kalman_tiempo_real  El filtro de Kalman extendido sobre el SIRS, día a día.
%
% Cada día llega una medición de i. El filtro predice con el modelo,
% compara con la medición (innovación) y corrige s, i, beta y gamma.
% La figura se redibuja en cada paso: puntos = mediciones, línea de color =
% estimación, banda = +-2 desviaciones (de P), negro = verdad oculta.

% ---------------- configuración (cámbiela) --------------------------------
escenario = "constante";   % "constante" o "intervencion" (beta: 0.5 -> 0.3 el día 40)
qBeta     = 1e-3;          % ruido de proceso de beta; con intervención pruebe 1e-2
pausa     = 0.03;          % segundos entre días (0 = lo más rápido posible)
mostrarVerdad = true;      % false: ver solo lo que ve el filtro
% ---------------------------------------------------------------------------

thisDir = "";
try, thisDir = string(fileparts(mfilename("fullpath"))); catch, end
if thisDir ~= "", addpath(thisDir), end

if escenario == "intervencion"
    datos = simularSIRS(struct("diaCambio", 40, "betaDespues", 0.3));
else
    datos = simularSIRS();
end
alpha = datos.opc.alpha;
t = datos.t;  n = numel(t);

% Filtro: suposición inicial mala a propósito
x = [0.99; 0.002; 0.3; 0.1];
P = diag([0.01; 0.002; 0.2; 0.1].^2);
Q = diag([1e-4; 1e-4; qBeta; 1e-4].^2);
H = [0 1 0 0];
f = @(x) sirsAumentado(x, alpha);
xs = nan(4, n);  sd = nan(4, n);
xs(:,1) = x;  sd(:,1) = sqrt(diag(P));

% ---------------- figura -----------------------------------------------------
fig = figure("Name", "EKF sobre SIRS en tiempo real", "Color", "w");
tl = tiledlayout(fig, 2, 2, "TileSpacing", "compact");
titulos = ["i: infectados (medidos)", "s: susceptibles (ocultos)", "\beta: transmisión", "\gamma: recuperación"];
limY = {[0 0.3], [0 1], [0 0.9], [0 0.4]};
ord = [2 1 3 4];           % panel c muestra el estado ord(c); el estado es [s; i; beta; gamma]
color = [0.10 0.55 0.75];
for c = 1:4
    ax(c) = nexttile(tl); %#ok<SAGROW>
    hold(ax(c), "on"), grid(ax(c), "on")
    banda(c) = fill(ax(c), nan, nan, color, "FaceAlpha", 0.2, "EdgeColor", "none"); %#ok<SAGROW>
    if mostrarVerdad, plot(ax(c), t, datos.x(ord(c),:), "k-", "LineWidth", 0.8); end
    linea(c) = plot(ax(c), nan, nan, "-", "Color", color, "LineWidth", 1.6); %#ok<SAGROW>
    title(ax(c), titulos(c)), xlim(ax(c), [0 t(end)]), ylim(ax(c), limY{c})
end
puntos = plot(ax(1), nan, nan, ".", "Color", [0.85 0.4 0.1], "MarkerSize", 7);
uistack(puntos, "bottom")
xlabel(ax(3), "día"), xlabel(ax(4), "día")
encabezado = title(tl, "día 0");

% ---------------- el filtro, un día a la vez ----------------------------------
for k = 2:n
    if ~isvalid(fig), break, end                 % se cerró la ventana
    R = (datos.opc.ruidoRel*max(H*x,0) + datos.opc.ruidoAbs)^2;
    [x, P, info] = ekfPaso(x, P, datos.y(k), f, H, Q, R);
    x = max(x, [0; 0; 1e-3; 1e-3]);
    xs(:,k) = x;  sd(:,k) = sqrt(diag(P));

    tk = t(1:k);
    set(puntos, "XData", tk, "YData", datos.y(1:k))
    for c = 1:4
        e = ord(c);
        set(linea(c), "XData", tk, "YData", xs(e,1:k))
        set(banda(c), "XData", [tk, fliplr(tk)], ...
            "YData", [xs(e,1:k) + 2*sd(e,1:k), fliplr(xs(e,1:k) - 2*sd(e,1:k))])
    end
    encabezado.String = sprintf("día %d   \\beta = %.3f \\pm %.3f   \\gamma = %.3f \\pm %.3f   innovación = %+.4f", ...
        t(k), x(3), 2*sd(3,k), x(4), 2*sd(4,k), info.innovacion);
    drawnow limitrate
    if pausa > 0, pause(pausa), end
end
drawnow
