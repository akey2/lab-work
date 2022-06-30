function [vals, idxs] = getClosestValues(points, vec, n)

if (nargin < 3 || isempty(n))
    n = 1;
end

vals = nan(n, length(points));
idxs = nan(n, length(points));
for i = 1:length(points)
    if (isnan(points(i)))
        continue;
    end
    
    [~, sortidx] = sort(abs(points(i) - vec));
    
    vals(:,i) = vec(sortidx(1:n));
    idxs(:,i) = sortidx(1:n);
end