function sol = sir_discreto(pars, domain, opt)
%SIR_DISCRETO  SIR en tiempo discreto (paso de 1 día) con probabilidad de contagio
%seleccionable mediante opt.prob.
%
%   sol = sir_discreto(pars, domain, opt)
%
%   S(t+1) = S(t)*(1 - P(t))
%   I(t+1) = I(t) + S(t)*P(t) - gamma*I(t)
%   R(t+1) = R(t) + gamma*I(t)
%
%   opt.prob (elección estructural; define también qué parámetros lleva pars):
%     'exp'    (por omisión)  P = 1 - exp(-beta*I/N)          pars = [beta gamma I0 R0]
%     'G1'  P = beta*G1,  G1 = 1 - (1 - 1/S)^(z*I*(S/N)^aleph) pars = [beta gamma nu z I0 R0]
%     'G2'  P = beta*G2,  G2 = 1 - (1 - (I/N)^aleph)^z         pars = [beta gamma nu z I0 R0]
%     'G3'  P = beta*G3,  G3 = (I/N)^aleph                     pars = [beta gamma nu I0 R0]
%   con aleph(S,I) = 1 + nu*I/(S+I)  (Cataño-López et al. 2022, Bull Math Biol, ec. 3-5).
%   gamma es una probabilidad diaria de recuperación en [0,1].
%   opt.N: población (5e7 por omisión). S0 = N - I0 - R0.
%
%   Filas de sol.y:
%     1 S, 2 I, 3 R, 4 activos (= I), 5 casos_nuevos (convención hacia atrás: S(t-1)*P(t-1),
%     contagios en el paso que TERMINA en t; en t0 vale I0).

if nargin < 3 || isempty(opt), opt = struct(); end
N    = leer_opt(opt, 'N', 5e7);
prob = char(leer_opt(opt, 'prob', 'exp'));

pars = double(pars(:).');
nu = 0; z = 0;
switch prob
    case 'exp'
        esperado = 4; nombres = '[beta gamma I0 R0]';
    case {'G1', 'G2'}
        esperado = 6; nombres = '[beta gamma nu z I0 R0]';
    case 'G3'
        esperado = 5; nombres = '[beta gamma nu I0 R0]';
    otherwise
        error('sir_discreto:prob', 'opt.prob desconocido: %s (use exp, G1, G2 o G3).', prob);
end
if numel(pars) ~= esperado
    error('sir_discreto:pars', 'Con opt.prob = ''%s'' se esperan %d valores %s; llegaron %d.', ...
        prob, esperado, nombres, numel(pars));
end
beta = pars(1); gamma = pars(2);
switch prob
    case {'G1', 'G2'}
        nu = pars(3); z = pars(4);
    case 'G3'
        nu = pars(3);
end
I0 = pars(end-1); R0 = pars(end);

t0 = round(domain(1)); tf = round(domain(end));
t  = t0:tf; Nt = numel(t);
Y  = zeros(5, Nt);
S = N - I0 - R0; I = I0; R = R0;
nuevos = I0;                       % casos_nuevos(t0) = infectados iniciales
for k = 1:Nt
    Y(:, k) = [S; I; R; I; nuevos];
    if k < Nt
        P = prob_contagio(prob, S, I, N, beta, nu, z);
        nuevos = S*P;
        Sn = S - nuevos;
        In = I + nuevos - gamma*I;
        Rn = R + gamma*I;
        S = Sn; I = In; R = Rn;
    end
end
sol = struct('x', t, 'y', Y, 'solver', '');
end

function P = prob_contagio(prob, S, I, N, beta, nu, z)
% Probabilidad de que un susceptible se contagie en un paso de tiempo.
switch prob
    case 'exp'
        P = -expm1(-beta*I/N);
    otherwise
        if S + I > 0
            aleph = 1 + nu*I/(S + I);
        else
            aleph = 1;
        end
        switch prob
            case 'G1'
                % 1 - (1 - 1/S)^x escrito con log1p/expm1 para no perder precisión.
                if S > 1
                    x = z*I*(S/N)^aleph;
                    G = -expm1(x*log1p(-1/S));
                else
                    G = 0;
                end
            case 'G2'
                p = (I/N)^aleph;
                if p < 1
                    G = -expm1(z*log1p(-p));
                else
                    G = 1;
                end
            case 'G3'
                G = (I/N)^aleph;
        end
        P = beta*G;
end
end

function v = leer_opt(opt, campo, defecto)
% Lee un campo de opt o devuelve el valor por omisión.
if isstruct(opt) && isfield(opt, campo) && ~isempty(opt.(campo))
    v = opt.(campo);
else
    v = defecto;
end
end
