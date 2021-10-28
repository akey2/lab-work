% A silly function to return the index of the max or min value as the main
% output, rather than the actual value. Used primarily within 1-line anonymous
% functions.
function idx = ExtremumLoc(maxmin, vec, dim)

if nargin < 3
    dim = find(size(vec) > 1, 1);
end

switch (maxmin)
    case 'max'
        [~, idx] = max(vec, [], dim);
    case 'min'
        [~, idx] = min(vec, [], dim);
    otherwise
        idx = [];
end