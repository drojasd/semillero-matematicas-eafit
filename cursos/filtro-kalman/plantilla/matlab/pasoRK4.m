function x = pasoRK4(g, x, p, Ts, nsub)
% pasoRK4  Avanza un modelo continuo dx/dt = g(x, p) un periodo de muestreo Ts.
%
%   x = pasoRK4(g, x, p, Ts, nsub)
%
%   Usa nsub subpasos de Runge-Kutta 4 de tamaño Ts/nsub. Así un modelo de
%   tiempo continuo se convierte en el modelo discreto x(k+1) = f(x(k)) que
%   necesita el filtro. Si el modelo ya es discreto, no se usa esta función.

    if nargin < 5, nsub = 10; end
    h = Ts/nsub;
    x = x(:);
    for s = 1:nsub
        k1 = g(x, p);
        k2 = g(x + h/2*k1, p);
        k3 = g(x + h/2*k2, p);
        k4 = g(x + h*k3, p);
        x = x + h/6*(k1 + 2*k2 + 2*k3 + k4);
    end
end
