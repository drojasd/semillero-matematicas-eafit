function [r, lags, limite] = autocorrInnov(z, maxLag)
% autocorrInnov  Prueba de blancura: autocorrelación de las innovaciones.
%
%   [r, lags, limite] = autocorrInnov(z, maxLag)
%
%   z son las innovaciones normalizadas (los NaN se descartan). Si el filtro
%   está bien sintonizado, z es ruido blanco: r(l) para l >= 1 debe quedar casi
%   siempre (95 %) dentro de +-limite = 1.96/sqrt(N).

    z = z(isfinite(z));
    z = z(:) - mean(z);
    N = numel(z);
    if nargin < 2, maxLag = min(20, N-1); end
    lags = 0:maxLag;
    r = zeros(size(lags));
    for l = lags
        r(l+1) = sum(z(1:N-l).*z(1+l:N)) / sum(z.^2);
    end
    limite = 1.96/sqrt(N);
end
