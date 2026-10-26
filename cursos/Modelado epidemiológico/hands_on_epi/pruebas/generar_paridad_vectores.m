%% Genera los archivos de paridad MATLAB -> Python de los modelos de vectores
% Para cada modelo <id> de modelos/catalogo_vectores.json escribe en esta carpeta:
%   pars_paridad_<id>.csv    20 vectores de parámetros (uno por fila, orden del catálogo),
%                            muestreados uniformemente en los rangos con semilla fija.
%   salidas_matlab_<id>.csv  una fila por (vector, fila de sol.y): vector, fila, y(t0..tf).
% Dominio [0 52] semanas y opt = opt_defecto del catálogo.
% Python los compara con pruebas/paridad_vectores.py.

aqui = fileparts(mfilename('fullpath'));
raiz = fileparts(aqui);
addpath(fullfile(raiz, 'matlab', 'modelos'));
catalogo = jsondecode(fileread(fullfile(raiz, 'modelos', 'catalogo_vectores.json')));
if ~iscell(catalogo), catalogo = num2cell(catalogo); end

dominio = [0 52];
Nvec = 20;
for i = 1:numel(catalogo)
    e = catalogo{i};
    R = [vertcat(e.parametros.rango); vertcat(e.condiciones_iniciales.rango)];
    if size(R, 2) ~= 2, R = reshape(R, 2, []).'; end
    rng(2026 + i, 'twister');
    P = R(:, 1).' + (R(:, 2) - R(:, 1)).'.*rand(Nvec, size(R, 1));

    fid = fopen(fullfile(aqui, ['pars_paridad_' e.id '.csv']), 'w');
    fprintf(fid, '%s\n', strjoin([{e.parametros.id}, {e.condiciones_iniciales.id}], ','));
    fprintf(fid, [repmat('%.17g,', 1, size(P, 2) - 1) '%.17g\n'], P.');
    fclose(fid);

    fid = fopen(fullfile(aqui, ['salidas_matlab_' e.id '.csv']), 'w');
    t = dominio(1):dominio(2);
    fprintf(fid, 'vector,fila,%s\n', strjoin(compose('t%d', t), ','));
    for k = 1:Nvec
        sol = feval(e.id, P(k, :), dominio, e.opt_defecto);
        for f = 1:size(sol.y, 1)
            fprintf(fid, ['%d,%d,' repmat('%.17g,', 1, numel(t) - 1) '%.17g\n'], k, f, sol.y(f, :));
        end
    end
    fclose(fid);
    fprintf('%s: %d vectores, %d filas de salida, dominio [%d %d]\n', e.id, Nvec, size(sol.y, 1), dominio);
end
