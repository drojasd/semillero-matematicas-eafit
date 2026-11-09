function [x, P, info] = ekfPaso(x, P, y, f, H, Q, R)
% ekfPaso  Un paso del filtro de Kalman extendido: predicción y corrección.
%
%   [x, P, info] = ekfPaso(x, P, y, f, H, Q, R)
%
%   x, P : estimación y covarianza corregidas en k-1      x(k-1|k-1), P(k-1|k-1)
%   y    : medición en k (NaN = no hubo medición: solo se predice)
%   f    : @(x) -> [xn, F], modelo y su jacobiano (por ejemplo sirsAumentado)
%   H    : matriz de medición, y = H*x + v
%   Q, R : covarianzas del ruido de proceso y de medición
%
%   Si el modelo es lineal (f = @(x) deal(A*x, A)) este es exactamente el
%   filtro de Kalman clásico. La única diferencia del extendido es que A se
%   reemplaza por el jacobiano F evaluado en la estimación actual.

    % --- Predicción (actualización en el tiempo) ---------------------------
    [x, F] = f(x);                       % x(k|k-1) = f(x(k-1|k-1))
    P = F*P*F' + Q;                      % P(k|k-1)

    info.xPred = x;
    info.PPred = P;
    info.innovacion = NaN;
    info.K = zeros(numel(x), size(H,1));

    if any(isnan(y)), return, end

    % --- Corrección (actualización con la medición) ------------------------
    e = y - H*x;                         % innovación
    S = H*P*H' + R;                      % covarianza de la innovación
    K = P*H' / S;                        % ganancia de Kalman
    x = x + K*e;                         % x(k|k)
    I = eye(numel(x));
    P = (I - K*H)*P*(I - K*H)' + K*R*K'; % forma de Joseph: P sigue simétrica y positiva

    info.innovacion = e;
    info.S = S;
    info.K = K;
end
