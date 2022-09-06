%%% INPUTS:
%%% * fileInfo - file info structure, found in the data .mat file
%%% * ttlchan - number of ttlchan used, if known
%%% * timesonly - ignore the stimulus file, extract TTL times only

function trials = ParseStimulusTrials(fileInfo, ttlchan, timesonly)

if (nargin < 2)
    ttlchan = [];
end
if (nargin < 3 || isempty(timesonly))
    timesonly = false;
end

if (~timesonly)
    %% Load stimulus file:
    
    % Parse stimulation file:
    stim = fileInfo.stimfile.text;
    
    % Make sure it's a correct MC_Stimulus file:
    assert(strcmpi(stim(1:36), 'Multi Channel Systems MC_Stimulus II'), 'File error: Not a valid MC_Stimulus file');
    
    %% Convert stimulus file to correct format:
    
    % Extract the output mode (voltage or current) and corresponding units:
    idx = strfind(stim, ['output mode:', char(9)]);
    outputmode = stim(idx+13:idx+19);
    if (strcmpi(outputmode, 'voltage'))
        units = 'mV';
    else
        units = 'uA';
    end
    
    % Determine maximum number of channels for this stimulator:
    maxchans = str2double(stim(strfind(stim, 'output mode:')-3));
    
    % Find TTL section and convert to numbers:
    numttl = length(strfind(stim, 'channel:')) - maxchans;
    ttlstart = zeros(1,numttl);
    ttlvals = cell(1,numttl);
    for i = 1:numttl
        ttlstart(i) = strfind(stim, ['channel:', char(9), num2str(i+maxchans)]) + 53;
        ttlvals{i} = sscanf(stim(ttlstart(i):end), '%f');
    end
    
    usedttl = find(~cellfun(@isempty, ttlvals));
    if (length(usedttl) > 1)
        usedttl = usedttl(ttlchan);
    end
    
    ttlvals = ttlvals{usedttl};
    
    assert(~isempty(ttlvals), sprintf('Format error: TTL channel %d empty', ttlchan+maxchans));
    assert(~any(ttlvals(repmat(logical([0 0 1 1 1 0 1]'),length(ttlvals)/7,1))), 'Format error: TTL columns 3, 4, 5, and 7 are not empty');
    assert(all(ttlvals(1:7:end) == 1), 'Format error: TTL voltages not all 1');
    
    stimvals = cell(1,maxchans); usedchans = zeros(1,maxchans,'logical');
    for i = 1:maxchans
        
        % Find start and end of ith channel stimuli definitions:
        stimstart = strfind(stim, sprintf('channel:\t%d\r\n', i)) + 53;
        stimend = strfind(stim(stimstart:end), 'channel:') + stimstart - 1;
        if (length(stimend) > 1)
            stimend = stimend(1);
        end
        
        % Convert this section to numbers:
        stimvals{i} = sscanf(stim(stimstart:stimend), '%f');
        
        % Make sure this channel is used:
        if (isempty(stimvals{i}) || length(stimvals{i}) ~= length(ttlvals))
            stimvals{i} = [];
            continue;
        end
        
        % Make sure the file matches the format we think it's in:
        assert(mod(length(stimvals{i}),7) == 0, 'Format error channel ', num2str(i), ': Number of columns is wrong');
        assert(~any(stimvals{i}(repmat(logical([0 0 0 0 1 0 1]'),length(stimvals{i})/7,1))), 'Format error channel ', num2str(i), ': Stimulus columns 5 and 7 are not empty');
        
        % Check if this channel is used at all:
        if (any(stimvals{i}(repmat(logical([1 0 1 0 0 0 0]'),length(stimvals{i})/7,1))))
            usedchans(i) = true;
        else
            continue;
        end
        
        % Check if this is a monophasic or biphasic stim file:
        if (~any(stimvals{i}(3:7:end))) % Only 1 stim pulse per line = monophasic stimulation
            isMono = true;
            stimvals{i}(6:7:end) = stimvals{i}(6:7:end) + stimvals{i}(4:7:end); % add any time from the empty 2nd pulse to the ISI time
        else
            isMono = false;
        end
        
        % Get rid of the unused columns in each vector:
        %   * remaining columns: 1 = pulse amplitude, 2 = pulse width, 3 = inter-pulse delay
        stimvals{i} = stimvals{i}(repmat(logical([1 1 ~isMono ~isMono 0 1 0]'),length(stimvals{i})/7,1));
        
    end
    
    % Get rid of unused columns in the TTL vector:
    ttlvals = ttlvals(repmat(logical([1 1 0 0 0 1 0]'),length(ttlvals)/7,1));
    
    % Determine which channels were actually used:
    chanidxs = find(usedchans);
    
end

%% Extract and measure TTL detection events from the EEG file recording

% Extract recorded ttl times:
ttlmarks = getTTLTimes(fileInfo.event);
usedttls = find(cellfun(@length, ttlmarks) > 1);

if (length(usedttls) == 1 || isempty(ttlchan))
%     ttlmarks = ttlmarks{usedttls(1)};
    ttlmarks = ttlmarks{ExtremumLoc('max', cellfun(@length, ttlmarks))};
elseif (~isempty(ttlchan))
    ttlmarks = ttlmarks{ttlchan};
end

risingedge = ttlmarks(1:2:end);
fallingedge = ttlmarks(2:2:end);

% Make sure TTL edge detections aren't screwed up:
if (length(fallingedge) == length(risingedge))
    assert(all(fallingedge-risingedge >= 1), 'Event error: Rising and falling edges not adjacent');
elseif (length(fallingedge) == length(risingedge)-1)
    assert(all(fallingedge-risingedge(1:end-1) >= 1), 'Event error: Rising and falling edges not adjacent');
    risingedge = risingedge(1:end-1);
else
    error('Event error: Missing half of a TTL pair');
end

if (~timesonly)
    % Get measured TTL widths:
    widths = (fallingedge - risingedge)';
    
    % Get intended TTL widths:
    ttlwidths = ttlvals(2:3:end)'*fileInfo.srate/1e6; % in samples
    
    % Find where intended TTL matches up with our measured values:
    for i = 1:length(ttlwidths)
        intended = ttlwidths(i:min([i + length(widths) - 1, length(ttlwidths)]));
        measured = widths(1:min([length(widths), length(intended)]));
        if (all(abs(intended - measured) < 2))
            break;
        elseif (all(abs(intended(1:end-1) - measured(1:end-1)) < 2)) % in case end TTL gets cut off?
            risingedge = risingedge(1:end-1);
            break;
        end
    end
    
    % If we didn't find a match, or there weren't enough captured values, throw an error:
    if (i == length(ttlwidths))
        error('Event error: measured TTL widths don''t match stimulus file');
    else
        eventstart = i;
    end
end

%% Create and fill in new data structure:
%   - NOTE: all time units in milliseconds, except where noted by "..._sample"

% Number of trials:
n = length(risingedge);
       
% Split events into trials (paired pulses):
trials = repmat(struct('StimNumber', [], ...
                       'StimLoc_sample', [],  ...
                       'StimWidth_ms', [], ...
                       'StimAmp', []), 1, n);

for i = 1:n
    
    % Record the trial:
    trials(i).StimNumber = i;
    
    % Record location (in samples) of pulse:
    trials(i).StimLoc_sample = risingedge(i);
    
    if (~timesonly)
        % Record width (in ms) of stimulus pulse:
        if (isMono)
            trials(i).StimWidth_ms = arrayfun(@(x) stimvals{x}(2 + (i+eventstart-2)*3)/1000, chanidxs);
        else % [channel1phase1 ... channelNphase1; channel1phase2 ... channelNphase2]
            trials(i).StimWidth_ms = cell2mat(arrayfun(@(x) stimvals{x}([2,4] + (i+eventstart-2)*5)/1000, chanidxs, 'UniformOutput', false));
        end
        
        % Record amplitude (in either mV or uA) of stimulus pulse:
        if (isMono)
            trials(i).StimAmp = arrayfun(@(x) stimvals{x}(1 + (i+eventstart-2)*3), chanidxs);
        else % [channel1phase1 ... channelNphase1; channel1phase2 ... channelNphase2]
            trials(i).StimAmp = cell2mat(arrayfun(@(x) stimvals{x}([1,3] + (i+eventstart-2)*5), chanidxs, 'UniformOutput', false));
        end
    end
end