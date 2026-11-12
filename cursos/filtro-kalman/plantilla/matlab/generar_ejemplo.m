% generar_ejemplo  Crea ../ejemplo_datos.csv, los datos del ejemplo de la plantilla.
%
% SIR continuo normalizado (s + i + r = 1), muestreado cada día durante 120 días:
%   ds/dt = -beta*s*i,   di/dt = beta*s*i - gamma*i,   beta = 0.5, gamma = 0.2.
% Medición: y = i + v, con v ~ N(0, (0.05*i + 0.0005)^2).
% Columnas: t, y, s, i (s e i verdaderos; en datos reales no existen).
% No hace falta correrlo: el CSV ya viene con la plantilla. Python lee el mismo archivo.

g = @(x,p) [-p(1)*x(1)*x(2); p(1)*x(1)*x(2) - p(2)*x(2)];
p = [0.5; 0.2];
Ts = 1;  N = 121;
X = zeros(2,N);  X(:,1) = [0.999; 0.001];
for k = 1:N-1
    X(:,k+1) = pasoRK4(g, X(:,k), p, Ts, 10);
end
rng(3)
y = max(X(2,:) + (0.05*X(2,:) + 5e-4).*randn(1,N), 0);
T = table((0:N-1)', y', X(1,:)', X(2,:)', 'VariableNames', {'t','y','s','i'});
aqui = fileparts(mfilename('fullpath'));
writetable(T, fullfile(aqui, '..', 'ejemplo_datos.csv'))
