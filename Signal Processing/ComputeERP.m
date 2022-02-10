%%% Dim = time x recording channel x stimulation channel x stimulation amplitude x stimulation pulse width
function [erps, t, epochs] = ComputeERP(subj, fname, modality, freq, window, montage) 

% parameters:
% subj = 'BB004';
% fname = 'LFP_200Hz';
% modality = 'dbs';
% freq = [10, 1000];
% window = [-150, 350];
% montage = 'bipolar'; % 'common', 'bipolar', or cell array of 2xN matrices (one per modality) 

% adjust parameters as necessary:
if (~iscell(fname))
    fname = {fname};
end
if (~iscell(modality))
    modality = {modality};
end
if (~iscell(montage))
    montage = repelem({montage}, length(modality));
end

% subject/file information:
info = getInfoFile;
sinfo = info(strcmp({info.ID}, subj));

data = cell(length(modality), length(fname));
trials = cell(1,length(fname));
for f = 1:length(fname)

    finfo = sinfo.File(strcmp({sinfo.File.FileName}, fname{f}));
    
    % load and select data:
    [dataf, fi] = LoadDatav2(subj, fname{f});
    
    datasel = cell(1,length(modality));
    badchans = cell(1,length(modality));
    for i = 1:length(modality)
        modchans = finfo.([upper(modality{i}), 'Chans']);
        
        datasel{i} = dataf(modchans,:);
        badchans{i} = finfo.(['Bad', upper(modality{i}), 'Contacts']);
        
        if (ischar(montage{i}) && strcmpi(montage{i}, 'common'))
            montage{i} = [1:length(modchans); zeros(1,length(modchans))];
        elseif (ischar(montage{i}) && strcmpi(montage{i}, 'bipolar'))
            montage{i} = [1:length(modchans)-1; 2:length(modchans)];
        end
    end
    dataf = datasel;
    
    % preprocess data:
    for i = 1:length(dataf)
        [dataf{i}, ~] = PreProcessData(dataf{i}, freq, finfo.SampleRate, [], montage{i}, badchans{i});
    end
    data(:,f) = dataf;
    
    % get stimulation info:
    trialsf = ParseStimulusTrials(fi);
    
    % remove 2nd pulse if stimuli are biphasic
    if (size(trialsf(1).StimAmp, 1) > 1)
        for i = 1:length(trialsf)
            trialsf(i).StimWidth_ms(2:end,:) = [];
            trialsf(i).StimAmp(2:end,:) = [];
        end
    end
    trials{f} = trialsf;
end

%  if multiple files:


% adjust stimulus times and concatenate data and trials across files
for i = 1:length(modality)
    for j = 2:length(fname)
        x = num2cell([trials{j}.StimLoc_sample] + sum(cellfun(@length, data(i,1:j-1))));
        [trials{j}.StimLoc_sample] = x{:};
    end
    data{i,1} = [data{i,:}];
end
data = data(:,1)';
trials = cell2mat(trials);

% determine unique stimulation conditions: stim channels, amplitude/polarity, pulse width
stimchans = unique(cell2mat(arrayfun(@(x) abs(x.StimAmp) == max(abs(x.StimAmp)), trials, 'uni', 0)'), 'rows');
[~, order] = sort(stimchans*(1:size(stimchans,2))' + (sum(stimchans,2)-1));
stimchans = stimchans(order,:);

trialstimchans = arrayfun(@(x) find(all(stimchans==(abs(x.StimAmp)==max(abs(x.StimAmp))),2)), trials);

% round to nearest 50 uA/mV to avoid near duplicate values:
trialstimamps = round(arrayfun(@(x,y) sum(x.StimAmp.*stimchans(y,:)), trials, trialstimchans)/50)*50;
stimamps = unique(abs(trialstimamps));
    
trialstimwidths = arrayfun(@(x,y) max(x.StimWidth_ms.*stimchans(y,:)), trials, trialstimchans);
stimwidths = unique(trialstimwidths);

% compute ERPs for each unique condition:
erps = cell(size(data));
for i = 1:length(data)
    erps{i} = zeros((window(2) - window(1))*finfo.SampleRate/1000 + 1, ... % dim 1 = time
                    size(data{i},1), ...                                   % dim 2 = recording channels
                    size(stimchans, 1), ...                                % dim 3 = stimulation channels
                    length(stimamps), ...                                  % dim 4 = stimulation amplitudes
                    length(stimwidths));                                   % dim 5 = stimulation pulse widths
    
    for j = 1:size(stimchans, 1)
        
%         jidx = all(cell2mat(arrayfun(@(x) abs(x.StimAmp) == max(abs(x.StimAmp)), trials, 'uni', 0)') == stimchans(j,:), 2);
        jidx = trialstimchans == j;
        trialsj = trials(jidx);
        trialstimampsj = trialstimamps(jidx);
        trialstimwidthsj = trialstimwidths(jidx);
        
        for k = 1:length(stimamps)
            
%             kidx = cell2mat(arrayfun(@(x) max(abs(x.StimAmp)), trialsj, 'uni', 0)') == stimamps(k);
            kidx = abs(trialstimampsj) == stimamps(k);
            trialsjk = trialsj(kidx);
            trialstimwidthsjk = trialstimwidthsj(kidx);
            
            for m = 1:length(stimwidths)
                
%                 midx = [trialsjk.StimWidth_ms] == stimwidths(m);
                midx = trialstimwidthsjk == stimwidths(m);
                trialsjkm = trialsjk(midx);
                
                pol = cell2mat(arrayfun(@(x) extremum(x.StimAmp), trialsjkm, 'uni', 0)') > 0;
         
                % collect data epochs:
                epochs = EpochData(data{i}, [trialsjkm.StimLoc_sample], window*finfo.SampleRate/1000);
                
                % remove outliers:
%                 maxamp = max(abs(epochs),[],2);
%                 outliers = maxamp > repmat(2*prctile(maxamp, 90, 3), 1, 1, size(maxamp, 3));
%                 epochs(repmat(outliers,1,size(epochs,2),1)) = NaN;
%                 numoutliers = sum(outliers, 'all');
%                 fprintf('(%s) Stim channel %d, amplitude %d, width %d: removed %d total outliers (%.02f%%)\n', ...
%                     modality{i}, j, k, m, numoutliers, 100*numoutliers/size(epochs, 3));
                
                % finally compute the erp:
                erps{i}(:,:,j,k,m) = sum(cat(3, mean(epochs(:,:,pol), 3, 'omitnan')', mean(epochs(:,:,~pol), 3, 'omitnan')'), 3,'omitnan');
            end
        end
    end
end
    
if (length(erps) == 1)
    erps = erps{1};
end

t = linspace(window(1), window(2), (window(2) - window(1))*finfo.SampleRate/1000 + 1);