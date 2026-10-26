%PRUEBAS_HUMANOS  Pruebas de los modelos humano-humano en MATLAB.
%   1. Corrida nominal (punto medio de los rangos) de cada entrada de
%      catalogo_humanos.json: forma de la salida, sin NaN, sin negativos,
%      conservación de la población y coherencia de las filas de salida.
%   2. sir_cuarentena_cl contra el código de los autores (CHIMERA_FQ.m), si está disponible.
%   3. Prueba corta con la toolbox GSUA-CSB: gsua_dataprep + gsua_pe (N = 2) con datos
%      sintéticos generados desde el nominal.
%
%   Ejecutar desde cualquier carpeta: run('.../pruebas/pruebas_humanos.m')

dirPruebas = fileparts(mfilename('fullpath'));
if isempty(dirPruebas), dirPruebas = pwd; end
raiz = fileparts(dirPruebas);
addpath(fullfile(raiz, 'matlab', 'modelos'), dirPruebas);

E = leer_catalogo_humanos();
fallos = 0;

%% 1. Corrida nominal
fprintf('--- 1. Corridas nominales ---\n');
for k = 1:numel(E)
    e = E{k};
    f = str2func(e.modelo);
    N = e.optS.N;
    nEst = numel(e.estados);
    try
        sol = f(e.nominal, [0 150], e.optS);
        Y = sol.y;
        assert(isequal(sol.x, 0:150), 'rejilla de tiempo incorrecta');
        assert(size(Y, 1) == nEst + numel(e.salidas), 'número de filas incorrecto');
        assert(all(isfinite(Y(:))), 'hay NaN o Inf');
        assert(min(Y(:)) >= -1e-9*N, 'hay valores negativos (min = %g)', min(Y(:)));
        consv = max(abs(sum(Y(1:nEst, :), 1) - N))/N;
        assert(consv < 1e-8, 'no conserva la población (error relativo %g)', consv);
        % la salida de activos coincide con su estado
        s1 = e.salidas(1); if iscell(s1), s1 = s1{1}; end
        if strcmp(e.modelo, 'sir_cuarentena_cl'), filaEst = 5; else, filaEst = 2; end
        assert(isequal(Y(s1.fila, :), Y(filaEst, :)), 'la fila de activos no coincide con el estado');
        % incidencia con convención hacia atrás: en t0 vale la condición inicial (I0 o Ij0)
        s2 = e.salidas(2); if iscell(s2), s2 = s2{1}; end
        if strcmp(e.modelo, 'sir_cuarentena_cl'), ci = 'Ij0'; else, ci = 'I0'; end
        inc = Y(s2.fila, :);
        assert(inc(1) == e.nominal(strcmp(e.nombres, ci)), 'casos nuevos en t0 distinto de %s', ci);
        if ~strcmp(e.modelo, 'sir_cuarentena_cl')   % en los SIR: casos(t) = S(t-1) - S(t)
            assert(max(abs(inc(2:end) - (Y(1, 1:end-1) - Y(1, 2:end)))) < 1e-8*N, 'casos(t) ~= S(t-1) - S(t)');
        end
        % pars como columna (así los pasa gsua) y dominio que no empieza en 0
        sol2 = f(e.nominal(:), [5 40], e.optS);
        assert(isequal(sol2.x, 5:40) && isequal(size(sol2.y), [size(Y,1) 36]), 'falla con pars columna o t0 ~= 0');
        fprintf('  OK  %-24s pico de activos %.4g, conservación %.1e\n', e.id, max(Y(s1.fila,:)), consv);
    catch ME
        fallos = fallos + 1;
        fprintf('  FALLA %-22s %s\n', e.id, ME.message);
    end
end

%% 2. Comparación con CHIMERA_FQ.m (código de los autores)
fprintf('--- 2. sir_cuarentena_cl frente a CHIMERA_FQ.m ---\n');
dirAutores = 'D:\MATLAB Drive.source-of-truth-20260718T095207\CHIMERITApaper\Repository\Covid19';
if exist(fullfile(dirAutores, 'CHIMERA_FQ.m'), 'file')
    addpath(dirAutores);
    codigoAutores = struct('G2', 1, 'G1', 2, 'G3', 3);  % Prob de CHIMERA_FQ
    rng(7, 'twister');
    probs = {'G1', 'G2', 'G3'};
    for ip = 1:numel(probs)
        prob = probs{ip};
        errAut = 0; errNu0 = 0;
        for r = 1:5
            N = 1e6;
            lam = rand; alf = rand; mu = 0.01*rand; th = rand; ga = rand;
            nu = 1000*rand; z = 30*rand; be = rand; If0 = 1000*rand; Ij0 = 1 + 99*rand;
            for modo = 1:2
                if modo == 2, nu = 0; end
                pAut = [N-If0-Ij0, If0, 0, Ij0, 0, 0, lam, alf, mu, th, ga, nu, z, be];
                M = CHIMERA_FQ(pAut, [0 120], struct('Prob', codigoAutores.(prob)));
                switch prob
                    case {'G1','G2'}, pn = [lam alf mu th ga nu z be If0 Ij0];
                    case 'G3',        pn = [lam alf mu th ga nu be If0 Ij0];
                end
                if modo == 1, modoA = 'autores'; else, modoA = 'articulo'; end
                S = sir_cuarentena_cl(pn, [0 120], struct('prob', prob, 'N', N, 'aleph', modoA));
                A = M.y(1:6, :); B = S.y(1:6, :);
                err = max(max(abs(A - B), [], 2) ./ max(max(abs(A), [], 2), 1e-12));
                if modo == 1, errAut = max(errAut, err); else, errNu0 = max(errNu0, err); end
            end
        end
        % Tolerancia 1e-6: CHIMERA_FQ evalúa 1 - (1 - x)^y de forma directa, lo que pierde
        % cifras por cancelación cuando x es pequeño (error relativo ~ eps/x, hasta ~1e-7 en G1/G2);
        % aquí se usa -expm1(y*log1p(-x)), que es la misma función calculada con más precisión.
        ok = errAut < 1e-6 && errNu0 < 1e-6;
        if ~ok, fallos = fallos + 1; end
        fprintf('  %s %-3s aleph=autores: err rel máx %.2e | aleph=articulo con nu=0: %.2e\n', ...
            ternario(ok, 'OK   ', 'FALLA'), prob, errAut, errNu0);
    end
    rmpath(dirAutores);
else
    fprintf('  (omitido: no se encontró CHIMERA_FQ.m)\n');
end

%% 3. GSUA-CSB: gsua_dataprep + gsua_pe (N = 2)
fprintf('--- 3. GSUA-CSB (gsua_dataprep + gsua_pe, N = 2) ---\n');
if exist('gsua_dataprep', 'file') && exist('gsua_pe', 'file')
    idsGSUA = {'sir_continuo', 'sir_discreto', 'sir_discreto_G1', 'sir_cuarentena_cl'};
    Tf = 60;
    for k = 1:numel(E)
        e = E{k};
        if ~any(strcmp(e.id, idsGSUA)), continue; end
        try
            s1 = e.salidas(1); if iscell(s1), s1 = s1{1}; end
            outNames = [reshape(e.estados, 1, []), cellfun(@(s) s.id, a_celdas(e.salidas), 'UniformOutput', false).'];
            f = str2func(e.modelo);
            sol = f(e.nominal, [0 Tf], e.optS);
            ydata = sol.y(s1.fila, :);
            evalc(['[T, ~] = gsua_dataprep(e.modelo, e.rangos, ''domain'', [0 Tf], ''names'', e.nombres, ', ...
                   '''out_names'', outNames, ''output'', s1.fila, ''opt'', e.optS);']);
            opciones = optimoptions('lsqcurvefit', 'Display', 'off', 'MaxIterations', 30);
            evalc('[T, res] = gsua_pe(T, 0:Tf, ydata, ''N'', 2, ''opt'', opciones, ''save'', false, ''timer'', false);');
            assert(all(isfinite(res)), 'costo no finito');
            fprintf('  OK  %-24s %d parámetros libres, costos [%s]\n', e.id, height(T), num2str(res(:).', '%.3g '));
        catch ME
            fallos = fallos + 1;
            fprintf('  FALLA %-22s %s\n', e.id, ME.message);
        end
    end
else
    fallos = fallos + 1;
    fprintf('  FALLA: la toolbox GSUA-CSB no está en el path de MATLAB\n');
end

%% Resumen
if fallos == 0
    fprintf('TODAS LAS PRUEBAS PASARON\n');
else
    error('pruebas_humanos:fallos', '%d prueba(s) fallaron', fallos);
end

function c = a_celdas(s)
if isstruct(s), c = num2cell(s(:)); else, c = s(:); end
end

function r = ternario(c, a, b)
if c, r = a; else, r = b; end
end
