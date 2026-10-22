function guardar_entrega(E, archivo)
% GUARDAR_ENTREGA  Escribe la entrega en JSON (mismo formato que guardar_entrega en Python).
%
%   guardar_entrega(E, 'entrega_mi_equipo.json')
%
%   Ver LLENAR_ENTREGA. Avisa si a algún parámetro le falta algún campo.
    if isempty(E.integrantes)
        E.integrantes = {};
    elseif ischar(E.integrantes)
        E.integrantes = {E.integrantes};
    end
    casos = fieldnames(E.casos);
    for c = 1:numel(casos)
        pars = E.casos.(casos{c}).parametros;
        ids = fieldnames(pars);
        for k = 1:numel(ids)
            q = pars.(ids{k});
            if isempty(q.estimacion) || isempty(q.ic_inferior) || isempty(q.ic_superior) || ...
                    isempty(q.identificable)
                warning('guardar_entrega:incompleta', 'Caso %s, %s: campos sin llenar.', ...
                    casos{c}, ids{k});
            end
        end
    end
    fid = fopen(archivo, 'w', 'n', 'UTF-8');
    fwrite(fid, unicode2native(json_canonico(E), 'UTF-8'));
    fclose(fid);
end
