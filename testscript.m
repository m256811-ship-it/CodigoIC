%====================== Configuração do teste ===========================

params = getChannelParams();

% Posições [x; y; z], em metros.
params.tx.pose.position_m = [0; 0;  1.5];
params.rx.pose.position_m = [1; 0; -1.5];

% Rotações [roll; pitch; yaw], em graus.
params.tx.pose.rpy_deg = [0; 30; 0];
params.rx.pose.rpy_deg = [0;  0; 0];

% Direções de referência.
params.tx.referenceNormal = [0; 0; -1];
params.rx.referenceNormal = [0; 0;  1];

%====================== Cálculo da geometria ============================

geometry = calculateLOSGeometry(params);

fprintf('\n========== RESULTADOS CALCULADOS ==========\n');
disp(geometry);

fprintf('Phi: %.6f graus\n', rad2deg(geometry.phi_rad));
fprintf('Psi: %.6f graus\n', rad2deg(geometry.psi_rad));

%====================== Resultados esperados ===========================

% Inclinação do caminho em relação à vertical.
pathTilt_deg = atand(1/3);

expectedDistance_m = sqrt(10);
expectedUTR = [1; 0; -3] / sqrt(10);

expectedNTx = [-sind(30); 0; -cosd(30)];
expectedNRx = [0; 0; 1];

expectedPhi_deg = 30 + pathTilt_deg;
expectedPsi_deg = pathTilt_deg;

fprintf('\n========== RESULTADOS ESPERADOS ===========\n');
fprintf('Distância: %.6f m\n', expectedDistance_m);
fprintf('Phi: %.6f graus\n', expectedPhi_deg);
fprintf('Psi: %.6f graus\n', expectedPsi_deg);

%====================== Verificação automática =========================

tol = 1e-10;

assert(norm(geometry.displacementTR_m - [1; 0; -3]) < tol, ...
    'Deslocamento incorreto.');

assert(abs(geometry.distance_m - expectedDistance_m) < tol, ...
    'Distância incorreta.');

assert(norm(geometry.uTR - expectedUTR) < tol, ...
    'Direção TX → RX incorreta.');

assert(norm(geometry.nTx - expectedNTx) < tol, ...
    'Orientação do TX incorreta.');

assert(norm(geometry.nRx - expectedNRx) < tol, ...
    'Orientação do RX incorreta.');

assert(abs(geometry.cosPhi - cosd(expectedPhi_deg)) < tol, ...
    'Cosseno de phi incorreto.');

assert(abs(geometry.cosPsi - cosd(expectedPsi_deg)) < tol, ...
    'Cosseno de psi incorreto.');

assert(abs(geometry.phi_rad - deg2rad(expectedPhi_deg)) < tol, ...
    'Ângulo phi incorreto.');

assert(abs(geometry.psi_rad - deg2rad(expectedPsi_deg)) < tol, ...
    'Ângulo psi incorreto.');

fprintf('\nTeste de posição e rotação: APROVADO.\n');