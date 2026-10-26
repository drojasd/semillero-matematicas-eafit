function generar_paridad_escenarios()
%GENERAR_PARIDAD_ESCENARIOS Archivo de paridad MATLAB -> Python de los escenarios.
%   Para cada escenario de escenarios.json y cada uno de sus modelos sugeridos corre las
%   secciones 1 y 2 de matlab/handson.m (datos y modelo, con SOLO_PREPARAR = true) y guarda en
%   pruebas/paridad_escenarios_matlab.json lo que el guion arma: la ventana de datos y, los
%   rangos, opt, la salida comparada y la simulación nominal (centro de los rangos).
%   Python lo compara con pruebas/paridad_escenarios.py.
aqui = fileparts(mfilename('fullpath'));
raiz = fileparts(aqui);
guion = fullfile(raiz, 'matlab', 'handson.m');
E = jsondecode(fileread(fullfile(raiz, 'escenarios.json')));
if isstruct(E), E = num2cell(E); end
R = {};
for i = 1:numel(E)
    for m = string(E{i}.modelos_sugeridos(:)).'
        R{end+1, 1} = uno(guion, E{i}.id, char(m)); %#ok<AGROW>
    end
end
fid = fopen(fullfile(aqui, 'paridad_escenarios_matlab.json'), 'w', 'n', 'UTF-8');
fprintf(fid, '%s\n', jsonencode(R, 'PrettyPrint', true));
fclose(fid);
fprintf('paridad_escenarios_matlab.json: %d combinaciones escenario-modelo\n', numel(R));
end

function r = uno(guion, ESCENARIO, MODELO)
    % Cada combinación corre en su propio espacio de trabajo.
    SOLO_PREPARAR = true; %#ok<NASGU>
    evalc('run(guion)');
    r = struct('escenario', ESCENARIO, 'modelo', MODELO, 'salida', char(salida), ...
        'nombres', {cellstr(nombres)}, 'rangos', Range, 'opt', opt, ...
        'x', x, 'y', y, 'y_nominal', simular(T.Nominal));
end
