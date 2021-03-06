% function [Result] = HL_FP_Process_Stim_CW_inputData(ses_data, FP_ch_name, Stim_ch_name, stimulus_length, auto_baseline)
% function to process WS data get dF/F, and get Stimulus timing and types
% for next step analysis
% it uses several helper function and pipeline Pratik wrote
% now it works for continues imaging session or single sweep imaging session
% Stim_ch_name: for HL rig Blue_ctx or RED_LED
%
%
%   OUTPUT:
%         Info.
%               
%         Result.ts_ds = ts_ds;
%         Result.df_F_ds = df_F_ds;
%         Result.FP_clean_inpaint = FP_clean_inpaint;
%         Result.df_F = df_F; % without downsampling, F_baseline, FP_filter
%         Result.F_baseline = F_baseline; % F0 without downsampling
%         Result.FP_filter = FP_filter; % raw data after filter
%         Result.Stim_ts = Stim_ts;
%         Result.trial_label = trial_label;
%         Result.trial_type = trial_type;
%         Result.idx_byTrialType = idx_byTrialType;
%   
%         WS_data. 
% 
% 
% Function dependency:
%   HL_FP_loadWS_parseData.m
%   HL_FP_parseWSStiLib.m
%   HL_FP_CleanStiArtiFact.m
%   inpaint_nans.m
%   HL_FP_df_cw.m
%   HL_FP_GenerateTrialTypeIndex.m
% status: complete
% Haixin Liu 2019-9
function [Result] = HL_FP_Process_Stim_CW_inputData(ses_data, FP_ch_name, Stim_ch_name, stimulus_length, auto_baseline)
%% default paramters
if nargin < 2
   FP_ch_name = 'FP1';
   Stim_ch_name = 'Blue_Ctx';
   stimulus_length = 500;
   auto_baseline = 0;
elseif nargin >1 && nargin < 5
    help HL_FP_Process_Stim_CW_inputData
    error('input number not matched')
end

fprintf(2,'Channel name used:\nFP ch: %s; Stim ch:%s\n', FP_ch_name,Stim_ch_name);

idx_Cstim_ch = find(cellfun(@(x) contains(x,Stim_ch_name), ses_data.ch_names));
idx_FP_ch = find(cellfun(@(x) contains(x,FP_ch_name), ses_data.ch_names));

%% load and parse data
% ses_data = HL_FP_loadWS_parseData(ses_fn);
% [DATA] = HL_FP_loadWS_parseData(fn) HL_loadWS_parseData_Csti_FP1ch
if ischar(auto_baseline) % if is a file name
if ~strcmp(auto_baseline, ' ')  && any(strfind(auto_baseline, '.h5'))
    baseline_ses_data = HL_FP_loadWS_parseData(auto_baseline);
else
    fprintf('baselie file name: %s\nUse 0 as baseline value\n', auto_baseline);
    baseline_ses_data = [];%load();
end
% process them
% idx_FP_ch = find(cellfun(@(x) contains(x,FP_ch_name), ses_data.ch_names));
if isempty(baseline_ses_data)
    auto_baseline = 0;
    sys_noise_est = NaN;
else
    auto_baseline= nanmedian(baseline_ses_data.ch_data(:,idx_FP_ch));
    sys_noise_est = nanstd(baseline_ses_data.ch_data(:,idx_FP_ch));
end
else % input is a number
    
    
end
[WS_trial, ~, ~] = HL_FP_parseWSStiLib(ses_data.StiLib); % HL_WS_parseStiLib
disp('Ch names');disp(ses_data.ch_names);
% idx_Cstim_ch = find(cellfun(@(x) contains(x,Stim_ch_name), ses_data.ch_names));
%     idx_Bitcode_ch = find(cellfun(@(x) contains(x,'Bitcode'), ses_data.ch_names));
%% 
% need to add in component to select multiple channels and the revise the
% HL_FP_CleanStiArtiFact.m function to make clean FP
if isfield (ses_data, 'WS_Stim_Thred')
[FP_clean, Thred, n_trial] = HL_FP_CleanStiArtiFact(ses_data.ch_data(:,idx_FP_ch),ses_data.ch_data(:,idx_Cstim_ch),ses_data.sr, ses_data.WS_Stim_Thred); % HL_cleanFP_StiArtiF
else
[FP_clean, Thred, n_trial] = HL_FP_CleanStiArtiFact(ses_data.ch_data(:,idx_FP_ch),ses_data.ch_data(:,idx_Cstim_ch),ses_data.sr); % HL_cleanFP_StiArtiF
end
% interpolate NaNs
FP_clean_inpaint = inpaint_nans(FP_clean,5); % just use nearest average to fill NaNs

% Use Pratik's pipeline to coordinate across Tlab
% [df_F_ds, ts_ds, df_F, F_baseline, FP_filter] = HL_FP_df_cw (rawFP, ts, rawFs, system_baseline, ...
%                                                                         lpCut, filtOrder, interpType, fitType, winSize, winOv, basePrc)
[df_F_ds, ts_ds, df_F, F_baseline, FP_filter] = HL_FP_df_cw (FP_clean_inpaint, ses_data.ts, ses_data.sr, auto_baseline);


% [df_F_1m, baseline_1m, ts_df_F, data_ft_rs ] = HL_FP_df(FP_clean_inpaint , ses_data.sr, ses_data.ts);
% [df_F_15s, baseline_15s, ~, ~ ] = ...
%     HL_FP_df(FP_clean_inpaint , ses_data.sr, ses_data.ts, 15,1.5);
% use default parameters

% get trial onset of BitCode ...
% TrialNumber = HL_ReadBitCode(ses_data.ch_data(:,idx_Bitcode_ch),ses_data.sr);

% [Stim_ts, ~]= HL_FP_ParseSti(ses_data.ch_data(:,idx_Cstim_ch),ses_data.sr, Thred, stimulus_length);

% [trial_label, trial_type, idx_byTrialType] = HL_FP_GenerateTrialTypeIndex(size(Stim_ts,1), WS_trial);

% record data

% format data 0 at Csti Onset -- move to another function 
%{
FP_trial_window_length = 6;
FP_trial_window_start = -4;
df_sr = median(diff(ts_ds));% sampling rate in processed df
trial_window =[ 1:round(FP_trial_window_length/df_sr)] + round(FP_trial_window_start/df_sr);  %50Hz 2s => 100 data points

FP_x_plot = [0:1:(length(trial_window)-1)]*df_sr+FP_trial_window_start;

Trial_FP_15s = zeros(size(CtxSti,1), length(trial_window));
Trial_FP_1m = Trial_FP_15s;
for ii = 1:size(CtxSti,1)
     [frame_idx] = HL_getFrameIdx(ts_ds, CtxSti(ii,1));
    Trial_FP_15s(ii,:) = df_F_15s(frame_idx+trial_window);
    Trial_FP_1m(ii,:) = df_F_1m(frame_idx+trial_window);

end
%}
%% return useful result
% Info.auto_baseline =auto_baseline ;
% Info.sys_noise_est =sys_noise_est ;
% Info.WS_trial = WS_trial;
% Info.Stim_Thred = Thred;
% Info.FP_trial_window_length = FP_trial_window_length;
% Info.FP_trial_window_start = FP_trial_window_start;
% Info. = ;
% Info. = ;
% Info. = ;
% Info. = ;

% Result.df_F_15s = df_F_15s;
% Result.baseline_15s = baseline_15s;
Result.ts_ds = ts_ds;
Result.df_F_ds = df_F_ds;
Result.FP_clean_inpaint = FP_clean_inpaint;
Result.df_F = df_F; % without downsampling, F_baseline, FP_filter
Result.F_baseline = F_baseline; % F0 without downsampling
Result.FP_filter = FP_filter; % raw data after filter
% Result.Stim_ts = Stim_ts;
% Result.trial_label = trial_label;
% Result.trial_type = trial_type;
% Result.idx_byTrialType = idx_byTrialType;
% Result.n_trial = n_trial;
% Result.Trial_FP_15s = Trial_FP_15s;
% Result.Trial_FP_1m = Trial_FP_1m;
% Result.FP_x_plot = FP_x_plot;


% WS_data.ses = ses_data;
% WS_data.baseline = baseline_ses_data;
