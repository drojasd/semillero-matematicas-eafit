function [xn, F] = sirsAumentado(x, alpha)
% sirsAumentado  Un paso (un día) del SIRS discreto con estado aumentado.
%
%   [xn, F] = sirsAumentado(x, alpha)
%
%   Estado aumentado (fracciones de la población, N = 1):
%     x = [s; i; beta; gamma]          alpha conocido (segundo argumento)
%     x = [s; i; beta; gamma; alpha]   alpha también se estima
%   r no es estado: r = 1 - s - i (la población se conserva).
%
%   Dinámica (la misma del semillero, SIRSemilleroSV, con N = 1):
%     P      = 1 - exp(-beta*i)         probabilidad de contagio en el día
%     s(k+1) = s*(1 - P) + alpha*r
%     i(k+1) = s*P + (1 - gamma)*i
%     beta(k+1) = beta,  gamma(k+1) = gamma,  (alpha(k+1) = alpha)
%   Los parámetros son estados "constantes": el ruido de proceso que les
%   asigne el filtro decide qué tan rápido pueden cambiar.
%
%   F = df/dx es el jacobiano, evaluado en x (lo usa el filtro extendido).

    s = x(1); i = x(2); beta = x(3); gamma = x(4);
    estimaAlpha = numel(x) == 5;
    if estimaAlpha, alpha = x(5); end

    E = exp(-beta*i);          % 1 - P
    r = 1 - s - i;

    xn = x;
    xn(1) = s*E + alpha*r;
    xn(2) = s*(1 - E) + (1 - gamma)*i;

    if nargout > 1
        n = numel(x);
        F = eye(n);
        %        d/ds        d/di                d/dbeta    d/dgamma
        F(1,1:4) = [E - alpha, -s*beta*E - alpha, -s*i*E,    0  ];
        F(2,1:4) = [1 - E,     s*beta*E + 1 - gamma, s*i*E, -i  ];
        if estimaAlpha
            F(1,5) = r;        % d s(k+1) / d alpha
            F(2,5) = 0;
        end
    end
end
