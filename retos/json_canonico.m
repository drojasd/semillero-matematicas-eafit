function texto = json_canonico(valor)
% JSON_CANONICO  JSON con un formato fijo, idéntico byte a byte al de comun.json_canonico (Python).
%
%   texto = json_canonico(valor)
%
%   Se usa para los archivos que se sellan con SHA-256 (la verdad) y para las entregas, de modo
%   que MATLAB y Python escriban exactamente el mismo archivo con los mismos datos.
%
%   Reglas: sangría de 2 espacios; objetos con un campo por línea, en el orden del struct;
%   listas de valores simples en una línea ([1, 2, 3]); números con %.15g; [] y NaN -> null;
%   true/false; texto en UTF-8 sin escapar. Una celda {} es una lista; un struct, un objeto.
    texto = [codificar(valor, '') newline];
end

function t = codificar(v, sangria)
    sub = [sangria '  '];
    if isstring(v) && isscalar(v)
        v = char(v);
    end
    if ischar(v)
        t = ['"' escapar(v) '"'];
    elseif isstruct(v) && isscalar(v)
        campos = fieldnames(v);
        if isempty(campos)
            t = '{}';
            return
        end
        partes = cell(numel(campos), 1);
        for k = 1:numel(campos)
            partes{k} = [sub '"' campos{k} '": ' codificar(v.(campos{k}), sub)];
        end
        t = ['{' newline strjoin(partes, [',' newline]) newline sangria '}'];
    elseif isstruct(v)
        t = lista(num2cell(v), sangria);
    elseif iscell(v)
        t = lista(v, sangria);
    elseif isempty(v)
        t = 'null';
    elseif islogical(v) && isscalar(v)
        if v, t = 'true'; else, t = 'false'; end
    elseif isnumeric(v) && isscalar(v)
        if isfinite(v)
            t = sprintf('%.15g', v);
        else
            t = 'null';
        end
    elseif isnumeric(v) || islogical(v)
        t = lista(num2cell(v(:).'), sangria);
    else
        error('json_canonico:tipo', 'Tipo no soportado: %s', class(v));
    end
end

function t = lista(c, sangria)
    if isempty(c)
        t = '[]';
        return
    end
    sub = [sangria '  '];
    simples = all(cellfun(@(x) ~isstruct(x) && ~iscell(x), c));
    partes = cellfun(@(x) codificar(x, sub), c, 'UniformOutput', false);
    if simples
        t = ['[' strjoin(partes, ', ') ']'];
    else
        t = ['[' newline sub strjoin(partes, [',' newline sub]) newline sangria ']'];
    end
end

function s = escapar(s)
    s = strrep(s, '\', '\\');
    s = strrep(s, '"', '\"');
    s = strrep(s, newline, '\n');
    s = strrep(s, sprintf('\r'), '\r');
    s = strrep(s, sprintf('\t'), '\t');
end
