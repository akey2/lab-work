function ext = Extents(data, dim)

if nargin < 2
%     dim = find(size(data) > 1, 1);
    ext = [min(data, [], 'all'), max(data, [], 'all')];
    return;
end

if (dim == 2)
    ext = [min(data, [], dim), max(data, [], dim)];
else
    ext = [min(data, [], dim); max(data, [], dim)];
end