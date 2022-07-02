% data: NxP matrix (N channels, P data points)
% filtband: filter cutoff frequencies in Hz
%               - bandpass: [low, high]
%               - lowpass: -high
%               - highpass: low
% samplerate: original data sampling rate in Hz
% newrate: desired output sampling rate in Hz
% montage: 2xN matrix (N channels)
%           - row 1: target channel
%           - row 2: reference channel (0 = average)
%           - example (bipolar montage): [1, 2, 3, 4; 2, 3, 4, 5]
% badchannels: [1xM] vector of known bad channels (not contacts)
function [D, newrate] = PreProcessData(data, filtband, samplerate, newrate, montage, badchannels)

if (nargin < 4)
    newrate = [];
end
if (nargin < 5)
    montage = [];
end
if (nargin < 6)
    badchannels = [];
end

trans = false;
if (size(data,1) > size(data,2))
    data = data';
    trans = true;
end

% Mask bad channels:
data(badchannels,:) = nan;

% Re-reference:
if (~isempty(montage))
    D = zeros(size(montage,2), size(data,2));
    mu = mean(data, 1, 'omitnan');
    for i = 1:size(montage,2)
        if (montage(2,i) ~= 0)
            D(i,:) = data(montage(1,i),:) - data(montage(2,i),:);
        else
            D(i,:) = data(montage(1,i),:) - mu;
        end
    end
else
    D = data;
end

% Filter:
if (~isempty(filtband) && ~all(isnan(data),'all'))
    if (length(filtband) == 2)
        [b, a] = butter(2, filtband/(samplerate/2), 'bandpass');
    elseif (sign(filtband) > 1)
        [b, a] = butter(4, abs(filtband)/(samplerate/2), 'high');
    elseif (sign(filtband) < 1)
        [b, a] = butter(4, abs(filtband)/(samplerate/2), 'low');
    end
    for i = 1:size(D,1)
        if (all(isnan(D(i,:))))
            continue;
        end
        D(i,:) = filtfilt(b, a, D(i,:));
    end
end

% Downsample:
if (~isempty(newrate) && ~isempty(samplerate))
    skip = round(samplerate/newrate);
    D = D(:,1:skip:end);
    newrate = samplerate/skip;
end

if (trans)
    D = D';
end