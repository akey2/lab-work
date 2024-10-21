% Helper function to get sample indices associated with a particular
% behavior, as listed in the "Behavior" table of an INFO file
%
% Input: (1) finfo - file info struct: INFO(i).File(j)
%        (2) type - behavior type as string/character vector
%                       * Not case sensitive
%                       * if a vector of strings or cell array of character
%                         vectors, will match any element
%        (3) sr - sampling rate
%                       * if not included, will use sampling rate in finfo struct
%        (4) split - boolean to combine or split repetitions
%                       * false (default): will combine all indices into a single vector
%                       * true: will keep repetitions separate in cell array
%
% Output: idxs - vector or cell array (depending on "split") of sample indices
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function idxs = GetBehaviorIdxs(finfo, type, sr, split)

if (nargin < 4 || isempty(split))
    split = false;
end
if (nargin < 3 || isempty(sr))
    sr = finfo.SampleRate;
end

behav_idxs =  ismember(lower(finfo.Behavior.Type), lower(type));

if ~any(behav_idxs)
    idxs = [];
    warning('Could not find any instances of specified behavior type - check input');
    return;
end

start = finfo.Behavior.StartTime(behav_idxs);
stop = finfo.Behavior.StopTime(behav_idxs);
idxs = arrayfun(@(x,y) (round(x*sr)+1):min(round(y*sr), finfo.TotalRecTime*sr), start, stop, 'uni', 0);

if ~split
    idxs = unique(cell2mat(idxs'));
end