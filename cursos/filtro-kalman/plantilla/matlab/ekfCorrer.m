function est = ekfCorrer(y, fa, ha, xa0, P0, Q, R, lb)
% ekfCorrer  Filtro de Kalman extendido sobre toda la serie de mediciones.
%
%   est = ekfCorrer(y, fa, ha, xa0, P0, Q, R)
%   est = ekfCorrer(y, fa, ha, xa0, P0, Q, R, lb)
%
%   y    (m x N) mediciones; y(:,1) es el instante del estado inicial y no se usa.
%        Un NaN significa que ese día no hubo medición: el filtro solo predice.
%   fa   @(xa) -> xa(k+1)   modelo aumentado (estados y parámetros), un paso
%   ha   @(xa) -> y         ecuación de medición
%   xa0, P0                 suposición inicial y su covarianza
%   Q    (n x n)            covarianza del ruido de proceso
%   R    (m x m) o @(xa)    covarianza del ruido de medición (puede depender del estado)
%   lb   (n x 1, opcional)  cota inferior: la estimación se proyecta a xa >= lb
%
%   Los jacobianos F = dfa/dxa y H = dha/dxa se calculan por diferencias
%   finitas (jacobianoNum), así que basta con escribir fa y ha.
%
%   est.x, est.sd (n x N)   estimación corregida y sus desviaciones (raíz de diag(P))
%   est.yhat (m x N)        medición predicha h(x(k|k-1))
%   est.e, est.z (m x N)    innovación y su versión normalizada e/sqrt(S)
%   est.trP, est.normK (1 x N)

    [m, N] = size(y);
    n = numel(xa0);
    if nargin < 8 || isempty(lb), lb = -inf(n,1); end
    if ~isa(R, 'function_handle'), Rc = R; R = @(xa) Rc; end

    x = xa0(:);  P = P0;
    est.x = nan(n,N);  est.sd = nan(n,N);  est.yhat = nan(m,N);
    est.e = nan(m,N);  est.z = nan(m,N);   est.trP = nan(1,N);  est.normK = zeros(1,N);
    est.x(:,1) = x;  est.sd(:,1) = sqrt(diag(P));  est.trP(1) = trace(P);

    for k = 2:N
        % --- predicción ---
        F = jacobianoNum(fa, x);
        x = fa(x);
        P = F*P*F' + Q;
        % --- corrección ---
        yk = y(:,k);
        yp = ha(x);
        est.yhat(:,k) = yp;
        if all(isfinite(yk))
            H = jacobianoNum(ha, x);
            Rk = R(x);
            S = H*P*H' + Rk;
            K = P*H' / S;
            e = yk - yp;
            x = x + K*e;
            I = eye(n);
            P = (I - K*H)*P*(I - K*H)' + K*Rk*K';   % forma de Joseph
            est.e(:,k) = e;
            est.z(:,k) = e ./ sqrt(diag(S));
            est.normK(k) = norm(K);
        end
        x = max(x, lb);
        est.x(:,k) = x;
        est.sd(:,k) = sqrt(max(diag(P),0));
        est.trP(k) = trace(P);
    end
end
