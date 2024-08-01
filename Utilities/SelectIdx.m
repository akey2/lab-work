% Helper function to return selected elements from a vector. This is
% helpful in maybe one scenario - where you are selecting elements from a
% subset of a larger vector; e.g. selecting the last element of
% data(other_indices), where data is a larger vector - in which case you
% could call SelectIdx(data(other_indices), sum(other_indices));

function out = SelectIdx(data, varargin)

% assert(all(cellfun(@isnumeric, varargin)), 'Make sure all index inputs are numeric');
for i = 1:nargin-1
    if (~isnumeric(varargin{i}) && strcmp(varargin{i}, 'end'))
        varargin{i} = size(data,find(size(data)>1,1)+i-1);
    end
end

if ~iscell(data)
    out = data(varargin{:});
else
    out = data{varargin{:}};
end