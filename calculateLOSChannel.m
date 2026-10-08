function los = calculateLOSChannel(params, geometry)
% CALCULATELOSCHANNEL Calcula o ganho óptico do caminho LOS.
%
% Hipóteses:
%   - Emissão Lambertiana.
%   - Concentrador óptico ideal.
%   - Caminho direto sem obstruções.

%---------------------- Parâmetros físicos ------------------------------

halfPowerAngle_deg = params.tx.halfPowerAngle_deg;
area_m2 = params.rx.area_m2;
fov_rad = params.rx.fov_rad;
filterTransmission = params.rx.filterTransmission;
refractiveIndex = params.rx.refractiveIndex;

%---------------------- Geometria ---------------------------------------

distance_m = geometry.distance_m;
cosPhi = geometry.cosPhi;
cosPsi = geometry.cosPsi;
psi_rad = geometry.psi_rad;

%---------------------- Ordem Lambertiana -------------------------------

m = -log(2) / log(cosd(halfPowerAngle_deg));

%---------------------- Aceitação do caminho ----------------------------

% RX na frente do TX e luz incidente na face sensível do RX.
% O ângulo de incidência também deve estar dentro do FOV.
isAccepted = (cosPhi > 0) && ...
    (cosPsi > 0) && ...
    (psi_rad <= fov_rad);

%---------------------- Ganho LOS ---------------------------------------

HLOS = 0;

if isAccepted
    % Ganho do concentrador dentro do FOV.
    concentratorGain = refractiveIndex^2 / sin(fov_rad)^2;

    HLOS = ((m + 1) * area_m2 / (2 * pi * distance_m^2)) ...
        * cosPhi^m ...
        * filterTransmission ...
        * concentratorGain ...
        * cosPsi;
end

%---------------------- Resultados --------------------------------------

los.gain = HLOS;
los.isAccepted = isAccepted;
los.lambertianOrder = m;
los.delay_s = distance_m / params.lightSpeed_m_s;
end