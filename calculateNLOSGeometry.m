function paths = calculateNLOSGeometry(params, geometry, walls)
% CALCULATENLOSGEOMETRY Geometria dos caminhos com uma reflexão.
% Cada caminho segue: TX → centro do patch → RX.
%
% Vetores usados nos cálculos são colunas [3×1].

pTx = params.tx.pose.position_m;
pRx = params.rx.pose.position_m;

nTx = geometry.nTx;
nRx = geometry.nRx;

% Número total de caminhos candidatos.
nPaths = sum(arrayfun(@(wall) size(wall.points, 1), walls));

% Uma entrada por patch.
paths.distanceTxPatch_m = zeros(nPaths, 1);
paths.distancePatchRx_m = zeros(nPaths, 1);
paths.cosPhi = zeros(nPaths, 1);
paths.cosAlpha = zeros(nPaths, 1);
paths.cosBeta = zeros(nPaths, 1);
paths.cosPsi = zeros(nPaths, 1);
paths.area_m2 = zeros(nPaths, 1);
paths.reflectivity = zeros(nPaths, 1);
paths.wallIndex = zeros(nPaths, 1);

pathIndex = 0;

for k = 1:numel(walls)

    % Converte a normal da parede para vetor coluna.
    nWall = walls(k).normal.';

    for j = 1:size(walls(k).points, 1)

        pathIndex = pathIndex + 1;

        % Centro do patch como vetor coluna.
        pPatch = walls(k).points(j, :).';

        %---------------------- Distâncias ------------------------------

        displacementTxPatch = pPatch - pTx;
        displacementPatchRx = pRx - pPatch;

        d1 = norm(displacementTxPatch);
        d2 = norm(displacementPatchRx);

        if d1 == 0 || d2 == 0
            error('TX ou RX coincide com o centro de um patch.');
        end

        %---------------------- Direções unitárias ----------------------

        uTxPatch = displacementTxPatch / d1; % TX → patch
        uPatchRx = displacementPatchRx / d2; % Patch → RX

        %---------------------- Fatores angulares -----------------------

        cosPhi   = dot(nTx, uTxPatch);
        cosAlpha = dot(nWall, -uTxPatch); % Patch → TX
        cosBeta  = dot(nWall, uPatchRx);
        cosPsi   = dot(nRx, -uPatchRx);   % RX → patch

        % Limita apenas erros de arredondamento; preserva sinais.
        angularCosines = [cosPhi, cosAlpha, cosBeta, cosPsi];
        angularCosines = max(-1, min(1, angularCosines));

        %---------------------- Resultados ------------------------------

        paths.distanceTxPatch_m(pathIndex) = d1;
        paths.distancePatchRx_m(pathIndex) = d2;

        paths.cosPhi(pathIndex)   = angularCosines(1);
        paths.cosAlpha(pathIndex) = angularCosines(2);
        paths.cosBeta(pathIndex)  = angularCosines(3);
        paths.cosPsi(pathIndex)   = angularCosines(4);

        paths.area_m2(pathIndex) = walls(k).dA;
        paths.reflectivity(pathIndex) = walls(k).reflectivity;
        paths.wallIndex(pathIndex) = k;

    end
end

% Distância total percorrida por cada caminho refletido.
paths.totalDistance_m = ...
    paths.distanceTxPatch_m + paths.distancePatchRx_m;

end