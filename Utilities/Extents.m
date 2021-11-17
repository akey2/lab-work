function ext = Extents(data, dim)

if nargin < 2
    dim = find(size(data) > 1, 1);
end

ext = [min(data, [], dim), max(data, [], dim)];