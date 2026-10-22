%% Hands-on: estimacion de parametros e identificabilidad de un modelo SIR
%  ------------------------------------------------------------------------
%  Semillero de Matematicas  --  Toolbox gsua_csb
%
%  Tienes datos de una epidemia simulada con un modelo SIR de tiempo
%  discreto (sin vacunacion). NO conoces los parametros que la generaron:
%  tu objetivo es ESTIMARLOS a partir de los datos y decidir CUALES se
%  pueden determinar con confianza (analisis de identificabilidad).
%
%  Modelo (poblacion N = S+I+R constante):
%     S(k+1) = S(k)*(1 - beta*I(k)/N) + alpha*R(k)
%     I(k+1) = S(k)*beta*I(k)/N + (1-gamma)*I(k)
%     R(k+1) = (1-alpha)*R(k) + gamma*I(k)
%  Parametros a estimar: S(0), I(0), R(0), beta, gamma, alpha
%
%  Ejecuta el script POR SECCIONES (Ctrl+Enter en cada bloque %%).
%  ========================================================================

%% 0) Preparacion del entorno
clear; clc; close all;
% Ruta al toolbox (ajusta si tu instalacion esta en otro lugar):
addpath(genpath('/home/drojasd/octopus-large/matlab-drive-source-of-truth-20260718T153305Z/Toolbox/Functions'));
addpath(genpath('/home/drojasd/octopus-large/matlab-drive-source-of-truth-20260718T153305Z/Toolbox/Add Funcs'));

%% 1) Conectar el modelo con el toolbox
% Se especifica el archivo que corre el modelo, junto con los intervalos y
% nombres de los parametros y condiciones iniciales.
func_name = 'SIRSemilleroSV';
domain    = [0 100];                    % instantes de simulacion

%           [  minimo   maximo ]
ranges = [   700     1100;    % S(0)  susceptibles iniciales
               1       20;    % I(0)  infectados iniciales
               0       50;    % R(0)  recuperados iniciales
             0.10    0.70;    % beta   tasa de transmision
             0.05    0.35;    % gamma  tasa de recuperacion
             0.00    0.10];   % alpha  tasa de perdida de inmunidad

paramNames = {'S(0)','I(0)','R(0)','\beta','\gamma','\alpha'};
out_names  = {'S(t)','I(t)','R(t)'};
input      = struct('action',1);        % opciones del modelo (no se usan)

control_table = gsua_dataprep(func_name,ranges,'domain',domain, ...
    'names',paramNames,'out_names',out_names,'opt',input);

%% 2) Cargar y visualizar los datos a ajustar
load('datos_semillero_SIR.mat');        % states_export, xdata, info
disp(info.descripcion)

num_sim  = 1;        % <-- ELIGE la curva a trabajar (1 a 6)
% Sugerencia de salidas segun la curva:
%   curvas 1,2,3  -> ajustar solo I           => num_outs = 2
%   curvas 4,5,6  -> ajuste multiobjetivo S+I => num_outs = [1 2]
num_outs = 2;        % <-- 2 para I ; [1 2] para S e I

control_table.Properties.CustomProperties.output = num_outs;

xdata = 0:100;       % instantes de tiempo disponibles
ydata = squeeze(states_export(num_sim,xdata+1,num_outs));
if numel(num_outs) > 1
    ydata = ydata';  % filas = salidas, columnas = tiempo
end

figure(1); clf
plot(xdata,ydata,'-o','LineWidth',1.2)
xlabel('Tiempo'); ylabel('Casos')
title(['Datos a ajustar  --  curva ' num2str(num_sim)])
legend(out_names(num_outs),'Location','best')

%% 3) ¿Es factible estimar con estos intervalos?
% Se generan muchas combinaciones dentro de los rangos y se comparan con
% los datos. Si la nube de simulaciones "envuelve" a los datos, el problema
% es factible.
M = gsua_dmatrix(control_table,100);
Y = gsua_eval(M',control_table,'ydata',ydata,'xdata',xdata,'parallel',false);

%% 4) Estimacion de parametros
% Se repite la estimacion N veces desde puntos iniciales distintos.
% solver: {'lsqc','lsqn','ga','particle','psearch','surrogate','annealing','fmincon'}
[CT_pe, costf] = gsua_pe(control_table,xdata,ydata, ...
    'N',30,'solver','fmincon','show','on');

%% 5) Seleccionar las estimaciones del "mismo minimo"
% Nos quedamos con las estimaciones cuyo costo esta cerca del mejor.
select = costf < costf(1)*1.2;
figure(2); clf
subplot(1,2,1); boxplot(costf);          title('Todas las funciones de costo')
subplot(1,2,2); boxplot(costf(select));  title(['Seleccionadas: ' num2str(sum(select))])

%% 6) Analisis de identificabilidad practico
% Revisa: (a) el ancho del intervalo de confianza de cada parametro,
%         (b) el mapa de correlaciones entre parametros,
%         (c) el indice de identificabilidad (0 = bien, 1 = mal).
% Pregunta clave: ¿cuales parametros quedan bien determinados y cuales no?
CT_ia = gsua_ia(CT_pe, CT_pe.Estfmincon(:,select), true, false, true);

%% 7) Idoneidad de los intervalos de confianza
% Simulamos usando los intervalos hallados y verificamos que sigan
% conteniendo a los datos.
Mia = gsua_dmatrix(CT_ia,100);
Yia = gsua_eval(Mia',CT_ia,'ydata',ydata,'xdata',xdata,'parallel',false);

%% 8) Tus conclusiones
% - ¿Que parametros lograste identificar con confianza?
% - ¿Cual(es) NO? ¿Por que crees que ocurre?
% - ¿Cambia algo si ajustas S+I en vez de solo I?
% Tu instructor tiene los valores reales para comparar al final.
disp('Valores estimados (nominal):')
disp(CT_ia(:,{'Nominal'}))

%% 9) (OPCIONAL) Reto: epidemia en curso
% Vuelve a estimar usando SOLO los primeros dias del brote (epidemia aun en
% desarrollo). ¿Siguen siendo identificables beta, gamma y alpha?
% Pista: cambia xdata por una ventana corta y repite las secciones 2-6.
%   xdata = 0:15;   ydata = squeeze(states_export(num_sim,xdata+1,num_outs));
%   if numel(num_outs)>1, ydata = ydata'; end
