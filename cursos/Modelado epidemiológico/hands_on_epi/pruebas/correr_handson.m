function correr_handson(filtro)
%CORRER_HANDSON Corre matlab/handson.m en modo rápido para cada escenario y sus modelos sugeridos.
%   correr_handson            % todas las combinaciones
%   correr_handson('dengue')  % solo escenarios cuyo id contiene 'dengue'
% Falla (error) si alguna combinación falla. Prueba que todo corre, no la calidad del ajuste.
if nargin < 1, filtro = ''; end
raiz = fileparts(fileparts(mfilename('fullpath')));
E = jsondecode(fileread(fullfile(raiz, 'escenarios.json')));
if isstruct(E), E = num2cell(E); end
fallas = {};
for i = 1:numel(E)
    e = E{i};
    if ~contains(e.id, filtro), continue; end
    for m = string(e.modelos_sugeridos(:)).'
        try
            uno(fullfile(raiz, 'matlab', 'handson.m'), e.id, char(m));
            fprintf('OK    %-24s %s\n', e.id, m);
        catch err
            fprintf('FALLA %-24s %s: %s\n', e.id, m, err.message);
            fallas{end+1} = sprintf('%s/%s', e.id, m); %#ok<AGROW>
        end
    end
end
if ~isempty(fallas), error('Fallaron: %s', strjoin(fallas, ', ')); end
end

function uno(guion, ESCENARIO, MODELO) %#ok<INUSD>
    % Cada combinación corre en su propio espacio de trabajo.
    RAPIDO = true; HACER_SA = false; %#ok<NASGU>
    evalc('run(guion)');
    close all force   % no acumular figuras entre combinaciones
end
