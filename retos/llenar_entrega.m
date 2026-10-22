function E = llenar_entrega(E, caso, R, varargin)
% LLENAR_ENTREGA  Llena un caso de la entrega de un reto a partir de lo que devuelve la toolbox.
%
%   E = llenar_entrega('reto_2/entrega_plantilla.json', 'c4', CT_ia)
%   E = llenar_entrega(E, 'c5', CT_ia, 'umbral', 0.4, 'justificacion', 'R(0) se va al borde...')
%   E = llenar_entrega(E, 'c1', CT_pe.Estfmincon(:,select), 'identificable', [1 1 0 1 1 1])
%   guardar_entrega(E, 'entrega_mi_equipo.json')
%
%   Entradas:
%     E      plantilla o entrega: struct, o ruta a un .json (p. ej. entrega_plantilla.json)
%     caso   identificador del caso, p. ej. 'c4'
%     R      uno de:
%            - la tabla que devuelve gsua_ia: usa Nominal (estimación), Range (intervalo) e
%              index (índice de identificabilidad: 0 bien identificado, 1 mal identificado).
%              Ojo: Range es el IC de la MEDIANA del ensamble que recibió gsua_ia, no un
%              intervalo para el parámetro (ver gsua_medianCI)
%            - una matriz Np x N de estimaciones repetidas de gsua_pe (p. ej. CT_pe.Estfmincon):
%              estimación = mediana, intervalo = cuantiles (1-nivel)/2 y (1+nivel)/2
%            - un struct con vectores estimacion, ic_inferior, ic_superior (y, si se quiere,
%              identificable): para intervalos de gsua_likelihood, gsua_csb o propios
%            Las filas van en el orden de los parámetros de la plantilla.
%   Opciones (nombre, valor):
%     'umbral'        con gsua_ia: identificable = index < umbral. Por defecto 0.5
%     'identificable' vector lógico que reemplaza el veredicto automático. ES TU DECISIÓN: con
%                     una matriz de gsua_pe no hay veredicto automático y hay que darlo aquí
%     'nivel'         nivel de los cuantiles con una matriz de gsua_pe. Por defecto 0.95
%     'justificacion' texto: por qué decidiste lo que decidiste en este caso
%     'equipo', 'integrantes'  nombre del equipo y celda con sus integrantes
%
%   Espejo en Python: llenar_entrega.py.
    p = inputParser;
    addParameter(p, 'umbral', 0.5);
    addParameter(p, 'identificable', []);
    addParameter(p, 'nivel', 0.95);
    addParameter(p, 'justificacion', []);
    addParameter(p, 'equipo', []);
    addParameter(p, 'integrantes', []);
    parse(p, varargin{:});
    o = p.Results;

    if ischar(E) || isstring(E)
        E = jsondecode(fileread(E));
    end
    if ~isfield(E.casos, caso)
        error('llenar_entrega:caso', 'La entrega no tiene el caso %s', caso);
    end
    ids = fieldnames(E.casos.(caso).parametros);
    Np = numel(ids);

    ident = [];
    if istable(R) || (isstruct(R) && isfield(R, 'Nominal'))
        est = R.Nominal(:);
        lo = R.Range(:, 1);
        hi = R.Range(:, 2);
        if (istable(R) && ismember('index', R.Properties.VariableNames)) || ...
                (isstruct(R) && isfield(R, 'index'))
            ident = R.index(:) < o.umbral;
        end
    elseif isnumeric(R)
        if size(R, 1) ~= Np
            error('llenar_entrega:dim', 'La matriz debe ser %d x N (una columna por estimación)', Np);
        end
        est = zeros(Np, 1); lo = est; hi = est;
        for k = 1:Np
            est(k) = cuantil(R(k, :), 0.5);
            lo(k) = cuantil(R(k, :), (1 - o.nivel) / 2);
            hi(k) = cuantil(R(k, :), (1 + o.nivel) / 2);
        end
    elseif isstruct(R)
        est = R.estimacion(:); lo = R.ic_inferior(:); hi = R.ic_superior(:);
        if isfield(R, 'identificable'), ident = logical(R.identificable(:)); end
    else
        error('llenar_entrega:tipo', 'No sé leer un %s', class(R));
    end
    if ~isempty(o.identificable)
        ident = logical(o.identificable(:));
    end
    if numel(est) ~= Np
        error('llenar_entrega:dim', 'Se esperaban %d parámetros (%s), llegaron %d', ...
            Np, strjoin(ids, ', '), numel(est));
    end
    if isempty(ident)
        warning('llenar_entrega:sinVeredicto', ...
            'Caso %s: falta el veredicto de identificabilidad; pásalo con ''identificable''.', caso);
    end

    for k = 1:Np
        q = E.casos.(caso).parametros.(ids{k});
        q.estimacion = est(k);
        q.ic_inferior = lo(k);
        q.ic_superior = hi(k);
        if ~isempty(ident), q.identificable = ident(k); end
        E.casos.(caso).parametros.(ids{k}) = q;
    end
    if ~isempty(o.justificacion), E.casos.(caso).justificacion = char(o.justificacion); end
    if ~isempty(o.equipo), E.equipo = char(o.equipo); end
    if ~isempty(o.integrantes), E.integrantes = cellstr(o.integrantes); end
end

function q = cuantil(v, prob)
% Interpolación lineal entre estadísticos de orden (el método por defecto de numpy), para que
% MATLAB y Python den el mismo intervalo con las mismas estimaciones.
    v = sort(v(:));
    h = (numel(v) - 1) * prob;
    i = floor(h);
    if i + 1 >= numel(v)
        q = v(end);
    else
        q = v(i + 1) + (h - i) * (v(i + 2) - v(i + 1));
    end
end
