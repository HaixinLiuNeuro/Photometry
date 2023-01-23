% function  [df_F_ds, ts_ds, df_F, F_baseline, rawFP_demod_filtered, params] = HL_FP_df_lockin (rawFP, rawFP_ref, ts, rawFs, LockInFreq, rawFP_base, rawFP_ref_base, lpCut, filtOrder, interpType, fitType, winSize, winOv, basePrc, dsRate)
% function to process photometry data using lockin amplification method
% using Pratik's functions 
%
%   INPUT:
%
%   
%   OUTPUT:
%       df_F_ds: processed dF/F data, downsampled using the low-pass filter
%                value (raw sample freq/filtered freq)
%       ts_ds: downsampled time stamp for each data point in df_F_ds
%       df_F: dF/F not downsampled
%       F_baseline: estimated baseline, not downsampled
%       FP_filter: low-pass filtered data, not down sampled
% use [sig,filtStruct] = digitalLIA(modSig,refSig,Fs,lpCut,filtOrder)
% to demodulat lockin method FP recording and then run dF/F
% 
% 
% 
function  [df_F_ds, ts_ds, df_F, F_baseline, rawFP_demod_filtered, params] = ...
    HL_FP_df_lockin (rawFP, rawFP_ref, ts, rawFs, LockInFreq, rawFP_base, rawFP_ref_base, ...
    lpCut, filtOrder, interpType, fitType, winSize, winOv, basePrc, dsRate)
%% default params
params.FP.lpCut = 30; % Cut-off frequency for filter 
params.FP.filtOrder = 10; % Order of the filter
params.FP.interpType = 'linear'; % 'linear' 'spline' 
params.FP.fitType = 'interp'; % Fit method 'interp' , 'exp' , 'line'
params.FP.winSize = 20; % Window size for baselining in seconds
params.FP.winOv = 1; %Window overlap size in seconds
params.FP.basePrc = 10; % Percentile value from 1 - 100 to use when finding baseline points
params.FP.ds2 = 500; % downsample to freq, default
params.FP.Edge2Nan_s = 5; % 
params.FP.LockInFreq = LockInFreq;
%%
if nargin < 8
    lpCut = params.FP.lpCut; % Cut-off frequency for filter
    filtOrder = params.FP.filtOrder; % Order of the filter
    interpType = params.FP.interpType;
    fitType = params.FP.fitType;
    winSize = params.FP.winSize;
    winOv = params.FP.winOv;
    basePrc = params.FP.basePrc;
    Edge2Nan_s = params.FP.Edge2Nan_s; % 
    dsRate = rawFs/params.FP.ds2; % downsample to 50Hz % dsRate = rawFs/lpCut; % raw sample freq/filtered freq
% elseif nargin < 6
%     lpCut = params.FP.lpCut; % Cut-off frequency for filter
%     filtOrder = params.FP.filtOrder; % Order of the filter
%     interpType = params.FP.interpType;
%     fitType = params.FP.fitType;
%     winSize = params.FP.winSize;
%     winOv = params.FP.winOv;
%     basePrc = params.FP.basePrc;  
%     Edge2Nan_s = params.FP.Edge2Nan_s; %
%     dsRate = rawFs/params.FP.ds2; 
elseif nargin >=7 && nargin < 15
    help HL_FP_df_lockin
    error('Not enought input paramters')
elseif nargin > 15
    help HL_FP_df_lockin
    error('too many input paramters')    
elseif nargin == 15
    params.FP.lpCut = lpCut; % Cut-off frequency for filter
    params.FP.filtOrder = filtOrder; % Order of the filter
    params.FP.interpType = interpType; % 'linear' 'spline'
    params.FP.fitType = fitType; % Fit method 'interp' , 'exp' , 'line'
    params.FP.winSize = winSize; % Window size for baselining in seconds
    params.FP.winOv = winOv; %Window overlap size in seconds
    params.FP.basePrc = basePrc; % Percentile value from 1 - 100 to use when finding baseline points
    params.FP.ds2 = rawFs/dsRate; % downsample to freq, default
    params.FP.Edge2Nan_s = 5; % use default
    Edge2Nan_s = 5;
end
fprintf(2,'Lowpass Filter: %d Hz. downsample to %d Hz. \nOther params:\n',lpCut, rawFs/dsRate);
disp(params.FP)
%%
% demodulate signal 
rawFP_demod_filtered = digitalLIA(rawFP,rawFP_ref, LockInFreq, rawFs, lpCut, filtOrder); % it also filters the data
% to avoid problem with filter and bleaching due to LED onset, remove 5s
% at the begining and at the end ==> Just NaN them
rawFP_demod_filtered(ts< Edge2Nan_s) = NaN;
rawFP_demod_filtered(ts>(ts(end)-Edge2Nan_s)) = NaN;

if ~isempty(rawFP_base) % having basline WS recording, use to substract 
    disp('Use WS baseline')
rawFP_demod_filtered_base = digitalLIA(rawFP_base, rawFP_ref_base, LockInFreq, rawFs, lpCut, filtOrder); % it also filters the data
% to avoid problem with filter and bleaching due to LED onset, remove 5s
% at the begining and at the end ==> Just NaN them
rawFP_demod_filtered_base(ts< Edge2Nan_s) = NaN;
rawFP_demod_filtered_base(ts>(ts(end)-Edge2Nan_s)) = NaN;
base = nanmedian(rawFP_demod_filtered_base);

[df_F, F_baseline] = baselineFP(rawFP_demod_filtered - base, interpType, fitType, basePrc, winSize, winOv, rawFs);
    
else
    disp('No WS baseline')
% calcuate dF/F using method: 
[df_F, F_baseline] = baselineFP(rawFP_demod_filtered, interpType, fitType, basePrc, winSize, winOv, rawFs);


end
% downsample to reduce data size, but not lose temporal info. 
df_F_ds = downsample(df_F,dsRate);
% baseline = downsample(baseline,dsRate);

%also return down sampled time stamps to match processed data
ts_ds = downsample(ts,dsRate);

