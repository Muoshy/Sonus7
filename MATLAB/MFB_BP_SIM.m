%% Resistor value calculation and frequency response

clc, clear variables
% Using round63 lib from Stephen Cobeldick
addpath('./round63')

% Center frequencies, 1:2.5 ratio
fm = [63 160 400 1000 2500 6250 16000];

% Gain (negative due to inverting op-amp configuration)
gain_fm = -10; 

% Quality factor (~bandwidth)
Q = 6;

% Capacitor values
C = 1e-9*[33 33 6.8 2.2 2.2 0.33 0.33];

% E-series for choosing resistor values
E = 'E24';

for i=1:length(fm)
    % Generate filt structure to store values
    filt = struct();
    filt.fm = fm(i); 
    
    % Calculate resistor values based on specified parameters
    R2 = Q/(pi*fm(i)*C(i));
    R1 = R2/(-2*gain_fm);
    R3 = -gain_fm*R1/(2*Q^2 + gain_fm);
    
    filt.R1 = R1;
    filt.R2 = R2;
    filt.R3 = R3;
    
    % Calculate bandwidth
    bandwidth = 1/(pi*R2*C(i));
    
    % Calculate transfer function
    wm = 1/C(i) * sqrt((R1+R3)/(R1*R2*R3));
    num = [(-R2*R3)/(R1+R3)*C(i)*wm 0];
    denom = [(R1*R2*R3)/(R1+R3)*C(i)^2*wm^2, (2*R1*R3)/(R1+R3)*C(i)*wm, 1];
    filt.num = num;
    filt.denom = denom;
    
    %Plot frequency response
    figure(1)
    subplot(1,2,1)
    
    % Normalize frequency to fm
    % Transfer function assumes normalized frequency
    w = (0:1:1e5)/fm(i);
    
    % Evaluate transer function
    s = 1j*w;
    h = polyval(num,s)./polyval(denom,s);
    
    mag = 20*log10(abs(h));
    
    % Scale back frequency axis with fm,
    % since frequency was prev normalized to fm
    semilogx(w*fm(i), mag); hold on; 
    str = [num2str(fm(i)), ' Hz' ];
    xline(fm(i), '-.', str)
    yline(0,'--')
    
    % Find nearest resistor value in E-series 
    filt.R1_E = round63(R1, E);
    filt.R2_E = round63(R2, E);
    filt.R3_E = round63(R3, E);
    
    R1 = filt.R1_E;
    R2 = filt.R2_E;
    R3 = filt.R3_E;
    
    % Recalculate new parameters with E-series values
    fm_new = Q/(R2*pi*C(i));
    wm = 1/C(i) * sqrt((R1+R3)/(R1*R2*R3));
    num = [(-R2*R3)/(R1+R3)*C(i)*wm 0];
    denom = [(R1*R2*R3)/(R1+R3)*C(i)^2*wm^2, (2*R1*R3)/(R1+R3)*C(i)*wm, 1];
    filt.num_E = num;
    filt.denom_E = denom;
    
    filt.fm_E = fm_new;
    filt.gain_E = R2/(-2*R1);
    
    filters(i) = filt;
    
    % Plot frequency response for E-series
    subplot(1,2,2)
    w = (0:1:1e5)/fm_new;
    s = 1j*w;
    h = polyval(num,s)./polyval(denom,s);
    mag = 20*log10(abs(h));
    semilogx(w*fm_new, mag); hold on;
    str = [num2str(round(fm_new)), ' Hz' ];
    xline(fm_new, '-.', str)
    yline(0,'--')
end

% Add labels
subplot(1,2,1)
xlabel('frequency [Hz]')
ylabel('magnitude [dB]')
title('MFB Band-pass filter')
axis([10 1e5 -10 25])

subplot(1,2,2)
xlabel('frequency [Hz]')
ylabel('magnitude [dB]')
title(['MFB Band-pass filter ', E, ' series'])
axis([10 1e5 -10 25])

%% Gain bandwidth calculations
% Run after first section

% Calculate noise gain at center frequencies 
% Use noise gain to calculate gain bandwidth product

clc
gbw = 2e6;
opamp = "TLC272";

noise_gain = zeros(1,7);
for i = 1:length(fm)
    R1 = filters(i).R1_E;
    R2 = filters(i).R2_E;
    R3 = filters(i).R3_E;
    fm_new = filters(i).fm_E;
    
    num_NG =  [C(i)^2*R1*R2*R3, C(i)*R1*R2 + 2*C(i)*R1*R3 + C(i)*R2*R3, R1 + R3];
    denom_NG = [C(i)^2*R1*R2*R3, 2*C(i)*R1*R3, R1 + R3];
        
    s = 1j*2*pi*fm_new;
    
    noise_gain(i) = polyval(num_NG,s)./polyval(denom_NG,s);
   
    fprintf('Noise gain at %i Hz:\t\t %.2f \n', round(fm_new), noise_gain(i))
    fprintf('Gain bandwidth: \t\t\t %.2f \n', noise_gain(i)*fm_new)
    fprintf('Unity gain bandwidth %s: %.2f  \n \n', opamp, gbw)
end




