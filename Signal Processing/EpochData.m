%%% Create epochs of data around a given list of times.
%%%
%%% data - data to be epoched (can be multiple channels, orientation arbitrary)
%%% times - timepoints for epoching (can be specified as samples, or as
%%%         msec if a samplerate is provided)
%%% window - epoch size of [pre post] time (can be specified as samples, or as
%%%          msec if a samplerate is provided)
%%% samplerate - (optional) sample rate of data to convert times to samples
%%%
%%% output: [size(data,1), size(data,2), length(times)]

function epochs = EpochData(data, times, window, samplerate)

times(isnan(times)) = []; % remove NaNs

if (nargin > 3 && ~isempty(samplerate)) % assume times/window are in msec
    window = window*samplerate/1000;
    times = times*samplerate/1000;
end

tflag = false;
if (size(data,1) > size(data,2)) % flip so columns are samples
    data = data';
    tflag = true;
end

epochs = zeros(size(data,1), window(2) - window(1) + 1, length(times));
for i = 1:length(times)
    epochs(:,:,i) = data(:, times(i) + (window(1):window(2)));
end

if (tflag)
    epochs = permute(epochs, [2,1,3]);
end
    