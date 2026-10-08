function geometry = calculateLOSGeometry(params)
% CALCULATELOSGEOMETRY Calcula a geometria do caminho direto TX–RX.

% Posições [x; y; z], em metros.
pTx = params.tx.pose.position_m;
pRx = params.rx.pose.position_m;

% Ângulos [roll; pitch; yaw], em graus.
rpyTx_deg = params.tx.pose.rpy_deg;
rpyRx_deg = params.rx.pose.rpy_deg;

% Direções de referência dos eixos ópticos.
n0Tx = params.tx.referenceNormal;
n0Rx = params.rx.referenceNormal;

%---------------------- Rotação do TX -----------------------------------

rollTx  = rpyTx_deg(1); % Rotação em torno de x [graus]
pitchTx = rpyTx_deg(2); % Rotação em torno de y [graus]
yawTx   = rpyTx_deg(3); % Rotação em torno de z [graus]

RxTx = [1, 0, 0;
    0, cosd(rollTx), -sind(rollTx);
    0, sind(rollTx),  cosd(rollTx)];

RyTx = [ cosd(pitchTx), 0, sind(pitchTx);
    0,             1, 0;
    -sind(pitchTx), 0, cosd(pitchTx)];

RzTx = [cosd(yawTx), -sind(yawTx), 0;
    sind(yawTx),  cosd(yawTx), 0;
    0,            0,           1];

RTx = RzTx * RyTx * RxTx;

% Eixo óptico do TX expresso nas coordenadas da sala.
nTx = RTx * n0Tx;

%---------------------- Rotação do RX -----------------------------------

rollRx  = rpyRx_deg(1);
pitchRx = rpyRx_deg(2);
yawRx   = rpyRx_deg(3);

RxRx = [1, 0, 0;
    0, cosd(rollRx), -sind(rollRx);
    0, sind(rollRx),  cosd(rollRx)];

RyRx = [ cosd(pitchRx), 0, sind(pitchRx);
    0,             1, 0;
    -sind(pitchRx), 0, cosd(pitchRx)];

RzRx = [cosd(yawRx), -sind(yawRx), 0;
    sind(yawRx),  cosd(yawRx), 0;
    0,            0,           1];

RRx = RzRx * RyRx * RxRx;

% Eixo óptico do RX expresso nas coordenadas da sala.
nRx = RRx * n0Rx;

%---------------------- Caminho direto TX–RX ----------------------------

% Vetor do TX até o RX [m].
displacementTR_m = pRx - pTx;

% Distância entre TX e RX [m].
distance_m = norm(displacementTR_m);

% A direção fica indefinida se os dispositivos estiverem no mesmo ponto.
if distance_m == 0
    error('TX e RX devem estar em posições diferentes.');
end

% Vetor unitário do TX para o RX.
uTR = displacementTR_m / distance_m;

% Vetor unitário do RX para o TX.
uRT = -uTR;

%---------------------- Ângulos de emissão e incidência -----------------

% Ângulo entre o eixo óptico do TX e a direção TX → RX.
cosPhi = dot(nTx, uTR);

% Ângulo entre o eixo óptico do RX e a direção RX → TX.
cosPsi = dot(nRx, uRT);

% Proteção contra pequenos erros numéricos antes de aplicar acos.
cosPhi = max(-1, min(1, cosPhi));
cosPsi = max(-1, min(1, cosPsi));

% Ângulos em radianos.
phi_rad = acos(cosPhi);
psi_rad = acos(cosPsi);

geometry.RTx = RTx;
geometry.RRx = RRx;
geometry.nTx = nTx;
geometry.nRx = nRx;

geometry.displacementTR_m = displacementTR_m;
geometry.distance_m = distance_m;
geometry.uTR = uTR;

geometry.cosPhi = cosPhi;
geometry.cosPsi = cosPsi;
geometry.phi_rad = phi_rad;
geometry.psi_rad = psi_rad;

end