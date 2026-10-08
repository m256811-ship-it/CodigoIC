% PLOTCHANNELIMPULSERESPONSE
% Resposta ao impulso do canal óptico VLC.

clearvars;
close all;
clc;

%---------------------- Configurações -----------------------------------

params = getChannelParams();
numerical = getNumericalSettings();

% Para testar outras posições ou rotações, altere params aqui,
% antes de calcular a geometria.

%---------------------- Cálculo do canal --------------------------------

geometry = calculateLOSGeometry(params);
walls = discretizeReflectiveWalls(params, numerical);

los = calculateLOSChannel(params, geometry);
nlos = calculateNLOSChannel(params, geometry, walls);

channel = discretizeImpulseResponse(los, nlos, numerical);

%---------------------- Informações -------------------------------------

fprintf('Número de taps: %d\n', numel(channel.t_s));
fprintf('Passo temporal: %.3f ns\n', numerical.timeStep_s * 1e9);
fprintf('Atraso LOS: %.6f ns\n', los.delay_s * 1e9);
fprintf('Ganho LOS: %.8e\n', los.gain);
fprintf('Ganho NLOS: %.8e\n', nlos.dcGain);
fprintf('Ganho total: %.8e\n', channel.dcGain);

%---------------------- Gráficos ----------------------------------------

t_ns = channel.t_s * 1e9;

figure('Color', 'w');

subplot(3, 1, 1);
stem(t_ns, channel.hWeights, 'filled');
title('Resposta ao impulso — LOS + NLOS');
ylabel('Peso [adimensional]');
grid on;
xlim([0, numerical.maxDelay_s * 1e9]);

subplot(3, 1, 2);
stem(t_ns, channel.hLOS, 'filled');
title('Contribuição LOS');
ylabel('Peso [adimensional]');
grid on;
xlim([0, numerical.maxDelay_s * 1e9]);

subplot(3, 1, 3);
stem(t_ns, channel.hNLOS, 'filled');
title('Contribuição NLOS — uma reflexão');
xlabel('Atraso de propagação [ns]');
ylabel('Peso [adimensional]');
grid on;
xlim([0, numerical.maxDelay_s * 1e9]);
