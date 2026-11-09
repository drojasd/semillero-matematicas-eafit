function datos = simularSIRS(opc)
% simularSIRS  Datos sintéticos de un brote SIRS con medición ruidosa de I.
%
%   datos = simularSIRS()          valores por defecto
%   datos = simularSIRS(opc)       opc puede traer cualquiera de los campos:
%     dias      (240)    días simulados
%     s0, i0    (0.999, 0.001)  condición inicial (fracciones)
%     beta      (0.5)    tasa de transmisión [1/día]
%     gamma     (0.2)    tasa de recuperación [1/día]
%     alpha     (0.01)   pérdida de inmunidad [1/día]
%     diaCambio (Inf)    día de una intervención: desde ahí beta = betaDespues
%     betaDespues (0.3)
%     ruidoRel  (0.05)   ruido de medición relativo (5 % de I)
%     ruidoAbs  (5e-4)   piso de ruido de medición
%     semilla   (7)
%
%   datos.t, datos.x (4 x n: s, i, beta, gamma verdaderos), datos.y (medición)

    def = struct('dias',240,'s0',0.999,'i0',0.001,'beta',0.5,'gamma',0.2, ...
        'alpha',0.01,'diaCambio',Inf,'betaDespues',0.3, ...
        'ruidoRel',0.05,'ruidoAbs',5e-4,'semilla',7);
    if nargin < 1, opc = struct(); end
    for c = fieldnames(def)'
        if ~isfield(opc,c{1}), opc.(c{1}) = def.(c{1}); end
    end

    rng(opc.semilla)
    n = opc.dias + 1;
    x = zeros(4,n);
    x(:,1) = [opc.s0; opc.i0; opc.beta; opc.gamma];
    for k = 1:n-1
        x(:,k+1) = sirsAumentado(x(:,k), opc.alpha);
        if k >= opc.diaCambio, x(3,k+1) = opc.betaDespues; end
    end
    sigma = opc.ruidoRel*x(2,:) + opc.ruidoAbs;     % desviación del ruido
    y = max(x(2,:) + sigma.*randn(1,n), 0);         % una fracción no es negativa

    datos.t = 0:opc.dias;
    datos.x = x;
    datos.y = y;
    datos.opc = opc;
end
