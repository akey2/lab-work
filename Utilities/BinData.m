%%% Bins data into time windows - basically a moving average with a defined
%%% window size and step length. Will also take custom functions instead of
%%% just the average.
%%%
%%% Input: 'data' - NxM matrix of data to bin. Function will operate along
%%%                 the longest dimension
%%%        'wlen' - length of time window, in samples/rows
%%%        'woverlap' - number of rows/samples to overlap windows
%%%        'fcn' - handle to custom function. Be sure to specify the
%%%                function as operating along the 1st dimension
%%% Output: 'out' - binned data
%%%         'centers' - samples/rows specifying the center of each bin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out, centers] = BinData(data, wlen, woverlap, fcn)

if (nargin < 4 || isempty(fcn))
    fcn = @(x) mean(x,1);
end

tflag = false;
if (size(data,2) > size(data,1))
    data = data';
    tflag = true;
end

start = 1:(wlen - woverlap):size(data,1);
stop = wlen:(wlen - woverlap):size(data,1);
start = start(1:length(stop));

centers = mean([start', stop'],2);


out = zeros(length(start), size(data,2));
for i = 1:length(start)
    out(i,:) = fcn(data(start(i):stop(i),:));
end

if (tflag)
    out = out';
end