%%% INPUTS:
%%% * fileInfo - file info structure, found in the data *.mat file
%%% * ttlchan - number of ttlchan used, if known
%%% * timesonly - ignore the stimulus file, extract TTL times only

function trials = ParseStimulusTrials(fileInfo, ttlchan, timesonly)

if (nargin < 2)
    ttlchan = [];
end
if (nargin < 3 || isempty(timesonly))
    timesonly = false;
end

%%% Extract intended stimulation and TTL values from stim script: %%%

if (~timesonly)
    % Load stimulus file:
    
    % Parse stimulation file:
    stim = fileInfo.stimfile.text;
    
    % Make sure it's a correct MC_Stimulus file:
    assert(strcmpi(stim(1:36), 'Multi Channel Systems MC_Stimulus II'), 'File error: Not a valid MC_Stimulus file');
    
    % Convert stimulus file to correct format:
    
    % Extract the output mode (voltage or current) and corresponding units:
    outputmode = regexp(stim, 'output mode:\t(\w+)', 'tokens', 'once');
    if (strcmpi(outputmode{1}, 'voltage'))
        units = 'mV';
    else
        units = 'uA';
    end

    format = str2double(regexp(stim, 'format:\t(\d)', 'tokens', 'once'));
    assert(ismember(format, [3, 5]), 'Format error: Only formats 3 and 5 are supported');
    
    % Determine maximum number of channels for this stimulator:
    maxchans = str2double(regexp(stim, 'channels:\t(\d)', 'tokens', 'once'));
    
    % Find TTL section and convert to numbers:
    numttl = length(regexp(stim, 'channel:\t(\d)')) - maxchans;
    ttlstart = zeros(1,numttl);
    ttlvals = cell(1,numttl);
    for i = 1:numttl
        ttlstart(i) = regexp(stim, sprintf('channel:\t%d\\D+', i+maxchans), 'end')+1;
        ttlvals{i} = sscanf(stim(ttlstart(i):end), '%f');
    end
    
    usedttl = find(~cellfun(@isempty, ttlvals));
    if (length(usedttl) > 1)
        if (isempty(ttlchan))
            error('Input error: multiple TTL channels present, please provide a TTL channel input');
        end
        usedttl = usedttl(ttlchan);
    end
    
    ttlvals = ttlvals{usedttl};
    
    assert(~isempty(ttlvals), sprintf('Format error: TTL channel %d empty', ttlchan+maxchans));

    if (format == 3)
        assert(~any(ttlvals(repmat(logical([0 0 1 1 1 0 1]'),length(ttlvals)/7,1))), 'Format error: TTL columns 3, 4, 5, and 7 are not zeros');
    elseif (format == 5)
        assert(~any(ttlvals(repmat(logical([1 1 0 0]'),length(ttlvals)/4,1))), 'Format error: TTL columns 1 and 2 are not zeros');

    end

    % Get intended TTL widths:
    if (format == 3)
        ttlwidths = ttlvals(2:7:end)'*fileInfo.srate/1e6; % in samples
        ttlisis = ttlvals(6:7:end)'*fileInfo.srate/1e6; % in samples
    elseif (format == 5)
        ttlwidths = ttlvals(4:8:end)'*fileInfo.srate/1e6; % in samples
        ttlisis = ttlvals(8:8:end)'*fileInfo.srate/1e6; % in samples
    end

    stimvals = repmat(struct('StimNumber', [], ...
                           'StimLoc_sample', [], ...
                           'StimChans', [], ...
                           'StimWidth_ms', [], ...
                           'StimFreq', [], ...
                           'StimAmp', []), 1, length(ttlwidths));

    for i = 1:maxchans
        
        % Find start and end of ith channel stimuli definitions:
        stimstart = regexp(stim, sprintf('channel:\t%d\\D+', i), 'end')+1;
        stimend = regexp(stim, sprintf('channel:\t%d\\D+', i+1), 'start')-5;
        
        % Convert this section to numbers:
        stimvalschan = sscanf(stim(stimstart:stimend), '%f');
        
        % Make sure this channel is used and correctly formatted:
        isMono = false;
        if (format == 3)
            if (isempty(stimvalschan) || length(stimvalschan) ~= length(ttlwidths))
                stimvalschan{i} = [];
                continue;
            end

            % Make sure the file matches the format we think it's in:
            assert(mod(length(stimvalschan),7) == 0, sprintf('Format error channel %d: Number of columns is wrong', i));
            assert(~any(stimvalschan(repmat(logical([0 0 0 0 1 0 1]'),length(stimvalschan)/7,1))), sprintf('Format error channel %d: Stimulus columns 5 and 7 are not empty', i));
            
            % Check if this channel is used at all:
            if (~any(stimvalschan(repmat(logical([1 0 1 0 0 0 0]'),length(stimvalschan)/7,1))))
                continue;
            end
            
             % Check if this is a monophasic or biphasic stim file:
            if (~any(stimvalschan{i}(3:7:end)))
                isMono = true;
                stimvalschan(6:7:end) = stimvalschan(6:7:end) + stimvalschan(4:7:end); % add any time from the empty 2nd pulse to the ISI time
            end
        elseif (format == 5)
            if (isempty(stimvalschan) || sum(stimvalschan(3:4:end) == 0) ~= length(ttlwidths))
                continue;
            end
            
            % Make sure the file matches the format we think it's in:
            assert(mod(length(stimvalschan),4) == 0, sprintf('Format error channel %d: Number of columns is wrong', i));
            assert(all(ismember(stimvalschan(1:4:end), [0, 2])), sprintf('Format error channel %d: Only rectangular and sinusoidal pulse shaped supported for Format 5', i));
           
            % Check if this channel is used at all:
            if (~any(stimvalschan(repmat(logical([1 0 1 0]'),length(stimvalschan)/4,1))))
                continue;
            end
        end
        
        % Extract intended stim data:
        if (format == 3)
            for j = 1:length(stimvals)
                stimvals(j).StimNumber = j;
                stimvals(j).StimChans(end+1) = i;
                if (isMono)
                    stimvals(j).StimWidth_ms(end+1) = stimvalschan(2 + (j-1)*7);
                    stimvals(j).StimAmp(end+1) = stimvalschan(1 + (j-1)*7);
                else % [channel1phase1 ... channelNphase1; channel1phase2 ... channelNphase2]
                    stimvals(j).StimWidth_ms(end+1) = stimvalschan([1,3] + (j-1)*7)/1000;
                    stimvals(j).StimAmp(end+1) = stimvalschan([1,3] + (j-1)*7);
                end
            end
            
        elseif (format == 5)
            stimidxs = [0; find(stimvalschan(3:4:end) == 0)];
            for j = 1:length(stimvals)
                stimvals(j).StimNumber = j;
                stimvals(j).StimChans(end+1) = i;
                stimvals(j).StimWidth_ms(end+1) = sum(stimvalschan((stimidxs(j)+1)*4:4:(stimidxs(j+1)-1)*4))/1000;
                stimvals(j).StimFreq(end+1) = 1/(stimvalschan(4 + (stimidxs(j))*4)/1e6);
                stimvals(j).StimAmp(end+1) = stimvalschan(3 + (stimidxs(j))*4);
            end
        end
       
        
    end
       
end

%%% Extract and measure TTL detection events from the EEG file recording %%%

% Extract recorded ttl times:
ttlmarks = getTTLTimes(fileInfo.event);
usedttls = find(cellfun(@length, ttlmarks) > 1);

if (length(usedttls) == 1 || isempty(ttlchan))
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

%%% Line up intended and measured TTL events: %%%

if (~timesonly)
    % Get measured TTL widths:
    widths = (fallingedge - risingedge)';
    
    % Find any restarts in the file:
    restarts = [1; find(risingedge(2:end) - fallingedge(1:end-1) > 1.5*max(ttlisis))+1; length(risingedge)+1];

    % Line up stim vals with each restart:
    trials = repmat(struct('StimNumber', [], ...
                           'StimLoc_sample', [], ...
                           'StimChans', [], ...
                           'StimWidth_ms', [], ...
                           'StimFreq', [], ...
                           'StimAmp', []), 1, length(widths));

    for k = 1:length(restarts)-1
        runidxs = restarts(k):restarts(k+1)-1;
        runwidths = widths(runidxs);

        % Find where intended TTL matches up with our measured values:
        for i = 1:length(ttlwidths)
            intended = ttlwidths(i:min([i + length(runwidths) - 1, length(ttlwidths)]));
            measured = runwidths(1:min([length(runwidths), length(intended)]));
            if (all(abs(intended - measured) < 2))
                break;
            elseif (all(abs(intended(1:end-1) - measured(1:end-1)) < 2)) % in case end TTL gets cut off?
                runidxs = runidxs(1:end-1);
                break;
            end
        end

        runidxs = runidxs(i:end);

        % If we didn't find a match, or there weren't enough captured values, throw an error:
        if (length(runidxs) < 10)
            error('Event error: measured TTL widths don''t match stimulus file');
        end

        trials(runidxs) = stimvals(i:i + length(runidxs) - 1);
        trials(runidxs) = [arrayfun(@(x) setfield(trials(x), 'StimLoc_sample', risingedge(x)), runidxs)];

    end

    trials(arrayfun(@(x) isempty(x.StimNumber), trials)) = [];
end
