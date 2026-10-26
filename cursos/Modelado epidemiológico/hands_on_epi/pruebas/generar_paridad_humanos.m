%GENERAR_PARIDAD_HUMANOS  Genera los archivos de paridad MATLAB -> Python de los modelos
%humano-humano (cada entrada de modelos/catalogo_humanos.json):
%   pruebas/pars_paridad_<id>.csv     20 vectores de parámetros (hipercubo latino, semilla fija),
%                                     una fila por vector, columnas en el orden del catálogo.
%   pruebas/salidas_matlab_<id>.csv   una fila por vector: sol.y aplanado por filas
%                                     (toda la fila 1 de sol.y, luego la fila 2, ...),
%                                     con domain = [0 100] y opt = opt_defecto.
%   paridad_humanos.py compara contra Python.

dirPruebas = fileparts(mfilename('fullpath'));
if isempty(dirPruebas), dirPruebas = pwd; end
raiz = fileparts(dirPruebas);
addpath(fullfile(raiz, 'matlab', 'modelos'), dirPruebas);

nVec   = 20;
domain = [0 100];
E = leer_catalogo_humanos();
for k = 1:numel(E)
    e = E{k};
    f = str2func(e.modelo);
    rng(20261025 + k, 'twister');               % semilla fija por entrada
    Np = size(e.rangos, 1);
    U = zeros(nVec, Np);
    for j = 1:Np                                 % hipercubo latino simple
        U(:, j) = (randperm(nVec).' - rand(nVec, 1))/nVec;
    end
    P = e.rangos(:, 1).' + U.*(e.rangos(:, 2) - e.rangos(:, 1)).';
    salidas = [];
    for i = 1:nVec
        sol = f(P(i, :), domain, e.optS);
        fila = reshape(sol.y.', 1, []);          % aplanado por filas de sol.y
        if isempty(salidas), salidas = zeros(nVec, numel(fila)); end
        salidas(i, :) = fila;
    end
    escribir(fullfile(dirPruebas, ['pars_paridad_' e.id '.csv']), P);
    escribir(fullfile(dirPruebas, ['salidas_matlab_' e.id '.csv']), salidas);
    fprintf('  %-24s %d vectores x %d parámetros -> %d columnas de salida\n', e.id, nVec, Np, size(salidas, 2));
end

function escribir(ruta, M)
% CSV sin encabezado, 17 cifras significativas (ida y vuelta exacta de double).
fid = fopen(ruta, 'w');
formato = [repmat('%.17g,', 1, size(M, 2) - 1) '%.17g\n'];
fprintf(fid, formato, M.');
fclose(fid);
end
