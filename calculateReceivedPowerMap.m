function map = calculateReceivedPowerMap(params, numerical, ...
    transmittedPower_W, rxHeight_m, nPointsX, nPointsY, margin_m)
% CALCULATERECEIVEDPOWERMAP Calcula a distribuição de potência óptica.
%
% Entradas:
%   params             : parâmetros físicos e poses dos dispositivos
%   numerical          : configurações de discretização
%   transmittedPower_W : potência óptica constante do TX [W]
%   rxHeight_m         : coordenada z do plano de avaliação [m]
%   nPointsX, nPointsY : número de posições do RX em cada direção
%   margin_m           : distância da grade às paredes laterais [m]
%
% O TX e as orientações permanecem fixos.
% Apenas as coordenadas x e y do RX variam.

L = params.room.length_m;
W = params.room.width_m;
H = params.room.height_m;

validateattributes(transmittedPower_W, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});

validateattributes(nPointsX, {'numeric'}, ...
    {'scalar', 'integer', '>=', 2});

validateattributes(nPointsY, {'numeric'}, ...
    {'scalar', 'integer', '>=', 2});

validateattributes(margin_m, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});

validateattributes(rxHeight_m, {'numeric'}, ...
    {'scalar', 'real', 'finite'});

if 2 * margin_m >= min(L, W)
    error('A margem deve ser menor que metade de cada dimensão lateral.');
end

if rxHeight_m < -H/2 || rxHeight_m > H/2
    error('O plano de avaliação deve estar dentro da altura da sala.');
end

%---------------------- Grade de posições do RX -------------------------

xPositions = linspace(-L/2 + margin_m, L/2 - margin_m, nPointsX);
yPositions = linspace(-W/2 + margin_m, W/2 - margin_m, nPointsY);

[X, Y] = meshgrid(xPositions, yPositions);

gainLOS = zeros(size(X));
gainNLOS = zeros(size(X));

% As paredes são discretizadas uma única vez.
walls = discretizeReflectiveWalls(params, numerical);

%---------------------- Canal em cada posição ---------------------------

for row = 1:size(X, 1)
    for col = 1:size(X, 2)

        params.rx.pose.position_m = ...
            [X(row, col); Y(row, col); rxHeight_m];

        geometry = calculateLOSGeometry(params);

        los = calculateLOSChannel(params, geometry);
        nlos = calculateNLOSChannel(params, geometry, walls);

        gainLOS(row, col) = los.gain;
        gainNLOS(row, col) = nlos.dcGain;

    end
end

%---------------------- Resultados --------------------------------------

map.X_m = X;
map.Y_m = Y;
map.rxHeight_m = rxHeight_m;

map.gainLOS = gainLOS;
map.gainNLOS = gainNLOS;
map.dcGain = gainLOS + gainNLOS;

map.powerLOS_W = transmittedPower_W * gainLOS;
map.powerNLOS_W = transmittedPower_W * gainNLOS;
map.receivedPower_W = map.powerLOS_W + map.powerNLOS_W;

end