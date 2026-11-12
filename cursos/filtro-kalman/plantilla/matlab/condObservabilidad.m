function obs = condObservabilidad(X, fa, ha, ventana, escala)
% condObservabilidad  Rango y número de condición de la observabilidad local.
%
%   obs = condObservabilidad(X, fa, ha, ventana, escala)
%
%   X        (n x N) trayectoria del estado aumentado (simulada o estimada)
%   fa, ha   modelo aumentado y medición, como en ekfCorrer
%   ventana  número de mediciones que se usan en cada instante (por defecto n)
%   escala   (n x 1) magnitud típica de cada estado (por defecto |X(:,1)|)
%
%   En cada k se linealiza a lo largo de la trayectoria y se arma
%     O(k) = [ H(k) ; H(k+1) F(k) ; H(k+2) F(k+1) F(k) ; ... ]
%   con 'ventana' bloques. Las columnas se multiplican por 'escala' para que el
%   número de condición no dependa de las unidades de cada estado.
%
%   obs.cond (1 x N)  número de condición de O(k)*diag(escala)  (Inf si pierde rango)
%   obs.rango (1 x N) rango numérico
%   obs.sv (n x N)    valores singulares

    [n, N] = size(X);
    if nargin < 4 || isempty(ventana), ventana = n; end
    if nargin < 5 || isempty(escala), escala = max(abs(X(:,1)), 1e-12); end
    D = diag(escala(:));
    obs.cond = nan(1,N);  obs.rango = nan(1,N);  obs.sv = nan(n,N);
    for k = 1:N - ventana + 1
        O = [];
        Phi = eye(n);
        for j = 0:ventana-1
            xk = X(:,k+j);
            O = [O; jacobianoNum(ha, xk)*Phi]; %#ok<AGROW>
            Phi = jacobianoNum(fa, xk)*Phi;
        end
        s = svd(O*D);
        obs.sv(1:numel(s),k) = s;
        obs.rango(k) = sum(s > max(size(O))*eps(s(1)));
        obs.cond(k) = s(1)/s(end);
    end
end
