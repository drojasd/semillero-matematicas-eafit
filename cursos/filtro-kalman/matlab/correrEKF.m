function est = correrEKF(datos, cfg)
% correrEKF  Corre el filtro de Kalman extendido sobre toda la serie.
%
%   est = correrEKF(datos)        configuración por defecto
%   est = correrEKF(datos, cfg)   cfg puede traer:
%     x0     ([0.99; 0.002; 0.3; 0.1])   suposición inicial [s; i; beta; gamma]
%     sd0    ([0.01; 0.002; 0.2; 0.1])   incertidumbre inicial (desviaciones)
%     q      ([1e-4; 1e-4; 1e-3; 1e-4])  desviación del ruido de proceso por día
%     alpha  (0.01)                      pérdida de inmunidad (conocida)
%     ruidoRel, ruidoAbs                 modelo del ruido de medición (R)
%
%   est.x (4 x n) estimaciones corregidas, est.sd (4 x n) desviaciones,
%   est.e (1 x n) innovaciones, est.S (1 x n) su varianza predicha,
%   est.K (4 x n) ganancias.

    def = struct('x0',[0.99;0.002;0.3;0.1],'sd0',[0.01;0.002;0.2;0.1], ...
        'q',[1e-4;1e-4;1e-3;1e-4],'alpha',0.01, ...
        'ruidoRel',datos.opc.ruidoRel,'ruidoAbs',datos.opc.ruidoAbs);
    if nargin < 2, cfg = struct(); end
    for c = fieldnames(def)'
        if ~isfield(cfg,c{1}), cfg.(c{1}) = def.(c{1}); end
    end

    n = numel(datos.t);
    H = [0 1 0 0];                               % solo se mide i
    Q = diag(cfg.q.^2);
    f = @(x) sirsAumentado(x, cfg.alpha);

    x = cfg.x0;
    P = diag(cfg.sd0.^2);
    est.x = zeros(4,n);  est.sd = zeros(4,n);
    est.e = nan(1,n);    est.S = nan(1,n);    est.K = zeros(4,n);
    est.x(:,1) = x;      est.sd(:,1) = sqrt(diag(P));

    for k = 2:n
        R = (cfg.ruidoRel*max(H*x,0) + cfg.ruidoAbs)^2;   % R(k) según el nivel de I
        [x, P, info] = ekfPaso(x, P, datos.y(k), f, H, Q, R);
        x = max(x, [0; 0; 1e-3; 1e-3]);                    % fracciones y tasas no negativas
        est.x(:,k) = x;
        est.sd(:,k) = sqrt(diag(P));
        est.e(k) = info.innovacion;
        est.S(k) = info.S;
        est.K(:,k) = info.K;
    end
    est.cfg = cfg;
end
