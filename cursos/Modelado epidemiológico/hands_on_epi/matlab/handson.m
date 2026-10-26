%% Hands-on de epidemiología con GSUA-CSB (MATLAB). Espejo de python/handson.py.
%
% Elige un ESCENARIO (datos reales + ventana + salida observada) y un MODELO del catálogo, y
% recorre el ciclo completo:
%   1. datos  2. modelo  3. simulación nominal  4. incertidumbre  5. sensibilidad
%   6. estimación multicomienzo  7. bootstrap  8. identificabilidad e intervalos
%
% Escenarios: ../escenarios.json.  Modelos: ../modelos/catalogo_*.json.
% Para ver la lista, ejecuta la sección 0 y mira las variables ESC y CAT.
% Resultados (JSON y figuras): ../resultados/

%% 0. Configuración (cambia aquí)
if ~exist('ESCENARIO', 'var'), ESCENARIO = 'covid_colombia_ola1'; end  % covid_colombia_ola1 | dengue_bello_2009_2011 | dengue_bello_acumulado | dengue_medellin_2010 | dengue_itagui_2010
if ~exist('MODELO', 'var'),    MODELO    = 'sir_discreto';        end  % sir_continuo | sir_discreto(_G1|_G2|_G3) | sir_cuarentena_cl(_G2|_G3) | dengue_lizarralde | dengue_cl_discreto
N_UA      = 200;                    % muestras para incertidumbre
N_SA      = 200;                    % muestras para sensibilidad
N_MULTI   = [];                     % arranques de la estimación ([] = 10 si hay <= 4 factores libres, 60 si hay más)
N_BOOT    = 20;                     % re-ajustes bootstrap
SEMILLA   = 2026;
if ~exist('HACER_SA', 'var'),  HACER_SA  = true;                  end  % la sensibilidad es lenta en los modelos de EDO
if exist('RAPIDO', 'var') && RAPIDO  % para probar que todo corre: RAPIDO = true; handson
    N_UA = 20; N_SA = 20; N_MULTI = 2; N_BOOT = 3;
end

aqui = fileparts(mfilename('fullpath'));
if isempty(aqui), aqui = pwd; end
raiz = fileparts(aqui);
addpath(fullfile(aqui, 'modelos'));
if isempty(which('gsua_dataprep'))
    error('No se encuentra la toolbox GSUA-CSB: instala GSUA-CSB.mltbx (v1.13).');
end
CAT = leer_catalogo(fullfile(raiz, 'modelos'));
ESC = celdas(jsondecode(fileread(fullfile(raiz, 'escenarios.json'))));
esc = ESC{cellfun(@(e) strcmp(e.id, ESCENARIO), ESC)};
ent = CAT{cellfun(@(m) strcmp(m.id, MODELO), CAT)};
if ~strcmp(ent.transmision, esc.transmision)
    fprintf('OJO: el modelo es de transmisión %s y los datos son %s.\n', ent.transmision, esc.transmision);
end
outdir = fullfile(raiz, 'resultados');
if ~isfolder(outdir), mkdir(outdir); end
tag = sprintf('%s__%s__matlab', esc.id, ent.id);
rng(SEMILLA);
reloj = tic;
unidad = ent.unidad_tiempo;

%% 1. Datos
D = readtable(fullfile(raiz, 'datos', esc.datos), 'TextType', 'string');
if isfield(esc, 'filtro') && ~isempty(esc.filtro)
    col = D.(esc.filtro.columna);
    if isstring(col)
        sel = col >= string(esc.filtro.desde) & col <= string(esc.filtro.hasta);
    else
        sel = col >= esc.filtro.desde & col <= esc.filtro.hasta;
    end
    D = D(sel, :);
end
y = double(D.(esc.columna)).';
if isfield(esc, 'acumular') && esc.acumular, y = cumsum(y); end
x = 0:numel(y)-1;                    % tiempo relativo en la unidad del modelo
fprintf('[1] Datos: %s -> %d puntos (%s)\n', esc.nombre, numel(y), unidad);

%% 2. Modelo
fun = ent.id; if isfield(ent, 'modelo'), fun = ent.modelo; end
factores = celdas(ent.parametros);
if isfield(ent, 'condiciones_iniciales') && ~isempty(ent.condiciones_iniciales)
    factores = [factores; celdas(ent.condiciones_iniciales)];
end
nombres = cellfun(@(p) string(p.id), factores).';
Range = cell2mat(cellfun(@(p) reshape(p.rango, 1, 2), factores, 'UniformOutput', false));
ajustes = struct();
if isfield(esc, 'rangos') && isstruct(esc.rangos)
    if isfield(esc.rangos, ent.id), ajustes = esc.rangos.(ent.id);
    elseif isfield(esc.rangos, fun), ajustes = esc.rangos.(fun); end
end
for k = string(fieldnames(ajustes)).'   % rangos propios de la localidad (escenarios.json)
    Range(nombres == k, :) = reshape(ajustes.(k), 1, 2);
end
opt = struct();
if isfield(ent, 'opt_defecto') && isstruct(ent.opt_defecto), opt = ent.opt_defecto; end
if isfield(esc, 'opt') && isstruct(esc.opt)
    for k = string(fieldnames(esc.opt)).', opt.(k) = esc.opt.(k); end
end
salidas_ent = celdas(ent.salidas);
sal_ids = cellfun(@(s) string(s.id), salidas_ent).';
sal_filas = cellfun(@(s) s.fila, salidas_ent).';
salida = "";
for s = string(esc.salidas).'
    if any(sal_ids == s), salida = s; break; end
end
fila = sal_filas(sal_ids == salida);
[~, orden] = sort(sal_filas);
filas = [string(ent.estados(:)).', sal_ids(orden)];   % una etiqueta por fila de la función

[T, ~] = gsua_dataprep(char(fun), Range, 'domain', [0 x(end)], 'names', cellstr(nombres), ...
    'out_names', cellstr(filas), 'output', fila, 'opt', opt);
libres = string(T.Properties.RowNames).';
if isempty(N_MULTI), N_MULTI = 10 + 50 * (numel(libres) > 4); end
fprintf('[2] Modelo: %s; salida comparada: %s\n', ent.nombre, salida);
fprintf('    Factores libres (%d): %s\n', numel(libres), strjoin(libres, ', '));
fprintf('    Estimación con %d arranques; bootstrap de %d re-ajustes\n', N_MULTI, N_BOOT);
simular = @(p) reshape(squeeze(gsua_eval(p(:), T, x, [], false, false, false)), 1, []);

%% 3. Simulación nominal
y_nom = simular(T.Nominal);
f = figure('Name', 'Nominal', 'Visible', 'off');
plot(x, y, 'r.', x, y_nom, 'b-', 'LineWidth', 1.5); grid on;
xlabel(sprintf('t (%ss)', unidad)); ylabel(salida, 'Interpreter', 'none');
legend('Datos', 'Modelo (nominal: centro de los rangos)');
exportgraphics(f, fullfile(outdir, tag + "_1_nominal.png")); close(f);
fprintf('[3] Simulación nominal guardada\n');

%% 4. Incertidumbre: ¿los datos caen dentro de lo que el modelo puede producir?
M = gsua_dmatrix(T, N_UA, 'Method', 'LatinHypercube');
Y = squeeze(gsua_ua(M, T, 'xdata', x, 'ynom', y, 'parallel', false, 'verbose', false));
if size(Y, 2) ~= numel(x), Y = Y.'; end
P = prctile(Y, [5 50 95], 1);
dentro = mean(y >= P(1, :) & y <= P(3, :));
f = figure('Name', 'Incertidumbre', 'Visible', 'off');
fill([x, fliplr(x)], [P(1, :), fliplr(P(3, :))], [0.8 0.88 0.98], 'EdgeColor', 'none'); hold on;
plot(x, P(2, :), 'b-', x, y, 'r.'); grid on;
xlabel(sprintf('t (%ss)', unidad)); ylabel(salida, 'Interpreter', 'none');
legend('Banda P5–P95', 'Mediana', 'Datos');
exportgraphics(f, fullfile(outdir, tag + "_2_incertidumbre.png")); close(f);
fprintf('[4] Incertidumbre: %.0f%% de los datos dentro de la banda P5–P95\n', 100 * dentro);

%% 5. Sensibilidad (Xiao): ¿qué factores explican la varianza de la salida?
sens = struct();
if HACER_SA
    Ms = gsua_dmatrix(T, N_SA, 'Method', 'LatinHypercube');
    [Ts, ~, ~] = gsua_sa(Ms, T, 'SensMethod', 'Xiao', 'parallel', false, 'verbose', false);
    [v, o] = sort(Ts.STi, 'descend');
    txt = strings(1, numel(o));
    for i = 1:numel(o)
        sens.(libres(o(i))) = v(i);
        txt(i) = sprintf('%s=%.2f', libres(o(i)), v(i));
    end
    fprintf('[5] Sensibilidad total ST_i: %s\n', strjoin(txt, ', '));
end

%% 6. Estimación multicomienzo
optls = optimoptions('lsqcurvefit', 'Display', 'off');
[Tpe, res] = gsua_pe(T, x, y, 'N', N_MULTI, 'solver', 'lsqc', 'opt', optls, 'save', false, 'timer', false);
[costo, ix] = min(res);
mejor = Tpe.Estlsqc(:, ix);
y_fit = simular(mejor);
fprintf('[6] Estimación: costo = %.4g\n', costo);
for i = 1:numel(libres), fprintf('      %-10s = %.6g\n', libres(i), mejor(i)); end

%% 7. Bootstrap de residuos: re-ajustar datos sintéticos = ajuste + residuos re-muestreados
resid = y - y_fit;
Est = zeros(numel(libres), N_BOOT);
for b = 1:N_BOOT
    yb = max(y_fit + resid(randi(numel(resid), 1, numel(resid))), 0);
    [Tb, rb] = gsua_pe(T, x, yb, 'N', max(3, floor(N_MULTI / 6)), 'solver', 'lsqc', 'opt', optls, ...
        'save', false, 'timer', false);
    [~, jx] = min(rb);
    Est(:, b) = Tb.Estlsqc(:, jx);
end
fprintf('[7] Bootstrap: %d re-ajustes\n', N_BOOT);

%% 8. Identificabilidad e intervalos
% El IC es el percentil 2.5–97.5 %% del bootstrap (no el Range de gsua_ia, que es un IC de la
% MEDIANA del conjunto). Veredicto sugerido según el ancho del IC relativo al rango de búsqueda:
% < 25 %% sí, > 50 %% no, en medio "dudoso".
Tia = gsua_ia(T, Est, false, false, false, false);
lo = prctile(Est, 2.5, 2); hi = prctile(Est, 97.5, 2);
ancho_rango = T.Range(:, 2) - T.Range(:, 1);
fprintf('[8] IC 95 %% bootstrap, ancho relativo al rango e índice de gsua_ia (0 = bien, 1 = mal)\n');
filas_res = struct('parametro', {}, 'estimacion', {}, 'ic_inferior', {}, 'ic_superior', {}, ...
    'ancho_relativo', {}, 'indice_gsua', {}, 'identificable_sugerido', {});
for i = 1:numel(libres)
    rel = (hi(i) - lo(i)) / ancho_rango(i);
    if rel < 0.25, ver = "sí"; elseif rel > 0.5, ver = "no"; else, ver = "dudoso"; end
    filas_res(end+1) = struct('parametro', libres(i), 'estimacion', mejor(i), 'ic_inferior', lo(i), ...
        'ic_superior', hi(i), 'ancho_relativo', rel, 'indice_gsua', Tia.index(i), ...
        'identificable_sugerido', ver); %#ok<SAGROW>
    fprintf('      %-10s %12.5g  [%.5g, %.5g]  ancho=%4.0f%%  índice=%.2f  identificable: %s\n', ...
        libres(i), mejor(i), lo(i), hi(i), 100 * rel, Tia.index(i), ver);
end
if numel(libres) > 1
    C = abs(corrcoef(Est.')) - eye(numel(libres));
    [mx, pos] = max(C(:)); [a1, a2] = ind2sub(size(C), pos);
    fprintf('      Par más correlacionado: %s <-> %s (|r| = %.2f)\n', libres(a1), libres(a2), mx);
end

f = figure('Name', 'Ajuste', 'Visible', 'off'); hold on;
for b = 1:N_BOOT, plot(x, simular(Est(:, b)), 'Color', [0.2 0.4 0.8 0.15]); end
plot(x, y_fit, 'b-', 'LineWidth', 2); plot(x, y, 'r.'); grid on;
xlabel(sprintf('t (%ss)', unidad)); ylabel(salida, 'Interpreter', 'none');
exportgraphics(f, fullfile(outdir, tag + "_3_ajuste.png")); close(f);

R = struct('escenario', esc.id, 'modelo', ent.id, 'lenguaje', 'matlab', 'salida', salida, ...
    'costo', costo, 'datos_dentro_banda_ua', dentro, 'sensibilidad_STi', sens, 'parametros', filas_res, ...
    'tamanos', struct('n_ua', N_UA, 'n_sa', N_SA, 'n_multi', N_MULTI, 'n_boot', N_BOOT), ...
    'semilla', SEMILLA, 'segundos', round(toc(reloj), 1));
fid = fopen(fullfile(outdir, tag + ".json"), 'w', 'n', 'UTF-8');
fprintf(fid, '%s\n', jsonencode(R, 'PrettyPrint', true)); fclose(fid);
fprintf('Listo en %.1f s. Resultados en resultados/%s.json y figuras *.png\n', R.segundos, tag);

%% Funciones locales
function CAT = leer_catalogo(carpeta)
    CAT = {};
    for f = dir(fullfile(carpeta, 'catalogo_*.json')).'
        CAT = [CAT; celdas(jsondecode(fileread(fullfile(f.folder, f.name))))]; %#ok<AGROW>
    end
end

function C = celdas(X)
    % jsondecode devuelve un arreglo de estructuras si todos los objetos tienen los mismos
    % campos y una celda si no: aquí siempre se trabaja con una celda columna.
    if isstruct(X), C = num2cell(X(:)); else, C = X(:); end
end
