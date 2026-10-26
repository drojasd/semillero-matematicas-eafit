function sol = dengue_lizarralde(pars, domain, opt)
%DENGUE_LIZARRALDE  Modelo (3) de Lizarralde-Bejarano et al. 2020 (PLOS ONE), EDO, tiempo en semanas.
%
%   sol = dengue_lizarralde(pars, domain, opt)
%
%   pars   = [Lambda mu_m beta_h beta_m theta_m theta_h gamma_h  Ms0 Me0 Mi0 Hs0 He0 Hi0 Hr0]
%            (fila o columna; primero los 7 parámetros, después las 7 condiciones iniciales,
%            en el orden de modelos/catalogo_vectores.json)
%   domain = [t0 tf] (semanas). La salida se entrega en la rejilla t0:tf.
%   opt    elecciones estructurales: opt.mu_h (natalidad = mortalidad humana por semana,
%          0.0004 por omisión, Tabla 1 del artículo; fijo, no se estima).
%
%   Ecuaciones (modelo 3, reclutamiento constante Lambda de mosquitos hembra):
%       Ms' = Lambda - beta_m*(Hi/H)*Ms - mu_m*Ms
%       Me' = beta_m*(Hi/H)*Ms - (theta_m + mu_m)*Me
%       Mi' = theta_m*Me - mu_m*Mi
%       Hs' = mu_h*H - beta_h*(Mi/M)*Hs - mu_h*Hs
%       He' = beta_h*(Mi/M)*Hs - (theta_h + mu_h)*He
%       Hi' = theta_h*He - (gamma_h + mu_h)*Hi
%       Hr' = gamma_h*Hi - mu_h*Hr
%       C'  = theta_h*He     (estado auxiliar: humanos que pasan a infecciosos)
%   con M = Ms+Me+Mi y H = Hs+He+Hi+Hr (H se conserva: H' = 0). Si M = 0, Mi/M se toma como 0.
%
%   C(t0) = Hi0, como en el guion de los autores (MainEstimations.mlx: Hit0 = Hi0): los
%   infecciosos iniciales ya cuentan como casos reportados.
%
%   Filas de sol.y:
%       1 Ms, 2 Me, 3 Mi, 4 Hs, 5 He, 6 Hi, 7 Hr,
%       8 casos_semanales  (= C(t) - C(t-1): casos de la semana que termina en t; en t0 vale Hi0),
%       9 casos_acumulados (= C(t))
%
%   ode45 con RelTol = AbsTol = 1e-6; deval en la rejilla t0:tf.

if nargin < 3 || isempty(opt), opt = struct(); end
mu_h = leer_opt(opt, 'mu_h', 0.0004);

pars = double(pars(:).');
if numel(pars) ~= 14
    error('dengue_lizarralde:pars', ...
        'dengue_lizarralde espera 14 valores (7 parámetros + 7 condiciones iniciales); llegaron %d.', numel(pars));
end
Lambda  = pars(1); mu_m    = pars(2); beta_h  = pars(3); beta_m = pars(4);
theta_m = pars(5); theta_h = pars(6); gamma_h = pars(7);
x0 = [pars(8:14).'; pars(13)];       % [Ms Me Mi Hs He Hi Hr C], C(t0) = Hi0

t0 = domain(1); tf = domain(end);
t  = t0:tf;

f = @(~, x) campo(x, Lambda, mu_m, beta_h, beta_m, theta_m, theta_h, gamma_h, mu_h);
if tf > t0
    opciones = odeset('RelTol', 1e-6, 'AbsTol', 1e-6);
    s = ode45(f, [t0 tf], x0, opciones);
    X = deval(s, t);
else
    X = x0;
end

semanales = [X(8, 1), diff(X(8, :))];
sol = struct();
sol.x = t;
sol.y = [X(1:7, :); semanales; X(8, :)];
sol.solver = '';
end

function dx = campo(x, Lambda, mu_m, beta_h, beta_m, theta_m, theta_h, gamma_h, mu_h)
% Lado derecho del modelo (3).
Ms = x(1); Me = x(2); Mi = x(3); Hs = x(4); He = x(5); Hi = x(6); Hr = x(7);
M = Ms + Me + Mi;
H = Hs + He + Hi + Hr;
if M > 0, fm = Mi / M; else, fm = 0; end
if H > 0, fh = Hi / H; else, fh = 0; end
dx = [ Lambda - beta_m*fh*Ms - mu_m*Ms;
       beta_m*fh*Ms - (theta_m + mu_m)*Me;
       theta_m*Me - mu_m*Mi;
       mu_h*H - beta_h*fm*Hs - mu_h*Hs;
       beta_h*fm*Hs - (theta_h + mu_h)*He;
       theta_h*He - (gamma_h + mu_h)*Hi;
       gamma_h*Hi - mu_h*Hr;
       theta_h*He ];
end

function v = leer_opt(opt, campo, defecto)
% Lee un campo de opt o devuelve el valor por omisión.
if isstruct(opt) && isfield(opt, campo) && ~isempty(opt.(campo))
    v = opt.(campo);
else
    v = defecto;
end
end
