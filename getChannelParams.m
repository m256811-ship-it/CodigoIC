function params = getChannelParams()
% GETCHANNELPARAMS
% Retorna os parâmetros físicos do canal óptico VLC.
%
% Hipóteses:
%   - Emissão Lambertiana.
%   - Receptor com concentrador óptico ideal.
%   - Sala retangular com quatro paredes de reflexão difusa.
%   - Piso e teto sem contribuições refletidas nesta etapa.
%
% Posições, orientações e discretização são definidos separadamente.

%---------------------- Características do TX ---------------------------
params.tx.halfPowerAngle_deg = 70; % Semiângulo de meia potência do LED

%---------------------- Características do RX ---------------------------
params.rx.area_m2 = 1e-4;          % Área efetiva do fotodetector [m²]
params.rx.fov_rad = pi/2;          % Semiângulo do campo de visão [rad]
params.rx.filterTransmission = 1; % Transmissão do filtro óptico [0,1]
params.rx.refractiveIndex = 1.5;   % Índice do concentrador óptico ideal

%---------------------- Parâmetros da sala ------------------------------
params.room.length_m = 2;         % Dimensão ao longo de x [m]
params.room.width_m = 2;          % Dimensão ao longo de y [m]
params.room.height_m = 3;         % Dimensão ao longo de z [m]

% Ordem das paredes: xMin, xMax, yMin, yMax
params.room.wallReflectivity = [0.8, 0.8, 0.8, 0.8];

%---------------------- Posição e orientação ----------------------------

% Origem no centro da sala.
% Posições como vetores coluna [x; y; z], em metros.
params.tx.pose.position_m = [0; 0;  params.room.height_m/2];
params.rx.pose.position_m = [0; 0; -params.room.height_m/2];

% Ângulos na ordem [roll; pitch; yaw], em graus.
params.tx.pose.rpy_deg = [0; 30; 0];
params.rx.pose.rpy_deg = [0; 0; 0];

% Direção do eixo óptico no sistema local de cada dispositivo.
params.tx.referenceNormal = [0; 0; -1];
params.rx.referenceNormal = [0; 0;  1];

%---------------------- Propagação -------------------------------------
params.lightSpeed_m_s = 3e8;       % Velocidade de propagação [m/s]

end