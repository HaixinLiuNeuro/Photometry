function [Result] = HL_FP_MMDAlesionData_analysis(tmp_data)

disp('FP channel names');
disp(tmp_data.acq.FPnames);
fprintf('Recording sampling rate: %i Hz\n', tmp_data.gen.acqFs);
% tmp_data.gen.params.FP

%{
%%
figure; a= [];
a(1)=subplot(2,1,1);
plot(tmp_data.acq.time, tmp_data.acq.FP{1});
title(tmp_data.acq.FPnames{1})
a(2)=subplot(2,1,2);
plot(tmp_data.acq.time, tmp_data.acq.FP{2});
title(tmp_data.acq.FPnames{2})
linkaxes(a, 'x')
%}
%% perform powerspectrum density calc in raw voltage
% addpath(genpath('R:\tritsn01lab\tritsn01labspace\Haixin\MATLAB\chronux_2_12'));

params.tapers = [2 3];
params.pad = 0; % default
params.Fs = tmp_data.gen.acqFs;
params.fpass = [0.1 30];

% tapers, pad, Fs, fpass, err, trialave
% bin freq: 0:0.1:30
f_bin = [0:0.1:30];
f_bin_x = f_bin(1:end-1)+0.05;
for i_p = 1:length(tmp_data.acq.FP)
    [S{i_p},f]=mtspectrumc(tmp_data.acq.FP{i_p},params);
    % for control signal to normalize to 
    % use the > 30 Hz hipass filtered signal as HF noise
    % use < 30Hz low pass filter signal to get baseline with exponetial
    % fitted decay (bleaching of F)
    % then add them together 
    
    LowPass = filterFP(tmp_data.acq.FP{i_p},tmp_data.gen.acqFs,30,10,'lowpass');
    HighPass = filterFP(tmp_data.acq.FP{i_p},tmp_data.gen.acqFs,30,10,'highpass');
    
    [~,F_baseline] = baselineFP(LowPass,'linear','exp',10,20,10,tmp_data.gen.acqFs);
    FP_control = F_baseline+HighPass;
    [S_one{i_p},f]=mtspectrumc(FP_control,params);
    X{i_p} = S{i_p};
    X_norm{i_p} = 10*(log10(X{i_p}) - log10(S_one{i_p}));
    
    X{i_p}=10*log10(X{i_p}); % dB
    
    for i_b = 1:(length(f_bin)-1)
        X_bin{i_p}(i_b)=nanmean(X{i_p}(f>f_bin(i_b) & f<f_bin(i_b+1)));        
        X_norm_bin{i_p}(i_b) = nanmean(X_norm{i_p}(f>f_bin(i_b) & f<f_bin(i_b+1)));        
    end
end
% f

%{
%%
figure;
plot(f_bin_x,X_norm_bin{1},'b' );
hold on;
plot(f_bin_x,X_norm_bin{2}, 'r' );
ylabel('Normalized Power (a.u.)');


figure;
plot(f_bin_x,X_bin{1},'b' );
hold on;
plot(f_bin_x,X_bin{2}, 'r' );

%}
ylabel('Power (dB)');

%%
% rmpath(genpath('R:\tritsn01lab\tritsn01labspace\Haixin\MATLAB\chronux_2_12'));


%% return result 
Result = [];
Result.f_bin_x = f_bin_x;
Result.X_bin = X_bin;
Result.X_norm_bin = X_norm_bin;
Result.f_bin = f_bin;
Result.params = params;
Result.FPnames = tmp_data.acq.FPnames;
% Result. = ;
