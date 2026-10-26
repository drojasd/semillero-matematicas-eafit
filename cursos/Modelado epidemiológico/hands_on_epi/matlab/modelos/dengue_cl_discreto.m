function sol = dengue_cl_discreto(pars, domain, opt)
%DENGUE_CL_DISCRETO  Modelo discreto vector-huésped de Cataño-López et al. 2022 (Bull Math Biol
%   84:127), ec. (9)-(10), paso semanal, implementado como CHIMERA_Vector.m de los autores.
%
%   sol = dengue_cl_discreto(pars, domain, opt)
%
%   pars   = [gamma mu_m z r C beta_mh beta_hm nu_m nu_h  Hs0 Hi0 Hr0 Ms0 Mi0]
%            Primero los 9 parámetros y luego las 5 condiciones iniciales; dentro de cada bloque
%            se conserva el orden del código de los autores (CHIMERA_Vector.m). Se omiten Md0
%            (mosquitos muertos: no entra en la dinámica) y mu_h (va en opt).
%   domain = [t0 tf] (semanas enteras). La salida se entrega en la rejilla t0:tf.
%   opt    elecciones estructurales: opt.mu_h (natalidad = mortalidad humana por semana;
%          0 por omisión, como en Range2 de Estiamtions_dengue.mlx).
%
%   Ecuaciones, para t = t0, ..., tf-1:
%       N_H = Sh + Ih + Rh,  N_M = Sm + Im
%       alephH = 1 + nu_h*Ih/(Sh+Ih),   alephM = 1 + nu_m*Im/(Sm+Im)   (1 si el denominador es 0)
%       psi = beta_hm*(1 - (1 - (Ih/N_H)^alephM)^z)                 contagio humano -> mosquito
%       phi = beta_mh*(1 - (1 - 1/Sh)^(z*Im*(Sh/N_H)^alephH))       contagio mosquito -> humano
%             (phi = 0 si Sh < 1)
%       A(t) = r*N_M(t-2)*exp(1 - N_M(t)/C)    Ricker con retardo de 2 pasos; en los dos primeros
%             pasos (t = t0, t0+1) se usa A = r*N_M(t0)*exp(1 - N_M(t0)/C), igual que el código
%             de los autores (también en t0+1 se toma N_M(t0) como población actual).
%       Sm(t+1) = Sm*(1-psi)*(1-mu_m) + A
%       Im(t+1) = Sm*psi*(1-mu_m) + Im*(1-mu_m)
%       Sh(t+1) = Sh*(1-phi)*(1-mu_h) + N_H*mu_h
%       Ih(t+1) = Sh*phi*(1-mu_h) + Ih*(1-gamma)*(1-mu_h)
%       Rh(t+1) = Rh*(1-mu_h) + Ih*gamma*(1-mu_h)
%       Ih_ins(t+1) = Sh*phi*(1-mu_h)            ec. (10): casos instantáneos de la semana
%   con Ih_ins(t0) = Ih0 y acumulados C(t) = suma de Ih_ins hasta t (C(t0) = Ih0), como en el
%   código de los autores.
%
%   Filas de sol.y:
%       1 Sm, 2 Im, 3 Sh, 4 Ih, 5 Rh,
%       6 casos_semanales  (Ih_ins),
%       7 casos_acumulados

if nargin < 3 || isempty(opt), opt = struct(); end
mu_h = leer_opt(opt, 'mu_h', 0);

pars = double(pars(:).');
if numel(pars) ~= 14
    error('dengue_cl_discreto:pars', ...
        'dengue_cl_discreto espera 14 valores (9 parámetros + 5 condiciones iniciales); llegaron %d.', numel(pars));
end
gamma = pars(1); mu_m = pars(2); z = pars(3); r = pars(4); C = pars(5);
beta_mh = pars(6); beta_hm = pars(7); nu_m = pars(8); nu_h = pars(9);
Hs0 = pars(10); Hi0 = pars(11); Hr0 = pars(12); Ms0 = pars(13); Mi0 = pars(14);

t0 = domain(1); tf = domain(end);
t  = t0:tf;
Nt = numel(t);

Y = zeros(7, Nt);
Y(:, 1) = [Ms0; Mi0; Hs0; Hi0; Hr0; Hi0; Hi0];
NM = zeros(1, Nt);

for k = 1:Nt-1
    Sm = Y(1, k); Im = Y(2, k); Sh = Y(3, k); Ih = Y(4, k); Rh = Y(5, k);
    NH = Sh + Ih + Rh;
    NM(k) = Sm + Im;

    if Sh + Ih > 0, alephH = 1 + nu_h*Ih/(Sh + Ih); else, alephH = 1; end
    if Sm + Im > 0, alephM = 1 + nu_m*Im/(Sm + Im); else, alephM = 1; end

    psi = beta_hm*(1 - (1 - (Ih/NH)^alephM)^z);
    if Sh >= 1
        phi = beta_mh*(1 - (1 - 1/Sh)^(z*Im*(Sh/NH)^alephH));
    else
        phi = 0;
    end

    if k > 2
        A = r*NM(k-2)*exp(1 - NM(k)/C);
    else
        A = r*NM(1)*exp(1 - NM(1)/C);
    end

    nuevos = Sh*phi*(1 - mu_h);
    Y(1, k+1) = Sm*(1 - psi)*(1 - mu_m) + A;
    Y(2, k+1) = Sm*psi*(1 - mu_m) + Im*(1 - mu_m);
    Y(3, k+1) = Sh*(1 - phi)*(1 - mu_h) + NH*mu_h;
    Y(4, k+1) = nuevos + Ih*(1 - gamma)*(1 - mu_h);
    Y(5, k+1) = Rh*(1 - mu_h) + Ih*gamma*(1 - mu_h);
    Y(6, k+1) = nuevos;
    Y(7, k+1) = Y(7, k) + nuevos;
end

sol = struct();
sol.x = t;
sol.y = Y;
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
