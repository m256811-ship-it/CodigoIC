function nlos = calculateNLOSChannel(params, geometry, walls)
% CALCULATENLOSCHANNEL Calcula ganhos e atrasos com uma reflexão.
%
% Hipóteses:
%   - TX com emissão Lambertiana.
%   - Paredes com reflexão difusa Lambertiana.
%   - RX com concentrador óptico ideal.
%   - Segmentos TX → patch e patch → RX sem obstruções.
%
% Saídas:
%   gain        : ganho óptico de cada caminho [adimensional]
%   delay_s     : atraso de cada caminho [s]
%   isAccepted  : aceitação geométrica e pelo FOV
%   dcGain      : soma dos ganhos NLOS
%   wallIndex   : parede associada a cada caminho

%---------------------- Geometria dos caminhos --------------------------

paths = calculateNLOSGeometry(params, geometry, walls);

d1 = paths.distanceTxPatch_m;
d2 = paths.distancePatchRx_m;

cosPhi   = paths.cosPhi;
cosAlpha = paths.cosAlpha;
cosBeta  = paths.cosBeta;
cosPsi   = paths.cosPsi;

%---------------------- Parâmetros físicos ------------------------------

halfPowerAngle_deg = params.tx.halfPowerAngle_deg;

area_m2 = params.rx.area_m2;
fov_rad = params.rx.fov_rad;
filterTransmission = params.rx.filterTransmission;
refractiveIndex = params.rx.refractiveIndex;

rho = paths.reflectivity;
patchArea_m2 = paths.area_m2;

%---------------------- Ordem Lambertiana -------------------------------

m = -log(2) / log(cosd(halfPowerAngle_deg));

%---------------------- Aceitação dos caminhos --------------------------

% Os cossenos já foram limitados a [-1, 1] na função de geometria.
psi_rad = acos(cosPsi);

isAccepted = ...
    (cosPhi > 0) & ...
    (cosAlpha > 0) & ...
    (cosBeta > 0) & ...
    (cosPsi > 0) & ...
    (psi_rad <= fov_rad);

%---------------------- Ganhos ópticos ----------------------------------

% Caminhos não aceitos permanecem com ganho zero.
gains = zeros(size(d1));

% Ganho do concentrador aplicado somente aos caminhos aceitos.
concentratorGain = refractiveIndex^2 / sin(fov_rad)^2;

% Seleciona os caminhos válidos antes de elevar cosPhi à potência m.
idx = isAccepted;

gains(idx) = ...
    ((m + 1) * area_m2 ...
    .* rho(idx) .* patchArea_m2(idx) ...
    ./ (2 * pi^2 .* d1(idx).^2 .* d2(idx).^2)) ...
    .* cosPhi(idx).^m ...
    .* cosAlpha(idx) ...
    .* cosBeta(idx) ...
    .* filterTransmission ...
    .* concentratorGain ...
    .* cosPsi(idx);

%---------------------- Atrasos de propagação ----------------------------

delays_s = paths.totalDistance_m / params.lightSpeed_m_s;

%---------------------- Resultados --------------------------------------

nlos.gain = gains;
nlos.delay_s = delays_s;
nlos.isAccepted = isAccepted;
nlos.dcGain = sum(gains);
nlos.wallIndex = paths.wallIndex;

end