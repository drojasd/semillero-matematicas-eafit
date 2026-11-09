function obs = observabilidadLocal(datos, alpha)
% observabilidadLocal  Observabilidad del SIRS aumentado a lo largo del brote.
%
%   obs = observabilidadLocal(datos, alpha)
%
%   Se linealiza el modelo a lo largo de la trayectoria verdadera datos.x y
%   se arma la matriz de observabilidad del sistema lineal variante en el
%   tiempo con TODAS las mediciones desde el día 0 hasta el día k:
%
%     O(k) = [ H ; H Phi(1) ; H Phi(2) ; ... ; H Phi(k) ],
%     Phi(j) = F(j-1) ... F(1) F(0)      (transición linealizada de 0 a j)
%
%   La fila j de O(k) dice cuánto cambia la medición del día j si se mueve
%   el estado inicial x(0) = [s0; i0; beta; gamma]. Dos detalles prácticos:
%   las columnas se multiplican por x(0) (cambios relativos, así s, i, beta y
%   gamma quedan en la misma escala) y las filas se dividen por la desviación
%   del ruido de medición de ese día (una medición ruidosa informa menos).
%
%   obs.t         días
%   obs.sv (4xN)  valores singulares de O(k), de mayor a menor
%   obs.cosBG     coseno entre las columnas de beta y gamma de O(k).
%                 Cerca de -1: las mediciones solo ven beta - gamma.

    x = datos.x;  y = datos.x(2,:);
    sigma = datos.opc.ruidoRel*y + datos.opc.ruidoAbs;
    [n, N] = size(x);
    H = [0 1 0 0];
    O = zeros(N, n);
    Phi = eye(n);
    for j = 1:N
        O(j,:) = H*Phi / sigma(j);
        if j < N
            [~, F] = sirsAumentado(x(:,j), alpha);
            Phi = F*Phi;
        end
    end
    O = O*diag(x(:,1));

    obs.t = datos.t;
    obs.sv = nan(n, N);
    obs.cosBG = nan(1, N);
    for k = n:N
        Ok = O(1:k,:);
        obs.sv(:,k) = svd(Ok);
        b = Ok(:,3);  g = Ok(:,4);
        obs.cosBG(k) = (b'*g)/(norm(b)*norm(g));
    end
end
