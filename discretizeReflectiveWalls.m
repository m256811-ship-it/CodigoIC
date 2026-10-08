function walls = discretizeReflectiveWalls(params, numerical)
% DISCRETIZEREFLECTIVEWALLS Divide as quatro paredes laterais em patches.
%
% Sala centrada na origem:
%   x = [-L/2, +L/2]
%   y = [-W/2, +W/2]
%   z = [-H/2, +H/2]
%
% Saída por parede:
%   name         : identificação da parede
%   points       : centros dos patches, uma linha [x y z] por patch [m]
%   normal       : normal unitária voltada para dentro da sala [1×3]
%   dA           : área de cada patch dessa parede [m²]
%   reflectivity : refletividade da parede

%---------------------- Entradas ----------------------------------------

L = params.room.length_m;
W = params.room.width_m;
H = params.room.height_m;

rho = params.room.wallReflectivity;
ppm = numerical.patchesPerMeter;

validateattributes(L, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});
validateattributes(W, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});
validateattributes(H, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});
validateattributes(ppm, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});
validateattributes(rho, {'numeric'}, ...
    {'vector', 'numel', 4, 'real', 'finite', '>=', 0, '<=', 1});

%---------------------- Número de divisões ------------------------------

Nx = ceil(L * ppm);
Ny = ceil(W * ppm);
Nz = ceil(H * ppm);

%---------------------- Dimensões dos patches ---------------------------

dx = L / Nx;
dy = W / Ny;
dz = H / Nz;

%---------------------- Centros dos patches -----------------------------

xCenters = -L/2 + ((0:Nx-1) + 0.5) * dx;
yCenters = -W/2 + ((0:Ny-1) + 0.5) * dy;
zCenters = -H/2 + ((0:Nz-1) + 0.5) * dz;

%---------------------- Parede xMin -------------------------------------

[Y, Z] = meshgrid(yCenters, zCenters);

walls(1).name = 'xMin';
walls(1).points = [-L/2 * ones(numel(Y), 1), Y(:), Z(:)];
walls(1).normal = [1, 0, 0];
walls(1).dA = dy * dz;
walls(1).reflectivity = rho(1);

%---------------------- Parede xMax -------------------------------------

walls(2).name = 'xMax';
walls(2).points = [L/2 * ones(numel(Y), 1), Y(:), Z(:)];
walls(2).normal = [-1, 0, 0];
walls(2).dA = dy * dz;
walls(2).reflectivity = rho(2);

%---------------------- Parede yMin -------------------------------------

[X, Z] = meshgrid(xCenters, zCenters);

walls(3).name = 'yMin';
walls(3).points = [X(:), -W/2 * ones(numel(X), 1), Z(:)];
walls(3).normal = [0, 1, 0];
walls(3).dA = dx * dz;
walls(3).reflectivity = rho(3);

%---------------------- Parede yMax -------------------------------------

walls(4).name = 'yMax';
walls(4).points = [X(:), W/2 * ones(numel(X), 1), Z(:)];
walls(4).normal = [0, -1, 0];
walls(4).dA = dx * dz;
walls(4).reflectivity = rho(4);

end