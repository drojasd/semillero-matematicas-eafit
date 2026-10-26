%% Genera la salida de datos/preparar_datos.m para compararla con la de preparar_datos.py
% Escribe en pruebas/paridad_datos_matlab/ (no se versiona) los CSV, resumen.json y
% escenarios.json que produce MATLAB. Si no están los archivos de origen del grupo, solo genera
% los escenarios a partir de los CSV versionados.
% Python los compara con los de datos/ y escenarios.json usando pruebas/paridad_datos.py.

aqui = fileparts(mfilename('fullpath'));
raiz = fileparts(aqui);
addpath(fullfile(raiz, 'datos'));
destino = fullfile(aqui, 'paridad_datos_matlab');
if isfolder(destino), rmdir(destino, 's'); end
try
    preparar_datos('salida', destino);
catch err
    fprintf('%s\nSolo se generan los escenarios.\n', err.message);
    preparar_datos('--solo-escenarios', 'salida', destino);
end
