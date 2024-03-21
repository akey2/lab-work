% Sync a Z Struct with the corresponding Grapevine file(s):
%
% Inputs:
% - Z: Z Struct to sync with the Grapevine files
% - run: which run does Z correspond to?
% - startRun: which run is the first one contained in the NEV files?
%       - Usually 1, but sometimes recording started after Run 1
% - NEVdir: directory containing relevant NEV files
%       - If not specified, will pop up the file picker GUI
% - badtrials: Specify bad trials here to be automatically put in Z
% - addspikes: Number of spike channels to add to Z struct from NEV files
%       - e.g. input of 96 = add spike times from channels 1-96
% - addbb: Broadband channels to add to Z struct from NSx files
%       - order of Broadband.Data fields same as that specified here
% - samprate: Specify the NSx extension number (e.g. "5" = .NS5, "4 = .NS4)
%       - default: 5
%
% Written by Zach Irwin for the Chestek Lab
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [newZ] = SyncZNeural(Z, run, startRun, NEVdir, badtrials, addspikes, addbb, samprate)

if (nargin < 2)
    error('Feed me, Seymour! Neeeed moooore inpuuuuts...');
end

if (nargin < 3 || isempty(startRun))
    startRun = 1;                    % which run does NEV_001 correspond to?
end

if (nargin < 4 || isempty(NEVdir))
    NEVdir = uigetdir(pwd);          % grab directory for NEV files
end

if (nargin < 5 || isempty(badtrials))
    badtrials = [];
end

if (nargin < 6 || isempty(addspikes))
    addspikes = [];
elseif (addspikes < 1 || addspikes > 128)
    error('Number of channels must be between 1 and 128');
end

if (nargin < 7 || isempty(addbb))
    addbb = [];
end

if (nargin < 8 || isempty(samprate))
    samprate = 5;
elseif (samprate < 1 || samprate > 6)
    error('Sampling rate must be in the range 1-6.');
end

notfirst = 0; % first NEV file
done = 0; % synced all trials
changed = 0; % current NEV file changed from last iteration
breakfound = 0; % found skipped section in NEV
lasttime = -1; % last experiment time in previous NEV file

% First, find the corresponding Cerebus times for each trial:
D = dir(sprintf('%s\\*.nev', NEVdir));
runnum = startRun;
trialnum = 1;
start = 1;

if (length(D) < 1)
    error('Whoah there fella, shit''s empty!');
end

for i = 1:length(D)
    
    if (done)
        break;
    end
    
    % Load in current NEV:
    nev = openNEV(sprintf('%s\\%s', NEVdir, D(i).name), 'read');
    
    % Get experiment/NEV times included in file:
    [etime, ctime] = FixNEVTimes(nev);
    
    if (isempty(etime) || isempty(ctime))
        if (i > 1)
            breakfound = 1;
        end
        continue;
    end
    
    %runnum = runnum + breakfound;
    %breakfound = 0;
    
    % Find run restarts included in file:
    runidxs = [1, find(etime(2:end)==0)+1, length(etime)+1];
    
    % Corresponding to which runs?
    if (etime(1) ~= 0)
        skip = etime(1) <= lasttime;
        %nevruns = (runnum+skip):(runnum + skip + length(runidxs) - 2);
        nevruns = (runnum+(skip||breakfound)):(runnum + (skip || breakfound) + length(runidxs) - 2);
    else
        nevruns = (runnum+notfirst):(runnum + notfirst + length(runidxs) - 2);
    end
    
    lasttime = etime(end);
    notfirst = 1;
    breakfound = 0;
    
    % Is the ZStruct run included?
    if (ismember(run, nevruns)) 
        
        idx = find(nevruns == run, 1);
        
        % Go through trials & sync:
        for j = trialnum:length(Z)
            
            % If this trial started before the first file, skip to next:
            if (i == 1 && idx == 1 && Z(j).ExperimentTime(1) < etime(1))
                continue;
            elseif ((i > 1 || idx > 1) && Z(j).ExperimentTime(1) < etime(runidxs(idx)))
                start = 1;
                changed = 0;
                Z(j).GoodTrial = 0;
                continue;    
            end
            
            % Find start of trial:
            if (~isempty(etime) && start)
                
                if (etime(runidxs(idx)) <= Z(j).ExperimentTime(1) && etime(runidxs(idx+1)-1) >= Z(j).ExperimentTime(1))  % this file contains trial start
                    Z(j).CerebusTimeStart = ctime(runidxs(idx)-1 + find(etime(runidxs(idx):runidxs(idx+1)-1) == Z(j).ExperimentTime(1),1));
                    start = 0;
                    changed = 0;
                end
                
            end
            
            % Find end of trial:
            if (~changed)
                if (~isempty(etime) && ~start)
                    
                    if (etime(runidxs(idx)) <= Z(j).ExperimentTime(end) && etime(runidxs(idx+1)-1) >= Z(j).ExperimentTime(end))  % this file contains trial start
                        Z(j).CerebusTimeStop = ctime(runidxs(idx)-1 + find(etime(runidxs(idx):runidxs(idx+1)-1) == Z(j).ExperimentTime(end),1));
                        start = 1;
                        Z(j).NEVFile = nev.MetaTags.Filename;
                        
                        if (~isempty(addspikes))
                            
                            % Go through each channel, adding spikes:
                            for k = 1:addspikes
                                
                                spikes = nev.Data.Spikes.TimeStamp(nev.Data.Spikes.Electrode == k & nev.Data.Spikes.Unit == 0);
                                times = ctime(ctime >= Z(j).CerebusTimeStart & ctime <= Z(j).CerebusTimeStop);
                                bins = histc(spikes, times);
                                spiketimes = zeros(1, sum(bins));
                                
                                num = 1;
                                for m = 1:length(bins)
                                    temp = m*ones(1, bins(m));
                                    spiketimes(num:num+length(temp)-1) = temp;
                                    num = num + length(temp);
                                end
                                
                                Z(j).Channel(k).SpikeTimes = Z(j).ExperimentTime(spiketimes);
                                
                            end
                            
                        end
                        
                        Z(j).GoodTrial = ~ismember(j, badtrials);
                        
                        continue;
                    end
                    
                end
            else
                changed = 0;
                start = 1;
                Z(j).GoodTrial = 0;
                continue;
            end
            
            % If failed to find both, move to next NEV file:
            trialnum = j;
            changed = 1;
            break;
        
        end
        
        if (j == length(Z) && ~isempty(Z(j).CerebusTimeStop))
            
            trialLen = max(arrayfun(@(x) length(x.ExperimentTime), Z));
            
            if (etime(runidxs(idx+1)-1) > (Z(end).ExperimentTime(end) + trialLen))   % rough sanity check
                error('Sheeeeiiiit, son, we''re looking in the wrong file!');
            end
            
            done = 1;
        end
        
    elseif (run < nevruns(1))
        error('Can''t find the correct run');
    end
    
    runnum = nevruns(end);
    
end

% Add broadband channels to Z Struct:
if (~isempty(addbb))
    
    % Get rid of trials we don't have data for:
    Z(arrayfun(@(x) isempty(x.CerebusTimeStart) || isempty(x.CerebusTimeStop), Z)) = [];
    
    % Set sampling rate & NS file extension:
    rates = [.5, 1, 2, 10, 30, 30];
    numsamp = rates(samprate);
    nsext = ['.ns', num2str(samprate)];
    
    % Add data:
    for i = 1:length(Z)
        
        % Load in NS5 file:
        file = '';
        if (~strcmp(Z(i).NEVFile, file))
            file = Z(i).NEVFile;
            NS = openNSx('read', [NEVdir, '\\', file, nsext]);
        end
        
        % Add in broadband data & trim to match trial length:
        t = length(Z(i).ExperimentTime)*numsamp;
        for j = 1:length(addbb)

            Z(i).Broadband(j).Data = double(NS.Data(addbb(j),ceil(Z(i).CerebusTimeStart/(30/numsamp)):ceil(Z(i).CerebusTimeStop/(30/numsamp))));

            len = length(Z(i).Broadband(j).Data);
            if (len > t)     % subtract some
                Z(i).Broadband(j).Data = Z(i).Broadband(j).Data(1+floor(abs(t-len)/2):end-ceil(abs(t-len)/2));
            elseif (len < t) % add some
                Z(i).Broadband(j).Data = padarray(Z(i).Broadband(j).Data, [0,floor(abs(t-len)/2)], 'replicate', 'pre');
                Z(i).Broadband(j).Data = padarray(Z(i).Broadband(j).Data, [0,ceil(abs(t-len)/2)], 'replicate', 'post');
            end
        end
        
    end

end


newZ = Z;


