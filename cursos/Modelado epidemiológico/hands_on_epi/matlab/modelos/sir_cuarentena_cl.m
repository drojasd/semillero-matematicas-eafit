function sol = sir_cuarentena_cl(pars, domain, opt)
%SIR_CUARENTENA_CL  Modelo discreto con cuarentena y detección de
%Cataño-López et al. 2022 (Bull Math Biol 84:127), ecuaciones (6)-(8). Paso de 1 día.
%
%   sol = sir_cuarentena_cl(pars, domain, opt)
%
%   Estados: Sf (susceptibles libres), Sq (susceptibles en cuarentena),
%            If (infectados libres), Iq (infectados en cuarentena),
%            Ij (infectados detectados/aislados), R (recuperados).
%
%   Sf(t+1) = Sf(1-beta*G)(1-lambda) + Sq*alpha + mu*R
%   Sq(t+1) = Sf(1-beta*G)*lambda + Sq(1-alpha)
%   If(t+1) = Sf*beta*G + If(1-gamma)(1-theta)(1-lambda) + Iq(1-gamma)(1-theta)*alpha
%   Iq(t+1) = If(1-gamma)(1-theta)*lambda + Iq(1-gamma)(1-theta)(1-alpha)
%   Ij(t+1) = (If+Iq)(1-gamma)*theta + Ij(1-gamma)
%   R(t+1)  = R(1-mu) + gamma(If+Iq+Ij)
%
%   Contagio G = G~ calculado sobre (Sf, If, N), opt.prob:
%     'G1' (por omisión) 1 - (1 - 1/Sf)^(z*If*(Sf/N)^aleph)
%     'G2'               1 - (1 - (If/N)^aleph)^z
%     'G3'               (If/N)^aleph
%   aleph = 1 + nu*If/(If+Sf)  (ec. 7 del artículo; opt.aleph = 'articulo', por omisión).
%   opt.aleph = 'autores' reproduce CHIMERA_FQ.m de los autores, que usa
%   aleph = 1 + nu*(If+Iq+Ij)/(Sf+If+Iq+Ij).
%
%   pars (orden de CHIMERA_FQ.m; los parámetros que la opción de contagio no usa NO van):
%     'G1','G2': [lambda alpha mu theta gamma nu z beta If0 Ij0]
%     'G3'     : [lambda alpha mu theta gamma nu beta If0 Ij0]
%   Condiciones iniciales: Sf0 = N - If0 - Ij0, Sq0 = Iq0 = R0 = 0. opt.N (5e7 por omisión).
%
%   Filas de sol.y:
%     1 Sf, 2 Sq, 3 If, 4 Iq, 5 Ij, 6 R,
%     7 activos_detectados (= Ij),
%     8 casos_nuevos_detectados (convención hacia atrás: theta*(1-gamma)*(If+Iq) evaluado
%       en t-1, detecciones en el paso que TERMINA en t; en t0 vale Ij0).

if nargin < 3 || isempty(opt), opt = struct(); end
N     = leer_opt(opt, 'N', 5e7);
prob  = char(leer_opt(opt, 'prob', 'G1'));
modoA = char(leer_opt(opt, 'aleph', 'articulo'));
if ~any(strcmp(modoA, {'articulo', 'autores'}))
    error('sir_cuarentena_cl:aleph', 'opt.aleph desconocido: %s (use articulo o autores).', modoA);
end

pars = double(pars(:).');
switch prob
    case {'G1', 'G2'}
        esperado = 10; nombres = '[lambda alpha mu theta gamma nu z beta If0 Ij0]';
    case 'G3'
        esperado = 9;  nombres = '[lambda alpha mu theta gamma nu beta If0 Ij0]';
    otherwise
        error('sir_cuarentena_cl:prob', 'opt.prob desconocido: %s (use G1, G2 o G3).', prob);
end
if numel(pars) ~= esperado
    error('sir_cuarentena_cl:pars', 'Con opt.prob = ''%s'' se esperan %d valores %s; llegaron %d.', ...
        prob, esperado, nombres, numel(pars));
end
lambda = pars(1); alpha = pars(2); mu = pars(3); theta = pars(4); gamma = pars(5);
nu = 0; z = 0;
switch prob
    case {'G1', 'G2'}
        nu = pars(6); z = pars(7); beta = pars(8);
    case 'G3'
        nu = pars(6); beta = pars(7);
end
If0 = pars(end-1); Ij0 = pars(end);

t0 = round(domain(1)); tf = round(domain(end));
t  = t0:tf; Nt = numel(t);
Y  = zeros(8, Nt);
Sf = N - If0 - Ij0; Sq = 0; If = If0; Iq = 0; Ij = Ij0; R = 0;
nuevosDet = Ij0;                   % casos_nuevos_detectados(t0) = detectados iniciales
for k = 1:Nt
    Y(:, k) = [Sf; Sq; If; Iq; Ij; R; Ij; nuevosDet];
    if k == Nt, break; end
    if strcmp(modoA, 'articulo')
        den = Sf + If; num = If;
    else
        den = Sf + If + Iq + Ij; num = If + Iq + Ij;
    end
    if den > 0, aleph = 1 + nu*num/den; else, aleph = 1; end
    switch prob
        case 'G1'
            if Sf > 1
                G = -expm1(z*If*(Sf/N)^aleph*log1p(-1/Sf));
            else
                G = 0;
            end
        case 'G2'
            p = (If/N)^aleph;
            if p < 1, G = -expm1(z*log1p(-p)); else, G = 1; end
        case 'G3'
            G = (If/N)^aleph;
    end
    P  = beta*G;
    sl = 1 - gamma;          % sobrevive a la recuperación
    nd = 1 - theta;          % no detectado
    nuevosDet = (If+Iq)*sl*theta;
    Sfn = Sf*(1-P)*(1-lambda) + Sq*alpha + mu*R;
    Sqn = Sf*(1-P)*lambda + Sq*(1-alpha);
    Ifn = Sf*P + If*sl*nd*(1-lambda) + Iq*sl*nd*alpha;
    Iqn = If*sl*nd*lambda + Iq*sl*nd*(1-alpha);
    Ijn = (If+Iq)*sl*theta + Ij*sl;
    Rn  = R*(1-mu) + gamma*(If+Iq+Ij);
    Sf = Sfn; Sq = Sqn; If = Ifn; Iq = Iqn; Ij = Ijn; R = Rn;
end
sol = struct('x', t, 'y', Y, 'solver', '');
end

function v = leer_opt(opt, campo, defecto)
% Lee un campo de opt o devuelve el valor por omisión.
if isstruct(opt) && isfield(opt, campo) && ~isempty(opt.(campo))
    v = opt.(campo);
else
    v = defecto;
end
end
