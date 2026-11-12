function J = jacobianoNum(fun, x)
% jacobianoNum  Jacobiano de fun en x por diferencias centrales.
%
%   J = jacobianoNum(fun, x)     J(i,j) = d fun_i / d x_j
%
%   El paso es relativo al tamaño de cada componente: h_j = 1e-6*max(|x_j|, 1e-3).
%   Si el modelo es suave basta; si se escribe el jacobiano a mano, conviene
%   compararlo con este en un punto para revisar que no tiene errores.

    x = x(:);
    f0 = fun(x);
    J = zeros(numel(f0), numel(x));
    for j = 1:numel(x)
        h = 1e-6*max(abs(x(j)), 1e-3);
        xp = x;  xp(j) = xp(j) + h;
        xm = x;  xm(j) = xm(j) - h;
        J(:,j) = (fun(xp) - fun(xm)) / (2*h);
    end
end
