%%% Create epochs of data around a given list of times.
%%%
%%% data - data to be epoched (can be multiple channels, orientation arbitrary)
%%% times - timepoints for epoching (can be specified as samples, or as
%%%         msec if a samplerate is provided)
%%% window - epoch size of [pre post] time (can be specified as samples, or as
%%%          msec if a samplerate is provided)
%%% samplerate - (optional) sample rate of data to convert times to samples
%%% average - (optional) instead of returning individual epochs, will
%%%           return a single window containing the average of all epochs
%%%
%%% output: [size(data,1), size(data,2), length(times)] OR
%%%         [size(data,1), size(data,2), 1] if 'average' == true
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function epochs = EpochData(data, times, window, samplerate, average)

times(isnan(times) | times == 0) = []; % remove NaNs or zeros

if (nargin > 3 && ~isempty(samplerate)) % assume times/window are in msec
    window = window*samplerate/1000;
    times = times*samplerate/1000;
end
if (nargin < 5 || isempty(average))
    average = false;
end

tflag = false;
if (size(data,1) > size(data,2)) % flip so columns are samples
    data = data';
    tflag = true;
end

% pad data with NaNs for edge cases:
% datap = [nan(size(data,1), abs(window(1))), data, nan(size(data,1), window(2))];
% times = times + abs(window(1));

if (~average)
    epochs = nan(size(data,1), window(2) - window(1) + 1, length(times));
else
    epochs = zeros(size(data,1), window(2) - window(1) + 1, 1);
end

n = 0;
for i = 1:length(times)
    idxs = times(i) + (window(1):window(2));
    if (any(idxs < 1 | idxs > size(data,2)))
        continue;
    end

    if (~average)
        epochs(:,:,i) = data(:, idxs);
    else
        epochs = epochs + data(:,idxs);
        n = n + 1;
    end
end

if (average)
    epochs = epochs/n;
end

if (tflag)
    epochs = permute(epochs, [2,1,3]);
end
    