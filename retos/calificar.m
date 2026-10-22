function T = calificar(carpetaReto, archivoVerdad, carpetaEntregas, varargin)
% CALIFICAR  Califica las entregas de un reto y produce la tabla de posiciones.
%
%   T = calificar('retos/reto_2', 'retos/privado/reto_2_verdad.json', 'retos/reto_2/entregas')
%   T = calificar(..., 'salida', carpeta)      % dónde escribir posiciones.csv/.json
%
%   Es público desde el lanzamiento del reto: así cada equipo sabe exactamente cómo se le
%   calificará. Espejo exacto de calificar.py (mismos números, mismos archivos byte a byte).
%
%   0. SELLO. Antes de calificar se comprueba que el SHA-256 de la verdad coincide con el que
%      se publicó al lanzar el reto (sha256_verdad en reto_K.json). Si no coincide, se aborta.
%
%   Por cada caso y parámetro, con verdad x, intervalo [l, u], ancho del rango de búsqueda W y
%   alfa = 1 - nivel (nivel = 0.95 -> alfa = 0.05):
%
%   1. PUNTAJE DE INTERVALO (Gneiting y Raftery, 2007), normalizado por W:
%        IS = (u - l) + (2/alfa)*(l - x)*[x < l] + (2/alfa)*(x - u)*[x > u]
%      Un intervalo estrecho que contiene la verdad cuesta poco; uno que no la contiene paga
%      2/alfa = 40 veces la distancia que le faltó. Un intervalo ausente o inválido (l > u)
%      cuenta como todo el rango de búsqueda ("no sé").
%   2. VEREDICTO DE IDENTIFICABILIDAD (identificable: sí/no frente a la verdad):
%        acierto                                                         0
%        dice "no" y sí lo es (falsa modestia), o no responde            1
%        dice "sí" y no lo es, pero su intervalo contiene la verdad      2
%        dice "sí" y no lo es, y su intervalo NO contiene la verdad      5  (sobreconfianza)
%   3. PENALIZACIÓN = suma de IS/W + veredicto sobre todos los casos y parámetros.
%      GANA LA MENOR. Desempate: error relativo medio |estimación - x|/W en los parámetros
%      que sí son identificables (sin estimación cuenta la mitad del intervalo).
%
%   Escribe posiciones.csv y posiciones.json (sin los valores verdaderos) y devuelve la tabla.
    p = inputParser;
    addParameter(p, 'salida', carpetaReto);
    parse(p, varargin{:});
    salida = p.Results.salida;

    infos = dir(fullfile(carpetaReto, 'reto_*.json'));
    if numel(infos) ~= 1
        error('calificar:info', 'Se esperaba un único reto_K.json en %s', carpetaReto);
    end
    info = jsondecode(fileread(fullfile(carpetaReto, infos(1).name)));

    % ---------------- 0. Sello ----------------
    sello = sha256_archivo(archivoVerdad);
    if ~strcmp(sello, info.sha256_verdad)
        error('calificar:sello', ['¡La verdad NO coincide con el sello publicado!\n' ...
            '  publicado: %s\n  archivo:   %s'], info.sha256_verdad, sello);
    end
    fprintf('Sello verificado: SHA-256 de la verdad = %s\n', sello);
    verdad = jsondecode(fileread(archivoVerdad));

    alfa = 1 - info.nivel;
    pars = info.parametros;
    casos = info.casos;
    archivos = dir(fullfile(carpetaEntregas, '*.json'));
    nombres = sort({archivos.name});

    filas = {};
    for e = 1:numel(nombres)
        E = jsondecode(fileread(fullfile(carpetaEntregas, nombres{e})));
        equipo = nombres{e};
        if isfield(E, 'equipo') && ischar(E.equipo) && ~isempty(E.equipo)
            equipo = E.equipo;
        end
        if ~isfield(E, 'reto') || ~isequal(E.reto, info.reto)
            warning('calificar:reto', '%s no es una entrega del reto %d: se omite.', ...
                nombres{e}, info.reto);
            continue
        end
        detalle = {};
        pen = 0; sumIS = 0; sumV = 0; aciertos = 0; dentro = 0; n = 0; sumErr = 0; nErr = 0;
        for c = 1:numel(casos)
            id = casos(c).id;
            for k = 1:numel(pars)
                pid = pars(k).id;
                rango = pars(k).rango(:).';
                W = rango(2) - rango(1);
                x = verdad.casos.(id).parametros.(pid).valor;
                esReal = verdad.casos.(id).parametros.(pid).identificable;
                [est, l, u, decl] = leer(E, id, pid, rango);

                IS = (u - l) + (2/alfa) * max(l - x, 0) + (2/alfa) * max(x - u, 0);
                ISn = IS / W;
                contiene = l <= x && x <= u;
                if isempty(decl)
                    V = 1;
                elseif decl == esReal
                    V = 0;
                elseif decl
                    V = 2 + 3 * ~contiene;
                else
                    V = 1;
                end
                err = abs(est - x) / W;
                if esReal
                    sumErr = sumErr + err; nErr = nErr + 1;
                end
                pen = pen + ISn + V;
                sumIS = sumIS + ISn;
                sumV = sumV + V;
                aciertos = aciertos + (V == 0);
                dentro = dentro + contiene;
                n = n + 1;
                detalle{end+1} = struct('caso', id, 'parametro', pid, ...
                    'puntaje_intervalo', ISn, 'contiene', contiene, ...
                    'identificable_declarado', decl, 'veredicto', V, ...
                    'error_relativo', err); %#ok<AGROW>
            end
        end
        errMedio = 0;
        if nErr > 0, errMedio = sumErr / nErr; end
        filas{end+1} = struct('posicion', 0, 'equipo', equipo, 'archivo', nombres{e}, ...
            'penalizacion', pen, 'intervalo', sumIS, 'veredicto', sumV, ...
            'aciertos', aciertos, 'total', n, 'cobertura', dentro / n, ...
            'error_relativo', errMedio, 'detalle', {detalle}); %#ok<AGROW>
    end

    % ---------------- Orden: menor penalización; desempate por error ----------------
    if isempty(filas)
        clave = zeros(0, 2); arch = {};
    else
        clave = [cellfun(@(f) round(f.penalizacion, 6), filas)', ...
                 cellfun(@(f) round(f.error_relativo, 6), filas)'];
        arch = cellfun(@(f) f.archivo, filas, 'UniformOutput', false)';
    end
    [~, orden] = sortrows(table(clave(:, 1), clave(:, 2), arch));
    filas = filas(orden);
    for i = 1:numel(filas)
        filas{i}.posicion = i;
    end

    % ---------------- Salidas ----------------
    if ~isfolder(salida), mkdir(salida); end
    lineas = {'posicion,equipo,archivo,penalizacion,intervalo,veredicto,aciertos,total,cobertura,error_relativo'};
    for i = 1:numel(filas)
        f = filas{i};
        lineas{end+1} = sprintf('%d,%s,%s,%.6f,%.6f,%.6f,%d,%d,%.6f,%.6f', f.posicion, ...
            csv(f.equipo), csv(f.archivo), f.penalizacion, f.intervalo, f.veredicto, ...
            f.aciertos, f.total, f.cobertura, f.error_relativo); %#ok<AGROW>
    end
    escribir(fullfile(salida, 'posiciones.csv'), [strjoin(lineas, newline) newline]);
    res = struct('reto', info.reto, 'titulo', info.titulo, 'sha256_verdad', sello, ...
        'verdad_verificada', true, 'nivel', info.nivel, 'posiciones', {filas});
    escribir(fullfile(salida, 'posiciones.json'), json_canonico(res));

    if isempty(filas)
        T = table();
    else
        sinDetalle = cellfun(@(f) rmfield(f, 'detalle'), filas, 'UniformOutput', false);
        T = struct2table([sinDetalle{:}]);
    end
    disp(T);
end

function [est, l, u, decl] = leer(E, id, pid, rango)
% Lee un parámetro de la entrega; lo ausente o inválido se vuelve "no sé".
    est = []; l = []; u = []; decl = [];
    if isfield(E, 'casos') && isfield(E.casos, id) && isfield(E.casos.(id), 'parametros') ...
            && isfield(E.casos.(id).parametros, pid)
        q = E.casos.(id).parametros.(pid);
        est = numero(q, 'estimacion');
        l = numero(q, 'ic_inferior');
        u = numero(q, 'ic_superior');
        if isfield(q, 'identificable') && isscalar(q.identificable) && ...
                (islogical(q.identificable) || isnumeric(q.identificable))
            decl = logical(q.identificable);
        end
    end
    if isempty(l) || isempty(u) || l > u
        l = rango(1); u = rango(2);
    end
    if isempty(est)
        est = (l + u) / 2;
    end
end

function v = numero(q, campo)
    v = [];
    if isfield(q, campo) && isnumeric(q.(campo)) && isscalar(q.(campo)) && isfinite(q.(campo))
        v = double(q.(campo));
    end
end

function s = csv(s)
    if any(s == ',') || any(s == '"')
        s = ['"' strrep(s, '"', '""') '"'];
    end
end

function escribir(archivo, texto)
    fid = fopen(archivo, 'w', 'n', 'UTF-8');
    fwrite(fid, unicode2native(texto, 'UTF-8'));
    fclose(fid);
end
