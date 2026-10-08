function numerical = getNumericalSettings()
% GETNUMERICALSETTINGS Define os parâmetros de discretização do canal.
%
% Estes parâmetros controlam a aproximação numérica,
% não as propriedades físicas do ambiente ou dos dispositivos.

%---------------------- Discretização espacial --------------------------

% Número alvo de subdivisões por metro nas paredes.
% Com ceil, cada lado do patch será <= 1/patchesPerMeter.
numerical.patchesPerMeter = 5;

%---------------------- Discretização temporal --------------------------

numerical.timeStep_s = 0.5e-9; % Espaçamento da grade temporal [s]
numerical.maxDelay_s = 40e-9;  % Atraso máximo da janela temporal [s]

end