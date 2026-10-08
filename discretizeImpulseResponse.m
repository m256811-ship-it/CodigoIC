function channel = discretizeImpulseResponse(los, nlos, numerical)
% DISCRETIZEIMPULSERESPONSE Discretiza o canal por distribuição linear.
%
% Entradas:
%   los.gain,  nlos.gain    : ganhos ópticos dos caminhos
%   los.delay_s, nlos.delay_s : atrasos exatos [s]
%   numerical.timeStep_s    : espaçamento temporal [s]
%   numerical.maxDelay_s    : atraso máximo representado [s]
%
% Saídas:
%   t_s      : grade de atrasos [s]
%   hLOS     : pesos discretos LOS
%   hNLOS    : pesos discretos NLOS
%   hWeights : soma de LOS e NLOS
%   dcGain   : soma dos pesos discretos
%
% Os pesos são adimensionais. Não há normalização do ganho.

dt = numerical.timeStep_s;
tMax = numerical.maxDelay_s;

validateattributes(dt, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});

validateattributes(tMax, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});

% Exige que o fim da janela coincida com um ponto da grade.
nIntervals = round(tMax / dt);

if abs(tMax / dt - nIntervals) > 1e-10
    error('maxDelay_s deve ser um múltiplo de timeStep_s.');
end

% Grade iniciada no instante de emissão.
t_s = (0:nIntervals).' * dt;

% Distribui separadamente as contribuições LOS e NLOS.
hLOS = distributePaths(los.gain, los.delay_s, dt, nIntervals);
hNLOS = distributePaths(nlos.gain, nlos.delay_s, dt, nIntervals);

channel.t_s = t_s;
channel.hLOS = hLOS;
channel.hNLOS = hNLOS;
channel.hWeights = hLOS + hNLOS;
channel.dcGain = sum(channel.hWeights);

end


function h = distributePaths(gains, delays_s, dt, nIntervals)
% DISTRIBUTEPATHS Acumula os ganhos nos pontos temporais vizinhos.

validateattributes(gains, {'numeric'}, ...
    {'real', 'finite', 'nonnegative'});

validateattributes(delays_s, {'numeric'}, ...
    {'real', 'finite', 'nonnegative'});

% Padroniza as entradas como vetores coluna.
gains = gains(:);
delays_s = delays_s(:);

if numel(gains) ~= numel(delays_s)
    error('Cada ganho deve possuir um atraso correspondente.');
end

h = zeros(nIntervals + 1, 1);

for j = 1:numel(gains)

    % Caminhos de ganho zero não contribuem.
    if gains(j) == 0
        continue;
    end

    % Atraso expresso em número de intervalos temporais.
    q = delays_s(j) / dt;

    % Corrige apenas arredondamentos próximos de pontos exatos da grade.
    nearestInteger = round(q);
    if abs(q - nearestInteger) <= 32 * eps(max(1, abs(q)))
        q = nearestInteger;
    end

    % Evita descartar contribuições fora da janela silenciosamente.
    if q > nIntervals
        error(['Um caminho com ganho positivo está fora da janela. ' ...
               'Aumente numerical.maxDelay_s.']);
    end

    k = floor(q);
    alpha = q - k;

    % Índice MATLAB correspondente ao ponto temporal k*dt.
    idx = k + 1;

    h(idx) = h(idx) + gains(j) * (1 - alpha);

    % Se o atraso coincide com um ponto da grade, alpha = 0.
    if alpha > 0
        h(idx + 1) = h(idx + 1) + gains(j) * alpha;
    end

end

end