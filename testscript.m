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

params = getChannelParams();
numerical.patchesPerMeter = 10;

walls = discretizeReflectiveWalls(params, numerical);

totalPatches = 0;
totalArea_m2 = 0;

for k = 1:numel(walls)
    count = size(walls(k).points, 1);
    wallArea_m2 = count * walls(k).dA;

    fprintf('%s: %d patches | dA = %.4f m² | área = %.2f m²\n', ...
        walls(k).name, count, walls(k).dA, wallArea_m2);

    totalPatches = totalPatches + count;
    totalArea_m2 = totalArea_m2 + wallArea_m2;
end

fprintf('\nTotal: %d patches | área total = %.2f m²\n', ...
    totalPatches, totalArea_m2);

params = getChannelParams();

numerical.patchesPerMeter = 5;

geometry = calculateLOSGeometry(params);
walls = discretizeReflectiveWalls(params, numerical);

paths = calculateNLOSGeometry(params, geometry, walls);

fprintf('Caminhos refletidos candidatos: %d\n', ...
    numel(paths.totalDistance_m));

fprintf('Menor distância refletida: %.6f m\n', ...
    min(paths.totalDistance_m));

fprintf('Maior distância refletida: %.6f m\n', ...
    max(paths.totalDistance_m));
%====================== Configuração padrão =============================

params = getChannelParams();

params.room.length_m = 2;
params.room.width_m = 2;
params.room.height_m = 3;

params.tx.pose.position_m = [0; 0;  1.5];
params.rx.pose.position_m = [0; 0; -1.5];

params.tx.pose.rpy_deg = [0; 0; 0];
params.rx.pose.rpy_deg = [0; 0; 0];

params.tx.referenceNormal = [0; 0; -1];
params.rx.referenceNormal = [0; 0;  1];

params.rx.fov_rad = pi/2;

numerical.patchesPerMeter = 5;

geometry = calculateLOSGeometry(params);
walls = discretizeReflectiveWalls(params, numerical);
paths = calculateNLOSGeometry(params, geometry, walls);

tol = 1e-10;

%====================== Seleção de um patch =============================

% Localiza a parede xMax.
k = find(strcmp({walls.name}, 'xMax'), 1);

% Seleciona o patch mais próximo do centro da parede.
targetPoint = [1, 0, 0];

squaredDistances = sum((walls(k).points - targetPoint).^2, 2);
[~, j] = min(squaredDistances);

% Converte o índice local para o índice global do caminho.
offset = 0;

for wallIndex = 1:k-1
    offset = offset + size(walls(wallIndex).points, 1);
end

pathIndex = offset + j;

fprintf('\nCentro do patch selecionado [m]:\n');
disp(walls(k).points(j, :).');

%====================== Comparação analítica ============================

% O patch selecionado está em [1; ±0.1; 0].
expectedDistance = sqrt(1^2 + 0.1^2 + 1.5^2);

expected = [ ...
    1.5 / expectedDistance;
    1.0 / expectedDistance;
    1.0 / expectedDistance;
    1.5 / expectedDistance];

calculated = [ ...
    paths.cosPhi(pathIndex);
    paths.cosAlpha(pathIndex);
    paths.cosBeta(pathIndex);
    paths.cosPsi(pathIndex)];

factor = ["cosPhi"; "cosAlpha"; "cosBeta"; "cosPsi"];

disp(table(factor, calculated, expected));

assert(abs(paths.distanceTxPatch_m(pathIndex) ...
    - expectedDistance) < tol, ...
    'Distância TX → patch incorreta.');

assert(abs(paths.distancePatchRx_m(pathIndex) ...
    - expectedDistance) < tol, ...
    'Distância patch → RX incorreta.');

assert(all(abs(calculated - expected) < tol), ...
    'Fatores angulares diferentes dos valores esperados.');

%====================== Todos os caminhos ===============================

assert(numel(paths.totalDistance_m) == 600, ...
    'Número de caminhos diferente de 600.');

allCosines = [paths.cosPhi, paths.cosAlpha, ...
              paths.cosBeta, paths.cosPsi];

assert(all(isfinite(allCosines(:))), ...
    'Existem fatores angulares não finitos.');

assert(all(abs(allCosines(:)) <= 1), ...
    'Existem cossenos fora de [-1, 1].');

% Nesta configuração, todos os fatores devem ser positivos.
assert(all(allCosines(:) > 0), ...
    'Há um fator angular não positivo na configuração padrão.');

%====================== Distâncias perpendiculares ======================

% cosAlpha e cosBeta não precisam ser iguais.
% Seus produtos pelas respectivas distâncias devem resultar na
% distância perpendicular de cada dispositivo à parede.

perpendicularDistanceTx = ...
    paths.cosAlpha .* paths.distanceTxPatch_m;

perpendicularDistanceRx = ...
    paths.cosBeta .* paths.distancePatchRx_m;

% Nesta configuração, TX e RX estão a 1 m de todas as paredes.
assert(all(abs(perpendicularDistanceTx - 1) < tol), ...
    'Distância perpendicular do TX à parede incorreta.');

assert(all(abs(perpendicularDistanceRx - 1) < tol), ...
    'Distância perpendicular do RX à parede incorreta.');

%====================== Comprimentos dos caminhos =======================

assert(all(isfinite(paths.totalDistance_m)), ...
    'Existem comprimentos de caminho não finitos.');

assert(all(paths.totalDistance_m >= geometry.distance_m - tol), ...
    'Um caminho refletido ficou menor que o caminho direto.');

%====================== Aceitação pelo receptor =========================

psi_rad = acos(paths.cosPsi);

isAccepted = ...
    (paths.cosPhi > 0) & ...
    (paths.cosAlpha > 0) & ...
    (paths.cosBeta > 0) & ...
    (paths.cosPsi > 0) & ...
    (psi_rad <= params.rx.fov_rad);

fprintf('Caminhos aceitos: %d de %d\n', ...
    nnz(isAccepted), numel(isAccepted));

assert(all(isAccepted), ...
    'Esperávamos todos os caminhos aceitos com FOV de 90 graus.');

%====================== Resumo ==========================================

fprintf('Menor distância refletida: %.6f m\n', ...
    min(paths.totalDistance_m));

fprintf('Maior distância refletida: %.6f m\n', ...
    max(paths.totalDistance_m));

fprintf('\nVerificação da geometria NLOS: APROVADA.\n');