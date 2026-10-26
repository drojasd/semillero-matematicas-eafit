%% Pruebas de los modelos de transmisión vectorial (dengue) en MATLAB
% Ejecutar desde cualquier carpeta:  run('<ruta>/pruebas/pruebas_vectores.m')
%
% 1. Nominal (punto medio de los rangos del catálogo): sin NaN ni negativos, forma correcta.
% 2. dengue_lizarralde conserva la población humana; acumulados = suma de semanales.
% 3. dengue_cl_discreto conserva la población humana (mu_h = 0 y mu_h > 0).
% 4. Reproducción del código de los autores (si está disponible en este equipo):
%    CHIMERA_Vector.m (dengue_cl_discreto) y Model.m (dengue_lizarralde, forma simbólica).
% 5. Humo GSUA: gsua_dataprep + gsua_pe (N = 2) con datos sintéticos del nominal.
% La paridad con Python se genera con generar_paridad_vectores.m.

aqui = fileparts(mfilename('fullpath'));
raiz = fileparts(aqui);
addpath(fullfile(raiz, 'matlab', 'modelos'));
catalogo = jsondecode(fileread(fullfile(raiz, 'modelos', 'catalogo_vectores.json')));
if iscell(catalogo), catalogo = [catalogo{:}]; end
ids = {'dengue_lizarralde', 'dengue_cl_discreto'};
fallas = 0;

%% 1. Nominal sin NaN ni negativos
for i = 1:numel(ids)
    e = entrada(catalogo, ids{i});
    R = rangos(e);
    sol = feval(ids{i}, mean(R, 2).', [0 104], e.opt_defecto);
    ok = isequal(size(sol.y), [numel(nombres_salida(e)) 105]) && isequal(sol.x, 0:104) && ...
         all(isfinite(sol.y(:))) && min(sol.y(:)) >= -1e-6*max(abs(sol.y(:)));
    fallas = fallas + reportar(ok, sprintf('%s: nominal sin NaN ni negativos', ids{i}));
end

%% 2. Lizarralde: conservación de humanos y acumulados
e = entrada(catalogo, 'dengue_lizarralde');
sol = dengue_lizarralde(mean(rangos(e), 2).', [0 104], e.opt_defecto);
H = sum(sol.y(4:7, :), 1);
ok = max(abs(H - H(1)))/H(1) < 1e-5 && max(abs(cumsum(sol.y(8, :)) - sol.y(9, :))) < 1e-8*max(sol.y(9, :));
fallas = fallas + reportar(ok, 'dengue_lizarralde: conserva H y acumulados = suma de semanales');

%% 3. CL discreto: conservación de humanos
e = entrada(catalogo, 'dengue_cl_discreto');
nom = mean(rangos(e), 2).';
for mu_h = [0 0.0004]
    sol = dengue_cl_discreto(nom, [0 104], struct('mu_h', mu_h));
    H = sum(sol.y(3:5, :), 1);
    ok = max(abs(H - H(1)))/H(1) < 1e-12 && max(abs(cumsum(sol.y(6, :)) - sol.y(7, :))) < 1e-10*max(sol.y(7, :));
    fallas = fallas + reportar(ok, sprintf('dengue_cl_discreto: conserva humanos (mu_h = %g)', mu_h));
end

%% 4. Reproducción del código de los autores
dirChimera = 'D:\MATLAB Drive.source-of-truth-20260718T095207\CHIMERITApaper\Repository\Dengue';
if isfile(fullfile(dirChimera, 'CHIMERA_Vector.m'))
    e = entrada(catalogo, 'dengue_cl_discreto');
    R = rangos(e);
    rng(7);
    dmax = 0;
    for k = 1:20
        p = (R(:, 1) + (R(:, 2) - R(:, 1)).*rand(size(R, 1), 1)).';
        mu_h = 0.0004*(k > 10);                 % la mitad con mu_h > 0
        nuestro = dengue_cl_discreto(p, [0 79], struct('mu_h', mu_h));
        % orden de los autores: Hs0 Hi0 Hr0 Ms0 Mi0 Md0 gamma mu_m mu_h z r C beta_mh beta_hm nu_m nu_h
        pa = [p(10:14) 0 p(1:2) mu_h p(3:9)];
        autores = llamar_en(dirChimera, @() CHIMERA_Vector(pa, [0 79]));
        A = autores.y([4 5 1 2 3 7 8], :);      % Sm Im Sh Ih Rh ins acumulados
        dmax = max(dmax, max(abs(A(:) - nuestro.y(:))./max(abs(A(:)), 1)));
    end
    fprintf('    diferencia relativa máxima con CHIMERA_Vector (20 vectores): %.3g\n', dmax);
    fallas = fallas + reportar(dmax < 1e-12, 'dengue_cl_discreto reproduce CHIMERA_Vector.m');
else
    fprintf('AVISO no se encontró CHIMERA_Vector.m; se omite la comparación\n');
end

dirModel = 'C:\Users\Lanre\MATLAB Drive\PaperCSB\Repositorio\Dengue';
if isfile(fullfile(dirModel, 'Model.m'))
    e = entrada(catalogo, 'dengue_lizarralde');
    R = rangos(e);
    rng(8);
    dmax = 0;
    for k = 1:5
        p = (R(:, 1) + (R(:, 2) - R(:, 1)).*rand(size(R, 1), 1)).';
        nuestro = dengue_lizarralde(p, [0 60], struct('mu_h', 0.0004));
        % Model.m: estados [Hit Hi Me Hr Hs He Ms Mi]; in3 = [beta_h beta_m gamma_h Lambda mu_m theta_h theta_m]
        in3 = [p(3) p(4) p(7) p(1) p(2) p(6) p(5)];
        x0 = [p(13); p(13); p(9); p(14); p(11); p(12); p(8); p(10)];
        ms = llamar_en(dirModel, @() ode45(@(t, x) Model(t, x, in3), [0 60], x0, ...
                       odeset('RelTol', 1e-6, 'AbsTol', 1e-6)));
        X = deval(ms, 0:60);
        A = X([7 3 8 5 6 2 4 1], :);           % Ms Me Mi Hs He Hi Hr C
        B = nuestro.y([1:7 9], :);
        dmax = max(dmax, max(abs(A(:) - B(:))./max(abs(A(:)), 1)));
    end
    fprintf('    diferencia relativa máxima con Model.m de los autores (5 vectores): %.3g\n', dmax);
    fallas = fallas + reportar(dmax < 1e-4, 'dengue_lizarralde coincide con Model.m (ode45, 1e-6)');
else
    fprintf('AVISO no se encontró Model.m; se omite la comparación\n');
end

%% 5. Humo GSUA
T = 30;
xdata = 0:T;
for i = 1:numel(ids)
    e = entrada(catalogo, ids{i});
    R = rangos(e);
    salidas = nombres_salida(e);
    k = e.salidas(strcmp({e.salidas.id}, 'casos_semanales')).fila;
    try
        Tb = gsua_dataprep(ids{i}, R, 'domain', [0 T], 'names', nombres(e), ...
                           'out_names', salidas, 'output', k, 'opt', e.opt_defecto);
        sol = feval(ids{i}, mean(R, 2).', [0 T], e.opt_defecto);   % Tb omite los fijos
        ydata = sol.y(k, :);
        opciones = optimoptions('lsqcurvefit', 'MaxFunctionEvaluations', 60, 'Display', 'off');
        [Test, res] = gsua_pe(Tb, xdata, ydata, 'N', 2, 'opt', opciones, 'save', false);
        ok = numel(res) == 2 && all(isfinite(res(:))) && height(Test) == height(Tb);
        fprintf('    GSUA %s: residuales %s\n', ids{i}, mat2str(res(:).', 4));
    catch err
        fprintf('    %s\n', err.message);
        ok = false;
    end
    fallas = fallas + reportar(ok, sprintf('%s: gsua_dataprep + gsua_pe (N = 2)', ids{i}));
end

%% Resumen
if fallas > 0
    error('pruebas_vectores:fallas', '%d prueba(s) fallaron.', fallas);
end
fprintf('Todas las pruebas de vectores pasaron.\n');

%% Funciones locales
function e = entrada(catalogo, id)
% Entrada del catálogo con ese id.
if iscell(catalogo)
    e = catalogo{cellfun(@(c) strcmp(c.id, id), catalogo)};
else
    e = catalogo(strcmp({catalogo.id}, id));
end
end

function R = rangos(e)
% Rangos (Np x 2): parámetros y luego condiciones iniciales.
R = [vertcat(e.parametros.rango); vertcat(e.condiciones_iniciales.rango)];
if size(R, 2) ~= 2, R = reshape(R, 2, []).'; end
end

function n = nombres(e)
n = [{e.parametros.id}, {e.condiciones_iniciales.id}];
end

function n = nombres_salida(e)
[~, orden] = sort([e.salidas.fila]);
n = [e.estados(:).', {e.salidas(orden).id}];
end

function f = reportar(ok, texto)
% Imprime OK/FALLA y devuelve 1 si falló.
if ok
    fprintf('OK    %s\n', texto); f = 0;
else
    fprintf('FALLA %s\n', texto); f = 1;
end
end

function varargout = llamar_en(carpeta, fn)
% Ejecuta fn con la carpeta de los autores al final del path y la quita después.
addpath(carpeta, '-end');
limpiar = onCleanup(@() rmpath(carpeta));
[varargout{1:nargout}] = fn();
end
