function E = leer_catalogo_humanos()
%LEER_CATALOGO_HUMANOS  Lee modelos/catalogo_humanos.json y devuelve un arreglo de
%celdas, una estructura por entrada, con campos adicionales listos para usar:
%   .rangos   (Np x 2) rangos de parámetros y luego condiciones iniciales
%   .nombres  (1 x Np) nombres en ese mismo orden
%   .nominal  (1 x Np) punto medio de los rangos
%   .optS     estructura opt (opt_defecto)

raiz = fileparts(fileparts(mfilename('fullpath')));
txt  = fileread(fullfile(raiz, 'modelos', 'catalogo_humanos.json'));
crudo = jsondecode(txt);
if isstruct(crudo), crudo = num2cell(crudo); end
E = cell(size(crudo));
for k = 1:numel(crudo)
    e = crudo{k};
    lista = [a_celdas(e.parametros); a_celdas(e.condiciones_iniciales)];
    Np = numel(lista);
    e.rangos = zeros(Np, 2);
    e.nombres = cell(1, Np);
    for j = 1:Np
        e.rangos(j, :) = lista{j}.rango(:).';
        e.nombres{j} = lista{j}.id;
    end
    e.nominal = mean(e.rangos, 2).';
    e.optS = e.opt_defecto;
    E{k} = e;
end
end

function c = a_celdas(s)
if isstruct(s), c = num2cell(s(:)); else, c = s(:); end
end
