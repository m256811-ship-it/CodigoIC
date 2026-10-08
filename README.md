# Modelo de canal óptico VLC — LOS e NLOS

Este projeto calcula a resposta ao impulso de um canal óptico VLC a partir das posições e orientações do transmissor (TX) e do receptor (RX), das características ópticas dos dispositivos e das reflexões nas quatro paredes laterais de uma sala retangular.

O modelo preserva os ganhos físicos e os atrasos de propagação. Modulação, demodulação, ruído e codificação não fazem parte desta etapa.

## Hipóteses do modelo

- Um transmissor com emissão Lambertiana.
- Receptor com filtro óptico de transmissão constante e concentrador ideal.
- Sala retangular centrada na origem.
- Quatro paredes laterais com reflexão difusa Lambertiana.
- Caminhos LOS e NLOS com uma única reflexão.
- Piso e teto sem contribuições refletidas.
- Ausência de obstruções nos caminhos.
- Posições e orientações fixas durante cada cálculo do canal.
- Velocidade de propagação constante.

## Organização das funções

| Arquivo | Responsabilidade |
|---|---|
| `getChannelParams.m` | Define parâmetros físicos, posições, rotações e direções ópticas de referência |
| `getNumericalSettings.m` | Define resolução espacial, passo temporal e janela de atrasos |
| `calculateLOSGeometry.m` | Calcula rotações, eixos ópticos e geometria do caminho direto |
| `calculateLOSChannel.m` | Calcula ganho e atraso LOS |
| `discretizeReflectiveWalls.m` | Divide as paredes laterais em patches |
| `calculateNLOSGeometry.m` | Calcula distâncias e fatores angulares dos caminhos refletidos |
| `calculateNLOSChannel.m` | Calcula ganhos e atrasos dos caminhos com uma reflexão |
| `discretizeImpulseResponse.m` | Distribui os ganhos na grade temporal pelo método linear |
| `calculateReceivedPowerMap.m` | Calcula a potência recebida em uma grade de posições do RX |
| `testReceivedPowerMap.m` | Verifica e plota a distribuição espacial de potência |

## Parâmetros físicos

Os parâmetros são definidos em `getChannelParams`.

| Campo | Significado |
|---|---|
| `tx.halfPowerAngle_deg` | Semiângulo de meia potência do LED [graus] |
| `rx.area_m2` | Área efetiva do fotodetector [m²] |
| `rx.fov_rad` | Semiângulo do campo de visão do RX [rad] |
| `rx.filterTransmission` | Transmissão do filtro óptico [adimensional] |
| `rx.refractiveIndex` | Índice de refração usado no concentrador ideal |
| `room.length_m` | Dimensão da sala no eixo x [m] |
| `room.width_m` | Dimensão da sala no eixo y [m] |
| `room.height_m` | Dimensão da sala no eixo z [m] |
| `room.wallReflectivity` | Refletividades na ordem xMin, xMax, yMin, yMax |
| `lightSpeed_m_s` | Velocidade de propagação [m/s] |

A potência transmitida é definida no experimento. Ela não é necessária para calcular os ganhos do canal.

## Posição e orientação

A origem está no centro da sala. As posições dos dispositivos são vetores coluna:

    params.tx.pose.position_m = [x; y; z];
    params.rx.pose.position_m = [x; y; z];

As rotações seguem a ordem:

    params.tx.pose.rpy_deg = [roll; pitch; yaw];
    params.rx.pose.rpy_deg = [roll; pitch; yaw];

A transformação do sistema local do dispositivo para o sistema da sala usa:

    R = Rz(yaw) * Ry(pitch) * Rx(roll);

Os eixos ópticos são calculados por:

    nTx = RTx * params.tx.referenceNormal;
    nRx = RRx * params.rx.referenceNormal;

As direções de referência devem ser unitárias. Na configuração padrão:

    params.tx.referenceNormal = [0; 0; -1];
    params.rx.referenceNormal = [0; 0;  1];

Assim, com rotação zero, o TX aponta para baixo e o RX para cima.

## Cálculo LOS

`calculateLOSGeometry` calcula:

- Matrizes de rotação de TX e RX.
- Eixos ópticos rotacionados.
- Deslocamento e distância entre os dispositivos.
- Direção unitária TX → RX.
- Cossenos e ângulos de emissão e incidência.

`calculateLOSChannel` usa essa geometria para calcular o ganho óptico.

O caminho contribui quando está na frente do TX, incide na face sensível do RX e está dentro do campo de visão.

O atraso é a distância direta dividida pela velocidade de propagação.

Saídas principais:

    los.gain
    los.delay_s
    los.isAccepted
    los.lambertianOrder

O ganho é adimensional; o atraso é dado em segundos.

## Discretização das paredes

`discretizeReflectiveWalls` divide cada parede em patches retangulares.

O número de divisões é calculado com `ceil`, de modo que cada lado do patch seja no máximo:

    1 / numerical.patchesPerMeter

Cada parede retorna:

    walls(k).name
    walls(k).points
    walls(k).normal
    walls(k).dA
    walls(k).reflectivity

Cada linha de `points` contém o centro de um patch, em metros.

As normais apontam para dentro da sala:

| Parede | Normal |
|---|---|
| xMin | `[1, 0, 0]` |
| xMax | `[-1, 0, 0]` |
| yMin | `[0, 1, 0]` |
| yMax | `[0, -1, 0]` |

Os centros são usados como pontos representativos das áreas dos patches.

## Cálculo NLOS

`calculateNLOSChannel` chama `calculateNLOSGeometry`.

Para cada patch, o caminho é:

    TX → patch → RX

São calculados:

- Distância TX → patch.
- Distância patch → RX.
- Fator angular de emissão do TX.
- Fator angular de incidência na parede.
- Fator angular de saída da parede.
- Fator angular de incidência no RX.

O ganho inclui as duas distâncias, os quatro fatores angulares, a área do patch, a refletividade e as características ópticas do receptor.

Caminhos com fatores angulares não positivos ou fora do FOV recebem ganho zero.

O atraso corresponde à soma dos dois segmentos dividida pela velocidade de propagação.

Saídas:

    nlos.gain
    nlos.delay_s
    nlos.isAccepted
    nlos.dcGain
    nlos.wallIndex

Cada elemento de `gain` corresponde ao elemento de mesmo índice em `delay_s`.

## Discretização temporal

`getNumericalSettings` define:

    numerical.patchesPerMeter
    numerical.timeStep_s
    numerical.maxDelay_s

`discretizeImpulseResponse` constrói uma grade iniciada em zero e distribui cada ganho entre os dois pontos vizinhos do atraso exato.

Se o atraso coincide com um ponto da grade, todo o ganho é colocado nesse ponto.

Contribuições de caminhos diferentes são somadas quando ocupam os mesmos taps.

A distribuição linear preserva:

- A soma dos ganhos.
- O atraso médio ponderado pelos ganhos.

Ela introduz uma pequena dispersão numérica para chegadas entre pontos da grade. Essa dispersão diminui com o refinamento temporal.

A função não remove zeros nem normaliza os ganhos. Um caminho com ganho positivo fora da janela gera erro.

`maxDelay_s` deve ser múltiplo de `timeStep_s`.

Saídas:

    channel.t_s
    channel.hLOS
    channel.hNLOS
    channel.hWeights
    channel.dcGain

`hWeights` contém pesos adimensionais:

    channel.hWeights = channel.hLOS + channel.hNLOS;
    channel.dcGain = sum(channel.hWeights);

Os atrasos absolutos são preservados.

## Como gerar a resposta ao impulso

    params = getChannelParams();
    numerical = getNumericalSettings();

    % Alterações do experimento devem ocorrer antes dos cálculos.
    params.rx.pose.rpy_deg = [0; 0; 0];

    geometry = calculateLOSGeometry(params);
    walls = discretizeReflectiveWalls(params, numerical);

    los = calculateLOSChannel(params, geometry);
    nlos = calculateNLOSChannel(params, geometry, walls);

    channel = discretizeImpulseResponse(los, nlos, numerical);

    figure;
    stem(channel.t_s * 1e9, channel.hWeights, 'filled');
    xlabel('Atraso de propagação [ns]');
    ylabel('Peso do canal [adimensional]');
    title('Resposta ao impulso — LOS + NLOS');
    grid on;

As funções de cálculo recebem os parâmetros do experimento. Elas não devem recarregar os defaults internamente.

Se a orientação mudar, a geometria deve ser recalculada. Se a sala ou a resolução espacial mudar, as paredes também devem ser recalculadas.

## Distribuição espacial de potência

`calculateReceivedPowerMap` percorre uma grade de posições do RX em um plano horizontal.

O TX e as orientações permanecem fixos. Apenas a posição x e y do RX varia.

Para potência óptica transmitida constante:

    receivedPower_W = transmittedPower_W * totalChannelGain;

O ganho total é:

    totalChannelGain = los.gain + nlos.dcGain;

Não é necessário construir a resposta temporal para esse cálculo.

A grade de posições do RX é independente dos patches das paredes:

- Mais posições do RX refinam o mapa.
- Mais patches refinam a aproximação das reflexões.

Exemplo:

    params = getChannelParams();
    numerical = getNumericalSettings();

    transmittedPower_W = 20e-3;
    rxHeight_m = -params.room.height_m/2;

    map = calculateReceivedPowerMap(params, numerical, ...
        transmittedPower_W, rxHeight_m, 21, 21, 0.05);

    figure;
    surf(map.X_m, map.Y_m, map.receivedPower_W * 1e6);
    xlabel('Posição x do RX [m]');
    ylabel('Posição y do RX [m]');
    zlabel('Potência óptica recebida [µW]');
    title('Optical power distribution of VLC — LOS + NLOS');
    colorbar;
    grid on;

Para executar o exemplo completo com verificações:

    testReceivedPowerMap

## Verificações realizadas

Na configuração central de uma sala de 2 × 2 × 3 m, com dispositivos alinhados e 5 subdivisões por metro:

- São gerados 600 patches.
- Os fatores angulares de um patch selecionado coincidem com os valores analíticos.
- As distâncias perpendiculares às paredes são consistentes.
- Os caminhos refletidos são mais longos que o caminho direto.
- Os 600 caminhos são aceitos com FOV de 90°.

Também foi construída a resposta temporal com passo de 0.5 ns e janela de 40 ns, resultando em 81 taps.

Essas verificações cobrem exemplos específicos. Não constituem uma validação completa para todas as posições e orientações.

## Uso posterior em um sistema de comunicação

O canal pode ser aplicado a uma forma de onda de potência óptica:

    receivedPower_W = conv(transmittedPower_W, channel.hWeights);

A forma de onda e o canal devem usar o mesmo passo temporal.

Não se multiplica essa convolução por `timeStep_s`, pois `hWeights` já contém os pesos integrados dos impulsos.

Para recuperar dados, ainda será necessário definir:

- Modulação e formato de pulso.
- Período de símbolo.
- Conversão óptico-elétrica.
- Ruído e processamento do receptor.
- Sincronização e demodulação.

O passo temporal do canal não é o período de símbolo.
