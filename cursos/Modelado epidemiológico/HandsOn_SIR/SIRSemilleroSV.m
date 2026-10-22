function sol = SIRSemilleroSV(pars,domain,in) %#ok<INUSD>
% SIRSemilleroSV  Modelo SIR de tiempo discreto SIN vacunacion.
%
%   sol = SIRSemilleroSV(pars,domain,in)
%
%   Version del modelo SIRSemillero sin la componente de vacunacion ni el
%   seguimiento de costos. Incluye perdida de inmunidad (R -> S) a tasa
%   alpha, de modo que con alpha = 0 se recupera el SIR clasico.
%
%   Entradas:
%     pars   = [S0, I0, R0, beta, gamma, alpha]
%              S0,I0,R0 <-- condiciones iniciales (susceptibles, infectados,
%                           recuperados)
%              beta     <-- tasa de transmision
%              gamma    <-- tasa de recuperacion
%              alpha    <-- tasa de perdida de inmunidad (R -> S)
%     domain = [t0, tf] instantes inicial y final (paso entero)
%     in     <-- struct de opciones (no se usa; presente por compatibilidad
%                con la interfaz de gsua_dataprep para funciones de usuario)
%
%   Salida:
%     sol.x = vector de tiempos t0:tf
%     sol.y = matriz 3 x length(t) con las filas [S; I; R]
%
%   Dinamica (poblacion N = S+I+R constante):
%     S(k+1) = S(k)*(1 - beta*I(k)/N) + alpha*R(k)
%     I(k+1) = S(k)*beta*I(k)/N + (1-gamma)*I(k)
%     R(k+1) = (1-alpha)*R(k) + gamma*I(k)

    time = domain(1):domain(2);
    M = zeros(3,length(time));
    M(1,1) = pars(1);   % S
    M(2,1) = pars(2);   % I
    M(3,1) = pars(3);   % R
    beta  = pars(4);
    gamma = pars(5);
    alpha = pars(6);

    sim_time = 1:(length(time)-1);
    for k = sim_time
        N = sum(M(1:3,k));
        M(1,k+1) = M(1,k)*(1 - M(2,k)/N*beta) + alpha*M(3,k);
        M(2,k+1) = M(1,k)*M(2,k)/N*beta + (1-gamma)*M(2,k);
        M(3,k+1) = (1-alpha)*M(3,k) + gamma*M(2,k);
    end

    sol = struct();
    sol.x = time;
    sol.y = M;
end
