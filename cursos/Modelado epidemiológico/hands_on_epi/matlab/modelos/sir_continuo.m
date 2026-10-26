function sol = sir_continuo(pars, domain, opt)
%SIR_CONTINUO  SIR clásico de Kermack-McKendrick (EDO), población fija N.
%
%   sol = sir_continuo(pars, domain, opt)
%
%   pars   = [beta gamma I0 R0]  (fila o columna)
%            beta  tasa de contagio (1/día), gamma tasa de recuperación (1/día),
%            I0, R0 condiciones iniciales (personas). S0 = N - I0 - R0.
%   domain = [t0 tf] (días). La salida se entrega en la rejilla t0:tf.
%   opt    estructura con elecciones estructurales: opt.N (población, 5e7 por omisión).
%
%   Ecuaciones:
%       S' = -beta*S*I/N
%       I' =  beta*S*I/N - gamma*I
%       R' =  gamma*I
%       C' =  beta*S*I/N          (estado auxiliar: infecciones acumuladas)
%
%   Filas de sol.y:
%       1 S, 2 I, 3 R,
%       4 activos      (= I)
%       5 casos_nuevos (convención hacia atrás: C(t) - C(t-1), infecciones nuevas en el
%         paso que TERMINA en t; en t0 vale I0, los infectados iniciales)
%
%   ode45 con RelTol = AbsTol = 1e-6.

if nargin < 3 || isempty(opt), opt = struct(); end
N = leer_opt(opt, 'N', 5e7);

pars  = double(pars(:).');
if numel(pars) ~= 4
    error('sir_continuo:pars', 'sir_continuo espera 4 valores [beta gamma I0 R0]; llegaron %d.', numel(pars));
end
beta = pars(1); gamma = pars(2); I0 = pars(3); R0 = pars(4);

t0 = domain(1); tf = domain(end);
t  = t0:tf;
x0 = [N - I0 - R0; I0; R0; 0];

f = @(~, x) [ -beta*x(1)*x(2)/N;
               beta*x(1)*x(2)/N - gamma*x(2);
               gamma*x(2);
               beta*x(1)*x(2)/N ];
opciones = odeset('RelTol', 1e-6, 'AbsTol', 1e-6);
if tf > t0
    s = ode45(f, [t0 tf], x0, opciones);
    X = deval(s, t);
else
    X = x0;
end

casos = [I0, diff(X(4, :))];
sol = struct();
sol.x = t;
sol.y = [X(1:3, :); X(2, :); casos];
sol.solver = '';
end

function v = leer_opt(opt, campo, defecto)
% Lee un campo de opt o devuelve el valor por omisión.
if isstruct(opt) && isfield(opt, campo) && ~isempty(opt.(campo))
    v = opt.(campo);
else
    v = defecto;
end
end
