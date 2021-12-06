% function [WS_trial] = HL_WS_ParseStiLib_DispMAPs(StiLib);
%   to parse the WS stim lib to get used MAPs disp the info and store in
%   WS_trial 
% call: HL_FP_parseWSStiLib.m
% dependency: Photometry

%%
function [WS_trial] = HL_WS_ParseStiLib_DispMAPs(StiLib)
[WS_trial, ~, ~] = HL_FP_parseWSStiLib(StiLib);
% disp WS Maps
for i_m = 1:length(WS_trial.type)
    fprintf('MAP name: %s\n', WS_trial.type{i_m});
    if ~ischar(WS_trial.ChannelName{i_m}) % multiple channels
        for i_ch = 1:length(WS_trial.ChannelName{i_m})
            fprintf('  Ch name: %s. Stim name: %s. Stim Params:\n', WS_trial.ChannelName{i_m}{i_ch}, WS_trial.Stim_name{i_m}{i_ch});
            disp(WS_trial.Stim_params{i_m}{i_ch});
            
        end
    else
        i_ch = 1;
        fprintf('  Ch name: %s. Stim name: %s. Stim Params:\n', WS_trial.ChannelName{i_m}, WS_trial.Stim_name{i_m}{i_ch});
        disp(WS_trial.Stim_params{i_m}{i_ch});
        
    end
end